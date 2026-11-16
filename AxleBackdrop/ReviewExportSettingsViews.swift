import SwiftUI
import UIKit

struct ReviewView: View {
    @Bindable var draft: ListingDraft
    let advance: () -> Void
    @State private var selectedSlot: PhotoSlot = .exteriorFront
    @State private var showEdited = true

    var body: some View {
        ZStack {
            AppColor.canvas.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(selectedSlot == .exteriorFront ? "Cover photo" : selectedSlot.title(for: draft.vehicleType))
                        .font(.title2.bold()).lineLimit(2).fixedSize(horizontal: false, vertical: true)
                    hero
                    Picker("Version", selection: $showEdited) { Text("Original").tag(false); Text("Edited").tag(true) }
                        .pickerStyle(.segmented).onChange(of: showEdited) { updateVariant() }
                    exportStrip
                    qualityNote
                }.padding(16).padding(.bottom, 88)
            }
        }
        .navigationTitle("Review").navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) { Button("Review Export", action: advance).buttonStyle(PrimaryButtonStyle()).padding(16).background(.ultraThinMaterial) }
        .onAppear { showEdited = draft.record(for: selectedSlot).useEdited && draft.record(for: selectedSlot).renderedFilename != nil }
        .onChange(of: selectedSlot) { showEdited = draft.record(for: selectedSlot).useEdited && draft.record(for: selectedSlot).renderedFilename != nil }
    }

    private var hero: some View {
        ZStack(alignment: .topTrailing) {
            StoredPhotoView(url: selectedURL).aspectRatio(4/3, contentMode: .fit)
            Text(showEdited ? badgeText : "Original").font(.caption.bold()).foregroundStyle(.white).padding(.horizontal, 10).padding(.vertical, 7)
                .background(.black.opacity(0.72)).clipShape(Capsule()).padding(12)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        }.background(AppColor.photoCanvas).clipShape(RoundedRectangle(cornerRadius: 24)).overlay { RoundedRectangle(cornerRadius: 24).stroke(AppColor.border) }
            .accessibilityLabel("\(selectedSlot.title(for: draft.vehicleType)), \(showEdited ? "edited" : "original")")
    }
    private var badgeText: String { selectedSlot.receivesScene ? "Scene" : selectedSlot == .instrument ? "Preserved" : "Adjusted" }

    private var exportStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            ViewThatFits(in: .horizontal) {
                HStack { Text("Export order").font(.headline); Spacer(); Text("1 is the cover").font(.caption).foregroundStyle(AppColor.secondaryText) }
                VStack(alignment: .leading, spacing: 2) { Text("Export order").font(.headline); Text("1 is the cover").font(.caption).foregroundStyle(AppColor.secondaryText) }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(PhotoSlot.allCases) { slot in
                        Button { selectedSlot = slot } label: {
                            VStack(alignment: .leading, spacing: 5) {
                                StoredPhotoView(url: url(for: slot)).frame(width: 88, height: 66).clipShape(RoundedRectangle(cornerRadius: 10))
                                HStack(spacing: 4) { Text("\(slot.rawValue)").font(.caption.bold()); Text(label(for: slot)).font(.caption2).lineLimit(1) }
                            }.padding(5).background(selectedSlot == slot ? AppColor.raised : .clear).clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay { RoundedRectangle(cornerRadius: 12).stroke(selectedSlot == slot ? AppColor.accent : .clear, lineWidth: 3) }
                        }.buttonStyle(.plain)
                    }
                }.padding(5)
            }
        }
    }

    private var qualityNote: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.shield.fill").foregroundStyle(AppColor.success)
            Text("Check mirrors, wheels, decals, accessories, visible condition, and ground contact. Choose Original if an edit hides a real detail.")
                .font(.subheadline).foregroundStyle(AppColor.secondaryText)
        }.padding(16).appCard()
    }

    private var selectedURL: URL? { showEdited ? editedURL(for: selectedSlot) ?? originalURL(for: selectedSlot) : originalURL(for: selectedSlot) }
    private func url(for slot: PhotoSlot) -> URL? { let r = draft.record(for: slot); return r.useEdited ? editedURL(for: slot) ?? originalURL(for: slot) : originalURL(for: slot) }
    private func originalURL(for slot: PhotoSlot) -> URL? { guard let name = draft.record(for: slot).originalFilename else { return nil }; return PhotoFileStore.originalURL(projectID: draft.id, filename: name) }
    private func editedURL(for slot: PhotoSlot) -> URL? { guard let name = draft.record(for: slot).renderedFilename else { return nil }; return PhotoFileStore.renderedURL(projectID: draft.id, filename: name) }
    private func label(for slot: PhotoSlot) -> String { let r = draft.record(for: slot); return r.useEdited && r.renderedFilename != nil ? (slot.receivesScene ? "Scene" : slot == .instrument ? "Preserved" : "Adjusted") : "Original" }
    private func updateVariant() { var r = draft.record(for: selectedSlot); r.useEdited = showEdited && r.renderedFilename != nil; draft.updateRecord(r) }
}

