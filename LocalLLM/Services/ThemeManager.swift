import SwiftUI
import Combine

/// Manages app-wide theme settings (appearance mode and accent color).
@MainActor
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @AppStorage("appTheme") var appTheme: AppTheme = .system
    @AppStorage("accentColorName") var accentColorName: String = "purple"

    var accentColor: Color {
        AccentColorOption.from(name: accentColorName).color
    }

    var colorScheme: ColorScheme? {
        switch appTheme {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

enum AppTheme: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

enum AccentColorOption: String, CaseIterable, Identifiable {
    case purple = "Purple"
    case blue = "Blue"
    case green = "Green"
    case orange = "Orange"
    case red = "Red"
    case pink = "Pink"
    case teal = "Teal"
    case indigo = "Indigo"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .purple: return .purple
        case .blue: return .blue
        case .green: return .green
        case .orange: return .orange
        case .red: return .red
        case .pink: return .pink
        case .teal: return .teal
        case .indigo: return .indigo
        }
    }

    static func from(name: String) -> AccentColorOption {
        AccentColorOption(rawValue: name) ?? .purple
    }
}
