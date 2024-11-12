import SwiftUI
import SwiftUIFX

// MARK: - SwiftUIViewGenerator

@objc(SwiftUIViewGenerator) class SwiftUIViewGenerator: TileableEffect {
    // MARK: Internal

    override var properties: [String: Any] {
        [
            kFxPropertyKey_MayRemapTime: false,
            kFxPropertyKey_VariesWhenParamsAreStatic: true
        ]
    }

    override func addParameters() throws {
        apiManager.parameterCreationAPI.addStringParameter(
            withName: "Package Path (Drag & Drop)",
            parameterID: 1,
            defaultValue: "",
            parameterFlags: FxParameterFlags(kFxParameterFlag_DEFAULT)
        )

        apiManager.parameterCreationAPI.addPushButton(
            withName: "Compile",
            parameterID: 2,
            selector: #selector(SwiftUIViewGenerator.updateAndCompile),
            parameterFlags: FxParameterFlags(kFxParameterFlag_DEFAULT)
        )

        apiManager.parameterCreationAPI.addIntSlider(
            withName: "Update",
            parameterID: 3,
            defaultValue: 0,
            parameterMin: Int32.min,
            parameterMax: Int32.max,
            sliderMin: Int32.min,
            sliderMax: Int32.max,
            delta: 1,
            parameterFlags: FxParameterFlags(kFxParameterFlag_DEFAULT)
        )
    }

    override func pluginInstanceAddedToDocument() {
        compile()
    }

    override func pluginState(
        at renderTime: CMTime,
        quality _: UInt
    ) throws -> Data? {
        try JSONEncoder().encode(State(
            timelineTime: apiManager.timingAPI.timelineTime(fromInputTime: renderTime),
            timelineTimeRange: .init(
                start: apiManager.timingAPI.inPointTimeOfTimeline,
                end: apiManager.timingAPI.outPointTimeOfTimeline
            ),
            generatorTimeRange: .init(
                start: apiManager.timingAPI.timelineTime(fromInputTime: apiManager.timingAPI.startTime),
                duration: apiManager.timingAPI.timelineTime(fromInputTime: apiManager.timingAPI.duration)
            )
        ))
    }

    override func renderDestinationImage(
        sourceImages: [CIImage],
        pluginState: Data?,
        at _: CMTime
    ) throws -> CIImage {
        guard let view else { return .clear }

        let state = try JSONDecoder().decode(State.self, from: pluginState ?? Data())

        return DispatchQueue.main.sync {
            let renderer = ImageRenderer(
                content: view
                    .environment(\.timelineTime, state.timelineTime)
                    .environment(\.timelineTimeRange, state.timelineTimeRange)
                    .environment(\.generatorTimeRange, state.generatorTimeRange)
                    .frame(width: sourceImages[0].extent.width, height: sourceImages[0].extent.height)
            )
            renderer.proposedSize = .init(sourceImages[0].extent.size)
            return CIImage(cgImage: renderer.cgImage!, options: [.applyOrientationProperty: true])
        }
    }

    // MARK: Private

    private var view: AnyView?
}

// MARK: SwiftUIViewGenerator.State

extension SwiftUIViewGenerator {
    struct State: Codable {
        let timelineTime: CMTime
        let timelineTimeRange: CMTimeRange
        let generatorTimeRange: CMTimeRange
    }
}

extension SwiftUIViewGenerator {
    @objc func updateAndCompile() {
        apiManager.parameterSettingAPI.setIntValue(
            Int32.random(in: Int32.min...Int32.max),
            toParameter: 3,
            at: .zero
        )
        compile()
    }

    func compile() {
        var packagePath: NSString = ""
        apiManager.parameterRetrievalAPI.getStringParameterValue(&packagePath, fromParameter: 1)
        let package = URL(filePath: packagePath as String)

        guard !(packagePath as String).isEmpty else { return }

        do {
            let dylib = try swiftBuild(package: package)
            view = try loadView(from: dylib)
        } catch {
            print(error.localizedDescription)
            Task { await showAlert(message: error.localizedDescription) }
        }
    }

    private func swiftBuild(package: URL) throws -> URL {
        let dylib = package.appendingPathComponent(".build/debug/lib\(package.lastPathComponent).dylib")
        try? FileManager.default.removeItem(at: dylib)

        let process = Process()
        process.executableURL = URL(filePath: "/usr/bin/swift")
        process.arguments = ["build", "--package-path", package.path()]

        let standardError = Pipe()
        process.standardError = standardError

        let semaphore = DispatchSemaphore(value: 0)
        var error: Error?
        process.terminationHandler = { terminatedProcess in
            if terminatedProcess.terminationStatus != 0 {
                error = Error.swiftError(
                    message: (try? standardError.fileHandleForReading.readToEnd())
                        .map { String(decoding: $0, as: UTF8.self) } ?? "Unknown Error"
                )
            }
            semaphore.signal()
        }
        try process.run()
        semaphore.wait()
        if let error { throw error }
        return dylib
    }

    private func loadView(from dylib: URL) throws -> AnyView {
        guard let handle = dlopen(dylib.path, RTLD_NOW | RTLD_LOCAL) else {
            throw Error.dlopenFailed(error: String(cString: dlerror()))
        }
        defer { dlclose(handle) }
        guard let symbol = dlsym(handle, "createView") else {
            throw Error.missingSymbol
        }
        let pointer = unsafeBitCast(symbol, to: (@convention(c) () -> UnsafeMutableRawPointer).self)()
        let view = Unmanaged<AnyObject>.fromOpaque(pointer).takeRetainedValue()
        return view as! AnyView
    }

    private func showAlert(message: String) async {
        CFUserNotificationDisplayNotice(
            0,
            kCFUserNotificationCautionAlertLevel,
            nil,
            nil,
            nil,
            "SwiftUIFX" as CFString,
            message as CFString,
            "Ok" as CFString
        )
    }
}

// MARK: - Error

enum Error: Swift.Error, LocalizedError {
    case swiftError(message: String)
    case dlopenFailed(error: String)
    case missingSymbol

    // MARK: Internal

    var errorDescription: String? {
        switch self {
        case let .swiftError(message): message
        case let .dlopenFailed(error): error
        case .missingSymbol:
            """
            Failed to load view from dylib. Make sure you include a createView function that returns a pointer to your view. Example:

            @_cdecl("createView") public func createView() -> UnsafeMutableRawPointer {
                return Unmanaged.passRetained(
                    AnyView(MyView()) as AnyObject
                ).toOpaque()
            }
            """
        }
    }
}
