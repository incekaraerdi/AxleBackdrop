import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ListingDraft.updatedAt, order: .reverse) private var drafts: [ListingDraft]
    @AppStorage("appearance") private var appearanceRaw = AppearancePreference.system.rawValue
    @AppStorage("didCompleteFirstLaunch") private var didCompleteFirstLaunch = false
    @State private var path: [UUID] = []
    private var appearance: AppearancePreference { AppearancePreference(rawValue: appearanceRaw) ?? .system }

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(drafts: drafts, onNewListing: createDraft, onOpen: { path.append($0.id) })
                .navigationDestination(for: UUID.self) { id in
                    if let draft = drafts.first(where: { $0.id == id }) { ListingFlowView(draft: draft) }
                    else { ContentUnavailableView("Draft unavailable", systemImage: "exclamationmark.triangle", description: Text("Return to Drafts and choose another listing.")) }
                }
        }
        .preferredColorScheme(appearance.scheme).tint(AppColor.accent)
        .onAppear {
#if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-QAHome") {
                didCompleteFirstLaunch = true
                return
            }
            if let qaStage = qaStageArgument {
                if path.isEmpty { createQADraft(stage: qaStage) }
                return
            }
#endif
            guard !didCompleteFirstLaunch else { return }
            didCompleteFirstLaunch = true; createDraft()
        }
    }

    private func createDraft() {
        let draft = ListingDraft(); modelContext.insert(draft); try? modelContext.save(); path.append(draft.id)
    }

#if DEBUG
    private var qaStageArgument: ListingStage? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-QAStage"), arguments.indices.contains(index + 1) else { return nil }
        return ListingStage(rawValue: arguments[index + 1])
    }

    private func createQADraft(stage: ListingStage) {
        let draft = ListingDraft(vehicleType: .car)
        guard let source = UIImage(named: "OutdoorScenic"), let data = source.normalizedFourByThree().jpegData(compressionQuality: 0.92) else { return }
        let originals = PhotoFileStore.projectURL(draft.id).appending(path: "Originals", directoryHint: .isDirectory)
        let rendered = PhotoFileStore.projectURL(draft.id).appending(path: "Rendered", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: originals, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: rendered, withIntermediateDirectories: true)
        var records: [PhotoRecord] = []
        for slot in PhotoSlot.allCases {
            let originalName = "slot-\(slot.rawValue)-original.jpg"
            let renderedName = "slot-\(slot.rawValue)-edited.jpg"
            try? data.write(to: originals.appending(path: originalName), options: .atomic)
            try? data.write(to: rendered.appending(path: renderedName), options: .atomic)
            records.append(PhotoRecord(slot: slot, originalFilename: originalName, renderedFilename: renderedName, state: .completed, useEdited: true))
        }
        draft.photoRecords = records; draft.stage = stage
        modelContext.insert(draft); try? modelContext.save(); path.append(draft.id)
    }
#endif
}

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    let drafts: [ListingDraft]
    let onNewListing: () -> Void
    let onOpen: (ListingDraft) -> Void
    @State private var showSettings = false

    var body: some View {
        ZStack {
            AppColor.canvas.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    hero
                    if drafts.isEmpty { emptyState } else { draftList }
                }.padding(16)
            }
        }
        .navigationTitle("AxleBackdrop")
        .toolbar { Button("Settings", systemImage: "gearshape") { showSettings = true } }
        .sheet(isPresented: $showSettings) { SettingsView() }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: "camera.aperture").font(.system(size: 34, weight: .semibold)).foregroundStyle(AppColor.accent)
            Text("Listing-ready photos, one consistent set.").font(.title.bold()).foregroundStyle(AppColor.primaryText)
            Text("Guide five real photos, apply one scene to both exterior angles, then save or share.").foregroundStyle(AppColor.secondaryText)
            Button(action: onNewListing) { Label("New Listing", systemImage: "plus") }.buttonStyle(PrimaryButtonStyle())
            Label("Photos stay on this iPhone unless you explicitly approve a future cloud fallback.", systemImage: "lock.shield")
                .font(.caption).foregroundStyle(AppColor.secondaryText)
        }.padding(20).appCard()
    }

    private var emptyState: some View {
        ContentUnavailableView("No drafts yet", systemImage: "car.side", description: Text("Your first five-photo set will appear here."))
            .frame(maxWidth: .infinity).padding(.vertical, 40)
    }

    private var draftList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Drafts").font(.title2.bold())
            ForEach(drafts) { draft in
                Button { onOpen(draft) } label: { DraftCard(draft: draft) }.buttonStyle(.plain)
                    .contextMenu {
                        Button("Delete Draft", role: .destructive) {
                            Task { try? await PhotoFileStore.shared.deleteProject(id: draft.id) }
                            modelContext.delete(draft); try? modelContext.save()
                        }
                    }
            }
        }
    }
}

