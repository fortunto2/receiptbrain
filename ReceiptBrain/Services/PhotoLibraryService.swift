import Photos
import UIKit

/// Saves receipt photos to a dedicated "ReceiptBrain" album in the Photos library.
actor PhotoLibraryService {
    static let shared = PhotoLibraryService()

    private static let albumName = "ReceiptBrain"
    private var cachedAlbum: PHAssetCollection?

    /// Save a photo to the "ReceiptBrain" album. Requests permission if needed.
    func savePhoto(_ image: UIImage) async throws {
        let status = await requestPermissionIfNeeded()
        guard status == .authorized || status == .limited else { return }

        let album = try await getOrCreateAlbum()
        var assetPlaceholder: PHObjectPlaceholder?

        try await PHPhotoLibrary.shared().performChanges {
            let assetRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
            assetPlaceholder = assetRequest.placeholderForCreatedAsset

            guard let albumChangeRequest = PHAssetCollectionChangeRequest(for: album),
                  let placeholder = assetPlaceholder else { return }
            albumChangeRequest.addAssets(NSArray(object: placeholder))
        }
    }

    // MARK: - Private

    private func requestPermissionIfNeeded() async -> PHAuthorizationStatus {
        let current = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        if current == .authorized || current == .limited { return current }
        if current == .notDetermined {
            return await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        }
        return current
    }

    private func getOrCreateAlbum() async throws -> PHAssetCollection {
        if let album = cachedAlbum { return album }

        // Search for existing album
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", Self.albumName)
        let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)

        if let existing = collections.firstObject {
            cachedAlbum = existing
            return existing
        }

        // Create new album
        var placeholder: PHObjectPlaceholder?
        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: Self.albumName)
            placeholder = request.placeholderForCreatedAssetCollection
        }

        guard let localID = placeholder?.localIdentifier,
              let newAlbum = PHAssetCollection.fetchAssetCollections(
                  withLocalIdentifiers: [localID], options: nil
              ).firstObject
        else {
            throw PhotoLibraryError.albumCreationFailed
        }

        cachedAlbum = newAlbum
        return newAlbum
    }

    enum PhotoLibraryError: LocalizedError {
        case albumCreationFailed

        var errorDescription: String? {
            switch self {
            case .albumCreationFailed: "Failed to create ReceiptBrain album"
            }
        }
    }
}
