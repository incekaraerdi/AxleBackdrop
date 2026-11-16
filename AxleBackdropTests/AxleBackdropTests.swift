import SwiftData
import UIKit
import XCTest
@testable import AxleBackdrop

@MainActor
final class AxleBackdropTests: XCTestCase {
    func testNewDraftHasFiveOrderedSlots() {
        let draft = ListingDraft()
        XCTAssertEqual(draft.photoRecords.map(\.slot), PhotoSlot.allCases)
        XCTAssertEqual(draft.completedCount, 0)
        XCTAssertFalse(draft.isPhotoComplete)
    }

    func testVehicleSpecificGuides() {
        XCTAssertEqual(PhotoSlot.detailThree.title(for: .car), "Front cabin")
        XCTAssertEqual(PhotoSlot.detailThree.title(for: .motorcycle), "Full left-side profile")
        XCTAssertTrue(PhotoSlot.exteriorFront.receivesScene)
        XCTAssertFalse(PhotoSlot.instrument.receivesScene)
    }

    func testRecordUpdatePersistsSelection() {
        let draft = ListingDraft(vehicleType: .motorcycle)
        var record = draft.record(for: .exteriorFront)
        record.originalFilename = "slot-1-original.jpg"
        record.state = .completed
        record.useEdited = false
        draft.updateRecord(record)
        XCTAssertEqual(draft.completedCount, 1)
        XCTAssertEqual(draft.record(for: .exteriorFront).state, .completed)
        XCTAssertFalse(draft.record(for: .exteriorFront).useEdited)
    }

    func testPlacementRoundTrip() {
        let draft = ListingDraft()
        let expected = Placement(x: 0.12, y: 0.2, scale: 0.74)
        draft.frontPlacement = expected
        XCTAssertEqual(draft.frontPlacement, expected)
    }

    func testInMemorySwiftDataRoundTrip() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: ListingDraft.self, DealerTemplate.self, configurations: configuration)
        let draft = ListingDraft(vehicleType: .car)
        container.mainContext.insert(draft)
        try container.mainContext.save()
        let fetched = try container.mainContext.fetch(FetchDescriptor<ListingDraft>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.vehicleType, .car)
    }

    func testSourceFilePreservation() async throws {
        let draft = ListingDraft()
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 640, height: 480))
        let image = renderer.image { context in
            UIColor.systemBlue.setFill(); context.fill(CGRect(x: 0, y: 0, width: 640, height: 480))
        }
        let sourceData = try XCTUnwrap(image.jpegData(compressionQuality: 1))
        let result = try await PhotoFileStore.shared.storeOriginal(data: sourceData, projectID: draft.id, slot: .exteriorFront)

        // Verify source file exists and matches original byte-for-byte
        let sourceURL = PhotoFileStore.originalURL(projectID: draft.id, filename: result.sourceFilename)
        let storedSourceData = try Data(contentsOf: sourceURL)
        XCTAssertEqual(sourceData, storedSourceData, "Source file should preserve original bytes exactly")

        // Verify normalized file exists for display
        let normalizedURL = PhotoFileStore.originalURL(projectID: draft.id, filename: result.originalFilename)
        XCTAssertTrue(FileManager.default.fileExists(atPath: normalizedURL.path), "Normalized file should exist")

        try await PhotoFileStore.shared.deleteProject(id: draft.id)
    }

    func testSourceMetadataPreservation() async throws {
        let draft = ListingDraft()
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 800, height: 600))
        let image = renderer.image { context in
            UIColor.systemGreen.setFill(); context.fill(CGRect(x: 0, y: 0, width: 800, height: 600))
        }
        let sourceData = try XCTUnwrap(image.jpegData(compressionQuality: 0.9))
        let result = try await PhotoFileStore.shared.storeOriginal(data: sourceData, projectID: draft.id, slot: .exteriorRear)

        var record = draft.record(for: .exteriorRear)
        record.sourceWidth = result.width
        record.sourceHeight = result.height
        record.sourceOrientation = result.orientation
        draft.updateRecord(record)

        let stored = draft.record(for: .exteriorRear)
        XCTAssertEqual(stored.sourceWidth, 2400, "Source width should be preserved (renderer scale = 3x)")
        XCTAssertEqual(stored.sourceHeight, 1800, "Source height should be preserved (renderer scale = 3x)")
        XCTAssertNotNil(stored.sourceOrientation, "Source orientation should be recorded")

        try await PhotoFileStore.shared.deleteProject(id: draft.id)
    }

    func testFiveJPEGExportOrderSizeAndMetadata() async throws {
        let draft = ListingDraft()
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 40, height: 30))
        let image = renderer.image { context in
            UIColor.systemOrange.setFill(); context.fill(CGRect(x: 0, y: 0, width: 40, height: 30))
        }
        let sourceData = try XCTUnwrap(image.jpegData(compressionQuality: 1))
        for slot in PhotoSlot.allCases {
            let result = try await PhotoFileStore.shared.storeOriginal(data: sourceData, projectID: draft.id, slot: slot)
            var record = draft.record(for: slot)
            record.originalFilename = result.originalFilename; record.useEdited = false; record.state = .completed
            draft.updateRecord(record)
        }

        let urls = try await ExportService.shared.prepare(draft: draft)
        XCTAssertEqual(urls.count, 5)
        XCTAssertEqual(urls.first?.lastPathComponent, "AxleBackdrop_01_Cover.jpg")
        XCTAssertEqual(urls.last?.lastPathComponent, "AxleBackdrop_05_Instrument.jpg")
        for url in urls {
            let exported = try XCTUnwrap(UIImage(contentsOfFile: url.path))
            XCTAssertEqual(exported.size, CGSize(width: 3000, height: 2250))
            let properties = try XCTUnwrap(CGImageSourceCopyPropertiesAtIndex(CGImageSourceCreateWithURL(url as CFURL, nil)!, 0, nil) as? [CFString: Any])
            XCTAssertNil(properties[kCGImagePropertyGPSDictionary])
        }
        try await PhotoFileStore.shared.deleteProject(id: draft.id)
    }
}
