import SwiftUI
import VisionKit

/// Document scanner with auto-crop, perspective correction, and multi-page support.
/// Replaces UIImagePickerController for significantly better OCR quality.
struct CameraView: UIViewControllerRepresentable {
    let onCapture: @MainActor (UIImage) -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture)
    }

    final class Coordinator: NSObject, @preconcurrency VNDocumentCameraViewControllerDelegate {
        let onCapture: @MainActor (UIImage) -> Void

        init(onCapture: @escaping @MainActor (UIImage) -> Void) {
            self.onCapture = onCapture
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            guard scan.pageCount > 0 else {
                controller.dismiss(animated: true)
                return
            }
            let image = scan.imageOfPage(at: 0)
            let callback = onCapture
            Task { @MainActor in
                callback(image)
            }
            controller.dismiss(animated: true)
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true)
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: Error
        ) {
            controller.dismiss(animated: true)
        }
    }
}
