import Foundation

// MARK: - TileableEffect

class TileableEffect: NSObject, FxTileableEffect {
    // MARK: Lifecycle

    required init?(apiManager: any PROAPIAccessing) {
        self.apiManager = apiManager
    }

    // MARK: Internal

    let apiManager: PROAPIAccessing

    var properties: [String: Any] {
        [
            kFxPropertyKey_MayRemapTime: false,
            kFxPropertyKey_VariesWhenParamsAreStatic: false
        ]
    }

    func pluginState(
        at _: CMTime,
        quality _: UInt
    ) throws -> Data? {
        nil
    }

    func destinationImageRect(
        sourceImage: FxImageTile,
        destinationImage _: FxImageTile,
        pluginState _: Data?,
        at _: CMTime
    ) -> CGRect {
        sourceImage.imagePixelBounds.cgRect
    }

    func sourceTileRect(
        sourceImage _: FxImageTile,
        destinationTileRect: CGRect,
        destinationImage _: FxImageTile,
        pluginState _: Data?,
        at _: CMTime
    ) -> CGRect {
        destinationTileRect
    }

    func renderDestinationImage(
        sourceImages: [CIImage],
        pluginState _: Data?,
        at _: CMTime
    ) throws -> CIImage {
        sourceImages.first ?? .clear
    }

    // MARK: Private

    private let context = CIContext()
}

extension TileableEffect {
    func pluginInstanceAddedToDocument() {}

    func addParameters() throws {}

    final func properties(
        _ properties: AutoreleasingUnsafeMutablePointer<NSDictionary>?
    ) throws {
        properties?.pointee = self.properties as NSDictionary
    }

    final func pluginState(
        _ pluginState: AutoreleasingUnsafeMutablePointer<NSData>?,
        at renderTime: CMTime,
        quality qualityLevel: UInt
    ) throws {
        if let state = try self.pluginState(
            at: renderTime,
            quality: qualityLevel
        ) {
            pluginState?.pointee = state as NSData
        }
    }

    final func destinationImageRect(
        _ destinationImageRect: UnsafeMutablePointer<FxRect>,
        sourceImages: [FxImageTile],
        destinationImage: FxImageTile,
        pluginState: Data?,
        at renderTime: CMTime
    ) throws {
        destinationImageRect.pointee = FxRect(self.destinationImageRect(
            sourceImage: sourceImages[0],
            destinationImage: destinationImage,
            pluginState: pluginState,
            at: renderTime
        ))
    }

    final func sourceTileRect(
        _ sourceTileRect: UnsafeMutablePointer<FxRect>,
        sourceImageIndex _: UInt,
        sourceImages: [FxImageTile],
        destinationTileRect: FxRect,
        destinationImage: FxImageTile,
        pluginState: Data?,
        at renderTime: CMTime
    ) throws {
        sourceTileRect.pointee = FxRect(self.sourceTileRect(
            sourceImage: sourceImages[0],
            destinationTileRect: destinationTileRect.cgRect,
            destinationImage: destinationImage,
            pluginState: pluginState,
            at: renderTime
        ))
    }

    final func renderDestinationImage(
        _ destinationImage: FxImageTile,
        sourceImages: [FxImageTile],
        pluginState: Data?,
        at renderTime: CMTime
    ) throws {
        let sourceImages = sourceImages.map {
            CIImage(
                ioSurface: $0.ioSurface,
                options: $0.colorSpace.map { [.colorSpace: $0] }
            )
        }

        var renderedImage = try renderDestinationImage(
            sourceImages: sourceImages,
            pluginState: pluginState,
            at: renderTime
        )

        renderedImage = renderedImage.transformed(
            by: .identity
                .scaledBy(x: 1, y: -1)
                .translatedBy(x: 0, y: -renderedImage.extent.height)
        )

        context.render(
            renderedImage,
            to: destinationImage.ioSurface,
            bounds: renderedImage.extent,
            colorSpace: destinationImage.colorSpace
        )
    }

    func parameterChanged(_: UInt32, at _: CMTime) throws {}
}
