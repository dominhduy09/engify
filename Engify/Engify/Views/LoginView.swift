import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @EnvironmentObject private var theme: ThemeManager
    @FocusState private var focusedField: Field?

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var displayName = ""
    @State private var mode: AuthMode = .login
    @State private var alertContext: AlertContext?
    @State private var localInfoMessage: String?
    @State private var shakeFields = false

    private enum AuthMode: String, CaseIterable {
        case login = "Sign In"
        case signUp = "Create Account"

        var title: String {
            switch self {
            case .login:
                return "Welcome back"
            case .signUp:
                return "Create your account"
            }
        }

        var subtitle: String {
            switch self {
            case .login:
                return "Sign in to continue your lessons, saved words, and progress."
            case .signUp:
                return "Start a secure Engify account and keep your learning synced."
            }
        }

        var actionTitle: String {
            switch self {
            case .login:
                return "Sign In"
            case .signUp:
                return "Create Account"
            }
        }

        var actionIcon: String {
            switch self {
            case .login:
                return "arrow.right.circle.fill"
            case .signUp:
                return "person.badge.plus"
            }
        }
    }

    private enum Field {
        case displayName
        case email
        case password
        case confirmPassword
    }

    private struct AlertContext: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }

    private var isInputValid: Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let emailValid = !trimmedEmail.isEmpty && trimmedEmail.contains("@")
        let passwordValid = password.count >= 6

        if mode == .signUp {
            let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
            let confirmValid = !confirmPassword.isEmpty && confirmPassword == password
            return emailValid && passwordValid && trimmedName.count >= 2 && confirmValid
        }

        return emailValid && passwordValid
    }

    var body: some View {
        EngifyScreenScroll(alignment: .center, spacing: Spacing.xl, bottomInset: 48) {
            VStack(spacing: Spacing.xl) {
                heroSection
                authCard
                trustSection
            }
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
        .animation(.easeInOut(duration: 0.22), value: mode)
        .animation(.easeInOut(duration: 0.18), value: shakeFields)
        .alert(item: $alertContext) { context in
            Alert(
                title: Text(context.title),
                message: Text(context.message),
                dismissButton: .default(Text("Continue"))
            )
        }
        .task {
            localInfoMessage = authManager.consumeInfoMessage()
        }
        .onChange(of: authManager.infoMessage) { infoMessage in
            if let infoMessage {
                localInfoMessage = infoMessage
            }
        }
        .onChange(of: mode) { _ in
            authManager.clearError()
            localInfoMessage = nil
            focusedField = nil
        }
    }

    private var heroSection: some View {
        VStack(spacing: Spacing.md) {
            EngifyLogoView()
                .frame(height: 112)

            VStack(spacing: Spacing.sm) {
                Text(mode.title)
                    .font(EngifyTypography.hero)
                    .foregroundStyle(EngifyColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(mode.subtitle)
                    .font(EngifyTypography.body)
                    .foregroundStyle(EngifyColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.top, 24)
    }

    private var authCard: some View {
        EngifyCard(tint: theme.accentColor) {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                modePicker
                statusSection
                formSection
                forgotPasswordButton
                actionSection
                dividerSection
                socialSection
            }
        }
    }

    private var modePicker: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(AuthMode.allCases, id: \.self) { item in
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                        mode = item
                    }
                } label: {
                    Text(item.rawValue)
                        .font(EngifyTypography.bodyStrong)
                        .foregroundStyle(mode == item ? EngifyColors.textInverse : EngifyColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(mode == item ? AnyShapeStyle(theme.accentColor) : AnyShapeStyle(Color.clear))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Spacing.xxs)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(EngifyColors.canvasRaised.opacity(0.85))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(EngifyColors.border.opacity(0.8), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var statusSection: some View {
        if let configurationError = authManager.configurationErrorMessage {
            StatusBanner(message: configurationError, type: .error)
        }

        if let errorMessage = authManager.errorMessage {
            StatusBanner(message: errorMessage, type: .error)
        }

        if let localInfoMessage, !localInfoMessage.isEmpty {
            StatusBanner(message: localInfoMessage, type: .info)
        }
    }

    private var formSection: some View {
        VStack(spacing: Spacing.md) {
            if mode == .signUp {
                FloatingLabelField(
                    label: "Full Name",
                    text: $displayName,
                    icon: "person.fill",
                    isFocused: focusedField == .displayName
                )
                .focused($focusedField, equals: .displayName)
                .textContentType(.name)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            FloatingLabelField(
                label: "Email Address",
                text: $email,
                icon: "envelope.fill",
                isFocused: focusedField == .email
            )
            .focused($focusedField, equals: .email)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .keyboardType(.emailAddress)
            .textContentType(.emailAddress)

            FloatingLabelField(
                label: "Password",
                text: $password,
                icon: "lock.fill",
                isFocused: focusedField == .password,
                isSecure: true
            )
            .focused($focusedField, equals: .password)
            .textContentType(mode == .login ? .password : .newPassword)

            if mode == .signUp {
                FloatingLabelField(
                    label: "Confirm Password",
                    text: $confirmPassword,
                    icon: "checkmark.shield.fill",
                    isFocused: focusedField == .confirmPassword,
                    isSecure: true
                )
                .focused($focusedField, equals: .confirmPassword)
                .textContentType(.newPassword)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .modifier(ShakeEffect(shake: shakeFields))
    }

    @ViewBuilder
    private var forgotPasswordButton: some View {
        if mode == .login {
            HStack {
                Spacer(minLength: 0)

                Button("Forgot password?") {
                    Task {
                        let success = await authManager.sendPasswordReset(email: email)
                        guard success, let infoMessage = authManager.consumeInfoMessage() else {
                            return
                        }

                        localInfoMessage = infoMessage
                        alertContext = AlertContext(
                            title: "Password Reset",
                            message: infoMessage
                        )
                    }
                }
                .buttonStyle(.plain)
                .font(EngifyTypography.caption)
                .foregroundStyle(theme.accentColor)
                .disabled(authManager.isLoading || authManager.configurationErrorMessage != nil)
            }
        }
    }

    private var actionSection: some View {
        VStack(spacing: Spacing.sm) {
            PrimaryButton(
                title: authManager.isLoading ? "Please wait..." : mode.actionTitle,
                systemImage: authManager.isLoading ? nil : mode.actionIcon,
                action: {
                    Task {
                        await performAuth()
                    }
                },
                isDisabled: !isInputValid || authManager.isLoading || authManager.configurationErrorMessage != nil,
                size: .large
            )
            .environmentObject(theme)

            Text(mode == .login ? "Your session stays securely restored between launches." : "We use Supabase Auth and never store secrets in the app.")
                .font(EngifyTypography.caption)
                .foregroundStyle(EngifyColors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
    }

    private var dividerSection: some View {
        HStack(spacing: Spacing.md) {
            Rectangle()
                .fill(EngifyColors.border.opacity(0.9))
                .frame(height: 1)

            Text("More options")
                .font(EngifyTypography.caption)
                .foregroundStyle(EngifyColors.textSecondary)

            Rectangle()
                .fill(EngifyColors.border.opacity(0.9))
                .frame(height: 1)
        }
        .padding(.vertical, Spacing.xs)
    }

    private var socialSection: some View {
        VStack(spacing: Spacing.sm) {
            SocialLoginButton(provider: "Continue with Google", icon: "g.circle.fill") {
                authManager.errorMessage = "Google sign-in is not enabled yet. Add Supabase OAuth callback wiring to turn it on safely."
            }

            SocialLoginButton(provider: "Continue with Apple", icon: "apple.logo") {
                authManager.errorMessage = "Apple sign-in is not enabled yet. Add Supabase OAuth callback wiring to turn it on safely."
            }
        }
    }

    private var trustSection: some View {
        EngifyCard(tint: EngifyColors.sky) {
            HStack(alignment: .top, spacing: Spacing.md) {
                EngifyIconBadge(systemImage: "lock.shield.fill", tint: EngifyColors.sky, size: 44)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Secure session management")
                        .font(EngifyTypography.bodyStrong)
                        .foregroundStyle(EngifyColors.textPrimary)

                    Text("Protected screens stay behind authentication, sessions restore automatically, and sign-out clears access cleanly.")
                        .font(EngifyTypography.caption)
                        .foregroundStyle(EngifyColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
        }
    }

    private func performAuth() async {
        focusedField = nil
        authManager.clearError()

        if mode == .signUp, password != confirmPassword {
            authManager.errorMessage = AuthValidationError.passwordsDoNotMatch.localizedDescription
            triggerShake()
            return
        }

        let wasSuccessful: Bool

        if mode == .login {
            wasSuccessful = await authManager.signIn(email: email, password: password)
            if wasSuccessful {
                clearLocalFields(keepEmail: true)
            } else {
                triggerShake()
            }
            return
        }

        wasSuccessful = await authManager.signUp(
            email: email,
            password: password,
            confirmPassword: confirmPassword,
            displayName: displayName
        )

        guard wasSuccessful else {
            triggerShake()
            return
        }

        if authManager.isAuthenticated {
            clearLocalFields(keepEmail: true)
            return
        }

        if let infoMessage = authManager.consumeInfoMessage() {
            localInfoMessage = infoMessage
            alertContext = AlertContext(
                title: "Check Your Email",
                message: infoMessage
            )
            password = ""
            confirmPassword = ""
        }
    }

    private func clearLocalFields(keepEmail: Bool) {
        if !keepEmail {
            email = ""
        }
        password = ""
        confirmPassword = ""
        displayName = ""
    }

    private func triggerShake() {
        withAnimation(.linear(duration: 0.08)) {
            shakeFields = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.linear(duration: 0.08)) {
                shakeFields = false
            }
        }
    }
}

struct FloatingLabelField: View {
    let label: String
    @Binding var text: String
    let icon: String
    var isFocused: Bool
    var isSecure: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(label)
                .font(EngifyTypography.caption)
                .foregroundStyle(isFocused ? EngifyColors.accent : EngifyColors.textSecondary)

            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isFocused ? EngifyColors.accent : EngifyColors.textSecondary)
                    .frame(width: 18)

                if isSecure {
                    SecureField(label, text: $text)
                        .font(EngifyTypography.body)
                } else {
                    TextField(label, text: $text)
                        .font(EngifyTypography.body)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .frame(minHeight: Spacing.controlHeight)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isFocused ? EngifyColors.accent.opacity(0.08) : EngifyColors.canvasRaised.opacity(0.92))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isFocused ? EngifyColors.accent.opacity(0.85) : EngifyColors.border.opacity(0.85), lineWidth: isFocused ? 2 : 1)
            )
        }
    }
}

struct StatusBanner: View {
    let message: String
    let type: BannerType

    enum BannerType {
        case error
        case info
        case success

        var tone: EngifyStateTone {
            switch self {
            case .error:
                return .error
            case .info:
                return .info
            case .success:
                return .success
            }
        }

        var icon: String {
            switch self {
            case .error:
                return "exclamationmark.triangle.fill"
            case .info:
                return "info.circle.fill"
            case .success:
                return "checkmark.circle.fill"
            }
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: type.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(type.tone.color)
                .padding(.top, 1)

            Text(message)
                .font(EngifyTypography.caption)
                .foregroundStyle(EngifyColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(type.tone.color.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(type.tone.color.opacity(0.22), lineWidth: 1)
        )
    }
}

struct SocialLoginButton: View {
    let provider: String
    let icon: String
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.headline)

                Text(provider)
                    .font(EngifyTypography.bodyStrong)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Spacer(minLength: 0)

                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(EngifyColors.textSecondary)
            }
            .foregroundStyle(EngifyColors.textPrimary)
            .padding(.horizontal, Spacing.lg)
            .frame(minHeight: Spacing.controlHeight)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(EngifyColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(EngifyColors.border.opacity(0.85), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.985 : 1)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.12)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.24, dampingFraction: 0.8)) {
                        isPressed = false
                    }
                }
        )
    }
}

struct ShakeEffect: GeometryEffect {
    var shake: Bool

    var animatableData: CGFloat {
        get { shake ? 1 : 0 }
        set { }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        guard shake else {
            return ProjectionTransform(.identity)
        }

        return ProjectionTransform(
            CGAffineTransform(translationX: sin(animatableData * .pi * 4) * 6, y: 0)
        )
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthenticationManager())
        .environmentObject(ThemeManager())
}
