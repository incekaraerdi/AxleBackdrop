import PhotosUI
import SwiftUI
import UIKit

struct PhotosView: View {
    @Bindable var draft: ListingDraft
    let advance: () -> Void
    @State private var selectedSlot: PhotoSlot = .exteriorFront
    @State private var selectedPickerItems: [PhotosPickerItem] = []
    @State private var showCamera = false
    @State private var pendingImage: UIImage?
    @State private var errorMessage: String?
    @State private var importingCount = 0
    @State private var cameraAvailable = UIImagePickerController.isSourceTypeAvailable(.camera)
    @State private var permissionDenied = false

    var body: some View {
        ZStack {
            AppColor.canvas.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    progressHeader
                    activePhoto
                    slotStrip
                    angleGuide
                    captureActions
                }.padding(16).padding(.bottom, 88)
            }
        }
        .navigationTitle("Photos").navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button("Choose a Scene", action: advance).buttonStyle(PrimaryButtonStyle())
                .disabled(!draft.isPhotoComplete).padding(16).background(.ultraThinMaterial)
        }
        .onChange(of: selectedPickerItems) { _, newItems in
            guard !newItems.isEmpty else { return }
            Task {
                for (index, item) in newItems.enumerated() {
                    do {
                        guard let data = try await item.loadTransferable(type: Data.self), let image = UIImage(data: data) else { throw PhotoFileStoreError.unreadableImage }
                        await MainActor.run {
                            importingCount = index + 1
                            Task { await store(image, for: PhotoSlot(rawValue: index) ?? .exteriorFront) }
                        }
                    } catch { await MainActor.run { errorMessage = error.localizedDescription } }
                }
                await MainActor.run { selectedPickerItems = [] }
            }
        }
        .sheet(isPresented: $showCamera) {
            CameraPicker(guide: selectedSlot.title(for: draft.vehicleType)) { image in pendingImage = image; showCamera = false }
                .ignoresSafeArea()
        }
        .alert("Photo unavailable", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: { Text(errorMessage ?? "") }
        .onAppear { cameraAvailable = UIImagePickerController.isSourceTypeAvailable(.camera) }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            cameraAvailable = UIImagePickerController.isSourceTypeAvailable(.camera)
        }
    }

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack { Text("\(draft.completedCount) of 5 photos").font(.headline); Spacer(); Text("Saved automatically").font(.caption).foregroundStyle(AppColor.secondaryText) }
            ProgressView(value: Double(draft.completedCount), total: 5).tint(AppColor.accent)
                .accessibilityLabel("Photo progress").accessibilityValue("\(draft.completedCount) of 5")
        }
    }

    private var activePhoto: some View {
        ZStack(alignment: .topLeading) {
            StoredPhotoView(url: originalURL(for: selectedSlot)).aspectRatio(4/3, contentMode: .fit)
            Text("\(selectedSlot.rawValue)  \(selectedSlot.title(for: draft.vehicleType))")
                .font(.caption.bold()).foregroundStyle(.white).padding(.horizontal, 10).padding(.vertical, 7)
                .background(.black.opacity(0.72)).clipShape(Capsule()).padding(12)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.72), style: StrokeStyle(lineWidth: 1.5, dash: [8, 6])).padding(28)
                .accessibilityHidden(true)
        }.background(AppColor.photoCanvas).clipShape(RoundedRectangle(cornerRadius: 24)).overlay { RoundedRectangle(cornerRadius: 24).stroke(AppColor.border) }
    }

    private var slotStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(PhotoSlot.allCases) { slot in
                    Button { selectedSlot = slot } label: {
                        VStack(spacing: 5) {
                            ZStack(alignment: .topTrailing) {
                                StoredPhotoView(url: originalURL(for: slot)).frame(width: 72, height: 54).clipShape(RoundedRectangle(cornerRadius: 9))
                                if draft.record(for: slot).originalFilename != nil {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.white, AppColor.success).offset(x: 5, y: -5)
                                }
                            }
                            Text("\(slot.rawValue)").font(.caption.bold())
                        }.padding(4).background(selectedSlot == slot ? AppColor.raised : .clear).clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay { RoundedRectangle(cornerRadius: 12).stroke(selectedSlot == slot ? AppColor.accent : .clear, lineWidth: 3) }
                    }.buttonStyle(.plain).accessibilityLabel("Photo \(slot.rawValue), \(slot.title(for: draft.vehicleType))")
                }
            }.padding(5)
        }
    }

    private var angleGuide: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: selectedSlot.receivesScene ? "viewfinder" : "sun.max")
                .font(.title2).frame(width: 44, height: 44).background(AppColor.raised).clipShape(Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(selectedSlot.title(for: draft.vehicleType)).font(.headline)
                Text(guideText).font(.subheadline).foregroundStyle(AppColor.secondaryText)
            }
        }.padding(16).appCard()
    }

    private var guideText: String {
        switch selectedSlot {
        case .exteriorFront: "Keep the full vehicle visible. Leave ground below the tires and space around mirrors."
        case .exteriorRear: "Match the camera height and distance from the first exterior photo."
        case .detailThree, .detailFour: "Use even light and keep condition-relevant details sharp. The original background stays."
        case .instrument: "Make every digit readable and keep the complete cluster inside the 4:3 frame."
        }
    }

    private var captureActions: some View {
        VStack(spacing: 10) {
            if cameraAvailable {
                if draft.record(for: selectedSlot).originalFilename == nil {
                    Button { showCamera = true } label: { Label("Take Photo", systemImage: "camera.fill") }
                        .buttonStyle(PrimaryButtonStyle())
                } else {
                    Button { showCamera = true } label: { Label("Retake Photo", systemImage: "camera.fill") }
                        .buttonStyle(SecondaryButtonStyle())
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Select 5 Photos (\(draft.completedCount) uploaded)").font(.caption).foregroundStyle(AppColor.secondaryText)
                PhotosPicker(selection: $selectedPickerItems, maxSelectionCount: 5, matching: .images) {
                    Label(draft.completedCount >= 5 ? "Replace from Library" : "Select Photos from Library", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(AppColor.accent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                if importingCount > 0 {
                    Text("Importing \(importingCount) of 5...").font(.caption).foregroundStyle(AppColor.accent)
                }
            }
        }
    }

    private func originalURL(for slot: PhotoSlot) -> URL? {
        guard let name = draft.record(for: slot).originalFilename else { return nil }
        return PhotoFileStore.originalURL(projectID: draft.id, filename: name)
    }

    @MainActor private func store(_ image: UIImage, for slot: PhotoSlot) async {
        do {
            guard let data = image.jpegData(compressionQuality: 0.95) else { throw PhotoFileStoreError.unableToEncode }
            let result = try await PhotoFileStore.shared.storeOriginal(data: data, projectID: draft.id, slot: slot)
            var record = draft.record(for: slot)
            record.originalFilename = result.originalFilename
            record.sourceFilename = result.sourceFilename
            record.sourceWidth = result.width
            record.sourceHeight = result.height
            record.sourceOrientation = result.orientation
            record.renderedFilename = nil
            record.state = .ready
            record.errorMessage = nil
            draft.updateRecord(record)
        } catch { errorMessage = error.localizedDescription }
    }
}
struct CameraPicker: UIViewControllerRepresentable {
    let guide: String
    let completion: (UIImage) -> Void
    func makeCoordinator() -> Coordinator { Coordinator(completion: completion) }
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController(); picker.sourceType = .camera; picker.cameraCaptureMode = .photo
        picker.delegate = context.coordinator; picker.allowsEditing = false
        picker.cameraOverlayView = CaptureGuideOverlay(frame: UIScreen.main.bounds, guide: guide)
        return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let completion: (UIImage) -> Void
        init(completion: @escaping (UIImage) -> Void) { self.completion = completion }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage { completion(image) } else { picker.dismiss(animated: true) }
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { picker.dismiss(animated: true) }
    }
}

private final class CaptureGuideOverlay: UIView {
    private let guideLayer = CAShapeLayer()
    init(frame: CGRect, guide: String) {
        super.init(frame: frame)
        isUserInteractionEnabled = false; backgroundColor = .clear
        guideLayer.fillColor = UIColor.clear.cgColor; guideLayer.strokeColor = UIColor.white.withAlphaComponent(0.85).cgColor
        guideLayer.lineWidth = 2; guideLayer.lineDashPattern = [10, 7]
        layer.addSublayer(guideLayer)
        let label = UILabel(); label.text = guide; label.textColor = .white; label.font = .preferredFont(forTextStyle: .headline)
        label.backgroundColor = UIColor.black.withAlphaComponent(0.72); label.textAlignment = .center; label.layer.cornerRadius = 18; label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false; addSubview(label)
        NSLayoutConstraint.activate([label.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 18), label.centerXAnchor.constraint(equalTo: centerXAnchor), label.heightAnchor.constraint(greaterThanOrEqualToConstant: 36), label.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, multiplier: 0.9)])
    }
    required init?(coder: NSCoder) { nil }
    override func layoutSubviews() {
        super.layoutSubviews()
        guideLayer.path = UIBezierPath(roundedRect: bounds.insetBy(dx: 34, dy: bounds.height * 0.23), cornerRadius: 28).cgPath
    }
}

extension UIImage: @retroactive Identifiable { public var id: ObjectIdentifier { ObjectIdentifier(self) } }
