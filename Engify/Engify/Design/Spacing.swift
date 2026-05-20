import Foundation

/// Systematic spacing scale for consistent UI layout across the entire app.
/// Follows a 4px base unit for harmonious proportions and easier design tuning.
///
/// WHEN IT SHOWS:
/// - Never directly visible to the user; it's a behind-the-scenes layout utility.
/// - Import this struct wherever you need padding, margins, or gaps between elements.
/// - All views in the app use these constants, so changing a value here updates the
///   spacing consistently app-wide.
///
/// HOW IT WORKS:
/// - Each static constant is a CGFloat value in points.
/// - xs = extra small (4pt), sm = small (8pt), md = medium (12pt),
///   lg = large (16pt), xl = extra large (24pt), xxl = double extra large (32pt).
struct Spacing {
    static let xxs: CGFloat = 2
    // Extra small spacing
    static let xs: CGFloat = 4
    
    // Small spacing
    static let sm: CGFloat = 8
    
    // Medium spacing (most common)
    static let md: CGFloat = 12
    
    // Large spacing
    static let lg: CGFloat = 16
    
    // Extra large spacing
    static let xl: CGFloat = 24
    
    // Double extra large spacing
    static let xxl: CGFloat = 32

    static let screenPadding: CGFloat = 20
    static let screenTopPadding: CGFloat = 20
    static let screenBottomInset: CGFloat = 168
    static let sectionGap: CGFloat = 24
    static let cardGap: CGFloat = 20
    static let cardPadding: CGFloat = 20
    static let controlHeight: CGFloat = 56
    static let floatingTabBarBottomPadding: CGFloat = 6
    static let floatingTabBarHeight: CGFloat = 72
}
