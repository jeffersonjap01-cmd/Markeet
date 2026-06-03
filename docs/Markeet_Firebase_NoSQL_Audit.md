# Markeet Firebase NoSQL Architecture Audit

Source of truth: current Swift codebase, `FirestoreCollections`, Firebase service calls, `SessionManager`, and Firebase Storage usage.

## Firebase Authentication

Used by:
- `MarkeetApp`: calls `FirebaseApp.configure()`.
- `AuthService`: creates accounts, logs in, signs out, sends password reset, sends email verification, signs in with Apple credential.
- `SessionManager`: listens to `Auth.auth().addStateDidChangeListener`, restores the current user by loading `users/{uid}`.

Authentication user UID is the primary key for `users/{uid}`.

## Firebase Storage

Active path:
- `profileImages/{uid}/profile.jpg`

Used by:
- `StorageService.uploadProfileImage(uid:image:)`
- `ProfileViewModel.saveProfile(...)`

Notes:
- `StoragePaths.materialThumbnail(...)` and `StoragePaths.materialContent(...)` exist as constants, but no active upload service currently writes to those paths. `materials.thumbnailURL` and `materials.contentURL` are stored as URL strings in Firestore.

## Active Firestore Collections

### `users`

Purpose:
- User profile documents linked to Firebase Authentication UID.
- Stores role, profile, membership, saved materials, event registrations, and account status.

Document id:
- `{uid}`

Fields:
- `uid: String`
- `fullName: String`
- `email: String`
- `role: String`
- `profileImageURL: String?`
- `bio: String`
- `createdAt: Timestamp`
- `onboardingStartDate: Timestamp`
- `onboardingEndDate: Timestamp`
- `onboardingActive: Bool`
- `marketingInterests: [String]`
- `assignedCommunities: [String]`
- `savedMaterials: [String]`
- `registeredEvents: [String]`
- `bannedStatus: Bool`
- `fcmToken: String?`

Referenced by:
- `AuthService`
- `SessionManager`
- `UserService`
- `AdminBootstrapService`
- `GroupService`
- `ScheduleService`
- `NewsService`
- `ReportService`
- `MaterialsViewModel`

Relationships:
- `users.uid` is referenced by `posts.authorId`, `post_comments.userId`, `post_likes.userId`, `post_comment_likes.userId`, `reports.reporterId`, `groups.members`, `groups.mentors`, `activities.mentorId`, `activities.assignedUserIds`, `activity_assignments.userId`, `activity_assignments.mentorId`, `events.mentorId`, `event_registrations.userId`, `event_registrations.mentorId`, `news.createdBy`, `materials.createdBy`, and `messages.senderId`.

### `groups`

Purpose:
- Community/group records created and managed by mentors.
- Stores membership, mentor ownership, tag, capacity, period, and open/closed/expired status.

Document id:
- `{groupId}`

Fields:
- `groupId: String`
- `groupName: String`
- `description: String`
- `batchNumber: Int`
- `startDate: Timestamp`
- `endDate: Timestamp`
- `registrationOpen: Bool`
- `status: String`
- `tag: String`
- `tags: [String]`
- `members: [String]`
- `mentors: [String]`
- `maxMembers: Int`
- `minMembers: Int`
- `maxMentors: Int`
- `minMentors: Int`
- `createdAt: Timestamp`

Referenced by:
- `GroupService`
- `GroupViewModel`
- `ScheduleService.fetchMentorParticipantCandidates(...)`
- `ChatService` indirectly because chat document id is the group id.

Relationships:
- `groups.members[]` and `groups.mentors[]` reference `users/{uid}`.
- `users.assignedCommunities[]` stores group ids.
- `chats/{groupId}` uses the same id as the group for community chat.

### `chats/{groupId}/messages`

Purpose:
- Firebase-backed community chat messages.

Parent document:
- `chats/{groupId}`.
- `ChatService` writes only the `messages` subcollection. Firestore rules expect the parent chat document to contain `participants: [uid]`.

Subcollection:
- `chats/{groupId}/messages/{messageId}`

Message fields:
- `messageId: String`
- `senderId: String`
- `senderName: String`
- `content: String`
- `createdAt: Timestamp`
- `deleted: Bool`

Referenced by:
- `ChatService`
- `ChatViewModel`
- `GroupChatView`

