import PhotosUI
import SwiftData
import SwiftUI

struct SceneView: View {
    @Bindable var draft: ListingDraft
    let advance: () -> Void
    @Query(sort: \DealerTemplate.createdAt, order: .reverse) private var templates: [DealerTemplate]
    @State private var previewSlot: PhotoSlot = .exteriorFront
    @State private var templatePicker: PhotosPickerItem?
    @State private var importedBackground: UIImage?
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            AppColor.canvas.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Choose one backdrop for both exterior photos.").font(.title2.bold())
                    scenePreview
                    Label("Placement preview only — the final cutout appears after processing.", systemImage: "info.circle")
                        .font(.caption).foregroundStyle(AppColor.secondaryText)
                    Picker("Exterior angle", selection: $previewSlot) {
                        Text("Front ¾").tag(PhotoSlot.exteriorFront); Text("Rear ¾").tag(PhotoSlot.exteriorRear)
                    }.pickerStyle(.segmented)
                    builtInScenes
                    dealerTemplates
                }.padding(16).padding(.bottom, 88)
            }
        }
        .navigationTitle("Scene").navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button("Process 5 Photos", action: advance).buttonStyle(PrimaryButtonStyle()).padding(16).background(.ultraThinMaterial)
        }
        .onChange(of: templatePicker) { _, item in
            guard let item else { return }
            Task {
                do {
                    guard let data = try await item.loadTransferable(type: Data.self), let image = UIImage(data: data) else { throw PhotoFileStoreError.unreadableImage }
                    await MainActor.run { importedBackground = image }
                } catch { await MainActor.run { errorMessage = error.localizedDescription } }
            }
        }
        .sheet(item: $importedBackground) { image in CustomSceneEditor(draft: draft, background: image) }
        .alert("Template unavailable", isPresented: .constant(errorMessage != nil)) { Button("OK") { errorMessage = nil } } message: { Text(errorMessage ?? "") }
    }

    private var scenePreview: some View {
        ZStack(alignment: .bottomLeading) {
            sceneImage.resizable().scaledToFill().aspectRatio(4/3, contentMode: .fit)
            if let url = photoURL(previewSlot), let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image).resizable().scaledToFit().opacity(0.42).padding(34)
            }
            Text("Preview • \(previewSlot.shortTitle)").font(.caption.bold()).foregroundStyle(.white)
                .padding(.horizontal, 10).padding(.vertical, 7).background(.black.opacity(0.72)).clipShape(Capsule()).padding(12)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        }.background(AppColor.photoCanvas).clipShape(RoundedRectangle(cornerRadius: 24)).overlay { RoundedRectangle(cornerRadius: 24).stroke(AppColor.border) }
    }

    private var builtInScenes: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Built-in scenes").font(.headline)
            HStack(spacing: 12) {
                sceneCard(.indoorGarage); sceneCard(.outdoorScenic)
            }
        }
    }

    private func sceneCard(_ scene: SceneKind) -> some View {
        Button { draft.scene = scene; draft.customTemplateID = nil } label: {
            VStack(alignment: .leading, spacing: 8) {
                Image(scene.assetName!).resizable().scaledToFill().frame(height: 92).clipped()
                HStack { Text(scene.title).font(.subheadline.bold()); Spacer(); Image(systemName: draft.scene == scene ? "checkmark.circle.fill" : "circle") }
                    .padding(.horizontal, 10).padding(.bottom, 10)
            }.background(AppColor.surface).clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay { RoundedRectangle(cornerRadius: 14).stroke(draft.scene == scene ? AppColor.accent : AppColor.border, lineWidth: draft.scene == scene ? 3 : 1) }
        }.buttonStyle(.plain).frame(maxWidth: .infinity)
    }

    private var dealerTemplates: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Dealer templates").font(.headline); Spacer()
                PhotosPicker(selection: $templatePicker, matching: .images) { Label("Import", systemImage: "plus") }
            }
            if templates.isEmpty {
                Text("Import an empty showroom or branded wall. You’ll check placement from both exterior angles before saving.")
                    .font(.subheadline).foregroundStyle(AppColor.secondaryText).padding(16).frame(maxWidth: .infinity, alignment: .leading).appCard()
            } else {
                ForEach(templates) { template in
                    Button {
                        draft.scene = .custom; draft.customTemplateID = template.id
                        draft.frontPlacement = template.frontPlacement; draft.rearPlacement = template.rearPlacement
                    } label: {
                        HStack {
                            StoredPhotoView(url: PhotoFileStore.templateURL(filename: template.backgroundFilename)).frame(width: 88, height: 66).clipShape(RoundedRectangle(cornerRadius: 10))
                            VStack(alignment: .leading) { Text(template.name).font(.headline); Text("Checked for both exterior angles").font(.caption).foregroundStyle(AppColor.secondaryText) }
                            Spacer(); Image(systemName: draft.customTemplateID == template.id ? "checkmark.circle.fill" : "circle")
                        }.padding(10).appCard()
                    }.buttonStyle(.plain)
                }
            }
        }
    }

    private var sceneImage: Image {
        if draft.scene == .custom, let template = templates.first(where: { $0.id == draft.customTemplateID }), let image = UIImage(contentsOfFile: PhotoFileStore.templateURL(filename: template.backgroundFilename).path) { return Image(uiImage: image) }
        return Image(draft.scene.assetName ?? "IndoorGarage")
    }
    private func photoURL(_ slot: PhotoSlot) -> URL? {
        guard let name = draft.record(for: slot).originalFilename else { return nil }
        return PhotoFileStore.originalURL(projectID: draft.id, filename: name)
    }
}

