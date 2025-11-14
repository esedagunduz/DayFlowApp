import SwiftUI
import PhotosUI

// MARK: - Profile Header View

struct ProfileHeaderView: View {
    @ObservedObject var viewModel: ProfileViewModel
    let onEditImage: () -> Void
    let onDeleteImage: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            profileImageWithButton
            userNameSection
            if viewModel.profileImageURL != nil {
                removePhotoButton
            }
        }
        .padding(.top, 20)
    }
    
    private var profileImageWithButton: some View {
        ZStack(alignment: .bottomTrailing) {
            ProfileImageCircle(
                imageURL: viewModel.profileImageURL,
                localImage: viewModel.profileImage
            )
            CameraButton(action: onEditImage)
        }
    }
    
    private var userNameSection: some View {
        VStack(spacing: 6) {
            Text(viewModel.userName.isEmpty ? "Set Your Name" : viewModel.userName)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text(viewModel.userEmail)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
    
    private var removePhotoButton: some View {
        Button(action: onDeleteImage) {
            Text("Remove Photo")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: "FF8A9B"))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color(hex: "FF8A9B").opacity(0.15)))
        }
    }
}

// MARK: - Profile Image Circle

private struct ProfileImageCircle: View {
    let imageURL: URL?
    let localImage: UIImage?
    
    var body: some View {
        ZStack {
            gradientBorder
            imageContent
        }
    }
    
    private var gradientBorder: some View {
        Circle()
            .fill(
                AngularGradient(
                    colors: [
                        Color(hex: "FFD97D"),
                        Color(hex: "FFAA5C"),
                        Color(hex: "FF8A9B"),
                        Color(hex: "FFD97D")
                    ],
                    center: .center
                )
            )
            .frame(width: 130, height: 130)
    }
    
    @ViewBuilder
    private var imageContent: some View {
        if let imageURL = imageURL {
            AsyncImage(url: imageURL) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                ProgressView()
            }
            .frame(width: 120, height: 120)
            .clipShape(Circle())
        } else if let image = localImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 120, height: 120)
                .clipShape(Circle())
        } else {
            placeholderImage
        }
    }
    
    private var placeholderImage: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "FFD97D").opacity(0.2))
                .frame(width: 120, height: 120)
            
            Image(systemName: "person.fill")
                .font(.system(size: 48))
                .foregroundColor(Color(hex: "FFD97D"))
        }
    }
}

// MARK: - Camera Button

private struct CameraButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 40, height: 40)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                
                Image(systemName: "camera.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "FFD97D"))
            }
        }
    }
}

// MARK: - Profile Info Card

struct ProfileInfoCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let hasAction: Bool
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button(action: { action?() }) {
            HStack(spacing: 16) {
                IconContainer(icon: icon, color: iconColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    Text(value)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                if hasAction {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(CardBackground())
        }
        .disabled(!hasAction)
        .buttonStyle(ProfileButtonStyle())
    }
}

// MARK: - Profile Action Button

struct ProfileActionButton: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    var isDanger: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                IconContainer(icon: icon, color: iconColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(CardBackground(isDanger: isDanger, dangerColor: iconColor))
        }
        .buttonStyle(ProfileButtonStyle())
    }
}

// MARK: - Icon Container (Reusable)

private struct IconContainer: View {
    let icon: String
    let color: Color
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(color.opacity(0.15))
                .frame(width: 50, height: 50)
            
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)
        }
    }
}

// MARK: - Card Background (Reusable)

private struct CardBackground: View {
    var isDanger: Bool = false
    var dangerColor: Color = .clear
    
    var body: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color.white)
            .shadow(
                color: isDanger ? dangerColor.opacity(0.15) : .black.opacity(0.04),
                radius: 12,
                x: 0,
                y: 6
            )
    }
}

// MARK: - Profile Loading Overlay

struct ProfileLoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.2)
                
                Text("Loading...")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.black.opacity(0.8))
            )
        }
    }
}

// MARK: - Profile Image Picker

struct ProfileImagePicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    @Binding var image: UIImage?
    let onImagePicked: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ProfileImagePicker
        
        init(_ parent: ProfileImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { return }
            
            provider.loadObject(ofClass: UIImage.self) { image, _ in
                guard let image = image as? UIImage else { return }
                
                DispatchQueue.main.async {
                    self.parent.image = image
                    self.parent.onImagePicked(image)
                }
            }
        }
    }
}

// MARK: - Profile Button Style 

struct ProfileButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
