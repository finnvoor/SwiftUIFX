extension FxRect {
    var cgRect: CGRect {
        CGRect(
            x: CGFloat(left),
            y: CGFloat(bottom),
            width: CGFloat(right - left),
            height: CGFloat(top - bottom)
        )
    }

    init(_ rect: CGRect) {
        self.init(
            left: Int32(rect.minX),
            bottom: Int32(rect.minY),
            right: Int32(rect.maxX),
            top: Int32(rect.maxY)
        )
    }
}
