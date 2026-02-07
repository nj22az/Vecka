//
//  ContactImagePicker.swift
//  Vecka
//
//  Native iOS photo picker with built-in crop/scale
//  Uses UIImagePickerController like iOS Contacts
//

import SwiftUI
import PhotosUI
import UIKit

struct ContactImagePicker: View {
    @Environment(\.dismiss) private var dismiss

    let onImageSelected: (Data?) -> Void

    @State private var showingImagePicker = false
    @State private var showingActionSheet = false

    var body: some View {
        // Show immediately on appear
        Color.clear
            .onAppear {
                showingActionSheet = true
            }
            .confirmationDialog("Add Photo", isPresented: $showingActionSheet) {
                Button("Choose Photo") {
                    showingImagePicker = true
                }
                Button("Cancel", role: .cancel) {
                    onImageSelected(nil)
                    dismiss()
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ContactPhotoPicker(onImageSelected: { imageData in
                    onImageSelected(imageData)
                    dismiss()
                }, onCancel: {
                    onImageSelected(nil)
                    dismiss()
                })
                .ignoresSafeArea()
            }
    }
}

// MARK: - UIImagePickerController Wrapper

struct ContactPhotoPicker: UIViewControllerRepresentable {
    let onImageSelected: (Data?) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true  // This enables the native iOS crop/zoom interface!
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImageSelected: onImageSelected, onCancel: onCancel)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImageSelected: (Data?) -> Void
        let onCancel: () -> Void

        init(onImageSelected: @escaping (Data?) -> Void, onCancel: @escaping () -> Void) {
            self.onImageSelected = onImageSelected
            self.onCancel = onCancel
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            // Get the edited image (cropped/scaled by user)
            if let editedImage = info[.editedImage] as? UIImage {
                // Convert to circular crop
                let circularImage = makeCircular(image: editedImage)
                let imageData = circularImage.jpegData(compressionQuality: 0.85)
                onImageSelected(imageData)
            } else if let originalImage = info[.originalImage] as? UIImage {
                // Fallback to original if editing disabled
                let circularImage = makeCircular(image: originalImage)
                let imageData = circularImage.jpegData(compressionQuality: 0.85)
                onImageSelected(imageData)
            } else {
                onImageSelected(nil)
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCancel()
        }

        private func makeCircular(image: UIImage) -> UIImage {
            let size = CGSize(width: 300, height: 300)

            // Normalize orientation first so cgImage coordinates match
            let normalized: UIImage
            if image.imageOrientation != .up {
                let renderer = UIGraphicsImageRenderer(size: image.size)
                normalized = renderer.image { _ in image.draw(at: .zero) }
            } else {
                normalized = image
            }

            // Center-crop to square
            let squareSize = min(normalized.size.width, normalized.size.height)
            let cropRect = CGRect(
                x: (normalized.size.width - squareSize) / 2,
                y: (normalized.size.height - squareSize) / 2,
                width: squareSize,
                height: squareSize
            )

            guard let croppedCGImage = normalized.cgImage?.cropping(to: cropRect) else {
                return image
            }

            let croppedImage = UIImage(cgImage: croppedCGImage)

            // Render as circular
            let renderer = UIGraphicsImageRenderer(size: size)
            return renderer.image { _ in
                let circlePath = UIBezierPath(ovalIn: CGRect(origin: .zero, size: size))
                circlePath.addClip()
                croppedImage.draw(in: CGRect(origin: .zero, size: size))
            }
        }
    }
}
