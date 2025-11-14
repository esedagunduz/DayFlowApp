//
//  SignUpView.swift
//  DayFlow
//
//  Created by ebrar seda gündüz on 13.10.2025.
//

import SwiftUI

struct SignUpView: View {
    // MARK: - Properties
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: AuthViewModel
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showSuccessMessage = false
    
    // MARK: - Computed Properties
    
    private var emailError: String? {
        guard !email.isEmpty else { return nil }
        return viewModel.validateEmail(email)
    }
    
    private var passwordErrors: [String] {
        guard !password.isEmpty else { return [] }
        return viewModel.validatePassword(password)
    }
    
    private var confirmPasswordError: String? {
        guard !confirmPassword.isEmpty else { return nil }
        return password != confirmPassword ? "Passwords don't match" : nil
    }
    
    private var isValid: Bool {
        !email.isEmpty &&
        emailError == nil &&
        passwordErrors.isEmpty &&
        !confirmPassword.isEmpty &&
        confirmPasswordError == nil
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
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "")
            }
            .alert("Success!", isPresented: $showSuccessMessage) {
                Button("OK") { dismiss() }
            } message: {
                Text("Account created! Please check your email for verification.")
            }
        }
    }
    
    // MARK: - View Components
    
    private var backgroundView: some View {
        Color(hex: "FAFAFA")
            .ignoresSafeArea()
    }
    
    private var contentView: some View {
   
            VStack(spacing: 32) {
                Spacer()
                titleSection
                inputFieldsSection
                signUpButton
                Spacer()
            }

    }
    

    
    private var titleSection: some View {
        AuthTitleSection(
            title: "Create Account",
            subtitle: "Start your journey with DayFlow"
        )
    }
    
    private var inputFieldsSection: some View {
        VStack(spacing: 18) {
            emailField
            passwordField
            passwordStrengthIndicator
            confirmPasswordField
        }
        .padding(.horizontal, 24)
    }
    
    private var emailField: some View {
        VStack(alignment: .leading, spacing: 8) {
            AuthInputField(
                icon: "envelope.fill",
                iconColor: Color(hex: "A0D6B4"),
                placeholder: "Email",
                text: $email,
                keyboardType: .emailAddress
            )
            
            if let error = emailError {
                ErrorText(error)
            }
        }
    }
    
    private var passwordField: some View {
        VStack(alignment: .leading, spacing: 8) {
            AuthSecureField(
                icon: "lock.fill",
                iconColor: Color(hex: "B8B5FF"),
                placeholder: "Password",
                text: $password,
                showPassword: $showPassword
            )
            
            if !passwordErrors.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(passwordErrors, id: \.self) { error in
                        ErrorText("• \(error)")
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var passwordStrengthIndicator: some View {
        if !password.isEmpty {
            PasswordStrengthView(password: password)
                .padding(.horizontal, 8)
        }
    }
    
    private var confirmPasswordField: some View {
        VStack(alignment: .leading, spacing: 8) {
            AuthSecureField(
                icon: "lock.fill",
                iconColor: Color(hex: "FFB5A0"),
                placeholder: "Confirm Password",
                text: $confirmPassword,
                showPassword: $showConfirmPassword
            )
            
            if let error = confirmPasswordError {
                ErrorText(error)
            }
        }
    }
    
    private var signUpButton: some View {
        AuthGradientButton(
            title: "Create Account",
            isLoading: isLoading,
            gradientColors: [Color(hex: "6B7FFF"), Color(hex: "5A67E8")],
            action: handleSignUp
        )
        .disabled(!isValid || isLoading)
        .opacity(isValid ? 1.0 : 0.5)
        .padding(.horizontal, 24)
    }
    
    // MARK: - Methods
    
    private func handleSignUp() {
        isLoading = true
        
        viewModel.signUp(email: email, password: password) { result in
            isLoading = false
            
            switch result {
            case .success:
                showSuccessMessage = true
            case .failure(let error):
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SignUpView()
        .environmentObject(AuthViewModel())
}
