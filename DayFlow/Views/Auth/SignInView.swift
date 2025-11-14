//
//  SignInView.swift
//  DayFlow
//
//  Created by ebrar seda gündüz on 13.10.2025.
//

import SwiftUI

struct SignInView: View {
    // MARK: - Properties
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: AuthViewModel
    
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showForgotPassword = false
    
    // MARK: - Computed Properties
    
    private var emailError: String? {
        guard !email.isEmpty else { return nil }
        return viewModel.validateEmail(email)
    }
    
    private var isValid: Bool {
        !email.isEmpty &&
        emailError == nil &&
        !password.isEmpty
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
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView()
                    .environmentObject(viewModel)
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
                forgotPasswordButton
                signInButton
                Spacer()
            }
            


    }


    
    private var titleSection: some View {
        AuthTitleSection(
            title: "Welcome Back!",
            subtitle: "Sign in to continue"
        )
    }
    
    private var inputFieldsSection: some View {
        VStack(spacing: 18) {
            emailField
            passwordField
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
        AuthSecureField(
            icon: "lock.fill",
            iconColor: Color(hex: "B8B5FF"),
            placeholder: "Password",
            text: $password,
            showPassword: $showPassword
        )
    }
    
    private var forgotPasswordButton: some View {
        Button {
            showForgotPassword = true
        } label: {
            Text("Forgot Password?")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(hex: "6B7FFF"))
        }
    }
    
    private var signInButton: some View {
        AuthGradientButton(
            title: "Sign In",
            isLoading: isLoading,
            gradientColors: [Color(hex: "6B7FFF"), Color(hex: "5A67E8")],
            action: handleSignIn
        )
        .disabled(!isValid || isLoading)
        .opacity(isValid ? 1.0 : 0.5)
        .padding(.horizontal, 24)
    }
    
    // MARK: - Methods
    
    private func handleSignIn() {
        isLoading = true
        
        viewModel.signIn(email: email, password: password) { result in
            isLoading = false
            
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

// MARK: - Preview

#Preview {
    SignInView()
        .environmentObject(AuthViewModel())
}
