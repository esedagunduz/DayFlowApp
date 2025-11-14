
import SwiftUI

struct EditNameView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ProfileViewModel
    @State private var newName: String = ""
    
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
            .onAppear {
                newName = viewModel.userName
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
        VStack(spacing: 32) {
            headerIcon
            titleSection
            inputField
            saveButton
            Spacer()
        }
    }
    
    private var headerIcon: some View {
        AuthHeaderIcon(
            icon: "person.text.rectangle.fill",
            backgroundColor: Color(hex: "FFD97D")
        )
        .padding(.top, 40)
    }
    
    private var titleSection: some View {
        AuthTitleSection(
            title: "Update Your Name",
            subtitle: "This name will be visible to you"
        )
    }
    
    private var inputField: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Display Name")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            TextField("Enter your name", text: $newName)
                .font(.system(size: 16, weight: .medium))
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
                )
                .textInputAutocapitalization(.words)
        }
        .padding(.horizontal, 24)
    }
    
    private var saveButton: some View {
        AuthGradientButton(
            title: "Save Changes",
            isLoading: false,
            gradientColors: [Color(hex: "FFD97D"), Color(hex: "FFAA5C")],
            action: handleSave
        )
        .disabled(newName.isEmpty)
        .opacity(newName.isEmpty ? 0.5 : 1.0)
        .padding(.horizontal, 24)
    }
    
    private var cancelButton: some View {
        Button("Cancel") { dismiss() }
            .foregroundColor(Color(hex: "FFD97D"))
            .fontWeight(.semibold)
    }
    
    // MARK: - Methods
    
    private func handleSave() {
        viewModel.updateDisplayName(newName)
        dismiss()
    }
}
