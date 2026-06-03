import FirebaseFirestore
import Foundation
import Testing
@testable import Markeet

struct ValidationAndAuthenticationTests {
    @Test func authenticationValidatorsAcceptValidRegistrationInput() throws {
        try Validators.validateName("Marketing Mentor")
        try Validators.validateEmail("mentor@example.com")
        try Validators.validatePasswords("secret1", confirmation: "secret1")
    }

    @Test func authenticationValidatorsRejectInvalidLoginInput() {
        #expect(throws: ValidationError.invalidEmail) {
            try Validators.validateEmail("not-an-email")
        }

        #expect(throws: ValidationError.weakPassword) {
            try Validators.validatePassword("123")
        }
    }

    @Test func authenticationValidatorsRejectEmptyNameAndMismatchedPasswords() {
        #expect(throws: ValidationError.emptyName) {
            try Validators.validateName("   ")
        }

        #expect(throws: ValidationError.passwordMismatch) {
            try Validators.validatePasswords("secret1", confirmation: "secret2")
        }
    }

    @Test func authAndBootstrapErrorsHaveUserFacingMessages() {
        #expect(AuthServiceError.bannedUser.errorDescription == "This account has been banned by an admin.")
        #expect(AuthServiceError.notSignedIn.errorDescription == "Please sign in first.")
        #expect(AdminBootstrapError.adminAlreadyExists.errorDescription == "An admin account already exists. Use the admin role management screen for further role changes.")
    }
}

struct UserRoleAndProfileTests {
    @Test func registeredUsersDefaultToDefaultUserRole() {
        let user = makeUser(role: .defaultUser)

        #expect(user.role == .defaultUser)
        #expect(!user.isAdmin)
        #expect(!user.isCommunityMember)
    }

    @Test func adminRoleRoutesAsAdminOnly() {
        let admin = makeUser(role: .admin)
        let mentor = makeUser(role: .mentor)

        #expect(admin.isAdmin)
        #expect(!mentor.isAdmin)
        #expect(UserRole.adminAssignableRoles == [.defaultUser, .member, .mentor, .admin])
    }

    @Test func userRoleDisplayNamesMatchVisibleLabels() {
        #expect(UserRole.defaultUser.displayName == "Default User")
        #expect(UserRole.member.displayName == "Member")
        #expect(UserRole.communityUser.displayName == "Community User")
        #expect(UserRole.mentor.displayName == "Mentor")
        #expect(UserRole.admin.displayName == "Admin")
    }

    @Test func assignedCommunityMakesUserACommunityMember() {
        let user = makeUser(role: .defaultUser, assignedCommunities: ["group-1"])

        #expect(user.isCommunityMember)
    }

    @Test func communityRolesAreCommunityMembersWithoutAssignments() {
        #expect(makeUser(role: .member).isCommunityMember)
        #expect(makeUser(role: .communityUser).isCommunityMember)
        #expect(!makeUser(role: .mentor).isCommunityMember)
    }

    @Test func userCommunityLimitIsFive() {
        let belowLimit = makeUser(assignedCommunities: ["1", "2", "3", "4"])
        let atLimit = makeUser(assignedCommunities: ["1", "2", "3", "4", "5"])

        #expect(AppConstants.maxJoinedCommunities == 5)
        #expect(belowLimit.canJoinMoreCommunities)
        #expect(!atLimit.canJoinMoreCommunities)
    }

    @MainActor
    @Test func profileViewModelPrepareEditingCopiesUserState() {
        let user = makeUser(fullName: "Updated Name", bio: "Bio text")
        let viewModel = ProfileViewModel()

        viewModel.prepareEditing(from: user)

        #expect(viewModel.user == user)
        #expect(viewModel.fullName == "Updated Name")
        #expect(viewModel.bio == "Bio text")
    }
}

struct CommunityBusinessRuleTests {
    @Test func communityOpenStatusRequiresOpenRegistrationAndActivePeriod() {
        let open = makeGroup(status: .open, registrationOpen: true, endDate: Date().addingDays(3))
        let closed = makeGroup(status: .closed, registrationOpen: false, endDate: Date().addingDays(3))
        let expired = makeGroup(status: .open, registrationOpen: true, endDate: Date().addingDays(-1))

        #expect(open.isOpen)
        #expect(!closed.isOpen)
        #expect(!expired.isOpen)
    }

