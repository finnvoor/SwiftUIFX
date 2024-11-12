import CoreMedia
import SwiftUI
import SwiftUIFX

@_cdecl("createView") public func createView() -> UnsafeMutableRawPointer {
    Unmanaged.passRetained(
        AnyView(HelloWorldView()) as AnyObject
    ).toOpaque()
}

// MARK: - HelloWorldView

struct HelloWorldView: View {
    @Environment(\.timelineTime) var timelineTime: CMTime

    var body: some View {
        GeometryReader { proxy in
            VStack {
                Text("Hello World")
                Text(timelineTime.seconds, format: .number.precision(.fractionLength(2)))
            }
            .font(.system(size: proxy.size.width / 14))
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .monospaced()
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .center
            )
        }
    }
}

#Preview {
    HelloWorldView()
        .frame(width: 1920, height: 1080)
}
