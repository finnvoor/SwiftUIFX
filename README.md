# SwiftUIFX

![card](https://github.com/user-attachments/assets/e564f5b3-8f13-450e-a28c-b29c80f7eaa8)

### Instructions

1. Move the [SwiftUIFX app](https://github.com/finnvoor/SwiftUIFX/releases/latest/download/SwiftUIFX.app.zip) to Applications, and run `xattr -cr /Applications/SwiftUIFX.app` to un-quarantine the app (see https://github.com/finnvoor/SwiftUIFX/issues/4). Open the app at least once to allow it to run.
2. Unzip [SwiftUIFX.zip](https://github.com/finnvoor/SwiftUIFX/releases/latest/download/SwiftUIFX.zip) and place the SwiftUIFX directory into `/Applications/Final Cut Pro.app/Contents/PlugIns/MediaProviders/MotionEffect.fxp/Contents/Resources/Templates.localized/Generators.localized/`.
3. Ensure you have the Swift toolchain installed, and create a new Swift package. Ensure the package's library name matches the package name, and set the library's `type` to `.dynamic`.
```swift
// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MyVideoOverlay",
    platforms: [.macOS(.v13)],
    products: [.library(name: "MyVideoOverlay", type: .dynamic, targets: ["MyVideoOverlay"])],
    targets: [.target(name: "MyVideoOverlay")]
)
```
4. Create a SwiftUI view in your package and expose it to the plugin by adding a `@_cdecl("createView")` function.
```swift
import SwiftUI

@_cdecl("createView") public func createView() -> UnsafeMutableRawPointer {
    return Unmanaged.passRetained(
        AnyView(MyView()) as AnyObject
    ).toOpaque()
}

struct MyView: View {
    var body: some View {
        Text("Hello World")
    }
}

#Preview {
    MyView()
        .frame(width: 1920, height: 1080)
}
```
5. Create or open a Final Cut Pro project and drag a "SwiftUI View" generator onto the timeline from the "Generators>SwiftUIFX" category in the library.
6. Select the generator, navigate to the generator inspector, and drag the top level directory of your Swift package into the "Package Path" text field.
7. Press the "Compile" button to compile your view. It should now be displayed in your video timeline.
8. Any time you make a change to your package you will need to press the "Compile" button again.

> [!NOTE]  
> The SwiftUIFX mac app will not auto-update, so any updates will need to be manually downloaded from the latest release.

### Environment Values

To access environment values in your SwiftUI view:
1. Add SwiftUIFX as a dependency of your package.
```swift
let package = Package(
    name: "MyVideoOverlay",
    platforms: [.macOS(.v13)],
    products: [.library(name: "MyVideoOverlay", type: .dynamic, targets: ["MyVideoOverlay"])],
    dependencies: [.package(url: "https://github.com/finnvoor/SwiftUIFX.git", branch: "main")],
    targets: [.target(name: "MyVideoOverlay", dependencies: [.product(name: "SwiftUIFX", package: "SwiftUIFX")])]
)
```
2. Import SwiftUIFX in your SwiftUI view.
```swift
import SwiftUIFX
```
3. Access the environment value using the `Environment` property wrapper.
```swift
@Environment(\.timelineTime) var timelineTime: CMTime
@Environment(\.timelineTimeRange) var timelineTimeRange: CMTimeRange
@Environment(\.generatorTimeRange) var generatorTimeRange: CMTimeRange
```

> [!NOTE]  
> See the [Examples](Examples/) directory for example packages that can be used with SwiftUIFX.

### Development

1. Clone the repository.
2. Run `swift build -c release --arch arm64 --arch x86_64` at the top level of the repository.
3. Change the code sign identity in the build script phases of Plugin ("Copy and Code Sign FxPlug.framework" and "Copy and Code Sign PluginManager.framework"). 
4. Open `SwiftUIFX.xcodeproj`.

### Acknowledgements

Thanks to [Arclite/Halloween2024](https://github.com/Arclite/Halloween2024) for demonstrating how SwiftUI views can be loaded from a dylib.
