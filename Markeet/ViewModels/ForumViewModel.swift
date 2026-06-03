import Foundation

/// Reserved view model for future forum-specific state.
/// The current Global Discussion implementation works directly through feed
/// views and post/comment/like/report services.
@MainActor
final class ForumViewModel: ObservableObject {}
