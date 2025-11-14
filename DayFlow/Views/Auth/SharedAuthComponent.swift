//
//  SharedAuthComponents.swift
//  DayFlow
//
//  Shared Components for Auth & Profile
//  Created by ebrar seda gündüz on 13.10.2025.
//

import SwiftUI

// MARK: - Header Icon Component

struct AuthHeaderIcon: View {
    let icon: String
    let backgroundColor: Color
    
    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor.opacity(0.15))
                .frame(width: 100, height: 100)
            
            Image(systemName: icon)
                .font(.system(size: 40, weight: .medium))
                .foregroundColor(backgroundColor)
        }
    }
}

// MARK: - Title Section Component

struct AuthTitleSection: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundColor(.black)
            
            Text(subtitle)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "6C7278"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
    }
}

// MARK: - Auth Input Field

struct AuthInputField: View {
    let icon: String
    let iconColor: Color
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            TextField(placeholder, text: $text)
                .font(.system(size: 16, weight: .medium))
                .keyboardType(keyboardType)
                .autocapitalization(.none)
                .autocorrectionDisabled()
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color(hex: "E8E8E8"), lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.03), radius: 6, x: 0, y: 2)
        )
    }
}

// MARK: - Auth Secure Field

struct AuthSecureField: View {
    let icon: String
    let iconColor: Color
    let placeholder: String
    @Binding var text: String
    @Binding var showPassword: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            Group {
                if showPassword {
                    TextField(placeholder, text: $text)
                        .font(.system(size: 16, weight: .medium))
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                } else {
                    SecureField(placeholder, text: $text)
                        .font(.system(size: 16, weight: .medium))
                }
            }
            
            Button(action: { showPassword.toggle() }) {
                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "9CA3AF"))
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color(hex: "E8E8E8"), lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.03), radius: 6, x: 0, y: 2)
        )
    }
}

// MARK: - Gradient Action Button

struct AuthGradientButton: View {
    let title: String
    let isLoading: Bool
    let gradientColors: [Color]
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: gradientColors.first?.opacity(0.3) ?? .clear, radius: 12, x: 0, y: 4)
            )
        }
    }
}

// MARK: - Close Button

struct AuthCloseButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(Color(hex: "9CA3AF"))
        }
    }
}

// MARK: - Info Message View

struct AuthInfoMessage: View {
    let icon: String
    let message: String
    let backgroundColor: Color
    let foregroundColor: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(foregroundColor)
            
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(foregroundColor)
                .multilineTextAlignment(.leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(backgroundColor)
        )
    }
}

// MARK: - Error Text (Auth & Profile için)

struct ErrorText: View {
    let message: String
    
    init(_ message: String) {
        self.message = message
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 12))
            
            Text(message)
                .font(.system(size: 13, weight: .medium))
        }
        .foregroundColor(Color(hex: "FF6B7A"))
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Password Strength View (Auth & Profile için)

struct PasswordStrengthView: View {
    let password: String
    
    private var strength: Int {
        var score = 0
        if password.count >= 8 { score += 1 }
        if password.contains(where: { $0.isUppercase }) { score += 1 }
        if password.contains(where: { $0.isLowercase }) { score += 1 }
        if password.contains(where: { $0.isNumber }) { score += 1 }
        if password.contains(where: { "!@#$%^&*()".contains($0) }) { score += 1 }
        return score
    }
    
    private var strengthText: String {
        switch strength {
        case 0...1: return "Very Weak"
        case 2: return "Weak"
        case 3: return "Medium"
        case 4: return "Strong"
        case 5: return "Very Strong"
        default: return ""
        }
    }
    
    private var strengthColor: Color {
        switch strength {
        case 0...1: return Color(hex: "FF6B7A")
        case 2: return Color(hex: "FFB5A0")
        case 3: return Color(hex: "FFC785")
        case 4: return Color(hex: "A0D6B4")
        case 5: return Color(hex: "A0D6B4")
        default: return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                ForEach(0..<5) { index in
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(index < strength ? strengthColor : Color(hex: "E8E8E8"))
                        .frame(height: 6)
                }
            }
            
            Text(strengthText)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(strengthColor)
        }
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(hex: "E9EDC9"))
            .cornerRadius(10)
            .foregroundColor(.black)
    }
}