struct CustomSceneEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var draft: ListingDraft
    let background: UIImage
    @State private var angle: PhotoSlot = .exteriorFront
    @State private var front = Placement()
    @State private var rear = Placement(y: 0.08, scale: 0.78)
    @State private var reviewedFront = false
    @State private var reviewedRear = false
    @State private var errorMessage: String?

    private var placement: Binding<Placement> {
        angle == .exteriorFront ? $front : $rear
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                ZStack {
                    Image(uiImage: background.normalizedFourByThree()).resizable().scaledToFit()
                    if let image = vehicleImage {
                        Image(uiImage: image).resizable().scaledToFit()
                            .scaleEffect(placement.wrappedValue.scale)
                            .offset(x: placement.wrappedValue.x * 240, y: placement.wrappedValue.y * 180)
                            .opacity(0.56).padding(28)
                    }
                    Rectangle().fill(.white.opacity(0.75)).frame(height: 1).offset(y: 72).accessibilityHidden(true)
                }.background(AppColor.photoCanvas).clipShape(RoundedRectangle(cornerRadius: 20)).padding(.horizontal)
                Picker("Angle", selection: $angle) {
                    Text("Front ¾").tag(PhotoSlot.exteriorFront); Text("Rear ¾").tag(PhotoSlot.exteriorRear)
                }.pickerStyle(.segmented).padding(.horizontal).onChange(of: angle) { markReviewed() }
                VStack(spacing: 12) {
                    HStack { Text("Scale"); Slider(value: placement.scale, in: 0.55...1.05); Text(placement.wrappedValue.scale, format: .percent.precision(.fractionLength(0))).monospacedDigit() }
                    HStack { Text("Horizontal"); Slider(value: placement.x, in: -0.25...0.25) }
                    HStack { Text("Ground contact"); Slider(value: placement.y, in: -0.12...0.25) }
                }.padding(16).appCard().padding(.horizontal)
                HStack {
                    Button("Reset") { if angle == .exteriorFront { front = Placement() } else { rear = Placement(y: 0.08, scale: 0.78) } }
                    Spacer(); Label(reviewedFront ? "Front checked" : "Check front", systemImage: reviewedFront ? "checkmark.circle.fill" : "circle"); Label(reviewedRear ? "Rear checked" : "Check rear", systemImage: reviewedRear ? "checkmark.circle.fill" : "circle")
                }.font(.caption).padding(.horizontal).foregroundStyle(AppColor.secondaryText)
                Spacer()
                Button("Save Dealer Template") { save() }.buttonStyle(PrimaryButtonStyle()).disabled(!(reviewedFront && reviewedRear)).padding()
            }.background(AppColor.canvas).navigationTitle("Custom Scene").navigationBarTitleDisplayMode(.inline)
                .toolbar { Button("Cancel") { dismiss() } }.onAppear { markReviewed() }
                .alert("Couldn’t save template", isPresented: .constant(errorMessage != nil)) { Button("OK") { errorMessage = nil } } message: { Text(errorMessage ?? "") }
        }
    }

    private var vehicleImage: UIImage? {
        guard let name = draft.record(for: angle).originalFilename else { return nil }
        return UIImage(contentsOfFile: PhotoFileStore.originalURL(projectID: draft.id, filename: name).path)
    }
    private func markReviewed() { if angle == .exteriorFront { reviewedFront = true } else { reviewedRear = true } }
    private func save() {
        Task { @MainActor in
            do {
                guard let data = background.jpegData(compressionQuality: 0.94) else { throw PhotoFileStoreError.unableToEncode }
                let id = UUID(); let filename = try await PhotoFileStore.shared.storeTemplate(data: data, id: id)
                let template = DealerTemplate(name: "Dealer Scene \(Date.now.formatted(date: .abbreviated, time: .omitted))", backgroundFilename: filename, front: front, rear: rear)
                modelContext.insert(template); try modelContext.save()
                draft.scene = .custom; draft.customTemplateID = template.id; draft.frontPlacement = front; draft.rearPlacement = rear
                dismiss()
            } catch { errorMessage = error.localizedDescription }
        }
    }
}

