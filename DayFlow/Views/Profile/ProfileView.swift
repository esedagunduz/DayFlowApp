import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ProfileViewModel()
    
    @State private var showImagePicker = false
    @State private var showEditName = false
    @State private var showChangePassword = false
    @State private var showDeleteAccount = false
    @State private var showSignOutAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                scrollContent
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .overlay {
                if viewModel.isLoading || viewModel.isUploadingImage {
                    ProfileLoadingOverlay()
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ProfileImagePicker(
                    image: $viewModel.profileImage,
                    onImagePicked: viewModel.uploadProfileImage
                )
            }
            .sheet(isPresented: $showEditName) {
                EditNameView(viewModel: viewModel)
            }
            .sheet(isPresented: $showChangePassword) {
                ChangePasswordView(viewModel: viewModel)
            }
            .alert("Success", isPresented: $viewModel.showSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.successMessage ?? "")
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    authViewModel.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Delete Account", isPresented: $showDeleteAccount) {
                DeleteAccountAlert(
                    viewModel: viewModel,
                    authViewModel: authViewModel
                )
            } message: {
                Text("This action cannot be undone. All your data will be deleted.")
            }
        }
    }
    
    // MARK: - View Builders
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color(hex: "F8F9FA"), Color(hex: "FFFFFF")],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    private var scrollContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                ProfileHeaderView(
                    viewModel: viewModel,
                    onEditImage: { showImagePicker = true },
                    onDeleteImage: viewModel.deleteProfileImage
                )
                userInfoSection
                settingsSection
                dangerZoneSection
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
    }
    
    private var userInfoSection: some View {
        VStack(spacing: 12) {
            ProfileInfoCard(
                icon: "person.fill",
                iconColor: Color(hex: "FFD97D"),
                title: "Display Name",
                value: viewModel.userName.isEmpty ? "Not set yet" : viewModel.userName,
                hasAction: true,
                action: { showEditName = true }
            )
            
            ProfileInfoCard(
                icon: "envelope.fill",
                iconColor: Color(hex: "A8E6CF"),
                title: "Email Address",
                value: viewModel.userEmail,
                hasAction: false
            )
        }
    }
    
    private var settingsSection: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "Settings", color: .primary)
            
            ProfileActionButton(
                icon: "key.fill",
                iconColor: Color(hex: "B4A7D6"),
                title: "Change Password",
                subtitle: "Update your password",
                action: { showChangePassword = true }
            )
        }
    }
    
    private var dangerZoneSection: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "Danger Zone", color: Color(hex: "FF8A9B"))
            
            VStack(spacing: 12) {
                ProfileActionButton(
                    icon: "arrow.right.square.fill",
                    iconColor: Color(hex: "FFB88C"),
                    title: "Sign Out",
                    subtitle: "Sign out from your account",
                    isDanger: true,
                    action: { showSignOutAlert = true }
                )
                
                ProfileActionButton(
                    icon: "trash.fill",
                    iconColor: Color(hex: "FF8A9B"),
                    title: "Delete Account",
                    subtitle: "Permanently delete your account",
                    isDanger: true,
                    action: { showDeleteAccount = true }
                )
            }
        }
    }
}

// MARK: - Section Header

private struct SectionHeader: View {
    let title: String
    let color: Color
    
    var body: some View {
        Text(title)
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .foregroundColor(color)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Delete Account Alert

struct DeleteAccountAlert: View {
    @ObservedObject var viewModel: ProfileViewModel
    @ObservedObject var authViewModel: AuthViewModel
    @State private var password: String = ""
    
    var body: some View {
        VStack {
            SecureField("Enter your password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button("Cancel", role: .cancel) { }
            
            Button("Delete Account", role: .destructive) {
                viewModel.deleteAccount(password: password) { result in
                    if case .success = result {
                        authViewModel.signOut()
                    }
                }
            }
            .disabled(password.isEmpty)
        }
    }
}
