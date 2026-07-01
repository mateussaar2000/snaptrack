import UIKit

enum ImageResizer {
    static func resize(_ image: UIImage, maxSize: CGFloat = 1536, quality: CGFloat = 0.9) -> Data? {
        let size = image.size
        var newSize = size
        if size.width > size.height && size.width > maxSize {
            newSize.height = size.height * maxSize / size.width
            newSize.width = maxSize
        } else if size.height > maxSize {
            newSize.width = size.width * maxSize / size.height
            newSize.height = maxSize
        }

        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        return resized.jpegData(compressionQuality: quality)
    }
}
