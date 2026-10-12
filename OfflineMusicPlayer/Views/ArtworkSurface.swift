import SwiftUI
import CoreImage
import ImageIO

/// Tiny, static backgrounds generated once per artwork, never blurred per playback tick.
actor ArtworkSurfaceCache {
    static let shared = ArtworkSurfaceCache()
    private let cache = NSCache<NSString, UIImage>()
    private let context = CIContext(options: [.useSoftwareRenderer: true, .cacheIntermediates: false])
    init() { cache.countLimit = 16; cache.totalCostLimit = 16 * 64 * 64 * 4 }

    func image(at url: URL) -> UIImage? {
        let key = url.path as NSString
        if let image = cache.object(forKey: key) { return image }
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceThumbnailMaxPixelSize: 64,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceShouldCacheImmediately: true
              ] as CFDictionary) else { return nil }
        let input = CIImage(cgImage: thumbnail)
        let extent = input.extent
        let rotated = input.transformed(by: CGAffineTransform(a: -1, b: 0, c: 0, d: -1, tx: extent.width, ty: extent.height))
        let blurred = rotated.clampedToExtent().applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: 12]).cropped(to: extent)
        guard let output = context.createCGImage(blurred, from: extent) else { return nil }
        let result = UIImage(cgImage: output)
        cache.setObject(result, forKey: key, cost: output.width * output.height * 4)
        return result
    }
}

struct ArtworkSurface: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    var artworkURL: URL?
    @State private var image: UIImage?
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(UIColor.systemBackground)
                if !reduceTransparency, let image = image {
                    Image(uiImage: image).resizable().scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height).clipped()
                    Color(UIColor.systemBackground).opacity(scheme == .dark ? 0.72 : 0.70)
                }
            }
        }.ignoresSafeArea().accessibilityHidden(true)
            .task(id: artworkURL) {
                image = nil
                guard !reduceTransparency, let url = artworkURL else { return }
                let rendered = await ArtworkSurfaceCache.shared.image(at: url)
                guard !Task.isCancelled else { return }
                image = rendered
            }
    }
}
