import Photos
import UIKit

enum ExportError: LocalizedError {
    case missingPhoto(Int), denied, unableToSave
    var errorDescription: String? {
        switch self {
        case .missingPhoto(let slot): "Photo \(slot) is missing."
        case .denied: "Photo Library access was not granted. You can still share the set."
        case .unableToSave: "The photos could not be saved. Try sharing the set instead."
        }
    }
}

actor ExportService {
    static let shared = ExportService()

    func prepare(draft: ListingDraft) throws -> [URL] {
        let exportDirectory = PhotoFileStore.projectURL(draft.id).appending(path: "Export", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: exportDirectory, withIntermediateDirectories: true)
        var output: [URL] = []
        for record in draft.photoRecords.sorted(by: { $0.slot.rawValue < $1.slot.rawValue }) {
            let filename = record.useEdited ? (record.renderedFilename ?? record.originalFilename) : record.originalFilename
            guard let filename else { throw ExportError.missingPhoto(record.slot.rawValue) }
            let source = record.useEdited && record.renderedFilename != nil
                ? PhotoFileStore.renderedURL(projectID: draft.id, filename: filename)
                : PhotoFileStore.originalURL(projectID: draft.id, filename: filename)
            let suffix = record.slot == .exteriorFront ? "Cover" : record.slot.shortTitle.replacingOccurrences(of: " ", with: "-")
            let destination = exportDirectory.appending(path: String(format: "AxleBackdrop_%02d_%@.jpg", record.slot.rawValue, suffix))
            let data = try Data(contentsOf: source)
            guard let image = UIImage(data: data), let clean = image.normalizedFourByThree().jpegData(compressionQuality: 0.92) else {
                throw ProcessingError.renderFailed
            }
            try clean.write(to: destination, options: .atomic)
            output.append(destination)
        }
        return output
    }

    func saveToPhotos(urls: [URL]) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else { throw ExportError.denied }
        try await PHPhotoLibrary.shared().performChanges {
            for url in urls { PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: url) }
        }
    }
}
