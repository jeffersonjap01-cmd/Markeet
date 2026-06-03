// AppTheme.swift
// Markeet — Centralized design system

import SwiftUI

// MARK: - App Theme
struct AppTheme {

    // MARK: Colors
    static let primary       = Color(red: 87/255, green: 79/255, blue: 222/255) // #574FDE — matches team tint
    static let primaryDark   = Color(red: 62/255, green: 55/255, blue: 180/255) // darker shade
    static let primaryLight  = Color(red: 116/255, green: 110/255, blue: 235/255) // lighter shade
    static let primaryGlow   = Color(hex: "5B2BE0").opacity(0.15)

    static let background    = Color(hex: "F2F2F7")
    static let surface       = Color.white
    static let surfaceAlt    = Color(hex: "F8F7FF")

    static let textPrimary   = Color(hex: "1C1C1E")
    static let textSecondary = Color(hex: "6E6E73")
    static let textTertiary  = Color(hex: "AEAEB2")
    static let textOnPrimary = Color.white

    static let divider       = Color(hex: "E5E5EA")
    static let success       = Color(hex: "34C759")
    static let error         = Color(hex: "FF3B30")
    static let warning       = Color(hex: "FF9500")
    static let info          = Color(hex: "007AFF")

    // MARK: Gradients
    static let primaryGradient = LinearGradient(
        colors: [Color(hex: "5B2BE0"), Color(hex: "3D1DB5")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let heroGradient = LinearGradient(
        colors: [Color(hex: "6B3FEA"), Color(hex: "3D1DB5")],
        startPoint: .top,
        endPoint: .bottom
    )

    // MARK: Corner Radius
    struct Radius {
        static let xs:   CGFloat = 6
        static let sm:   CGFloat = 10
        static let md:   CGFloat = 14
        static let lg:   CGFloat = 18
        static let xl:   CGFloat = 24
        static let pill: CGFloat = 100
    }

    // MARK: Spacing
    struct Spacing {
        static let xs:  CGFloat = 4
        static let sm:  CGFloat = 8
        static let md:  CGFloat = 16
        static let lg:  CGFloat = 24
        static let xl:  CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: Shadow
    struct Shadow {
        static let color  = Color.black.opacity(0.07)
        static let radius: CGFloat = 12
        static let x:      CGFloat = 0
        static let y:      CGFloat = 4

        static let soft   = Color.black.opacity(0.04)
    }

    // MARK: Animation
    static let defaultAnimation = Animation.easeInOut(duration: 0.2)
    static let springAnimation  = Animation.spring(response: 0.35, dampingFraction: 0.65)

    static func roleColor(_ role: UserRole) -> Color {
        switch role {
        case .admin:
            error
        case .mentor:
            warning
        case .member, .communityUser:
            success
        case .defaultUser:
            info
        }
    }
}

// MARK: - Reusable ViewModifiers

struct CardModifier: ViewModifier {
    var padding: CGFloat = AppTheme.Spacing.md
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppTheme.surface)
            .cornerRadius(AppTheme.Radius.lg)
            .shadow(color: AppTheme.Shadow.color, radius: AppTheme.Shadow.radius,
                    x: AppTheme.Shadow.x, y: AppTheme.Shadow.y)
    }
}

struct PrimaryButtonModifier: ViewModifier {
    var isEnabled: Bool = true
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(isEnabled ? AppTheme.primary : AppTheme.textTertiary)
            .foregroundColor(AppTheme.textOnPrimary)
            .cornerRadius(AppTheme.Radius.md)
            .font(.system(size: 16, weight: .semibold))
    }
}

struct SecondaryButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(AppTheme.primaryGlow)
            .foregroundColor(AppTheme.primary)
            .cornerRadius(AppTheme.Radius.md)
            .font(.system(size: 16, weight: .semibold))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                    .stroke(AppTheme.primary.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - View Extensions
extension View {
    func cardStyle(padding: CGFloat = AppTheme.Spacing.md) -> some View {
        modifier(CardModifier(padding: padding))
    }

    func primaryButton(isEnabled: Bool = true) -> some View {
        modifier(PrimaryButtonModifier(isEnabled: isEnabled))
    }

    func secondaryButton() -> some View {
        modifier(SecondaryButtonModifier())
    }

    func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil
        )
    }
}

