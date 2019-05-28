import Foundation

/**
 Search/Trending endpoint parameters.
 - parameters:
 - type: The type(s) of *Media* to be returned (comma separated).
 - stereoscopicType: Search only for *Media* with a particular stereoscopic type.
 - category: Search only for *Media* with a particular category.
 - size: The number of results to return per-page, from 1 to 100.
 - minimumWidth: The minimum width for video and photo Media, in pixels.
 - isFaceFilter: Search only for face filters.
 - hasBlendShapes: Search only for Media that has blend shapes.
 - requiresBlendShapes: Search only for Media that requires blend shapes.
 - pageNum: Pagination control to fetch the next page of results, if applicable.
 */
public struct SvrfOptions {
    public init(type: [SvrfMediaType]? = nil,
                stereoscopicType: SvrfStereoscopicType? = nil,
                category: SvrfCategory? = nil,
                size: Int? = nil,
                minimumWidth: Int? = nil,
                isFaceFilter: Bool? = nil,
                hasBlendShapes: Bool? = nil,
                requiresBlendShapes: Bool? = nil,
                pageNum: Int? = nil) {
        self.type = type
        self.stereoscopicType = stereoscopicType
        self.category = category
        self.size = size
        self.minimumWidth = minimumWidth
        self.isFaceFilter = isFaceFilter
        self.hasBlendShapes = hasBlendShapes
        self.requiresBlendShapes = requiresBlendShapes
        self.pageNum = pageNum
    }

    let type: [SvrfMediaType]?
    let stereoscopicType: SvrfStereoscopicType?
    let category: SvrfCategory?
    let size: Int?
    let minimumWidth: Int?
    let isFaceFilter: Bool?
    let hasBlendShapes: Bool?
    let requiresBlendShapes: Bool?
    let pageNum: Int?
}
