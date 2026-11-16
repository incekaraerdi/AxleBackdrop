import SwiftUI

enum AppearancePreference: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var scheme: ColorScheme? {
        switch self { case .system: nil; case .light: .light; case .dark: .dark }
    }
}

enum AppColor {
    static let canvas = Color(light: 0xF6F2EB, dark: 0x111315)
    static let surface = Color(light: 0xFFFFFF, dark: 0x1B1E21)
    static let raised = Color(light: 0xFBF8F3, dark: 0x25292D)
    static let primaryText = Color(light: 0x17191C, dark: 0xF5F3EF)
    static let secondaryText = Color(light: 0x5D646B, dark: 0xB7BDC4)
    static let border = Color(light: 0xD9D3CA, dark: 0x3C4248)
    static let accent = Color(light: 0xB83D20, dark: 0xFF7A50)
    static let success = Color(light: 0x16784A, dark: 0x52D49A)
    static let warning = Color(light: 0x8A5600, dark: 0xFFC15A)
    static let error = Color(light: 0xB3261E, dark: 0xFF8178)
    static let photoCanvas = Color(light: 0xE4E5E3, dark: 0x202326)
}

private extension Color {
    init(light: UInt, dark: UInt) {
        self.init(uiColor: UIColor { UIColor(rgb: $0.userInterfaceStyle == .dark ? dark : light) })
    }
}

private extension UIColor {
    convenience init(rgb: UInt) {
        self.init(red: CGFloat((rgb >> 16) & 0xFF) / 255,
                  green: CGFloat((rgb >> 8) & 0xFF) / 255,
                  blue: CGFloat(rgb & 0xFF) / 255, alpha: 1)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 52)
            .foregroundStyle(.white)
            .background(isEnabled ? AppColor.accent : AppColor.border)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .opacity(configuration.isPressed ? 0.82 : 1)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 50)
            .foregroundStyle(AppColor.primaryText)
            .background(AppColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(AppColor.border) }
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.background(AppColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(AppColor.border, lineWidth: 1) }
    }
}

extension View { func appCard() -> some View { modifier(CardModifier()) } }
