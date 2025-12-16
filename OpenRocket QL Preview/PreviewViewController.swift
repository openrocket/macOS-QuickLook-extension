//
//  PreviewViewController.swift
//  OpenRocket QL Preview
//
//  Created by David Hoerl on 11/2/25.
//

import Cocoa
import Quartz
import ZIPFoundation

private final class ORImageView: NSImageView {
    override var intrinsicContentSize: NSSize {
        return NSSize.zero
    }
}

final class PreviewViewController: NSViewController, QLPreviewingController {

    override var nibName: NSNib.Name? {
        return NSNib.Name("PreviewViewController")
    }

    override func loadView() {
        super.loadView()

    }

    override func viewDidLayout() {
        super.view.layout()

        //print("View size: \(view.bounds.size) ratio: \(view.bounds.width / view.bounds.height)")
    }
    /*
    func preparePreviewOfSearchableItem(identifier: String, queryString: String?) async throws {
         Implement this method and set QLSupportsSearchableItems to YES in the Info.plist of the extension if you support CoreSpotlight.

         Perform any setup necessary in order to prepare the view.
         Quick Look will display a loading spinner until this returns.
    }
    */

    func preparePreviewOfFile(at archiveURL: URL) async throws {
        do {
            let archive = try Archive(url: archiveURL, accessMode: .read)
            guard let entry = archive["preview.png"] else {
                //print("DAMN - no preview file")
                return
            }

            var imageData = Data()
            _ = try archive.extract(entry, skipCRC32: true, consumer: { (data) in
                //print("Chunk Size: \(data.count)")
                imageData.append(data)
            })
            //print("Size = \(imageData.count)")
            if !imageData.isEmpty, let image = NSImage(data: imageData) {
                //print("Loaded image. Size=\(image.size)")

                let nsImageView: ORImageView = .init()
                nsImageView.translatesAutoresizingMaskIntoConstraints = false
                nsImageView.imageScaling = .scaleProportionallyDown
                nsImageView.image = image
                view.addSubview(nsImageView)

                let edges: [NSLayoutConstraint.Attribute] = [.top, .bottom, .right, .left]
                for edge in edges {
                    _ = NSLayoutConstraint(item: nsImageView, attribute: edge, relatedBy: .equal, toItem: view, attribute: edge, multiplier: 1, constant: 0).isActive = true
                }
            } else {
                print("No image")
            }
        } catch {
            print("CANNOT DO ARCHIVE DIR \(error)")
            return
        }
    }

}