// MARK: - Reusable UI Components

/// Avatar circle showing initials or image
struct AvatarView: View {
    var initials: String
    var imageURL: String?
    var size: CGFloat = 44
    var fontSize: CGFloat = 16

    var body: some View {
        ZStack {
            Circle()
                .fill(AppTheme.primaryGradient)
                .frame(width: size, height: size)

            if let urlStr = imageURL, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFill()
                            .frame(width: size, height: size)
                            .clipShape(Circle())
                    default:
                        initialsText
                    }
                }
            } else {
                initialsText
            }
        }
    }

    private var initialsText: some View {
        Text(initials)
            .font(.system(size: fontSize, weight: .bold))
            .foregroundColor(.white)
    }
}

/// Role badge pill
struct RoleBadge: View {
    var role: String
    var color: Color = AppTheme.primary

    var body: some View {
        Text(role)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .cornerRadius(AppTheme.Radius.pill)
    }
}

/// Section header with optional "See All" button
struct SectionHeader: View {
    var title: String
    var actionTitle: String? = "Lihat Semua"
    var action: (() -> Void)?

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
            Spacer()
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.primary)
                }
            }
        }
    }
}

/// Styled text field
struct MarkeetTextField: View {
    var label: String
    var placeholder: String
    var icon: String
    @Binding var text: String
    var errorText: String? = nil
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)

            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(errorText != nil ? AppTheme.error : AppTheme.textTertiary)
                    .frame(width: 20)

                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .foregroundColor(AppTheme.textPrimary)
                    .font(.system(size: 15))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(AppTheme.background)
            .cornerRadius(AppTheme.Radius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                    .stroke(errorText != nil ? AppTheme.error : AppTheme.divider, lineWidth: 1)
            )

            if let err = errorText {
                Text(err)
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.error)
            }
        }
    }
}

/// Styled secure field
struct MarkeetSecureField: View {
    var label: String
    var placeholder: String
    var icon: String
    @Binding var text: String
    @Binding var isVisible: Bool
    var errorText: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)

            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(errorText != nil ? AppTheme.error : AppTheme.textTertiary)
                    .frame(width: 20)

                if isVisible {
                    TextField(placeholder, text: $text)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .foregroundColor(AppTheme.textPrimary)
                        .font(.system(size: 15))
                } else {
                    SecureField(placeholder, text: $text)
                        .foregroundColor(AppTheme.textPrimary)
                        .font(.system(size: 15))
                }

                Button(action: { isVisible.toggle() }) {
                    Image(systemName: isVisible ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.textTertiary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(AppTheme.background)
            .cornerRadius(AppTheme.Radius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                    .stroke(errorText != nil ? AppTheme.error : AppTheme.divider, lineWidth: 1)
            )

            if let err = errorText {
                Text(err)
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.error)
            }
        }
    }
}

/// Generic loading overlay
struct LoadingOverlay: View {
    var message: String = "Memuat..."

    var body: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primary))
                    .scaleEffect(1.2)
                Text(message)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)
            }
            .padding(AppTheme.Spacing.xl)
            .background(AppTheme.surface)
            .cornerRadius(AppTheme.Radius.lg)
            .shadow(color: AppTheme.Shadow.color, radius: 20)
        }
    }
}

/// Empty state view
struct EmptyStateView: View {
    var icon: String
    var title: String
    var subtitle: String
    var buttonTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 52))
                .foregroundColor(AppTheme.textTertiary)
                .padding(.bottom, 4)

            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)

            Text(subtitle)
                .font(.system(size: 14))
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.xl)

            if let buttonTitle, let action {
                Button(action: action) {
                    Text(buttonTitle)
                }
                .primaryButton()
                .padding(.horizontal, AppTheme.Spacing.xl)
                .padding(.top, 4)
            }
        }
        .padding(AppTheme.Spacing.xl)
    }
}
