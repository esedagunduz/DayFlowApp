//
//  AuthViewModel.swift
//  DayFlow
//
//  Created by ebrar seda gündüz on 13.10.2025.
//

import Foundation
import FirebaseAuth
import Combine
import GoogleSignIn
import FirebaseCore

// MARK: - Custom Error Type
enum AuthError: LocalizedError {
    case message(String)
    
    var errorDescription: String? {
        switch self {
        case .message(let text):
            return text
        }
    }
}

class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var isEmailVerified = false
    
    private var handle: AuthStateDidChangeListenerHandle?
    private var timer: Timer?
    
    init() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
            self?.isAuthenticated = user != nil
            self?.isEmailVerified = user?.isEmailVerified ?? false
        }
    }
    
    deinit {
        handle.map { Auth.auth().removeStateDidChangeListener($0) }
        timer?.invalidate()
    }
    
    // MARK: - Google Sign-In
    
    func signInWithGoogle() {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            print("No Firebase client ID found")
            return
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            print("No root view controller found")
            return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
            if let error = error {
                print("Google Sign-In Error: \(error.localizedDescription)")
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                print("Missing user or ID token")
                return
            }
            
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )
            
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print("Firebase Sign-In Error: \(error.localizedDescription)")
                    return
                }

                print("Successfully signed in with Google")
            }
        }
    }
    
    // MARK: - Validations
    
    func validateEmail(_ email: String) -> String? {
        guard !email.isEmpty else { return nil }
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        return predicate.evaluate(with: email) ? nil : "Invalid email address"
    }
    
    func validatePassword(_ password: String) -> [String] {
        guard !password.isEmpty else { return [] }
        var errors: [String] = []
        
        if password.count < 8 { errors.append("At least 8 characters") }
        if !password.contains(where: { $0.isUppercase }) { errors.append("Uppercase letter") }
        if !password.contains(where: { $0.isLowercase }) { errors.append("Lowercase letter") }
        if !password.contains(where: { $0.isNumber }) { errors.append("Number") }
        if !password.contains(where: { "!@#$%^&*()".contains($0) }) { errors.append("Special character") }
        
        return errors
    }
    
    // MARK: - Email/Password Auth
    
    func signUp(email: String, password: String, completion: @escaping (Result<Void, AuthError>) -> Void) {
        if let error = validateEmail(email) {
            completion(.failure(.message(error)))
            return
        }
        
        let passwordErrors = validatePassword(password)
        if !passwordErrors.isEmpty {
            completion(.failure(.message("Password: " + passwordErrors.joined(separator: ", "))))
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                completion(.failure(.message(self?.errorMessage(error) ?? "Error occurred")))
                return
            }
            
            result?.user.sendEmailVerification { error in
                if error != nil {
                    completion(.failure(.message("Could not send verification email")))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
    
    func signIn(email: String, password: String, completion: @escaping (Result<Void, AuthError>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] _, error in
            if let error = error {
                completion(.failure(.message(self?.errorMessage(error) ?? "Error occurred")))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func sendVerificationEmail(completion: @escaping (Bool) -> Void) {
        Auth.auth().currentUser?.sendEmailVerification { error in
            completion(error == nil)
        }
    }
    
    func checkEmailVerification(completion: @escaping (Bool) -> Void) {
        Auth.auth().currentUser?.reload { [weak self] _ in
            let isVerified = Auth.auth().currentUser?.isEmailVerified ?? false
            self?.isEmailVerified = isVerified
            completion(isVerified)
        }
    }
    
    func startVerificationTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            self?.checkEmailVerification { isVerified in
                if isVerified { self?.timer?.invalidate() }
            }
        }
    }
    
    func resetPassword(email: String, completion: @escaping (Result<Void, AuthError>) -> Void) {
        if let error = validateEmail(email) {
            completion(.failure(.message(error)))
            return
        }
        
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if error != nil {
                completion(.failure(.message("Could not send email")))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func signOut() {
        try? Auth.auth().signOut()
        GIDSignIn.sharedInstance.signOut()
        timer?.invalidate()
    }
    
    // MARK: - Error Handling
    
    private func errorMessage(_ error: Error) -> String {
        let code = (error as NSError).code
        switch code {
        case 17007: return "This email is already in use"
        case 17008: return "Invalid email"
        case 17009: return "Wrong password"
        case 17011: return "User not found"
        case 17026: return "Password is too weak"
        default: return "An error occurred"
        }
    }
}
