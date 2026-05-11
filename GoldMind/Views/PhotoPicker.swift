import SwiftUI
import PhotosUI
import UIKit

/// SwiftUI wrapper around PHPickerViewController for picking ONE image
/// from the user's library. Returns a downsized + JPEG-compressed Data
/// blob suitable for Supabase Storage upload. Returns nil if the user
/// cancels or picks something unsupported.
///
/// Usage:
///     .sheet(isPresented: $showPicker) {
///         PhotoPicker { data in
///             // upload `data` to Supabase Storage
///         }
///     }
struct PhotoPicker: UIViewControllerRepresentable {
    let onPicked: (Data?) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1
        config.preferredAssetRepresentationMode = .compatible
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onPicked: onPicked) }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onPicked: (Data?) -> Void
        init(onPicked: @escaping (Data?) -> Void) { self.onPicked = onPicked }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else {
                onPicked(nil)
                return
            }
            provider.loadObject(ofClass: UIImage.self) { [weak self] obj, _ in
                guard let img = obj as? UIImage else {
                    DispatchQueue.main.async { self?.onPicked(nil) }
                    return
                }
                let data = Self.normalize(img)
                DispatchQueue.main.async { self?.onPicked(data) }
            }
        }

        /// Resize to max 512×512 (avatar disc is at most 76pt → 228px @3x)
        /// and JPEG compress at 0.8 quality. Keeps uploads small + fast.
        private static func normalize(_ image: UIImage) -> Data? {
            let maxSide: CGFloat = 512
            let size = image.size
            let scale = min(1, maxSide / max(size.width, size.height))
            let target = CGSize(width: size.width * scale, height: size.height * scale)
            let renderer = UIGraphicsImageRenderer(size: target)
            let resized = renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: target))
            }
            return resized.jpegData(compressionQuality: 0.8)
        }
    }
}
