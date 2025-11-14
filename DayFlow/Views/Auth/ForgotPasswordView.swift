//
//  ForgotPasswordView.swift
//  DayFlow
//
//  Created by ebrar seda gündüz on 13.10.2025.
//

import SwiftUI

struct ForgotPasswordView: View {
    // MARK: - Properties
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: AuthViewModel
    
    @State private var email = ""
    @State private var isLoading = false
    @State private var message = ""
    @State private var showAlert = false
    @State private var isSuccess = false
    
    // MARK: - Computed Properties
    
    private var emailError: String? {
        guard !email.isEmpty else { return nil }
        return viewModel.validateEmail(email)
    }
    
    private var isValid: Bool {
        !email.isEmpty && emailError == nil
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundView
                contentView
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    AuthCloseButton { dismiss() }
                }
            }
            .alert(isSuccess ? "Success!" : "Error", isPresented: $showAlert) {
                Button("OK") {
                    if isSuccess { dismiss() }
                }
            } message: {
                Text(message)
            }
        }
    }
    
    // MARK: - View Components
    
    private var backgroundView: some View {
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
                headerSection
                titleSection
                emailField
                infoMessage
                sendButton
                Spacer()
            }
        }
    }
    
    private var headerSection: some View {
        AuthHeaderIcon(
            icon: "key.fill",
            backgroundColor: Color(hex: "5A67E8")
        )
        .padding(.top, 40)
    }
    
    private var titleSection: some View {
        AuthTitleSection(
            title: "Reset Password",
            subtitle: "Enter your email to receive a password reset link"
        )
    }
    
    private var emailField: some View {
        VStack(alignment: .leading, spacing: 8) {
            AuthInputField(
                icon: "envelope.fill",
                iconColor: Color(hex: "A8E6CF"),
                placeholder: "Email",
                text: $email,
                keyboardType: .emailAddress
            )
            
            if let error = emailError {
                ErrorText(error)
            }
        }
        .padding(.horizontal, 24)
    }
    
    private var infoMessage: some View {
        AuthInfoMessage(
            icon: "info.circle.fill",
            message: "We'll send you an email with instructions to reset your password. Please check your spam folder if you don't see it.",
            backgroundColor: Color(hex: "5A67E8").opacity(0.1),
            foregroundColor: Color(hex: "2D5F4F")
        )
        .padding(.horizontal, 24)
    }
    
    private var sendButton: some View {
        AuthGradientButton(
            title: "Send Reset Link",
            isLoading: isLoading,
            gradientColors: [Color(hex: "6B7FFF"), Color(hex: "5A67E8")],
            action: handleResetPassword
        )
        .disabled(!isValid || isLoading)
        .opacity(isValid ? 1.0 : 0.5)
        .padding(.horizontal, 24)
    }
    
    // MARK: - Methods
    
    private func handleResetPassword() {
        isLoading = true
        
        viewModel.resetPassword(email: email) { result in
            isLoading = false
            
            switch result {
            case .success:
                isSuccess = true
                message = "Password reset link has been sent to your email."
            case .failure(let error):
                isSuccess = false
                message = error.localizedDescription
            }
            
            showAlert = true
        }
    }
}

// MARK: - Preview

#Preview {
    ForgotPasswordView()
        .environmentObject(AuthViewModel())
}