    @Test func communityUsesExactlyOneSearchTag() {
        let group = makeGroup(tag: "SEO")

        #expect(group.tag == "SEO")
        #expect(group.tags == ["SEO"])
    }

    @Test func communityCapacityConstantsMatchBusinessRules() {
        #expect(AppConstants.maxGroupMembers == 15)
        #expect(AppConstants.maxGroupMentors == 3)
        #expect(AppConstants.minGroupMembers == 5)
        #expect(AppConstants.minGroupMentors == 1)
        #expect(AppConstants.maxMentorCommunities == 5)
    }

    @Test func groupServiceCanJoinRejectsClosedExpiredFullAndAlreadyJoinedCommunities() {
        let user = makeUser(uid: "user-1")

        #expect(!GroupService.shared.canJoin(user: user, group: makeGroup(members: Array(repeating: "member", count: 15))))
        #expect(!GroupService.shared.canJoin(user: user, group: makeGroup(status: .closed, registrationOpen: false)))
        #expect(!GroupService.shared.canJoin(user: user, group: makeGroup(endDate: Date().addingDays(-1))))
        #expect(!GroupService.shared.canJoin(user: user, group: makeGroup(members: ["user-1"])))
    }

    @Test func groupServiceCanJoinAllowsEligibleUserAndMentorWithinCapacity() {
        let user = makeUser(uid: "user-1", role: .defaultUser, assignedCommunities: ["1", "2"])
        let mentor = makeUser(uid: "mentor-2", role: .mentor, assignedCommunities: ["1", "2"])

        #expect(GroupService.shared.canJoin(user: user, group: makeGroup(members: ["member-1"])))
        #expect(GroupService.shared.canJoin(user: mentor, group: makeGroup(mentors: ["mentor-1"])))
    }

    @Test func groupServiceCanJoinEnforcesUserAndMentorCommunityLimits() {
        let fullUser = makeUser(uid: "user-1", role: .defaultUser, assignedCommunities: ["1", "2", "3", "4", "5"])
        let fullMentor = makeUser(uid: "mentor-2", role: .mentor, assignedCommunities: ["1", "2", "3", "4", "5"])
        let fullMentorGroup = makeGroup(mentors: ["m1", "m2", "m3"])

        #expect(!GroupService.shared.canJoin(user: fullUser, group: makeGroup()))
        #expect(!GroupService.shared.canJoin(user: fullMentor, group: makeGroup(mentors: ["mentor-1"])))
        #expect(!GroupService.shared.canJoin(user: makeUser(uid: "mentor-4", role: .mentor), group: fullMentorGroup))
    }

    @MainActor
    @Test func groupViewModelToggleTagAddsAndRemovesSelection() {
        let viewModel = GroupViewModel()

        viewModel.toggleTag("SEO")
        #expect(viewModel.selectedTags == ["SEO"])

        viewModel.toggleTag("SEO")
        #expect(viewModel.selectedTags.isEmpty)
    }

    @Test func onboardingBatchBoundariesMatchQuarterlySchedule() {
        let manager = OnboardingManager.shared

        #expect(manager.currentBatch(at: makeDate(year: 2026, month: 1, day: 15)).batchNumber == 1)
        #expect(manager.currentBatch(at: makeDate(year: 2026, month: 4, day: 1)).batchNumber == 2)
        #expect(manager.currentBatch(at: makeDate(year: 2026, month: 10, day: 31)).batchNumber == 4)
    }

    @Test func onboardingRegistrationWindowIsOpenOnlyForFirstSevenDays() {
        let batch = OnboardingManager.shared.currentBatch(at: makeDate(year: 2026, month: 7, day: 1))

        #expect(batch.isRegistrationOpen(at: batch.startDate))
        #expect(batch.isRegistrationOpen(at: batch.startDate.addingDays(AppConstants.onboardingDays)))
        #expect(!batch.isRegistrationOpen(at: batch.startDate.addingDays(AppConstants.onboardingDays + 1)))
    }

}

struct GlobalDiscussionAndReportTests {
    @Test func postOwnershipControlsDeletePermissionInFeedModel() {
        let ownPost = makeFeedPost(authorId: "user-1", isMine: true)
        let otherPost = makeFeedPost(authorId: "user-2", isMine: false)

        #expect(ownPost.isMine)
        #expect(!otherPost.isMine)
    }