Relationships:
- `messages.senderId` references `users/{uid}`.
- `groupId` corresponds to `groups/{groupId}`.

### `posts`

Purpose:
- Global discussion posts.

Document id:
- `{postId}`

Fields:
- `postId: String`
- `authorId: String`
- `content: String`
- `imageURL: String?`
- `likeCount: Int`
- `commentCount: Int`
- `reportCount: Int`
- `createdAt: Timestamp`
- `deleted: Bool`

Referenced by:
- `PostService`
- `CommentService`
- `LikeService`
- `ReportService`
- `FeedView` / `PostCard`

Relationships:
- `posts.authorId` references `users/{uid}`.
- `post_comments.postId` references posts.
- `post_likes.postId` references posts.
- `reports.targetId` references posts when `targetType == "post"`.

### `post_comments`

Purpose:
- Top-level comments for global discussion posts.

Document id:
- `{commentId}`

Fields:
- `commentId: String`
- `postId: String`
- `userId: String`
- `userName: String`
- `content: String`
- `likeCount: Int`
- `createdAt: Timestamp`
- `deleted: Bool`

Referenced by:
- `CommentService`
- `CommentLikeService`

Relationships:
- `post_comments.postId` references `posts/{postId}`.
- `post_comments.userId` references `users/{uid}`.
- Creating/deleting comments increments/decrements `posts.commentCount`.

### `post_likes`

Purpose:
- Top-level likes for global discussion posts.

Document id:
- `{postId}_{userId}`

Fields:
- `likeId: String`
- `postId: String`
- `userId: String`
- `createdAt: Timestamp`

Referenced by:
- `LikeService`

Relationships:
- `post_likes.postId` references `posts/{postId}`.
- `post_likes.userId` references `users/{uid}`.
- Creating/deleting likes increments/decrements `posts.likeCount`.

### `post_comment_likes`

Purpose:
- Top-level likes for comments.

Document id:
- `{commentId}_{userId}`

Fields:
- `likeId: String`
- `commentId: String`
- `userId: String`
- `createdAt: Timestamp`

Referenced by:
- `CommentLikeService`

Relationships:
- `post_comment_likes.commentId` references `post_comments/{commentId}`.
- `post_comment_likes.userId` references `users/{uid}`.
- Creating/deleting comment likes increments/decrements `post_comments.likeCount`.

### `reports`

Purpose:
- Reports submitted against global discussion posts.
- Admin report moderation reads this collection.

Document id:
- `{postId}_{reporterId}`

Fields:
- `reportId: String`
- `reporterId: String`
- `targetId: String`
- `targetType: String`
- `reason: String`
- `status: String`
- `createdAt: Timestamp`
- `updatedAt: Timestamp?` when an existing report is re-opened.

Referenced by:
- `PostService.reportPost(...)`
- `ReportService`
- `AdminReportsViewModel`

Relationships:
- `reports.reporterId` references `users/{uid}`.
- `reports.targetId` references `posts/{postId}` when `targetType == "post"`.
- Creating a report increments `posts.reportCount`.
- Resolving/dismissing reports resets `posts.reportCount` to `0`.

### `news`

Purpose:
- Admin-managed platform news and home updates.

Document id:
- `{newsId}`

Fields:
- `newsId: String`
- `title: String`
- `description: String`
- `imageURL: String?`
- `createdAt: Timestamp`
- `createdBy: String`
- `category: String`

Referenced by:
- `NewsService`
- `NewsViewModel`
- `AdminNewsViewModel`
- `HomeView`
- `AdminHomeView`

Relationships:
- `news.createdBy` references admin `users/{uid}`.

### `materials`

Purpose:
- Learning materials shown and saved by users.

Document id:
- `{materialId}`

Fields:
- `materialId: String`
- `title: String`
- `description: String`
- `thumbnailURL: String?`
- `contentURL: String`
- `createdAt: Timestamp`
- `createdBy: String`
- `tags: [String]`

Referenced by:
- `MaterialService`
- `MaterialsViewModel`
- `MaterialsListView`
- `SavedMaterialsView`

Relationships:
- `materials.createdBy` references `users/{uid}`.
- `users.savedMaterials[]` stores material ids.

### `activities`

