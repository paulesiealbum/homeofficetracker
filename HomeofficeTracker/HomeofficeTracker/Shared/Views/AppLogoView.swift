import SwiftUI

struct AppLogoView: View {
    var size: CGFloat = 72

    var body: some View {
        Group {
            if let icon = appIcon {
                Image(uiImage: icon)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.22))
            } else {
                // Fallback: generisches Haus-Icon falls App-Icon nicht geladen werden kann
                ZStack {
                    RoundedRectangle(cornerRadius: size * 0.22)
                        .fill(LinearGradient(
                            colors: [.green, .green.opacity(0.7)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .frame(width: size, height: size)
                    Image(systemName: "house.fill")
                        .font(.system(size: size * 0.44, weight: .medium))
                        .foregroundStyle(.white)
                }
            }
        }
    }

    /// Lädt das App-Icon aus dem Bundle (funktioniert im Simulator und auf dem Gerät).
    private var appIcon: UIImage? {
        guard
            let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
            let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
            let files = primary["CFBundleIconFiles"] as? [String],
            let name = files.last
        else { return nil }
        return UIImage(named: name)
    }
}