    @Test func postServiceErrorsProtectDeleteAndReportRules() {
        #expect(PostServiceError.notPostOwner.errorDescription == "Only the post owner can delete this post.")
        #expect(PostServiceError.cannotReportOwnPost.errorDescription == "You cannot report your own post.")
    }

    @Test func reportAndPostModelsExposeStableIdentities() {
        let post = makePost(postId: "post-9")
        let report = makeReport(reportId: "report-9", status: .pending)

        #expect(post.id == "post-9")
        #expect(report.id == "report-9")
        #expect(report.targetType == .post)
    }

    @Test func reportAggregationKeepsPendingStatusWhenAnyReportIsPending() {
        let item = AdminReportedPostModel(
            post: makePost(reportCount: 2),
            author: makeUser(uid: "author-1"),
            reports: [
                makeReport(status: .rejected),
                makeReport(reportId: "report-2", status: .pending)
            ]
        )

        #expect(item.reportStatus == .pending)
    }

    @Test func reportAggregationFallsBackToAcceptedThenRejected() {
        let accepted = AdminReportedPostModel(post: makePost(reportCount: 1), author: nil, reports: [makeReport(status: .accepted)])
        let rejected = AdminReportedPostModel(post: makePost(reportCount: 1), author: nil, reports: [makeReport(status: .rejected)])

        #expect(accepted.reportStatus == .accepted)
        #expect(rejected.reportStatus == .rejected)
    }

    @Test func emptyReportAggregationIsRejectedFallbackForResolvedListItems() {
        let item = AdminReportedPostModel(post: makePost(), author: nil, reports: [])

        #expect(item.reportStatus == .rejected)
    }

    @Test func globalDiscussionModelsSupportLikesAndComments() {
        let comment = CommentModel(
            commentId: "comment-1",
            postId: "post-1",
            userId: "user-1",
            userName: "User One",
            content: "Nice insight",
            likeCount: 1,
            createdAt: Date(),
            deleted: false
        )
        let like = LikeModel(likeId: "like-1", postId: "post-1", userId: "user-1", createdAt: Date())

        #expect(comment.postId == "post-1")
        #expect(comment.deleted == false)
        #expect(comment.id == "comment-1")
        #expect(like.postId == "post-1")
        #expect(like.id == "like-1")
    }
}

struct ViewModelStateTests {
    @MainActor
    @Test func adminUserManagementFiltersByNameEmailAndRole() {
        let viewModel = AdminUserManagementViewModel()
        viewModel.users = [
            makeUser(uid: "1", fullName: "Alice Admin", email: "alice@example.com", role: .admin),
            makeUser(uid: "2", fullName: "Mira Mentor", email: "mira@example.com", role: .mentor),
            makeUser(uid: "3", fullName: "Dede User", email: "dede@example.com", role: .defaultUser)
        ]

        viewModel.searchText = "mentor"
        #expect(viewModel.filteredUsers.map(\.uid) == ["2"])

        viewModel.searchText = "alice@example"
        #expect(viewModel.filteredUsers.map(\.uid) == ["1"])

        viewModel.searchText = "  "
        #expect(viewModel.filteredUsers.count == 3)
    }

    @Test func viewModelErrorsHaveClearMessages() {
        #expect(GroupViewModelError.mentorRequired.errorDescription == "Only mentors can create communities.")
        #expect(AdminNewsError.missingAdmin.errorDescription == "Admin session is missing.")
    }

    @MainActor
    @Test func materialsViewModelDetectsSavedMaterialState() {
        let viewModel = MaterialsViewModel()
        let material = makeMaterial(id: "material-1")

        #expect(viewModel.isSaved(material, by: makeUser(savedMaterials: ["material-1"])))
        #expect(!viewModel.isSaved(material, by: makeUser(savedMaterials: [])))
        #expect(!viewModel.isSaved(material, by: nil))
    }

    @MainActor
    @Test func authViewModelInitialStateIsEmptyAndNotLoading() {
        let viewModel = AuthViewModel()

        #expect(viewModel.fullName.isEmpty)
        #expect(viewModel.email.isEmpty)
        #expect(viewModel.password.isEmpty)
        #expect(viewModel.confirmPassword.isEmpty)
        #expect(!viewModel.isLoading)
        #expect(viewModel.errorMessage == nil)
    }

