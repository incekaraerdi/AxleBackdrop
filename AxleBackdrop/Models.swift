import Foundation
import SwiftData

enum VehicleType: String, Codable, CaseIterable, Identifiable {
    case car, motorcycle
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var symbol: String { self == .car ? "car.side.fill" : "motorcycle.fill" }
}

enum ListingStage: String, Codable { case vehicleType, photos, scene, processing, review, export }

enum PhotoSlot: Int, Codable, CaseIterable, Identifiable {
    case exteriorFront = 1, exteriorRear, detailThree, detailFour, instrument
    var id: Int { rawValue }
    func title(for vehicle: VehicleType) -> String {
        switch (self, vehicle) {
        case (.exteriorFront, _): "Front-left three-quarter"
        case (.exteriorRear, _): "Rear-right three-quarter"
        case (.detailThree, .car): "Front cabin"
        case (.detailFour, .car): "Rear cabin"
        case (.detailThree, .motorcycle): "Full left-side profile"
        case (.detailFour, .motorcycle): "Full right-side profile"
        case (.instrument, _): "Odometer or instrument cluster"
        }
    }
    var shortTitle: String {
        switch self {
        case .exteriorFront: "Front ¾"; case .exteriorRear: "Rear ¾"
        case .detailThree: "Photo 3"; case .detailFour: "Photo 4"; case .instrument: "Instrument"
        }
    }
    var receivesScene: Bool { rawValue <= 2 }
}

enum PhotoProcessingState: String, Codable { case empty, ready, queued, processing, completed, needsAttention }

struct PhotoRecord: Codable, Identifiable, Equatable {
    var slot: PhotoSlot
    var originalFilename: String?
    var sourceFilename: String?
    var renderedFilename: String?
    var state: PhotoProcessingState = .empty
    var useEdited = true
    var errorMessage: String?
    var sourceWidth: Int?
    var sourceHeight: Int?
    var sourceOrientation: String?
    var id: Int { slot.rawValue }
}

enum SceneKind: String, Codable, CaseIterable, Identifiable {
    case indoorGarage, outdoorScenic, custom
    var id: String { rawValue }
    var title: String {
        switch self { case .indoorGarage: "Indoor Garage"; case .outdoorScenic: "Outdoor Scenic"; case .custom: "Dealer Template" }
    }
    var assetName: String? {
        switch self { case .indoorGarage: "IndoorGarage"; case .outdoorScenic: "OutdoorScenic"; case .custom: nil }
    }
}

struct Placement: Codable, Equatable { var x = 0.0; var y = 0.08; var scale = 0.82 }

@Model
final class ListingDraft {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var vehicleTypeRaw: String
    var stageRaw: String
    var sceneRaw: String
    var customTemplateID: UUID?
    var photoRecordsData: Data
    var frontPlacementData: Data
    var rearPlacementData: Data

    init(vehicleType: VehicleType = .car) {
        id = UUID(); createdAt = .now; updatedAt = .now
        vehicleTypeRaw = vehicleType.rawValue; stageRaw = ListingStage.vehicleType.rawValue
        sceneRaw = SceneKind.indoorGarage.rawValue
        photoRecordsData = Self.encode(PhotoSlot.allCases.map { PhotoRecord(slot: $0) })
        frontPlacementData = Self.encode(Placement())
        rearPlacementData = Self.encode(Placement(y: 0.08, scale: 0.78))
    }

    var vehicleType: VehicleType {
        get { VehicleType(rawValue: vehicleTypeRaw) ?? .car }
        set { vehicleTypeRaw = newValue.rawValue; touch() }
    }
    var stage: ListingStage {
        get { ListingStage(rawValue: stageRaw) ?? .vehicleType }
        set { stageRaw = newValue.rawValue; touch() }
    }
    var scene: SceneKind {
        get { SceneKind(rawValue: sceneRaw) ?? .indoorGarage }
        set { sceneRaw = newValue.rawValue; touch() }
    }
    var photoRecords: [PhotoRecord] {
        get { Self.decode([PhotoRecord].self, from: photoRecordsData) ?? PhotoSlot.allCases.map { PhotoRecord(slot: $0) } }
        set { photoRecordsData = Self.encode(newValue); touch() }
    }
    var frontPlacement: Placement {
        get { Self.decode(Placement.self, from: frontPlacementData) ?? Placement() }
        set { frontPlacementData = Self.encode(newValue); touch() }
    }
    var rearPlacement: Placement {
        get { Self.decode(Placement.self, from: rearPlacementData) ?? Placement(y: 0.08, scale: 0.78) }
        set { rearPlacementData = Self.encode(newValue); touch() }
    }
    var completedCount: Int { photoRecords.filter { $0.originalFilename != nil }.count }
    var isPhotoComplete: Bool { completedCount == PhotoSlot.allCases.count }
    func record(for slot: PhotoSlot) -> PhotoRecord { photoRecords.first { $0.slot == slot } ?? PhotoRecord(slot: slot) }
    func updateRecord(_ record: PhotoRecord) {
        var records = photoRecords
        if let index = records.firstIndex(where: { $0.slot == record.slot }) { records[index] = record }
        photoRecords = records
    }
    func touch() { updatedAt = .now }
    private static func encode<T: Encodable>(_ value: T) -> Data { (try? JSONEncoder().encode(value)) ?? Data() }
    private static func decode<T: Decodable>(_ type: T.Type, from data: Data) -> T? { try? JSONDecoder().decode(type, from: data) }
}

@Model
final class DealerTemplate {
    @Attribute(.unique) var id: UUID
    var name: String
    var backgroundFilename: String
    var createdAt: Date
    var frontPlacementData: Data
    var rearPlacementData: Data
    init(name: String, backgroundFilename: String, front: Placement, rear: Placement) {
        id = UUID(); self.name = name; self.backgroundFilename = backgroundFilename; createdAt = .now
        frontPlacementData = (try? JSONEncoder().encode(front)) ?? Data()
        rearPlacementData = (try? JSONEncoder().encode(rear)) ?? Data()
    }
    var frontPlacement: Placement { (try? JSONDecoder().decode(Placement.self, from: frontPlacementData)) ?? Placement() }
    var rearPlacement: Placement { (try? JSONDecoder().decode(Placement.self, from: rearPlacementData)) ?? Placement() }
}