struct ProcessingView: View {
    @Bindable var draft: ListingDraft
    let advance: () -> Void
    @Query private var templates: [DealerTemplate]
    @State private var started = false
    @State private var isFinished = false
    @State private var processingTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            AppColor.canvas.ignoresSafeArea()
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(isFinished ? "Your set is ready" : "Preparing your set").font(.largeTitle.bold())
                    Text("Completed photos stay available if another photo needs attention.").foregroundStyle(AppColor.secondaryText)
                }.frame(maxWidth: .infinity, alignment: .leading)
                VStack(spacing: 0) {
                    ForEach(draft.photoRecords) { record in
                        ProcessingRow(record: record, useOriginal: { useOriginal(record) })
                        if record.slot != .instrument { Divider() }
                    }
                }.padding(.horizontal, 16).appCard()
                Spacer()
                Button("Review Photos", action: advance).buttonStyle(PrimaryButtonStyle()).disabled(!isFinished)
            }.padding(16)
        }.navigationTitle("Processing").navigationBarBackButtonHidden(!isFinished)
            .task { guard !started else { return }; started = true; await process() }
    }

    @MainActor private func process() async {
        for record in draft.photoRecords where record.state != .completed {
            var working = record; working.state = .processing; working.errorMessage = nil; draft.updateRecord(working)
            do {
                let sourceFilename = working.sourceFilename ?? working.originalFilename
                guard let name = sourceFilename else { throw ExportError.missingPhoto(working.slot.rawValue) }
                let source = PhotoFileStore.originalURL(projectID: draft.id, filename: name)
                let data: Data
                if working.slot.receivesScene {
                    guard let background = selectedBackground else { throw ProcessingError.imageUnavailable }
                    let placement = working.slot == .exteriorFront ? draft.frontPlacement : draft.rearPlacement
                    data = try await ImageProcessingService.shared.renderExterior(sourceURL: source, background: background, placement: placement)
                } else if working.slot == .instrument {
                    data = try await ImageProcessingService.shared.metadataStrippedCopy(sourceURL: source)
                } else {
                    data = try await ImageProcessingService.shared.correctDetail(sourceURL: source)
                }
                let filename = try await PhotoFileStore.shared.storeRendered(data: data, projectID: draft.id, slot: working.slot)
                working.renderedFilename = filename; working.state = .completed; working.useEdited = true
            } catch is CancellationError { return }
            catch { working.state = .needsAttention; working.errorMessage = error.localizedDescription }
            draft.updateRecord(working)
        }
        isFinished = draft.photoRecords.allSatisfy { $0.state == .completed }
    }

    private var selectedBackground: UIImage? {
        if draft.scene == .custom, let template = templates.first(where: { $0.id == draft.customTemplateID }) { return UIImage(contentsOfFile: PhotoFileStore.templateURL(filename: template.backgroundFilename).path) }
        return UIImage(named: draft.scene.assetName ?? "IndoorGarage")
    }
    private func useOriginal(_ record: PhotoRecord) {
        var updated = record; updated.renderedFilename = nil; updated.useEdited = false; updated.state = .completed; updated.errorMessage = nil; draft.updateRecord(updated)
        isFinished = draft.photoRecords.allSatisfy { $0.state == .completed }
    }
}

private struct ProcessingRow: View {
    let record: PhotoRecord
    let useOriginal: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Text("\(record.slot.rawValue)").font(.caption.bold()).frame(width: 28, height: 28).background(AppColor.raised).clipShape(Circle())
                VStack(alignment: .leading) { Text(record.slot.shortTitle).font(.headline); Text(statusText).font(.caption).foregroundStyle(statusColor) }
                Spacer(); statusIcon
            }
            if let error = record.errorMessage {
                Text(error).font(.caption).foregroundStyle(AppColor.error)
                Button("Use Original", action: useOriginal).font(.subheadline.bold())
            }
        }.padding(.vertical, 13).accessibilityElement(children: .combine)
    }
    private var statusText: String {
        switch record.state { case .empty: "Missing"; case .ready: "Queued"; case .queued: "Queued"; case .processing: "Processing"; case .completed: record.useEdited ? "Completed" : "Original selected"; case .needsAttention: "Needs attention" }
    }
    private var statusColor: Color { record.state == .needsAttention ? AppColor.error : record.state == .completed ? AppColor.success : AppColor.secondaryText }
    @ViewBuilder private var statusIcon: some View {
        switch record.state {
        case .processing: ProgressView()
        case .completed: Image(systemName: "checkmark.circle.fill").foregroundStyle(AppColor.success)
        case .needsAttention: Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(AppColor.error)
        default: Image(systemName: "circle").foregroundStyle(AppColor.secondaryText)
        }
    }
}
