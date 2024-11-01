import SwiftUI

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
        parameterCreationAPI.addStringParameter(
            withName: "Package Path (Drag & Drop)",
            parameterID: 1,
            defaultValue: "",
            parameterFlags: FxParameterFlags(kFxParameterFlag_DEFAULT)
        )

        parameterCreationAPI.addPushButton(
            withName: "Compile",
            parameterID: 2,
            selector: #selector(SwiftUIViewGenerator.compile),
            parameterFlags: FxParameterFlags(kFxParameterFlag_DEFAULT)
        )
    }

    override func pluginInstanceAddedToDocument() {
        compile()
    }

    override func renderDestinationImage(
        sourceImages: [CIImage],
        pluginState _: Data?,
        at _: CMTime
    ) -> CIImage {
        guard let view else { return .clear }
        return DispatchQueue.main.sync {
            let renderer = ImageRenderer(
                content: view
                    .frame(width: sourceImages[0].extent.width, height: sourceImages[0].extent.height)
            )
            renderer.proposedSize = .init(sourceImages[0].extent.size)
            return CIImage(cgImage: renderer.cgImage!, options: [.applyOrientationProperty: true])
        }
    }

    // MARK: Private

    private var view: AnyView?
}

extension SwiftUIViewGenerator {
    @objc func compile() {
        var packagePath: NSString = ""
        parameterRetrievalAPI.getStringParameterValue(&packagePath, fromParameter: 1)
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
            throw Error.missingDylib(path: dylib)
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
    case missingDylib(path: URL)
    case missingSymbol

    // MARK: Internal

    var errorDescription: String? {
        switch self {
        case let .swiftError(message):
            message
        case let .missingDylib(path):
            "Could not find dylib at \(path.path). Ensure your library product is set to type: .dynamic in your Package.swift file, and that the library name matches the package name."
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