private struct DraftCard: View {
    let draft: ListingDraft
    var body: some View {
        HStack(spacing: 14) {
            StoredPhotoView(url: coverURL).frame(width: 104, height: 78).clipShape(RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 6) {
                Label(draft.vehicleType.title, systemImage: draft.vehicleType.symbol).font(.headline)
                Text("\(draft.completedCount) of 5 photos").font(.subheadline).foregroundStyle(AppColor.secondaryText)
                ProgressView(value: Double(draft.completedCount), total: 5).tint(AppColor.accent)
                Text(draft.updatedAt, style: .relative).font(.caption).foregroundStyle(AppColor.secondaryText)
            }
            Spacer(); Image(systemName: "chevron.right").foregroundStyle(AppColor.secondaryText)
        }.padding(12).appCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(draft.vehicleType.title) draft, \(draft.completedCount) of 5 photos")
    }
    private var coverURL: URL? {
        guard let filename = draft.record(for: .exteriorFront).originalFilename else { return nil }
        return PhotoFileStore.originalURL(projectID: draft.id, filename: filename)
    }
}

struct ListingFlowView: View {
    @Bindable var draft: ListingDraft
    @Environment(\.modelContext) private var modelContext
    var body: some View {
        Group {
            switch draft.stage {
            case .vehicleType: VehicleTypeView(draft: draft, advance: { move(to: .photos) })
            case .photos: PhotosView(draft: draft, advance: { move(to: .scene) })
            case .scene: SceneView(draft: draft, advance: { move(to: .processing) })
            case .processing: ProcessingView(draft: draft, advance: { move(to: .review) })
            case .review: ReviewView(draft: draft, advance: { move(to: .export) })
            case .export: ExportView(draft: draft)
            }
        }.onChange(of: draft.updatedAt) { try? modelContext.save() }
    }
    private func move(to stage: ListingStage) {
        withAnimation(.easeInOut(duration: 0.22)) { draft.stage = stage }; try? modelContext.save()
    }
}

struct VehicleTypeView: View {
    @Bindable var draft: ListingDraft
    let advance: () -> Void
    var body: some View {
        ZStack {
            AppColor.canvas.ignoresSafeArea()
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Choose a vehicle").font(.largeTitle.bold())
                    Text("The five-photo guide adapts to the vehicle type.").foregroundStyle(AppColor.secondaryText)
                }.frame(maxWidth: .infinity, alignment: .leading)
                HStack(spacing: 12) {
                    ForEach(VehicleType.allCases) { type in
                        Button { draft.vehicleType = type } label: {
                            VStack(spacing: 12) {
                                Image(systemName: type.symbol).font(.system(size: 36)); Text(type.title).font(.headline)
                                Image(systemName: draft.vehicleType == type ? "checkmark.circle.fill" : "circle")
                            }.frame(maxWidth: .infinity, minHeight: 154)
                                .foregroundStyle(draft.vehicleType == type ? AppColor.accent : AppColor.primaryText)
                                .background(AppColor.surface).clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay { RoundedRectangle(cornerRadius: 16).stroke(draft.vehicleType == type ? AppColor.accent : AppColor.border, lineWidth: draft.vehicleType == type ? 3 : 1) }
                        }.buttonStyle(.plain)
                    }
                }
                VStack(spacing: 0) {
                    ForEach(PhotoSlot.allCases) { slot in
                        HStack { Text("\(slot.rawValue)").font(.caption.bold()).frame(width: 24, height: 24).background(AppColor.raised).clipShape(Circle()); Text(slot.title(for: draft.vehicleType)); Spacer() }.padding(.vertical, 10)
                        if slot != .instrument { Divider() }
                    }
                }.padding(.horizontal, 16).appCard()
                Spacer(); Button("Continue", action: advance).buttonStyle(PrimaryButtonStyle())
            }.padding(16)
        }.navigationTitle("New Listing").navigationBarTitleDisplayMode(.inline)
    }
}

struct StoredPhotoView: View {
    let url: URL?
    var body: some View {
        ZStack {
            AppColor.photoCanvas
            if let url, let image = UIImage(contentsOfFile: url.path) { Image(uiImage: image).resizable().scaledToFill() }
            else { Image(systemName: "photo").font(.title2).foregroundStyle(AppColor.secondaryText) }
        }.clipped()
    }
}

#Preview { ContentView().modelContainer(for: [ListingDraft.self, DealerTemplate.self], inMemory: true) }
