enum AvatarSize {
    case small, medium, large, xLarge

    var dimensions: CGFloat {
        switch self {
        case .small: return 30
        case .medium: return 50
        case .large: return 70
        case .xLarge: return 100
        }
    }
}