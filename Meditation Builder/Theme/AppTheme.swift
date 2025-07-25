//
//  AppTheme.swift
//  Meditation Builder
//
//  Created by harsh  on 09/07/25.
//

import SwiftUI

// MARK: - App Theme
struct AppTheme {
    // MARK: - Colors
    static let backgroundColor = Color(red: 20/255, green: 21/255, blue: 24/255) // #141518
	static let cardColor = Color(red: 26/255, green: 27/255, blue: 29/255) // #222326
//	static let cardColor = Color(red: 30/255, green: 32/255, blue: 32/255) // #
	static let searchBar = Color(red: 35/255, green: 37/255, blue: 40/255) //232528
	static let tabBar = Color(red: 35/255, green: 36/255, blue: 39/255) //232427

//	static let accentColor = Color(red: 221/255, green: 97/255, blue: 27/255) // #dd611b (orange)
	static let accentColor = Color(red: 77/255, green: 181/255, blue: 172/255) // #4DB6AC (Teal)
    static let lightGrey = Color(red: 119/255, green: 119/255, blue: 129/255) // #777781
    
    // MARK: - Typography
//    struct Typography {
//        static let titleFont = Font.system(size: 32, weight: .bold, design: .rounded)
//		static let headlineFontLarge = Font.system(size: 28, weight: .bold, design: .rounded)
//        static let headlineFont = Font.system(size: 17, weight: .bold, design: .rounded)
//        static let bodyFont = Font.system(size: 15, weight: .regular, design: .rounded)
//        static let buttonFont = Font.system(size: 20, weight: .bold, design: .rounded)
//        static let captionFont = Font.system(size: 19, weight: .semibold, design: .rounded)
//    }
	
	struct Typography {
			// Big, bold serif for main titles
		static let titleFont          = Font.system(size: 25, weight: .thin,   design: .serif)
		
			// Medium-weight serif for large headlines
		static let headlineFontLarge  = Font.system(size: 18, weight: .medium, design: .serif)
		
			// Regular serif for section headers
		static let headlineFont       = Font.system(size: 15, weight: .light, design: .serif)
		
			// Clean, readable sans-serif for body text
		static let bodyFont           = Font.system(size: 16, weight: .regular, design: .default)
		
			// Slightly smaller, semibold sans-serif for tappable buttons
		static let buttonFont         = Font.system(size: 16, weight: .semibold, design: .default)
		
			// Light, compact sans-serif for captions & metadata
		static let captionFont        = Font.system(size: 14, weight: .light,   design: .default)
	}
    
    // MARK: - Spacing
    struct Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 20
        static let extraLarge: CGFloat = 24
        static let section: CGFloat = 32
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 12
        static let medium: CGFloat = 14
        static let large: CGFloat = 16
        static let button: CGFloat = 24
		static let extraLarge: CGFloat = 32
    }
    
    // MARK: - Shadows
    struct Shadows {
        static let card = Color.black.opacity(0.18)
        static let button = Color.black.opacity(0.1)
    }
    
    // MARK: - Opacity
    struct Opacity {
        static let disabled: Double = 0.7
        static let overlay: Double = 0.08
        static let border: Double = 0.07
        static let timeline: Double = 0.25
    }
} 
