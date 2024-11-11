import CoreMedia

extension CMTimeRange: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let start = try container.decode(CMTime.self, forKey: .start)
        let duration = try container.decode(CMTime.self, forKey: .duration)
        self.init(start: start, duration: duration)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(start, forKey: .start)
        try container.encode(duration, forKey: .duration)
    }

    private enum CodingKeys: CodingKey {
        case start
        case duration
    }
}
