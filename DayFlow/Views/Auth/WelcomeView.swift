//
//  WelcomeView.swift
//  DayFlow
//
//  Created by ebrar seda gündüz on 13.10.2025.
//

import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var showSignIn = false
    @State private var showSignUp = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AnimatedGradientBackground()
                
                VStack(spacing: 0) {
                    Spacer()

                    LogoSection()
                    
                    Spacer()
                    ActionButtonsSection(
                        showSignIn: $showSignIn,
                        showSignUp: $showSignUp
                    )
                }
            }
            .sheet(isPresented: $showSignIn) {
                SignInView()
                    .environmentObject(viewModel)
            }
            .sheet(isPresented: $showSignUp) {
                SignUpView()
                    .environmentObject(viewModel)
            }
        }
    }
}

// MARK: - Logo Section

private struct LogoSection: View {
    @State private var rotateGradient = 0.0
    @State private var shimmerOffset: CGFloat = -200
    
    var body: some View {
        VStack(spacing: 27) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: "6B7FFF").opacity(0.25),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 90
                        )
                    )
                    .frame(width: 180, height: 180)
                    .blur(radius: 25)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "1a1a1a"),
                                Color(hex: "000000")
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 135, height: 135)
                    .shadow(color: .black.opacity(0.4), radius: 25, x: 0, y: 12)

                Text("DayFlow")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .onAppear {
                withAnimation(.linear(duration: 3.5).repeatForever(autoreverses: true)) {
                    shimmerOffset = 350
                }
            }

            Text("Plan, Track, Achieve")
                .font(.system(size: 15, weight: .semibold))
                .tracking(1.3)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(hex: "6B7FFF"),
                            Color(hex: "5A67E8")
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay(
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color.white.opacity(0.6),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 100)
                        .offset(x: shimmerOffset)
                        .blendMode(.overlay)
                )
        }
    }
}

// MARK: - Action Buttons Section

private struct ActionButtonsSection: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @Binding var showSignIn: Bool
    @Binding var showSignUp: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            GoogleSignInButton {
                viewModel.signInWithGoogle()
            }

            DividerWithText(text: "OR")

            EmailSignInButton {
                showSignIn = true
            }

            SignUpLink {
                showSignUp = true
            }
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 60)
    }
}

// MARK: - Google Sign In Button

private struct GoogleSignInButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: "g.circle.fill")
                    .font(.system(size: 22))
                
                Text("Continue with Google")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color(hex: "E8E8E8"), lineWidth: 1.5)
                    )
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            )
        }
    }
}

// MARK: - Divider With Text

private struct DividerWithText: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Rectangle()
                .fill(Color(hex: "E0E0E0"))
                .frame(height: 1)
            
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(hex: "9CA3AF"))
                .tracking(1)
            
            Rectangle()
                .fill(Color(hex: "E0E0E0"))
                .frame(height: 1)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Email Sign In Button

private struct EmailSignInButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: "envelope.fill")
                    .font(.system(size: 20))
                
                Text("Sign In with Email")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "6B7FFF"), Color(hex: "5A67E8")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: Color(hex: "6B7FFF").opacity(0.3), radius: 12, x: 0, y: 4)
            )
        }
    }
}

// MARK: - Sign Up Link

private struct SignUpLink: View {
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Text("Don't have an account?")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(hex: "6C7278"))
            
            Button(action: action) {
                Text("Sign Up")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: "6B7FFF"))
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - Animated Gradient Background

struct AnimatedGradientBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        LinearGradient(
            colors: [
                Color(hex: "FAFAFA"),
                Color(hex: "FFFFFF"),
                Color(hex: "F8F9FA")
            ],
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    WelcomeView()
        .environmentObject(AuthViewModel())
}