    @MainActor
    @Test func scheduleViewModelFiltersActivitiesForSelectedDate() {
        let today = Date()
        let tomorrow = today.addingDays(1)
        let viewModel = EventViewModel()
        viewModel.selectedDate = today
        viewModel.activities = [
            makeActivity(id: "today", date: today),
            makeActivity(id: "tomorrow", date: tomorrow)
        ]
        viewModel.assignments = [
            makeAssignment(activityId: "today", completed: false),
            makeAssignment(activityId: "tomorrow", completed: false)
        ]

        #expect(viewModel.selectedDateActivities.map { $0.activity.activityId } == ["today"])
    }

    @MainActor
    @Test func scheduleCalendarDotOnlyShowsForCurrentOrFuturePendingActivities() {
        let today = Date()
        let yesterday = today.addingDays(-1)
        let viewModel = EventViewModel()

        viewModel.activities = [makeActivity(id: "a1", date: today)]
        viewModel.assignments = [makeAssignment(activityId: "a1", completed: false)]
        #expect(viewModel.activitiesContainPendingItem(on: today))

        viewModel.assignments = [makeAssignment(activityId: "a1", completed: true)]
        #expect(!viewModel.activitiesContainPendingItem(on: today))

        viewModel.activities = [makeActivity(id: "past", date: yesterday)]
        viewModel.assignments = [makeAssignment(activityId: "past", completed: false)]
        #expect(!viewModel.activitiesContainPendingItem(on: yesterday))
    }

    @Test func eventRegistrationOpenRequiresDeadlineAndCapacity() {
        let open = makeEvent(participantCount: 1, capacity: 2, registrationDeadline: Date().addingDays(1))
        let full = makeEvent(participantCount: 2, capacity: 2, registrationDeadline: Date().addingDays(1))
        let closed = makeEvent(participantCount: 0, capacity: 2, registrationDeadline: Date().addingDays(-1))

        #expect(open.isRegistrationOpen)
        #expect(!full.isRegistrationOpen)
        #expect(!closed.isRegistrationOpen)
    }
}

struct UtilitiesAndConstantsTests {
    @Test func firestoreCollectionNamesUseReadablePostSubcollections() {
        #expect(FirestoreCollections.users == "users")
        #expect(FirestoreCollections.posts == "posts")
        #expect(FirestoreCollections.reports == "reports")
        #expect(FirestoreCollections.postComments == "post_comments")
        #expect(FirestoreCollections.postLikes == "post_likes")
        #expect(FirestoreCollections.postCommentLikes == "post_comment_likes")
        #expect(FirestoreCollections.groups == "groups")
        #expect(FirestoreCollections.news == "news")
        #expect(FirestoreCollections.activities == "activities")
        #expect(FirestoreCollections.activityAssignments == "activity_assignments")
        #expect(FirestoreCollections.eventRegistrations == "event_registrations")
    }

    @Test func storagePathsAreStableAndScopedByResourceId() {
        #expect(StoragePaths.profileImage(uid: "u1") == "profileImages/u1/profile.jpg")
        #expect(StoragePaths.materialThumbnail(materialId: "m1") == "materials/m1/thumbnail.jpg")
        #expect(StoragePaths.materialContent(materialId: "m1", fileName: "lesson.pdf") == "materials/m1/lesson.pdf")
    }

    @Test func marketingInterestListContainsExpectedReusableTags() {
        #expect(AppConstants.marketingInterests.contains("SEO"))
        #expect(AppConstants.marketingInterests.contains("Digital Marketing"))
        #expect(AppConstants.marketingInterests.count == 10)
    }

    @Test func dictionaryHelpersReturnTypedValuesAndDefaults() {
        let date = Date()
        let data: [String: Any] = [
            "name": "Markeet",
            "active": true,
            "count": 3,
            "tags": ["SEO"],
            "createdAt": Timestamp(date: date)
        ]

        #expect(data.string("name") == "Markeet")
        #expect(data.string("missing", default: "fallback") == "fallback")
        #expect(data.bool("active"))
        #expect(data.bool("missingBool", default: true))
        #expect(data.int("count") == 3)
        #expect(data.int("missingInt", default: 9) == 9)
        #expect(data.stringArray("tags") == ["SEO"])
        #expect(abs(data.date("createdAt").timeIntervalSince(date)) < 0.001)
    }
}

