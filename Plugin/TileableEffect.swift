import Foundation

// MARK: - TileableEffect

class TileableEffect: NSObject, FxTileableEffect {
    // MARK: Lifecycle

    required init?(apiManager: any PROAPIAccessing) {
        self.apiManager = apiManager
    }

    // MARK: Internal

    var properties: [String: Any] {
        [
            kFxPropertyKey_MayRemapTime: false,
            kFxPropertyKey_VariesWhenParamsAreStatic: false
        ]
    }

    var parameterCreationAPI: FxParameterCreationAPI_v5 {
        apiManager.api(for: FxParameterCreationAPI_v5.self) as! FxParameterCreationAPI_v5
    }

    var parameterRetrievalAPI: FxParameterRetrievalAPI_v6 {
        apiManager.api(for: FxParameterRetrievalAPI_v6.self) as! FxParameterRetrievalAPI_v6
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
    ) -> CIImage {
        sourceImages.first ?? .clear
    }

    // MARK: Private

    private let apiManager: PROAPIAccessing
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

    func pluginState(
        _: AutoreleasingUnsafeMutablePointer<NSData>?,
        at _: CMTime,
        quality _: UInt
    ) throws {}

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

        var renderedImage = renderDestinationImage(
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
