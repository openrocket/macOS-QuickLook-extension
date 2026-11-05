//
//  ThumbnailProvider.swift
//  OpenRocket QL Thumbnail
//

import AppKit
import QuickLookThumbnailing
import ZIPFoundation

/// Provides the Finder icon for .ork files.
///
/// .ork files are ZIP archives. OpenRocket stores a small, simplified rendering of the rocket for icons as
/// thumbnail.png, next to the larger preview.png used by the Quick Look preview. Files saved by older versions of
/// OpenRocket only contain preview.png, so that is used when there is no thumbnail.
final class ThumbnailProvider: QLThumbnailProvider {

    private static let imageEntries = ["thumbnail.png", "preview.png"]

    override func provideThumbnail(for request: QLFileThumbnailRequest,
                                   _ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {
        do {
            guard let data = try Self.loadImageData(fromORK: request.fileURL),
                  let image = NSImage(data: data),
                  image.size.width > 0, image.size.height > 0 else {
                // No image in the file: let Finder show the default document icon.
                handler(nil, nil)
                return
            }

            let contextSize = Self.aspectFit(image.size, in: request.maximumSize)
            let reply = QLThumbnailReply(contextSize: contextSize) { () -> Bool in
                image.draw(in: CGRect(origin: .zero, size: contextSize))
                return true
            }
            handler(reply, nil)
        } catch {
            handler(nil, error)
        }
    }

    /// Returns the data of the first image in `imageEntries` that is present in the archive, or nil if none is.
    private static func loadImageData(fromORK url: URL) throws -> Data? {
        let archive = try Archive(url: url, accessMode: .read)
        for name in imageEntries {
            if let entry = archive[name] {
                var data = Data()
                _ = try archive.extract(entry, skipCRC32: true) { data.append($0) }
                return data
            }
        }
        return nil
    }

    /// Largest size with the aspect ratio of `size` that fits in `bounds`.
    private static func aspectFit(_ size: CGSize, in bounds: CGSize) -> CGSize {
        let scale = min(bounds.width / size.width, bounds.height / size.height)
        return CGSize(width: size.width * scale, height: size.height * scale)
    }
}
