import Foundation

struct PhotoReference: Identifiable, Hashable, Sendable {
    let id: UUID
    let thumbnailData: Data
    let widthPx: Int
    let heightPx: Int
    let caption: String?
}
