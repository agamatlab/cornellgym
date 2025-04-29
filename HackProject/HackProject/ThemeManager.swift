import SwiftUI

// MARK: - Color Theme
struct AppTheme {
    // Main background colors
    let background1: Color
    let background2: Color
    let background3: Color
    
    // Content backgrounds
    let surface1: Color
    let surface2: Color
    let surface3: Color
    
    // Text colors
    let textPrimary: Color
    let textSecondary: Color
    let textMuted: Color
    
    // Accent colors
    let accent1: Color
    let accent2: Color
    
    // Functional colors
    let success: Color
    let warning: Color
    let error: Color
    
    // Additional colors
    let highlight: Color
    let divider: Color
    
    // Muscle group colors
    let chestColor: Color
    let backColor: Color
    let legsColor: Color
    let shouldersColor: Color
    let armsColor: Color
    let coreColor: Color
    let restColor: Color
    
    // Default constructor with Nord color scheme
    static let nord = AppTheme(
        // Main backgrounds
        background1: Color(hex: "2E3440"),
        background2: Color(hex: "242933"),
        background3: Color(hex: "222831"),
        
        // Content backgrounds
        surface1: Color(hex: "3B4252"),
        surface2: Color(hex: "434C5E"),
        surface3: Color(hex: "4C566A"),
        
        // Text colors
        textPrimary: Color(hex: "ECEFF4"),
        textSecondary: Color(hex: "D8DEE9"),
        textMuted: Color(hex: "D8DEE9").opacity(0.7),
        
        // Accent colors
        accent1: Color(hex: "88C0D0"),
        accent2: Color(hex: "81A1C1"),
        
        // Functional colors
        success: Color(hex: "A3BE8C"),
        warning: Color(hex: "EBCB8B"),
        error: Color(hex: "BF616A"),
        
        // Additional colors
        highlight: Color(hex: "5E81AC"),
        divider: Color(hex: "434C5E"),
        
        // Muscle group colors
        chestColor: Color(hex: "A3BE8C"),
        backColor: Color(hex: "EBCB8B"),
        legsColor: Color(hex: "B48EAD"),
        shouldersColor: Color(hex: "88C0D0"),
        armsColor: Color(hex: "BF616A"),
        coreColor: Color(hex: "D08770"),
        restColor: Color(hex: "81A1C1")
    )
    
    // Dark theme with black backgrounds and bright accents
    static let midnight = AppTheme(
        // Main backgrounds - true black and very dark grays
        background1: Color(hex: "000000"),
        background2: Color(hex: "0A0A0A"),
        background3: Color(hex: "121212"),
        
        // Content backgrounds - dark with slight contrast
        surface1: Color(hex: "1A1A1A"),
        surface2: Color(hex: "242424"),
        surface3: Color(hex: "2C2C2C"),
        
        // Text colors - bright white and light gray
        textPrimary: Color(hex: "FFFFFF"),
        textSecondary: Color(hex: "DDDDDD"),
        textMuted: Color(hex: "AAAAAA"),
        
        // Accent colors - vibrant neon blue and cyan
        accent1: Color(hex: "00FFFF"), // Bright cyan
        accent2: Color(hex: "00AAFF"), // Electric blue
        
        // Functional colors - bright and vibrant
        success: Color(hex: "00FF7F"), // Bright spring green
        warning: Color(hex: "FFFF00"), // Bright yellow
        error: Color(hex: "FF3366"),   // Vibrant magenta-red
        
        // Additional colors
        highlight: Color(hex: "FF00FF"), // Bright magenta
        divider: Color(hex: "333333"),   // Dark gray
        
        // Muscle group colors - vibrant neon colors
        chestColor: Color(hex: "00FF7F"),  // Neon green
        backColor: Color(hex: "FFFF00"),   // Neon yellow
        legsColor: Color(hex: "FF77FF"),   // Neon pink
        shouldersColor: Color(hex: "00FFFF"), // Neon cyan
        armsColor: Color(hex: "FF3366"),   // Neon red
        coreColor: Color(hex: "FF9933"),   // Neon orange
        restColor: Color(hex: "7777FF")    // Neon purple-blue
    )
    
    // Classic dark theme
    static let dark = AppTheme(
        // Main backgrounds
        background1: Color(hex: "121212"),
        background2: Color(hex: "1E1E1E"),
        background3: Color(hex: "242424"),
        
        // Content backgrounds
        surface1: Color(hex: "333333"),
        surface2: Color(hex: "424242"),
        surface3: Color(hex: "535353"),
        
        // Text colors
        textPrimary: Color(hex: "FFFFFF"),
        textSecondary: Color(hex: "E0E0E0"),
        textMuted: Color(hex: "BBBBBB"),
        
        // Accent colors
        accent1: Color(hex: "90CAF9"),
        accent2: Color(hex: "64B5F6"),
        
        // Functional colors
        success: Color(hex: "81C784"),
        warning: Color(hex: "FFD54F"),
        error: Color(hex: "E57373"),
        
        // Additional colors
        highlight: Color(hex: "7986CB"),
        divider: Color(hex: "424242"),
        
        // Muscle group colors
        chestColor: Color(hex: "81C784"),
        backColor: Color(hex: "FFD54F"),
        legsColor: Color(hex: "CE93D8"),
        shouldersColor: Color(hex: "90CAF9"),
        armsColor: Color(hex: "E57373"),
        coreColor: Color(hex: "FF8A65"),
        restColor: Color(hex: "78909C")
    )
}

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    @Published var current: AppTheme
    
    init(theme: AppTheme = .midnight) { // Changed default to midnight
        self.current = theme
    }
    
    func switchTheme(to theme: AppTheme) {
        self.current = theme
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
