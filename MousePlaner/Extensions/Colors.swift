import SwiftUI

// MARK: - Base Colors

extension Color {
    
    static let customBlueLight = Color(red: 0.231, green: 0.420, blue: 0.490)
    static let customBlueMid = Color(red: 0.451, green: 0.678, blue: 0.722)
    
    // фон
    static var adaptiveBackground: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1)
            : UIColor(red: 0.97, green: 0.95, blue: 0.91, alpha: 1)
        })
    }
    
    // карточки
    static var adaptiveCard: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.22, green: 0.22, blue: 0.22, alpha: 1)
            : .white
        })
    }
    
    // фон табов
    static var adaptiveTabBackground: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.28, green: 0.28, blue: 0.28, alpha: 1)
            : UIColor(red: 0.91, green: 0.87, blue: 0.82, alpha: 1)
        })
    }
    
    // выбранный таб
    static var adaptiveSelectedTab: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.35, green: 0.35, blue: 0.35, alpha: 1)
            : UIColor(red: 1, green: 0.96, blue: 0.92, alpha: 1)
        })
    }
}

// MARK: - Gradient

extension LinearGradient {
    
    static var customBlueGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.customBlueLight,
                Color.customBlueMid
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