Purpose:
- Mentor-created schedule activities assigned to members.

Document id:
- `{activityId}`

Fields:
- `activityId: String`
- `title: String`
- `description: String`
- `date: Timestamp`
- `startTime: Timestamp`
- `endTime: Timestamp`
- `mentorId: String`
- `assignedUserIds: [String]`
- `createdAt: Timestamp`
- `updatedAt: Timestamp`

Referenced by:
- `ScheduleService`
- `EventViewModel`
- `ScheduleView`

Relationships:
- `activities.mentorId` references mentor `users/{uid}`.
- `activities.assignedUserIds[]` references member `users/{uid}`.
- `activity_assignments.activityId` references `activities/{activityId}`.

### `activity_assignments`

Purpose:
- Per-user activity completion status.

Document id:
- `{activityId}_{userId}`

Fields:
- `assignmentId: String`
- `activityId: String`
- `userId: String`
- `mentorId: String`
- `completed: Bool`
- `completedAt: Timestamp?`
- `assignedAt: Timestamp`

Referenced by:
- `ScheduleService`
- `EventViewModel`
- `ScheduleView`

Relationships:
- `activity_assignments.activityId` references `activities/{activityId}`.
- `activity_assignments.userId` references assigned member `users/{uid}`.
- `activity_assignments.mentorId` references mentor `users/{uid}`.

### `events`

Purpose:
- Mentor-created public events for member registration.

Document id:
- `{eventId}`

Fields:
- `eventId: String`
- `title: String`
- `description: String`
- `imageURL: String?`
- `location: String`
- `startDate: Timestamp`
- `endDate: Timestamp`
- `capacity: Int`
- `registrationDeadline: Timestamp`
- `mentorId: String`
- `participantCount: Int`
- `createdAt: Timestamp`
- `updatedAt: Timestamp`

Referenced by:
- `ScheduleService`
- `EventViewModel`
- `ScheduleView`

Relationships:
- `events.mentorId` references mentor `users/{uid}`.
- `event_registrations.eventId` references `events/{eventId}`.

### `event_registrations`

Purpose:
- Member event registration records.

Document id:
- `{eventId}_{userId}`

Fields:
- `registrationId: String`
- `eventId: String`
- `userId: String`
- `mentorId: String`
- `registeredAt: Timestamp`

Referenced by:
- `ScheduleService`
- `EventViewModel`
- `ScheduleView`

Relationships:
- `event_registrations.eventId` references `events/{eventId}`.
- `event_registrations.userId` references member `users/{uid}`.
- `event_registrations.mentorId` references mentor `users/{uid}`.
- Creating/deleting registrations increments/decrements `events.participantCount`.
- `users.registeredEvents[]` stores registered event ids.

## Onboarding and Tags

Current implementation:
- `users.marketingInterests` still exists in `UserModel` and Firestore decoding/encoding.
- The first-login interest-selection view/model has been removed.
- Community discovery uses user-selected tags from `AppConstants.marketingInterests` at search time, not stored recommendations.
- `groups.tag` is the current primary community tag. `groups.tags` is also written as `[tag]` for compatibility.
- `OnboardingManager` is still used for `batchNumber` and to deactivate expired `onboardingActive`, but no longer gates community joining.

## Firestore Rules Mismatches Found

These are not included as active application architecture because current Swift code does not use them:
- `match /notifications/{notificationId}` exists in `firestore.rules`, but notification model/service/view and the `notifications` constant were removed.
- Nested rules under `posts/{postId}/comments/{commentId}` and `posts/{postId}/likes/{uid}` exist, but current Swift code uses top-level `post_comments`, `post_likes`, and `post_comment_likes`.

Recommended future cleanup:
- Update `firestore.rules` to align with top-level `post_comments`, `post_likes`, and `post_comment_likes`.
- Remove stale `notifications` rules unless notifications are reintroduced.

## Assumptions

- `chats/{groupId}` parent documents are expected to contain `participants: [uid]` because Firestore rules require that field. `ChatService` currently writes only `chats/{groupId}/messages/{messageId}` and does not create/update the parent chat document.
- `materials.thumbnailURL`, `materials.contentURL`, `news.imageURL`, `events.imageURL`, and `posts.imageURL` are URL fields. The only implemented Firebase Storage upload flow is profile image upload.
