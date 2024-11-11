import CoreMedia
import SwiftUI

public extension EnvironmentValues {
    @Entry var timelineTime: CMTime = .zero
    @Entry var timelineTimeRange: CMTimeRange = .zero
    @Entry var generatorTimeRange: CMTimeRange = .zero
}
