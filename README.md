# SwiftUIFX

### Instructions

1. Install the SwiftUIFX app.
2. TODO: - Install the motion template
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
