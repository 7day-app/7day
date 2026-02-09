import SwiftUI
import UIKit

// MARK: - Colors

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        self.init(
            red: Double((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: Double((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: Double(rgbValue & 0x0000FF) / 255.0
        )
    }
}

enum AppColors {
    // Backgrounds
    static let background = Color(hex: "#F5F5F3")
    static let surface = Color.white
    static let surfaceHover = Color(hex: "#F0F0ED")

    // Text
    static let textPrimary = Color(hex: "#2D2D2D")
    static let textSecondary = Color(hex: "#7A7A7A")
    static let textMuted = Color(hex: "#AAAAAA")

    // Accent
    static let accent = Color(hex: "#34D399")
    static let accentLight = Color(hex: "#86EFAC")
    static let accentDim = Color(hex: "#34D399").opacity(0.10)

    // Semantic — block types
    static let cut = Color(hex: "#F87171")
    static let bulk = Color(hex: "#34D399")
    static let maintain = Color(hex: "#60A5FA")

    // Semantic — deltas
    static let positive = Color(hex: "#22C55E")
    static let negative = Color(hex: "#EF4444")

    // Borders
    static let border = Color(hex: "#E4E4E0")
}

// MARK: - Typography

enum AppFonts {
    static func weightInput() -> Font {
        .system(size: 52, weight: .light, design: .monospaced)
    }

    static func weeklyAverage() -> Font {
        .system(size: 32, weight: .medium, design: .monospaced)
    }

    static func monoBody() -> Font {
        .system(.body, design: .monospaced)
    }

    static func sectionLabel() -> Font {
        .system(size: 11, weight: .semibold, design: .rounded)
    }

    static func body() -> Font {
        .system(.body, design: .rounded)
    }

    static func headline() -> Font {
        .system(.headline, design: .rounded)
    }
}

// MARK: - View Modifiers

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(22)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }
}

struct SectionLabelStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppFonts.sectionLabel())
            .foregroundStyle(AppColors.textMuted)
            .textCase(.uppercase)
            .tracking(0.8)
    }
}

struct KeyboardInputModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button {
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.resignFirstResponder),
                            to: nil, from: nil, for: nil
                        )
                    } label: {
                        Text("Done")
                            .font(.system(.body, design: .rounded, weight: .semibold))
                            .foregroundStyle(AppColors.accent)
                    }
                }
            }
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }

    func sectionLabel() -> some View {
        modifier(SectionLabelStyle())
    }

    func keyboardInput() -> some View {
        modifier(KeyboardInputModifier())
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, design: .rounded, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(AppColors.accent)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(color: AppColors.accent.opacity(0.3), radius: 4, y: 2)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
    }
}

struct OutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, design: .rounded, weight: .medium))
            .foregroundStyle(AppColors.textPrimary)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(AppColors.border, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == OutlineButtonStyle {
    static var outline: OutlineButtonStyle { OutlineButtonStyle() }
}
