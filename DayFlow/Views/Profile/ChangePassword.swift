
import SwiftUI
struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ProfileViewModel
    
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var showCurrentPassword: Bool = false
    @State private var showNewPassword: Bool = false
    @State private var showConfirmPassword: Bool = false
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                contentView
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    cancelButton
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - View Builders
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color(hex: "F8F9FA"), Color.white],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    private var contentView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                headerIcon
                titleSection
                passwordFields
                updateButton
                Spacer()
            }
        }
    }
    
    private var headerIcon: some View {
        AuthHeaderIcon(
            icon: "lock.shield.fill",
            backgroundColor: Color(hex: "B4A7D6")
        )
        .padding(.top, 40)
    }
    
    private var titleSection: some View {
        AuthTitleSection(
            title: "Change Password",
            subtitle: "Ensure your account is secure"
        )
    }
    
    private var passwordFields: some View {
        VStack(spacing: 20) {
            PasswordField(
                title: "Current Password",
                text: $currentPassword,
                show: $showCurrentPassword
            )
            
            PasswordField(
                title: "New Password",
                text: $newPassword,
                show: $showNewPassword
            )
            
            if !newPassword.isEmpty {
                PasswordStrengthView(password: newPassword)
                    .padding(.horizontal, 24)
            }
            
            PasswordField(
                title: "Confirm New Password",
                text: $confirmPassword,
                show: $showConfirmPassword
            )
            
            if !confirmPassword.isEmpty && confirmPassword != newPassword {
                ErrorText("Passwords don't match")
                    .padding(.horizontal, 24)
            }
        }
    }
    
    private var updateButton: some View {
        AuthGradientButton(
            title: "Update Password",
            isLoading: false,
            gradientColors: [Color(hex: "B4A7D6"), Color(hex: "9B89C8")],
            action: handleUpdatePassword
        )
        .disabled(!isValid)
        .opacity(isValid ? 1.0 : 0.5)
        .padding(.horizontal, 24)
    }
    
    private var cancelButton: some View {
        Button("Cancel") { dismiss() }
            .foregroundColor(Color(hex: "B4A7D6"))
            .fontWeight(.semibold)
    }
    
    // MARK: - Computed Properties
    
    private var isValid: Bool {
        !currentPassword.isEmpty &&
        !newPassword.isEmpty &&
        newPassword.count >= 8 &&
        newPassword == confirmPassword
    }
    
    // MARK: - Methods
    
    private func handleUpdatePassword() {
        viewModel.changePassword(
            currentPassword: currentPassword,
            newPassword: newPassword
        ) { result in
            switch result {
            case .success:
                dismiss()
            case .failure(let error):
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

// MARK: - Password Field Component

 struct PasswordField: View {
    let title: String
    @Binding var text: String
    @Binding var show: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            HStack {
                Group {
                    if show {
                        TextField("", text: $text)
                            .font(.system(size: 16, weight: .medium))
                    } else {
                        SecureField("", text: $text)
                            .font(.system(size: 16, weight: .medium))
                    }
                }
                
                Button(action: { show.toggle() }) {
                    Image(systemName: show ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
            )
        }
        .padding(.horizontal, 24)
    }
}
