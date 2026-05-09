import Foundation
import Supabase
import OSLog

// MARK: - Storage Service

/// Handles photo upload/download via Supabase Storage bucket "photos".
/// This is a basic stub — extend with progress tracking, compression, and caching as needed.
final class StorageService {
    static let shared = StorageService()
    
    private let client: SupabaseClient
    private let bucketName = "photos"
    
    private init() {
        self.client = SupabaseManager.shared.client
    }
    
    /// Uploads photo data to Supabase Storage.
    /// - Parameters:
    ///   - data: The image data (JPEG/PNG).
    ///   - path: The storage path, e.g. "projects/{projectId}/photo.jpg"
    /// - Returns: The public URL string of the uploaded file.
    func uploadPhoto(data: Data, path: String) async throws -> String {
        Logger.network.info("Uploading photo to \(self.bucketName)/\(path)")
        
        try await client.storage
            .from(bucketName)
            .upload(path, data: data)
        
        let publicURL = try client.storage
            .from(bucketName)
            .getPublicURL(path: path)
        
        return publicURL.absoluteString
    }
    
    /// Downloads photo data from Supabase Storage.
    /// - Parameter path: The storage path.
    /// - Returns: Raw image data.
    func downloadPhoto(path: String) async throws -> Data {
        Logger.network.info("Downloading photo from \(self.bucketName)/\(path)")
        
        let data = try await client.storage
            .from(bucketName)
            .download(path: path)
        
        return data
    }
    
    /// Deletes a photo from Supabase Storage.
    /// - Parameter path: The storage path.
    func deletePhoto(path: String) async throws {
        Logger.network.info("Deleting photo at \(self.bucketName)/\(path)")
        
        try await client.storage
            .from(bucketName)
            .remove(paths: [path])
    }
    
    /// Lists photos in a directory.
    /// - Parameter path: Directory prefix, e.g. "projects/{projectId}/"
    /// - Returns: Array of file paths.
    func listPhotos(path: String) async throws -> [String] {
        let files = try await client.storage
            .from(bucketName)
            .list(path: path)
        
        return files.compactMap { $0.name }
    }
}
