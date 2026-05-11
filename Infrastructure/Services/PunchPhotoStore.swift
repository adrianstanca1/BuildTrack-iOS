import Foundation
import OSLog
#if canImport(UIKit)
import UIKit
#endif
/// Local file storage for PunchItem photos. Each item gets its own folder under
/// `Documents/PunchPhotos/<itemId>/`. Photos are JPEG-encoded at quality 0.85 and
/// downscaled if their longest side exceeds `maxDimension` to keep on-disk size sane.
///
/// Returned URLs are absolute `file://...` URLs so they can be persisted in
/// `PunchItem.photoUrls` alongside any remote (http/https) URLs and rendered by
/// SwiftUI's `AsyncImage` without further translation.
enum PunchPhotoStore {
    static let maxDimension: CGFloat = 2000
    static let jpegQuality: CGFloat = 0.85

    enum StoreError: Error {
        case couldNotEncode
        case couldNotWrite(underlying: Error)
    }

    static func directory(for itemId: UUID) throws -> URL {
        let fm = FileManager.default
        let documents = try fm.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let folder = documents
            .appendingPathComponent("PunchPhotos", isDirectory: true)
            .appendingPathComponent(itemId.uuidString, isDirectory: true)
        if !fm.fileExists(atPath: folder.path) {
            try fm.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder
    }

    /// Removes a photo by URL string. Only deletes when the URL points inside the
    /// app's `Documents/PunchPhotos/` tree — remote URLs are ignored, never throw.
    static func delete(urlString: String) {
        guard let url = URL(string: urlString), url.isFileURL else { return }
        let documentsPath: String? = try? FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        ).path
        guard let documentsPath, url.path.hasPrefix(documentsPath) else { return }
        try? FileManager.default.removeItem(at: url)
    }
}

#if canImport(UIKit)
extension PunchPhotoStore {
    @discardableResult
    static func save(_ image: UIImage, for itemId: UUID) throws -> URL {
        let resized = resize(image, maxDimension: maxDimension)
        guard let data = resized.jpegData(compressionQuality: jpegQuality) else {
            throw StoreError.couldNotEncode
        }
        let folder = try directory(for: itemId)
        let url = folder.appendingPathComponent("\(UUID().uuidString).jpg")
        do {
            try data.write(to: url, options: [.atomic])
        } catch {
            throw StoreError.couldNotWrite(underlying: error)
        }
        return url
    }

    private static func resize(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let longest = max(image.size.width, image.size.height)
        guard longest > maxDimension else { return image }
        let scale = maxDimension / longest
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
#endif