struct ExportView: View {
    @Bindable var draft: ListingDraft
    @State private var urls: [URL] = []
    @State private var isPreparing = true
    @State private var isSaving = false
    @State private var showShare = false
    @State private var message: ExportMessage?

    var body: some View {
        ZStack {
            AppColor.canvas.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Exactly five JPEGs").font(.largeTitle.bold())
                    Text("3000 × 2250 • 4:3 • sRGB • location metadata removed").foregroundStyle(AppColor.secondaryText)
                    exportList
                    if let message { statusCard(message) }
                    Button { Task { await save() } } label: {
                        if isSaving { ProgressView().tint(.white) } else { Label("Save 5 Photos", systemImage: "square.and.arrow.down") }
                    }.buttonStyle(PrimaryButtonStyle()).disabled(isPreparing || isSaving)
                    Button { showShare = true } label: {
                        Label("Share Set", systemImage: "square.and.arrow.up").frame(maxWidth: .infinity, minHeight: 50)
                            .background(AppColor.surface).clipShape(RoundedRectangle(cornerRadius: 12)).overlay { RoundedRectangle(cornerRadius: 12).stroke(AppColor.border) }
                    }.buttonStyle(.plain).disabled(urls.count != 5)
                }.padding(16)
            }
        }.navigationTitle("Export").navigationBarTitleDisplayMode(.inline)
            .task { await prepare() }
            .sheet(isPresented: $showShare) { ActivityView(items: urls) }
    }

    private var exportList: some View {
        VStack(spacing: 0) {
            ForEach(Array(PhotoSlot.allCases.enumerated()), id: \.element) { index, slot in
                HStack(spacing: 12) {
                    StoredPhotoView(url: index < urls.count ? urls[index] : nil).frame(width: 88, height: 66).clipShape(RoundedRectangle(cornerRadius: 10))
                    VStack(alignment: .leading) {
                        Text(slot == .exteriorFront ? "Cover" : slot.shortTitle).font(.headline)
                        Text(String(format: "AxleBackdrop_%02d_%@.jpg", slot.rawValue, slot == .exteriorFront ? "Cover" : slot.shortTitle.replacingOccurrences(of: " ", with: "-")))
                            .font(.caption).foregroundStyle(AppColor.secondaryText).lineLimit(1)
                    }
                    Spacer(); Image(systemName: index < urls.count ? "checkmark.circle.fill" : "clock").foregroundStyle(index < urls.count ? AppColor.success : AppColor.secondaryText)
                }.padding(.vertical, 10)
                if slot != .instrument { Divider() }
            }
        }.padding(.horizontal, 14).appCard()
    }

    private func statusCard(_ message: ExportMessage) -> some View {
        Label(message.text, systemImage: message.success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
            .foregroundStyle(message.success ? AppColor.success : AppColor.error).padding(16).frame(maxWidth: .infinity, alignment: .leading).appCard()
    }
    @MainActor private func prepare() async {
        do { urls = try await ExportService.shared.prepare(draft: draft); isPreparing = false }
        catch { isPreparing = false; message = ExportMessage(text: error.localizedDescription, success: false) }
    }
    @MainActor private func save() async {
        isSaving = true
        do { try await ExportService.shared.saveToPhotos(urls: urls); message = ExportMessage(text: "Five photos were saved to your library.", success: true) }
        catch { message = ExportMessage(text: error.localizedDescription, success: false) }
        isSaving = false
    }
}

private struct ExportMessage { let text: String; let success: Bool }

struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController { UIActivityViewController(activityItems: items, applicationActivities: nil) }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appearance") private var appearanceRaw = AppearancePreference.system.rawValue
    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Picker("Appearance", selection: $appearanceRaw) {
                        ForEach(AppearancePreference.allCases) { Text($0.label).tag($0.rawValue) }
                    }.pickerStyle(.segmented)
                }
                Section("Privacy") {
                    Label("Photos are processed on this iPhone in this beta.", systemImage: "iphone.and.arrow.forward")
                    Label("Location and unnecessary metadata are removed on export.", systemImage: "location.slash")
                    Text("If a future cloud fallback is offered, AxleBackdrop will explain the provider, purpose, and retention before asking for consent.")
                        .font(.footnote).foregroundStyle(AppColor.secondaryText)
                }
                Section("Support") {
                    Link("Contact Support", destination: URL(string: "mailto:support@axlebackdrop.app")!)
                    LabeledContent("Version", value: version)
                }
            }.navigationTitle("Settings").toolbar { Button("Done") { dismiss() } }
        }
    }
    private var version: String {
        let info = Bundle.main.infoDictionary
        let marketing = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(marketing) (\(build))"
    }
}