private func makeUser(
    uid: String = "user-1",
    fullName: String = "User One",
    email: String = "user@example.com",
    role: UserRole = .defaultUser,
    bio: String = "",
    onboardingEndDate: Date = Date().addingDays(AppConstants.onboardingDays),
    onboardingActive: Bool = true,
    marketingInterests: [String] = [],
    assignedCommunities: [String] = [],
    savedMaterials: [String] = [],
    bannedStatus: Bool = false
) -> UserModel {
    let now = Date()
    return UserModel(
        uid: uid,
        fullName: fullName,
        email: email,
        role: role,
        profileImageURL: nil,
        bio: bio,
        createdAt: now,
        onboardingStartDate: now,
        onboardingEndDate: onboardingEndDate,
        onboardingActive: onboardingActive,
        marketingInterests: marketingInterests,
        assignedCommunities: assignedCommunities,
        savedMaterials: savedMaterials,
        registeredEvents: [],
        bannedStatus: bannedStatus,
        fcmToken: nil
    )
}

private func makeGroup(
    status: CommunityStatus = .open,
    registrationOpen: Bool = true,
    tag: String = "SEO",
    endDate: Date = Date().addingDays(30),
    members: [String] = [],
    mentors: [String] = ["mentor-1"]
) -> GroupModel {
    GroupModel(
        groupId: "group-1",
        groupName: "SEO Growth",
        description: "A focused SEO community",
        batchNumber: 1,
        startDate: Date().addingDays(-1),
        endDate: endDate,
        registrationOpen: registrationOpen,
        status: status,
        tag: tag,
        members: members,
        mentors: mentors,
        maxMembers: AppConstants.maxGroupMembers,
        minMembers: AppConstants.minGroupMembers,
        maxMentors: AppConstants.maxGroupMentors,
        minMentors: AppConstants.minGroupMentors,
        createdAt: Date()
    )
}

private func makeFeedPost(authorId: String, isMine: Bool) -> FeedPost {
    FeedPost(
        postId: "post-1",
        authorId: authorId,
        initials: "UO",
        username: "User One",
        role: "Default User",
        time: "Today",
        content: "Marketing update",
        likes: 0,
        comments: 0,
        isMine: isMine
    )
}

private func makePost(postId: String = "post-1", reportCount: Int = 0) -> PostModel {
    PostModel(
        postId: postId,
        authorId: "author-1",
        content: "Reported content",
        imageURL: nil,
        likeCount: 0,
        commentCount: 0,
        reportCount: reportCount,
        createdAt: Date(),
        deleted: false
    )
}

private func makeReport(reportId: String = "report-1", status: ReportStatus) -> ReportModel {
    ReportModel(
        reportId: reportId,
        reporterId: "reporter-1",
        targetId: "post-1",
        targetType: .post,
        reason: "Spam",
        status: status,
        createdAt: Date()
    )
}

private func makeMaterial(id: String) -> MaterialModel {
    MaterialModel(
        materialId: id,
        title: "SEO Basics",
        description: "Intro material",
        thumbnailURL: nil,
        contentURL: "https://example.com/material.pdf",
        createdAt: Date(),
        createdBy: "admin-1",
        tags: ["SEO"]
    )
}

private func makeActivity(id: String, date: Date) -> ActivityModel {
    ActivityModel(
        activityId: id,
        title: "Activity \(id)",
        description: "Practice session",
        date: date,
        startTime: date,
        endTime: date.addingTimeInterval(3600),
        mentorId: "mentor-1",
        assignedUserIds: ["user-1"],
        createdAt: date,
        updatedAt: date
    )
}

private func makeAssignment(activityId: String, completed: Bool) -> ActivityAssignmentModel {
    ActivityAssignmentModel(
        assignmentId: "\(activityId)_user-1",
        activityId: activityId,
        userId: "user-1",
        completed: completed,
        completedAt: completed ? Date() : nil,
        assignedAt: Date()
    )
}

private func makeEvent(participantCount: Int, capacity: Int, registrationDeadline: Date) -> EventModel {
    EventModel(
        eventId: "event-1",
        title: "Marketing Event",
        description: "Event description",
        imageURL: nil,
        location: "Online",
        startDate: Date().addingDays(2),
        endDate: Date().addingDays(2).addingTimeInterval(7200),
        capacity: capacity,
        registrationDeadline: registrationDeadline,
        mentorId: "mentor-1",
        participantCount: participantCount,
        createdAt: Date(),
        updatedAt: Date()
    )
}

private func makeDate(year: Int, month: Int, day: Int) -> Date {
    Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
}
