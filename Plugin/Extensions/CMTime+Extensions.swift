import CoreMedia

extension CMTime: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let value = try container.decode(CMTimeValue.self, forKey: .value)
        let timescale = try container.decode(CMTimeScale.self, forKey: .timescale)
        let flags = try CMTimeFlags(rawValue: container.decode(UInt32.self, forKey: .flags))
        let epoch = try container.decode(CMTimeEpoch.self, forKey: .epoch)
        self.init(value: value, timescale: timescale, flags: flags, epoch: epoch)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(value, forKey: .value)
        try container.encode(timescale, forKey: .timescale)
        try container.encode(flags.rawValue, forKey: .flags)
        try container.encode(epoch, forKey: .epoch)
    }

    private enum CodingKeys: CodingKey {
        case value
        case timescale
        case flags
        case epoch
    }
}
