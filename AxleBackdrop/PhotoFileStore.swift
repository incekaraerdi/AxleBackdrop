import ImageIO
import UIKit

enum PhotoFileStoreError: LocalizedError {
    case unreadableImage, unableToEncode, insufficientStorage
    var errorDescription: String? {
        switch self {
        case .unreadableImage: "This photo could not be read. Choose another photo."
        case .unableToEncode: "The photo could not be prepared."
        case .insufficientStorage: "There is not enough free storage to save this photo."
        }
    }
}

extension PhotoFileStore {
    nonisolated static func checkDiskSpace(minRequired: Int = 100 * 1024 * 1024) throws {
        let path = NSHomeDirectory()
        let fileManager = FileManager.default
        guard let attributes = try? fileManager.attributesOfFileSystem(forPath: path) as NSDictionary,
              let freeSpace = attributes[FileAttributeKey.systemFreeSize] as? NSNumber else {
            throw PhotoFileStoreError.insufficientStorage
        }
        guard freeSpace.intValue > minRequired else {
            throw PhotoFileStoreError.insufficientStorage
        }
    }
}

actor PhotoFileStore {
    static let shared = PhotoFileStore()

    nonisolated static var rootURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appending(path: "AxleBackdrop", directoryHint: .isDirectory)
    }

    nonisolated static func projectURL(_ id: UUID) -> URL {
        rootURL.appending(path: "Drafts/\(id.uuidString)", directoryHint: .isDirectory)
    }

    nonisolated static func originalURL(projectID: UUID, filename: String) -> URL {
        projectURL(projectID).appending(path: "Originals/\(filename)")
    }

    nonisolated static func renderedURL(projectID: UUID, filename: String) -> URL {
        projectURL(projectID).appending(path: "Rendered/\(filename)")
    }

    nonisolated static func templateURL(filename: String) -> URL {
        rootURL.appending(path: "Templates/\(filename)")
    }

    func storeOriginal(data: Data, projectID: UUID, slot: PhotoSlot) throws -> (originalFilename: String, sourceFilename: String, width: Int, height: Int, orientation: String) {
        try Self.checkDiskSpace()
        guard let image = UIImage(data: data) else { throw PhotoFileStoreError.unreadableImage }
        let directory = Self.projectURL(projectID).appending(path: "Originals", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        // Store source file byte-for-byte
        let sourceFilename = "slot-\(slot.rawValue)-source.jpg"
        let sourceURL = directory.appending(path: sourceFilename)
        try data.write(to: sourceURL, options: .atomic)

        // Create and store normalized 4:3 derivative for display
        let normalized = image.normalizedFourByThree()
        guard let normalizedData = normalized.jpegData(compressionQuality: 0.94) else { throw PhotoFileStoreError.unableToEncode }
        let originalFilename = "slot-\(slot.rawValue)-original.jpg"
        try normalizedData.write(to: directory.appending(path: originalFilename), options: .atomic)

        let width = image.cgImage?.width ?? Int(image.size.width)
        let height = image.cgImage?.height ?? Int(image.size.height)
        let orientation = "\(image.imageOrientation.rawValue)"

        return (originalFilename, sourceFilename, width, height, orientation)
    }

    func storeRendered(data: Data, projectID: UUID, slot: PhotoSlot) throws -> String {
        let directory = Self.projectURL(projectID).appending(path: "Rendered", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let filename = "slot-\(slot.rawValue)-edited.jpg"
        try data.write(to: directory.appending(path: filename), options: .atomic)
        return filename
    }

    func storeTemplate(data: Data, id: UUID) throws -> String {
        guard let image = UIImage(data: data), let jpeg = image.normalizedFourByThree().jpegData(compressionQuality: 0.94) else {
            throw PhotoFileStoreError.unreadableImage
        }
        let directory = Self.rootURL.appending(path: "Templates", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let filename = "template-\(id.uuidString).jpg"
        try jpeg.write(to: directory.appending(path: filename), options: .atomic)
        return filename
    }

    func deleteProject(id: UUID) throws {
        let url = Self.projectURL(id)
        if FileManager.default.fileExists(atPath: url.path) { try FileManager.default.removeItem(at: url) }
    }
}

extension UIImage {
    func normalizedFourByThree(target: CGSize = CGSize(width: 3000, height: 2250)) -> UIImage {
        let sourceAspect = size.width / size.height
        let targetAspect = target.width / target.height
        let crop: CGRect
        if sourceAspect > targetAspect {
            let width = size.height * targetAspect
            crop = CGRect(x: (size.width - width) / 2, y: 0, width: width, height: size.height)
        } else {
            let height = size.width / targetAspect
            crop = CGRect(x: 0, y: (size.height - height) / 2, width: size.width, height: height)
        }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: target), blendMode: .copy, alpha: 1, sourceRect: crop)
        }
    }

    private func draw(in rect: CGRect, blendMode: CGBlendMode, alpha: CGFloat, sourceRect: CGRect) {
        guard let cgImage, let cropped = cgImage.cropping(to: CGRect(
            x: sourceRect.minX * cgImage.width.cg / size.width,
            y: sourceRect.minY * cgImage.height.cg / size.height,
            width: sourceRect.width * cgImage.width.cg / size.width,
            height: sourceRect.height * cgImage.height.cg / size.height
        )) else { return }
        UIImage(cgImage: cropped, scale: 1, orientation: imageOrientation).draw(in: rect, blendMode: blendMode, alpha: alpha)
    }
}

private extension Int { var cg: CGFloat { CGFloat(self) } }
