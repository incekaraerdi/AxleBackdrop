import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit
import Vision

enum ProcessingError: LocalizedError {
    case imageUnavailable, noVehicleFound, renderFailed
    var errorDescription: String? {
        switch self {
        case .imageUnavailable: "The source photo is unavailable."
        case .noVehicleFound: "The vehicle could not be separated cleanly. Retake, adjust placement, or use the original."
        case .renderFailed: "The edited photo could not be rendered."
        }
    }
}

actor ImageProcessingService {
    static let shared = ImageProcessingService()
    private let context = CIContext(options: [.cacheIntermediates: false])
    private let outputRect = CGRect(x: 0, y: 0, width: 3000, height: 2250)

    private let maxInputResolution = CGSize(width: 4000, height: 3000)
    private let renderTimeout: TimeInterval = 30

    func renderExterior(sourceURL: URL, background: UIImage, placement: Placement) throws -> Data {
        guard let source = CIImage(contentsOf: sourceURL), let backgroundCI = CIImage(image: background.normalizedFourByThree()) else {
            throw ProcessingError.imageUnavailable
        }

        guard source.extent.width <= maxInputResolution.width && source.extent.height <= maxInputResolution.height else {
            throw ProcessingError.renderFailed
        }

        try Task.checkCancellation()
        let handler = VNImageRequestHandler(ciImage: source, orientation: .up)
        let request = VNGenerateForegroundInstanceMaskRequest()
        try handler.perform([request])
        guard let observation = request.results?.first else { throw ProcessingError.noVehicleFound }
        let maskBuffer = try observation.generateScaledMaskForImage(forInstances: observation.allInstances, from: handler)
        var mask = CIImage(cvPixelBuffer: maskBuffer).cropped(to: source.extent)

        let blend = CIFilter.blendWithMask()
        blend.inputImage = source
        blend.backgroundImage = CIImage.empty()
        blend.maskImage = mask
        guard var vehicle = blend.outputImage else { throw ProcessingError.renderFailed }

        let scale = CGFloat(placement.scale)
        let scaledSize = CGSize(width: source.extent.width * scale, height: source.extent.height * scale)
        let targetCenter = CGPoint(x: outputRect.midX + CGFloat(placement.x) * outputRect.width,
                                   y: outputRect.midY - CGFloat(placement.y) * outputRect.height)
        var transform = CGAffineTransform(scaleX: scale, y: scale)
        transform = transform.concatenating(CGAffineTransform(
            translationX: targetCenter.x - scaledSize.width / 2,
            y: targetCenter.y - scaledSize.height / 2
        ))
        vehicle = vehicle.transformed(by: transform)
        mask = mask.transformed(by: transform)

        let shadowColor = CIFilter.falseColor()
        shadowColor.inputImage = mask
        shadowColor.color0 = CIColor(red: 0, green: 0, blue: 0, alpha: 0.42)
        shadowColor.color1 = CIColor.clear
        let shadow = (shadowColor.outputImage ?? mask)
            .transformed(by: CGAffineTransform(scaleX: 0.92, y: 0.12))
            .transformed(by: CGAffineTransform(translationX: outputRect.width * 0.04, y: outputRect.height * 0.17))
            .clampedToExtent()
            .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: 32])
            .cropped(to: outputRect)

        let base = backgroundCI.cropped(to: outputRect)
        let withShadow = shadow.composited(over: base)
        let output = vehicle.composited(over: withShadow).cropped(to: outputRect)
        return try jpegData(from: output)
    }

    func correctDetail(sourceURL: URL) throws -> Data {
        guard let source = CIImage(contentsOf: sourceURL) else { throw ProcessingError.imageUnavailable }
        let corrected = source
            .applyingFilter("CIExposureAdjust", parameters: [kCIInputEVKey: 0.12])
            .applyingFilter("CIColorControls", parameters: [kCIInputSaturationKey: 0.99, kCIInputContrastKey: 1.02])
        return try jpegData(from: corrected.cropped(to: source.extent))
    }

    func metadataStrippedCopy(sourceURL: URL) throws -> Data {
        guard let source = CIImage(contentsOf: sourceURL) else { throw ProcessingError.imageUnavailable }
        return try jpegData(from: source)
    }

    private func jpegData(from image: CIImage) throws -> Data {
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        guard let data = context.jpegRepresentation(of: image, colorSpace: colorSpace, options: [kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption: 0.92]) else {
            throw ProcessingError.renderFailed
        }
        return data
    }
}
