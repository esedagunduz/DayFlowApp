//
//  EmailVerificationView.swift
//  DayFlow
//
//  Created by ebrar seda gündüz on 13.10.2025.
//

import SwiftUI

struct EmailVerificationView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var isChecking = false
    @State private var canResend = true
    @State private var countdown = 0
    @State private var showMessage = false
    @State private var message = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // MARK: - Background
                LinearGradient(
                    colors: [Color(hex: "F8F9FA"), Color.white],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // MARK: - Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        headerSection
                        titleSection
                        infoSection
                        actionSection
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    AuthCloseButton { viewModel.signOut() }
                }
            }
            .alert("Info", isPresented: $showMessage) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(message)
            }
            .onAppear { startVerificationCheck() }
        }
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        AuthHeaderIcon(
            icon: "envelope.badge.shield.half.filled",
            backgroundColor: Color(hex: "FFD97D")
        )
        .padding(.top, 40)
    }
    
    private var titleSection: some View {
        AuthTitleSection(
            title: "Verify Your Email",
            subtitle: "We’ve sent a verification link to your email address"
        )
    }
    
    private var infoSection: some View {
        VStack(spacing: 16) {
            if let email = viewModel.user?.email {
                Text(email)
                    .font(.headline)
                    .foregroundColor(.black.opacity(0.8))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
            }
            
            Text("Please check your inbox and spam folder to confirm your email.")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
        }
    }
    
    private var actionSection: some View {
        VStack(spacing: 20) {
            AuthGradientButton(
                title: isChecking ? "Checking..." : "Check Verification",
                isLoading: isChecking,
                gradientColors: [Color(hex: "FFD97D"), Color(hex: "FFAA5C")],
                action: checkVerification
            )
            .disabled(isChecking)
            
            Button(action: resendEmail) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text(countdown > 0 ? "Resend (\(countdown)s)" : "Resend Email")
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(canResend ? .accentColor : .gray)
            }
            .disabled(!canResend)
            .opacity(canResend ? 1 : 0.5)
            
            Button("Sign Out") { viewModel.signOut() }
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.red.opacity(0.8))
                .padding(.top, 8)
        }
        .padding(.bottom, 40)
    }
    
    // MARK: - Methods
    
    private func startVerificationCheck() {
        viewModel.startVerificationTimer()
    }
    
    private func checkVerification() {
        isChecking = true
        viewModel.checkEmailVerification { verified in
            isChecking = false
            message = verified
                ? "Your email has been verified successfully!"
                : "Email is not verified yet. Please check again later."
            showMessage = true
        }
    }
    
    private func resendEmail() {
        canResend = false
        countdown = 60
        
        viewModel.sendVerificationEmail { success in
            if success {
                message = "Verification email has been sent again."
                showMessage = true
                startCountdown()
            } else {
                message = "Failed to send email. Please try again."
                showMessage = true
                canResend = true
                countdown = 0
            }
        }
    }
    
    private func startCountdown() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if countdown > 0 {
                countdown -= 1
            } else {
                timer.invalidate()
                canResend = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    EmailVerificationView()
        .environmentObject(AuthViewModel())
}
