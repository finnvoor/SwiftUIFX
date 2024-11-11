import CoreMedia

extension FxTimingAPI_v4 {
    func timelineTime(fromInputTime inputTime: CMTime) -> CMTime {
        var timelineTime: CMTime = .zero
        self.timelineTime(&timelineTime, fromInputTime: inputTime)
        return timelineTime
    }

    var inPointTimeOfTimeline: CMTime {
        var inPointTime: CMTime = .zero
        self.inPointTimeOfTimeline(forEffect: &inPointTime)
        return inPointTime
    }

    var outPointTimeOfTimeline: CMTime {
        var outPointTime: CMTime = .zero
        self.outPointTimeOfTimeline(forEffect: &outPointTime)
        return outPointTime
    }

    var startTime: CMTime {
        var startTime: CMTime = .zero
        self.startTime(forEffect: &startTime)
        return startTime
    }

    var duration: CMTime {
        var duration: CMTime = .zero
        durationTime(forEffect: &duration)
        return duration
    }
}
