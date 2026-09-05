import SwiftUI

// ============================================================================
// MilliScreens v3 — pixel-faithful SwiftUI implementation of Ian's 35 approved
// reference views (Aug 31, 2026). References are the single source of truth:
// layouts, copy, figures and states below are transcribed 1:1 from them.
// ============================================================================

// MARK: - Design tokens (from approved references)

enum MilliTheme {
    static let background     = Color(hex: 0x05090D)   // obsidian / near-black navy
    static let surface        = Color(hex: 0x0E1114)   // carbon panel
    static let card           = Color(hex: 0x10161B)   // dark card fill
    static let navChrome      = Color(hex: 0x141414)
    static let accent         = Color(hex: 0x00D9FF)   // electric cyan
    static let accentDeep     = Color(hex: 0x008BC5)
    static let green          = Color(hex: 0x22DB83)
    static let red            = Color(hex: 0xFF5661)
    static let gold           = Color(hex: 0xF4B73B)
    static let textPrimary    = Color.white
    static let textSecondary  = Color(hex: 0x9AA3AD)
    static let textTertiary   = Color(hex: 0x5E6870)
    static let chromeLight    = Color(hex: 0xE8E8EC)
    static let chromeMid      = Color(hex: 0x9A9AA2)
    static let chromeDark     = Color(hex: 0x6E6E76)

    static let screenPadding: CGFloat = 16
    static let cardRadius: CGFloat = 14
    static let navHeight: CGFloat = 88
}

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB,
                  red:   Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8)  & 0xFF) / 255,
                  blue:  Double( hex        & 0xFF) / 255)
    }
}

// MARK: - Shared brand components

/// Metallic MILLI wordmark + tagline, as on every reference header.
struct MilliLogoHeader: View {
    var compact = false
    var body: some View {
        VStack(spacing: 3) {
            Text("MILLI")
                .font(.custom("Sora-Bold", size: compact ? 20 : 26))
                .kerning(6)
                .foregroundStyle(LinearGradient(colors: [MilliTheme.chromeLight, MilliTheme.chromeMid, MilliTheme.chromeDark],
                                               startPoint: .top, endPoint: .bottom))
            Text("Money, Made Intelligent.")
                .font(.system(size: 9, weight: .medium))
                .kerning(2)
                .foregroundColor(MilliTheme.textTertiary)
        }
    }
}

/// Small screen-title bar: M logo left, centered title, trailing icon.
struct ScreenTitleBar: View {
    let title: String
    var trailing: String = "bell"
    var showTrailing = true
    var body: some View {
        HStack {
            MilliMark(size: 22)
            Spacer()
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(MilliTheme.textPrimary)
            Spacer()
            if showTrailing {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: trailing)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(MilliTheme.textSecondary)
                    Circle().fill(MilliTheme.accent).frame(width: 5, height: 5).offset(x: 3, y: -2)
                }
            } else { Color.clear.frame(width: 16) }
        }
        .padding(.horizontal, MilliTheme.screenPadding)
        .padding(.vertical, 8)
    }
}

/// Chrome "M" mark used in headers.
struct MilliMark: View {
    var size: CGFloat = 24
    var body: some View {
        Text("M")
            .font(.custom("Sora-Bold", size: size))
            .foregroundStyle(LinearGradient(colors: [MilliTheme.chromeLight, MilliTheme.chromeDark],
                                            startPoint: .top, endPoint: .bottom))
    }
}

/// Milli AI speech callout card shown beside the mascot on reference headers.
struct MilliAICallout: View {
    let message: String
    var body: some View {
        HStack(spacing: 10) {
            MilliAICharacterView(size: 44)
            VStack(alignment: .leading, spacing: 3) {
                Text("Milli AI")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(MilliTheme.accent)
                Text(message)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(MilliTheme.textSecondary)
                    .lineLimit(3)
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12).fill(MilliTheme.surface)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.10), lineWidth: 0.5)))
    }
}

/// MILLI AI canonical character (glossy black faceplate, cyan oval eyes, chest M).
struct MilliAICharacterView: View {
    var size: CGFloat = 120
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.30)
                .fill(LinearGradient(colors: [Color(hex: 0x1C1C22), Color(hex: 0x0B0B10)],
                                     startPoint: .top, endPoint: .bottom))
                .overlay(RoundedRectangle(cornerRadius: size * 0.30)
                    .stroke(LinearGradient(colors: [MilliTheme.chromeLight, MilliTheme.chromeDark],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: size * 0.025))
                .frame(width: size, height: size * 0.78)
            HStack(spacing: size * 0.18) {
                Capsule().fill(MilliTheme.accent)
                    .frame(width: size * 0.14, height: size * 0.20)
                    .shadow(color: MilliTheme.accent.opacity(0.8), radius: size * 0.05)
                Capsule().fill(MilliTheme.accent)
                    .frame(width: size * 0.14, height: size * 0.20)
                    .shadow(color: MilliTheme.accent.opacity(0.8), radius: size * 0.05)
            }
            .offset(y: -size * 0.06)
            Text("M")
                .font(.custom("Sora-Bold", size: size * 0.16))
                .foregroundStyle(LinearGradient(colors: [Color(hex: 0xF5F5F7), Color(hex: 0x8A8A92)],
                                                startPoint: .top, endPoint: .bottom))
                .offset(y: size * 0.22)
        }
        .frame(width: size, height: size)
    }
}

/// Standard dark rounded card.
struct MilliCard<Content: View>: View {
    var glow = false
    @ViewBuilder let content: Content
    var body: some View {
        content
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: MilliTheme.cardRadius)
                    .fill(MilliTheme.card)
                    .overlay(RoundedRectangle(cornerRadius: MilliTheme.cardRadius)
                        .stroke(glow ? MilliTheme.accent.opacity(0.7) : Color.white.opacity(0.08),
                                lineWidth: glow ? 1.2 : 0.5))
            )
    }
}

/// Uppercase cyan section label.
struct SectionLabel: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .tracking(1.5)
            .foregroundColor(MilliTheme.accent)
    }
}

/// Primary cyan gradient action button.
struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    var body: some View {
        HStack(spacing: 8) {
            if let icon { Image(systemName: icon).font(.system(size: 14, weight: .semibold)) }
            Text(title).font(.system(size: 15, weight: .semibold))
        }
        .foregroundColor(Color(hex: 0x04121A))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(LinearGradient(colors: [MilliTheme.accent, MilliTheme.accentDeep],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: MilliTheme.accent.opacity(0.45), radius: 12)
        )
    }
}

/// Outlined secondary button.
struct OutlineButton: View {
    let title: String
    var icon: String? = nil
    var tint: Color = MilliTheme.textPrimary
    var body: some View {
        HStack(spacing: 6) {
            if let icon { Image(systemName: icon).font(.system(size: 12, weight: .medium)) }
            Text(title).font(.system(size: 13, weight: .semibold))
        }
        .foregroundColor(tint)
        .padding(.horizontal, 14).padding(.vertical, 9)
        .background(Capsule().stroke(tint.opacity(0.6), lineWidth: 1))
    }
}

/// Cyan toggle switch.
struct MilliToggle: View {
    @Binding var isOn: Bool
    var body: some View {
        Toggle("", isOn: $isOn)
            .labelsHidden()
            .tint(MilliTheme.accent)
            .scaleEffect(0.8)
    }
}

/// Circular cyan progress ring with center label.
struct ProgressRing: View {
    var progress: CGFloat
    var lineWidth: CGFloat = 6
    var label: String
    var sublabel: String = ""
    var body: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.10), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(MilliTheme.accent, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: MilliTheme.accent.opacity(0.6), radius: 4)
            VStack(spacing: 1) {
                Text(label).font(.system(size: 15, weight: .bold)).foregroundColor(MilliTheme.textPrimary)
                if !sublabel.isEmpty {
                    Text(sublabel).font(.system(size: 9, weight: .medium)).foregroundColor(MilliTheme.textSecondary)
                }
            }
        }
    }
}

/// Simple rising cyan line chart.
struct Sparkline: View {
    var points: [CGFloat] = [0.2, 0.35, 0.3, 0.5, 0.45, 0.7, 0.65, 0.9]
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let path = Path { p in
                for (i, y) in points.enumerated() {
                    let x = w * CGFloat(i) / CGFloat(max(points.count - 1, 1))
                    let pt = CGPoint(x: x, y: h * (1 - y))
                    if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                }
            }
            path.stroke(MilliTheme.accent, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                .shadow(color: MilliTheme.accent.opacity(0.5), radius: 3)
        }
    }
}

/// Donut chart with segments.
struct DonutChart: View {
    let segments: [(CGFloat, Color)]
    var body: some View {
        ZStack {
            ForEach(0..<segments.count, id: \.self) { i in
                let start = segments[0..<i].map(\.0).reduce(0, +)
                Circle()
                    .trim(from: start, to: start + segments[i].0)
                    .stroke(segments[i].1, style: StrokeStyle(lineWidth: 10, lineCap: .butt))
                    .rotationEffect(.degrees(-90))
            }
        }
    }
}

/// Metallic MILLI Visa Elite card visual.
struct MilliCardVisual: View {
    var rotated = false
    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(colors: [Color(hex: 0x2A2E33), Color(hex: 0x0B0D10)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .stroke(LinearGradient(colors: [MilliTheme.chromeLight.opacity(0.6), .clear],
                                           startPoint: .topLeading, endPoint: .center), lineWidth: 0.8))
                .overlay(MilliTheme.accent.opacity(0.18)
                    .clipShape(RoundedRectangle(cornerRadius: 12)
                        .rotationEffect(.degrees(20)).padding(-20)))
            VStack(alignment: .leading) {
                MilliMark(size: 16)
                Spacer()
                HStack {
                    Text("MILLI").font(.custom("Sora-SemiBold", size: 10)).kerning(2)
                        .foregroundColor(MilliTheme.chromeLight)
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("VISA").font(.system(size: 9, weight: .bold)).foregroundColor(.white).italic()
                        Text("ELITE").font(.system(size: 7, weight: .bold)).kerning(1).foregroundColor(MilliTheme.chromeMid)
                    }
                }
            }
            .padding(10)
        }
        .frame(width: 110, height: 70)
        .rotationEffect(.degrees(rotated ? -8 : 0))
        .shadow(color: MilliTheme.accent.opacity(0.25), radius: 10)
    }
}

/// Dark map-style route panel with glowing cyan route.
struct RouteMapPanel: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(colors: [Color(hex: 0x0B141A), Color(hex: 0x1A2B32)],
                                     startPoint: .top, endPoint: .bottom))
            Path { p in
                p.move(to: CGPoint(x: 30, y: 130))
                p.addCurve(to: CGPoint(x: 160, y: 40),
                           control1: CGPoint(x: 70, y: 120), control2: CGPoint(x: 120, y: 70))
            }
            .stroke(MilliTheme.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
            .shadow(color: MilliTheme.accent.opacity(0.8), radius: 5)
            ZStack {
                Circle().fill(MilliTheme.green).frame(width: 10, height: 10)
                    .shadow(color: MilliTheme.green.opacity(0.8), radius: 4)
            }.position(x: 30, y: 130)
            ZStack {
                Circle().fill(MilliTheme.accent).frame(width: 10, height: 10)
                    .shadow(color: MilliTheme.accent.opacity(0.8), radius: 4)
            }.position(x: 160, y: 40)
        }
    }
}

// MARK: - Tab model & navigation
//
// ⚠️ CANONICAL NAV IS IMMUTABLE (Ian, Aug 31):
// The bottom navigation must use the existing approved canonical MILLI nav
// implementation/assets. It must NEVER be recreated from reference screenshots.
// `MilliScreensNavBar` below is a thin seam: production injects the approved canonical
// nav renderer via `MilliScreensNavBar.canonicalRenderer`. The screenshot-derived dock
// (`MilliNavReferencePreview`) is quarantined for design-preview builds only
// and MUST NOT ship.

enum MilliScreensTab: String, CaseIterable, Identifiable {
    case payouts = "Payouts"
    case mileage = "Mileage"
    case wealth  = "Wealth"
    case more    = "More"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .payouts: return "wallet.pass.fill"
        case .mileage: return "paperplane.fill"
        case .wealth:  return "banknote.fill"
        case .more:    return "ellipsis"
        }
    }
}

struct MilliScreensNavBar: View {
    @Binding var selectedTab: MilliScreensTab

    /// The ONLY nav source of truth. Production wiring (app root / Julian's
    /// integration layer) sets this once to the approved canonical nav
    /// implementation, e.g.:
    ///   MilliScreensNavBar.canonicalRenderer = { $tab in AnyView(MilliCanonicalNav(selectedTab: $tab)) }
    /// When nil, the quarantined reference preview renders (design builds only).
    static var canonicalRenderer: ((Binding<MilliScreensTab>) -> AnyView)? = nil

    var body: some View {
        if let render = Self.canonicalRenderer {
            render($selectedTab)
        } else {
            MilliNavReferencePreview(selectedTab: $selectedTab)
        }
    }
}

// MARK: - Screenshot-derived dock — REFERENCE PREVIEW ONLY, DO NOT SHIP
// Recreated from the Aug 31 reference images. Kept solely so design previews
// render without the production module. Every applicable screen must instead
// use the canonical nav via `MilliScreensNavBar.canonicalRenderer`.

struct MilliNavReferencePreview: View {
    @Binding var selectedTab: MilliScreensTab
    var body: some View {
        ZStack {
            // Sculpted metallic dock
            RoundedRectangle(cornerRadius: 26)
                .fill(LinearGradient(colors: [Color(hex: 0x2E3136), Color(hex: 0x14161A), Color(hex: 0x0C0E11)],
                                     startPoint: .top, endPoint: .bottom))
                .overlay(RoundedRectangle(cornerRadius: 26)
                    .stroke(LinearGradient(colors: [MilliTheme.chromeLight.opacity(0.5), .clear],
                                           startPoint: .top, endPoint: .bottom), lineWidth: 0.8))
                .shadow(color: .black.opacity(0.6), radius: 12, y: 4)
            // Chrome rivets
            HStack {
                ForEach(0..<3, id: \.self) { _ in
                    Circle().fill(LinearGradient(colors: [MilliTheme.chromeLight, MilliTheme.chromeDark],
                                                  startPoint: .top, endPoint: .bottom))
                        .frame(width: 10, height: 10)
                }
                Spacer()
                ForEach(0..<3, id: \.self) { _ in
                    Circle().fill(LinearGradient(colors: [MilliTheme.chromeLight, MilliTheme.chromeDark],
                                                  startPoint: .top, endPoint: .bottom))
                        .frame(width: 10, height: 10)
                }
            }
            .padding(.horizontal, 24).offset(y: -26)

            HStack {
                navItem(.payouts)
                Spacer()
                navItem(.mileage)
                Spacer()
                Color.clear.frame(width: 64)
                Spacer()
                navItem(.wealth)
                Spacer()
                navItem(.more)
            }
            .padding(.horizontal, 20)
            .frame(height: MilliTheme.navHeight - 22)

            MilliCenterButton()
        }
        .frame(height: MilliTheme.navHeight)
        .padding(.horizontal, 8)
    }

    @ViewBuilder
    private func navItem(_ tab: MilliScreensTab) -> some View {
        let isActive = selectedTab == tab
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.icon).font(.system(size: 20, weight: .medium))
                Text(tab.rawValue).font(.system(size: 9, weight: .medium))
            }
            .foregroundColor(isActive ? MilliTheme.accent : MilliTheme.textSecondary)
            .frame(width: 60)
        }
        .buttonStyle(.plain)
    }
}

/// Center M button of the screenshot-derived preview dock. DO NOT SHIP —
/// the canonical nav provides its own center M housing.
struct MilliCenterButton: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [MilliTheme.chromeLight, MilliTheme.chromeMid, MilliTheme.chromeDark],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 60, height: 60)
                .shadow(color: MilliTheme.accent.opacity(0.6), radius: 12)
            Circle().strokeBorder(Color.black.opacity(0.6), lineWidth: 2).frame(width: 52, height: 52)
            Text("M")
                .font(.custom("Sora-SemiBold", size: 24))
                .foregroundStyle(LinearGradient(colors: [Color(hex: 0xF5F5F7), Color(hex: 0x8A8A92)],
                                                startPoint: .top, endPoint: .bottom))
        }
    }
}

// MARK: - 01. Splash / Launch

struct SplashScreen: View {
    var body: some View {
        ZStack {
            MilliTheme.background.ignoresSafeArea()
            VStack(spacing: 26) {
                Spacer()
                MilliLogoHeader()
                Rectangle().fill(LinearGradient(colors: [.clear, MilliTheme.accent.opacity(0.8), .clear],
                                                startPoint: .leading, endPoint: .trailing))
                    .frame(height: 1).padding(.horizontal, 40)
                MilliAICharacterView(size: 150)
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - 02/03. Welcome / Sign In

struct WelcomeScreen: View {
    @State private var email = ""
    @State private var password = ""
    @State private var remember = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top) {
                    MilliLogoHeader()
                    Spacer()
                    MilliCardVisual(rotated: true)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome").font(.system(size: 30, weight: .bold)).foregroundColor(.white)
                    Text("to the ").font(.system(size: 30, weight: .bold)).foregroundColor(.white)
                        + Text("future").font(.system(size: 30, weight: .bold)).foregroundColor(MilliTheme.accent)
                    Text("of money.").font(.system(size: 30, weight: .bold)).foregroundColor(MilliTheme.accent)
                    Text("AI-powered banking designed around you.")
                        .font(.system(size: 13)).foregroundColor(MilliTheme.textSecondary)
                }
                MilliAICallout(message: "Hi there! I'm Milli AI. Here to help you bank smarter, every day.")
                AuthField(icon: "envelope", placeholder: "Email address", text: $email)
                AuthField(icon: "lock", placeholder: "Password", text: $password, secure: true)
                HStack {
                    Button { remember.toggle() } label: {
                        HStack(spacing: 6) {
                            Image(systemName: remember ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(MilliTheme.accent)
                            Text("Remember me").font(.system(size: 12)).foregroundColor(MilliTheme.textSecondary)
                        }
                    }
                    Spacer()
                    Text("Forgot password?").font(.system(size: 12, weight: .semibold)).foregroundColor(MilliTheme.accent)
                }
                PrimaryButton(title: "Sign In")
                HStack {
                    Rectangle().fill(Color.white.opacity(0.12)).frame(height: 0.5)
                    Text("or continue with").font(.system(size: 11)).foregroundColor(MilliTheme.textTertiary)
                    Rectangle().fill(Color.white.opacity(0.12)).frame(height: 0.5)
                }
                HStack(spacing: 8) {
                    Image(systemName: "fingerprint").foregroundColor(MilliTheme.accent)
                    Text("Use Face ID / Touch ID").font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 13)
                .background(RoundedRectangle(cornerRadius: 14).stroke(MilliTheme.accent.opacity(0.5), lineWidth: 1))
                MilliCard {
                    HStack(spacing: 12) {
                        Text("7 DAYS").font(.system(size: 11, weight: .bold)).kerning(1)
                            .foregroundColor(MilliTheme.accent)
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 8).stroke(MilliTheme.accent.opacity(0.6), lineWidth: 1))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Start your 7-day trial").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                            Text("Experience the future of private banking. No commitment. Cancel anytime.")
                                .font(.system(size: 10)).foregroundColor(MilliTheme.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(MilliTheme.textSecondary)
                    }
                }
            }
            .padding(MilliTheme.screenPadding)
        }
        .background(MilliTheme.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }
}

struct AuthField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var secure = false
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundColor(MilliTheme.textSecondary)
            if secure {
                SecureField(placeholder, text: $text).font(.system(size: 14)).foregroundColor(.white)
            } else {
                TextField(placeholder, text: $text).font(.system(size: 14)).foregroundColor(.white)
            }
            if secure { Image(systemName: "eye").foregroundColor(MilliTheme.textSecondary) }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12).fill(MilliTheme.surface)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.10), lineWidth: 0.5)))
    }
}

// MARK: - 04. Create Account

struct CreateAccountScreen: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "chevron.left").foregroundColor(MilliTheme.textSecondary)
                    Spacer()
                    Text("Create Your Account").font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                    Spacer()
                    Color.clear.frame(width: 16)
                }
                Text("Let's build your future, together.")
                    .font(.system(size: 12)).foregroundColor(MilliTheme.textSecondary)
                FormFieldRow(icon: "person", label: "Full Name", value: "Alex Johnson", validated: true)
                FormFieldRow(icon: "envelope", label: "Email Address", value: "alex.johnson@email.com", validated: true)
                VStack(alignment: .leading, spacing: 6) {
                    FormFieldRow(icon: "lock", label: "Password", value: "••••••••••", validated: true, trailing: "eye.slash")
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.08))
                            Capsule().fill(MilliTheme.accent).frame(width: geo.size.width * 0.85)
                        }
                    }.frame(height: 3)
                    Text("Strong password.").font(.system(size: 10)).foregroundColor(MilliTheme.accent)
                }
                FormFieldRow(icon: "phone", label: "Phone Number", value: "(415) 555-9876", validated: true)
                FormFieldRow(icon: "mappin.and.ellipse", label: "State", value: "California", validated: true, trailing: "chevron.down")
                MilliCard {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(LinearGradient(colors: [MilliTheme.chromeLight, MilliTheme.chromeDark],
                                                          startPoint: .top, endPoint: .bottom)).frame(width: 40, height: 40)
                            MilliMark(size: 18)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Start Your 7-Day Free Trial").font(.system(size: 13, weight: .bold)).foregroundColor(MilliTheme.accent)
                            Text("Experience the power of Milli AI. Cancel anytime. No commitment.")
                                .font(.system(size: 10)).foregroundColor(MilliTheme.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(MilliTheme.textSecondary)
                    }
                }
                MilliCard {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel(text: "Plan Highlight")
                        HStack {
                            Text("Pro Plan").font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                            Spacer()
                            Text("$14.99 / month").font(.system(size: 13, weight: .semibold)).foregroundColor(MilliTheme.textSecondary)
                        }
                        ForEach(["AI-driven insights", "Advanced planning", "Priority support"], id: \.self) { benefit in
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundColor(MilliTheme.accent)
                                Text(benefit).font(.system(size: 11)).foregroundColor(MilliTheme.textSecondary)
                            }
                        }
                    }
                }
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.shield.fill").foregroundColor(MilliTheme.accent)
                    Text("Your information is secure and encrypted with bank-level protection.")
                        .font(.system(size: 11)).foregroundColor(MilliTheme.textSecondary)
                }
            }
            .padding(MilliTheme.screenPadding)
        }
        .background(MilliTheme.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }
}

struct FormFieldRow: View {
    let icon: String
    let label: String
    let value: String
    var validated = false
    var trailing: String? = nil
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundColor(MilliTheme.textSecondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.system(size: 9, weight: .semibold)).kerning(1).foregroundColor(MilliTheme.textTertiary)
                Text(value).font(.system(size: 14)).foregroundColor(.white)
            }
            Spacer()
            if let trailing {
                Image(systemName: trailing).font(.system(size: 12)).foregroundColor(MilliTheme.textSecondary)
            }
            if validated {
                Image(systemName: "checkmark.circle.fill").foregroundColor(MilliTheme.accent)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(MilliTheme.surface)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.10), lineWidth: 0.5)))
    }
}

// MARK: - 05. Onboarding / Tax Profile

struct TaxProfileOnboardingScreen: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Onboarding").font(.system(size: 12, weight: .semibold)).foregroundColor(MilliTheme.accent)
                    Spacer()
                    Text("1 of 5").font(.system(size: 11, weight: .semibold)).foregroundColor(MilliTheme.textSecondary)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Let's build your").font(.system(size: 26, weight: .bold)).foregroundColor(.white)
                        + Text(" Tax").font(.system(size: 26, weight: .bold)).foregroundColor(MilliTheme.accent)
                    Text(" Profile").font(.system(size: 26, weight: .bold)).foregroundColor(.white)
                    Text("Tell us about your work so we can optimize your taxes and maximize your savings.")
                        .font(.system(size: 12)).foregroundColor(MilliTheme.textSecondary)
                }
                MilliAICallout(message: "I'll help you get the most out of every deduction. Let's get started.")
                // 5-step progress
                HStack(spacing: 4) {
                    Capsule().fill(MilliTheme.accent).frame(height: 3)
                    ForEach(0..<4, id: \.self) { _ in
                        Capsule().fill(Color.white.opacity(0.12)).frame(height: 3)
                    }
                }
                FormFieldRow(icon: "mappin.and.ellipse", label: "STATE OF RESIDENCE", value: "California", trailing: "chevron.down")
                FormFieldRow(icon: "person", label: "FILING STATUS", value: "Single", trailing: "chevron.down")
                FormFieldRow(icon: "dollarsign", label: "ESTIMATED ANNUAL GIG INCOME", value: "$65,000", trailing: "info.circle")
                FormFieldRow(icon: "briefcase", label: "BUSINESS TYPE", value: "Sole Proprietor (1099)", trailing: "chevron.down")
                MilliCard {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(text: "TAX PREFERENCES")
                        preferenceRow(title: "Maximize Deductions", subtitle: "Find every deduction you qualify for.",
                                      selected: true, recommended: true, icon: "magnifyingglass")
                        preferenceRow(title: "Quarterly Estimates", subtitle: "Plan and estimate taxes quarterly.",
                                      selected: false, recommended: false, icon: "calendar")
                        preferenceRow(title: "Year-End Optimization", subtitle: "Optimize deductions before tax season.",
                                      selected: false, recommended: false, icon: "sparkles")
                    }
                }
                PrimaryButton(title: "Continue", icon: "chevron.right")
            }
            .padding(MilliTheme.screenPadding)
        }
        .background(MilliTheme.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func preferenceRow(title: String, subtitle: String, selected: Bool, recommended: Bool, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundColor(selected ? MilliTheme.accent : MilliTheme.textSecondary)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title).font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                    if recommended {
                        Text("Recommended").font(.system(size: 8, weight: .bold))
                            .foregroundColor(MilliTheme.accent)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Capsule().stroke(MilliTheme.accent.opacity(0.6), lineWidth: 1))
                    }
                }
                Text(subtitle).font(.system(size: 10)).foregroundColor(MilliTheme.textSecondary)
            }
            Spacer()
            ZStack {
                Circle().strokeBorder(selected ? MilliTheme.accent : Color.white.opacity(0.2), lineWidth: 1.5).frame(width: 18, height: 18)
                if selected { Circle().fill(MilliTheme.accent).frame(width: 8, height: 8) }
            }
        }
    }
}

// MARK: - 06. Onboarding / Gig Platforms

struct GigPlatformsScreen: View {
    let platforms = ["Uber", "DoorDash", "Walmart Spark", "Amazon Flex", "Lyft", "Instacart", "Grubhub"]
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ScreenTitleBar(title: "Gig Platforms", trailing: "bell")
                VStack(alignment: .leading, spacing: 6) {
                    Text("Connect Your Gig Platforms").font(.system(size: 22, weight: .bold)).foregroundColor(.white)
                    Text("We'll detect payouts automatically and help you stay on top of your income.")
                        .font(.system(size: 12)).foregroundColor(MilliTheme.textSecondary)
                }
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(platforms, id: \.self) { platform in
                        VStack(spacing: 8) {
                            Circle().fill(MilliTheme.surface).frame(width: 38, height: 38)
                                .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 0.5))
                                .overlay(Text(String(platform.prefix(1))).font(.system(size: 15, weight: .bold)).foregroundColor(MilliTheme.textSecondary))
                            Text(platform).font(.system(size: 10, weight: .semibold)).foregroundColor(.white).lineLimit(1)
                            Text("Connect").font(.system(size: 10, weight: .semibold)).foregroundColor(MilliTheme.accent)
                                .padding(.horizontal, 12).padding(.vertical, 4)
                                .background(Capsule().stroke(MilliTheme.accent.opacity(0.7), lineWidth: 1))
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 12).fill(MilliTheme.card)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 0.5)))
                    }
                }
                MilliCard {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.shield.fill").foregroundColor(MilliTheme.accent)
                            Text("Secure. Automatic. Effortless.").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                        }
                        Text("We use bank-level encryption to monitor payouts and notify you the moment your money hits.")
                            .font(.system(size: 11)).foregroundColor(MilliTheme.textSecondary)
                    }
                }
            }
            .padding(MilliTheme.screenPadding)
        }
        .background(MilliTheme.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }
}

// MARK: - 07. Autopilot Setup

struct AutopilotSetupScreen: View {
    @State private var retirement = 10.0
    @State private var investing = 15.0
    @State private var savings = 5.0
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ScreenTitleBar(title: "Autopilot Setup", trailing: "sparkles", showTrailing: true)
                MilliCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Every payout has automatic tax withholding for your peace of mind.")
                                .font(.system(size: 13, weight: .medium)).foregroundColor(.white)
                            Text("I've got your back.").font(.system(size: 11)).foregroundColor(MilliTheme.accent)
                        }
                        Spacer()
                        MilliAICharacterView(size: 56)
                    }
                }
                MilliCard {
                    VStack(alignment: .leading, spacing: 14) {
                        SectionLabel(text: "PAYOUT AUTOMATION")
                        automationRow(icon: "checkmark.shield.fill", title: "Taxes (Always On)", subtitle: "Automatic tax withholding", percent: nil)
                        automationRow(icon: "leaf", title: "Retirement", subtitle: "Build your future", percent: retirement)
                        automationRow(icon: "chart.line.uptrend.xyaxis", title: "Investing", subtitle: "Grow your wealth", percent: investing)
                        automationRow(icon: "banknote", title: "Savings", subtitle: "Build your safety net", percent: savings)
                    }
                }
                MilliCard {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionLabel(text: "EXAMPLE PAYOUT BREAKDOWN")
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Payout Received:").font(.system(size: 11)).foregroundColor(MilliTheme.textSecondary)
                                Text("$3,250.00").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                            }
                            Spacer()
                            VStack(alignment: .leading) {
                                Text("Taxes Spend:").font(.system(size: 11)).foregroundColor(MilliTheme.textSecondary)
                                Text("-$812.50").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("Available to Spend:").font(.system(size: 11)).foregroundColor(MilliTheme.textSecondary)
                                Text("$2,437.50").font(.system(size: 16, weight: .bold)).foregroundColor(MilliTheme.accent)
                            }
                        }
                        Divider().overlay(Color.white.opacity(0.08))
                        breakdownRow(color: MilliTheme.accent, title: "Taxes (Withholding)", amount: "-$812.50", pct: "25%")
                        breakdownRow(color: MilliTheme.gold, title: "Retirement", amount: "-$325.00", pct: "10%")
                        breakdownRow(color: MilliTheme.green, title: "Investing", amount: "-$487.50", pct: "15%")
                        breakdownRow(color: Color(hex: 0x3399FF), title: "Savings", amount: "-$162.50", pct: "5%")
                        Divider().overlay(Color.white.opacity(0.08))
                        HStack {
                            Text("Available to Spend").font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                            Spacer()
                            Text("$2,437.50 (75%)").font(.system(size: 13, weight: .bold)).foregroundColor(MilliTheme.accent)
                        }
                    }
                }
                HStack(spacing: 8) {
                    Image(systemName: "gearshape.2").foregroundColor(MilliTheme.accent)
                    Text("These preferences can be adjusted anytime. MILLI adapts as your life evolves.")
                        .font(.system(size: 11)).foregroundColor(MilliTheme.textSecondary)
                }
            }
            .padding(MilliTheme.screenPadding)
        }
        .background(MilliTheme.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func automationRow(icon: String, title: String, subtitle: String, percent: Double?) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundColor(MilliTheme.accent).frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                Text(subtitle).font(.system(size: 10)).foregroundColor(MilliTheme.textSecondary)
            }
            Spacer()
            if let percent {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(percent))%").font(.system(size: 13, weight: .bold)).foregroundColor(MilliTheme.accent)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.10))
                            Capsule().fill(MilliTheme.accent).frame(width: geo.size.width * percent / 30)
                        }
                    }.frame(width: 70, height: 3)
                }
            } else {
                Text("Always On").font(.system(size: 10, weight: .semibold)).foregroundColor(MilliTheme.accent)
            }
        }
    }

    @ViewBuilder
    private func breakdownRow(color: Color, title: String, amount: String, pct: String) -> some View {
        HStack(spacing: 8) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(title).font(.system(size: 12)).foregroundColor(.white)
            Spacer()
            Text(amount).font(.system(size: 12, weight: .semibold)).foregroundColor(.white)
            Text(pct).font(.system(size: 11)).foregroundColor(MilliTheme.textSecondary).frame(width: 36, alignment: .trailing)
        }
    }
}
// MARK: - 08. Home Dashboard

struct HomeDashboardScreen: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    MilliMark(size: 22)
                    Spacer()
                    Text("Good morning, Alex").font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                    Spacer()
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell").font(.system(size: 16)).foregroundColor(MilliTheme.textSecondary)
                        Circle().fill(MilliTheme.accent).frame(width: 5, height: 5).offset(x: 2, y: -2)
                    }
                }
                MilliCard(glow: true) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                SectionLabel(text: "AVAILABLE TO SPEND")
                                Image(systemName: "eye").font(.system(size: 11)).foregroundColor(MilliTheme.textSecondary)
                            }
                            Text("$8,642.31").font(.system(size: 30, weight: .bold)).foregroundColor(.white)
                            HStack(spacing: 4) {
                                Text("MILLI CHECKING •••• 3847").font(.system(size: 10)).foregroundColor(MilliTheme.textSecondary)
                                Image(systemName: "chevron.right").font(.system(size: 9)).foregroundColor(MilliTheme.textSecondary)
                            }
                        }
                        Spacer()
                        MilliCardVisual()
                    }
                }
                MilliCard {
                    HStack(spacing: 10) {
                        Circle().fill(MilliTheme.red).frame(width: 30, height: 30)
                            .overlay(Text("D").font(.system(size: 13, weight: .bold)).foregroundColor(.white))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("DoorDash").font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                            Text("Today, 8:24 AM Completed").font(.system(size: 10)).foregroundColor(MilliTheme.textSecondary)
                        }
                        Spacer()
                        Text("+$312.75").font(.system(size: 14, weight: .bold)).foregroundColor(MilliTheme.accent)
                    }
                }
                HStack(spacing: 12) {
                    MilliCard {
                        VStack(alignment: .leading, spacing: 6) {
                            SectionLabel(text: "MILLI TAX VAULT")
                            Text("$7,128.45").font(.system(size: 17, weight: .bold)).foregroundColor(.white)
                            Text("Set aside for taxes").font(.system(size: 10)).foregroundColor(MilliTheme.textSecondary)
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Color.white.opacity(0.10))
                                    Capsule().fill(MilliTheme.accent).frame(width: geo.size.width * 0.28)
                                }
                            }.frame(height: 4)
                            Text("28% of annual target").font(.system(size: 9)).foregroundColor(MilliTheme.textSecondary)
                        }
                    }
                    MilliCard {
                        VStack(spacing: 6) {
                            SectionLabel(text: "TAX READY SCORE")
                            ProgressRing(progress: 0.82, label: "82", sublabel: "Great")
                            Text("On track for tax season.").font(.system(size: 9)).foregroundColor(MilliTheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                MilliCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            SectionLabel(text: "FINANCIAL TIMELINE")
                            Spacer()
                            Text("See timeline >").font(.system(size: 11)).foregroundColor(MilliTheme.accent)
                        }
                        HStack(alignment: .top, spacing: 0) {
                            timelinePoint(label: "MAY", value: "$1,243", sub: "Payouts")
                            timelinePoint(label: "JUN", value: "$1,892", sub: "Payouts")
                            timelinePoint(label: "JUL", value: "$2,410", sub: "Payouts")
                            timelinePoint(label: "AUG", value: "$3,102", sub: "Projected")
                        }
                    }
                }
                HStack(spacing: 12) {
                    miniMetric(title: "MILEAGE", value: "1,247 mi", sub: "This month", foot: "$748 est. deduction")
                    miniMetric(title: "RETIREMENT", value: "$2,341.08", sub: "Total balance", foot: "+12% this year")
                    miniMetric(title: "INVESTING", value: "$5,210.76", sub: "Total balance", foot: "+18% this year")
                }
                MilliCard {
                    HStack(spacing: 10) {
                        MilliAICharacterView(size: 36)
                        VStack(alignment: .leading, spacing: 2) {
                            SectionLabel(text: "MILLI AI INSIGHT")
                            Text("You're on track to save $1,320 in taxes this year. Keep it up!")
                                .font(.system(size: 11)).foregroundColor(MilliTheme.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(MilliTheme.textSecondary)
                    }
                }
            }
            .padding(MilliTheme.screenPadding)
        }
        .background(MilliTheme.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func timelinePoint(label: String, value: String, sub: String) -> some View {
        VStack(spacing: 6) {
            Circle().fill(MilliTheme.accent).frame(width: 8, height: 8)
                .shadow(color: MilliTheme.accent.opacity(0.8), radius: 3)
            Text(label).font(.system(size: 9, weight: .bold)).foregroundColor(MilliTheme.textSecondary)
            Text(value).font(.system(size: 11, weight: .bold)).foregroundColor(.white)
            Text(sub).font(.system(size: 8)).foregroundColor(MilliTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func miniMetric(title: String, value: String, sub: String, foot: String) -> some View {
        MilliCard {
            VStack(alignment: .leading, spacing: 4) {
                SectionLabel(text: title)
                Text(value).font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                Text(sub).font(.system(size: 9)).foregroundColor(MilliTheme.textSecondary)
                Text(foot).font(.system(size: 9, weight: .semibold)).foregroundColor(MilliTheme.accent)
            }
        }
    }
}

// MARK: - 09. Payouts

struct PayoutsScreen: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                ScreenTitleBar(title: "Payouts")
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Payouts").font(.system(size: 24, weight: .bold)).foregroundColor(.white)
                        Text("Track your gig earnings in one place.").font(.system(size: 11)).foregroundColor(MilliTheme.textSecondary)
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Text("This Month").font(.system(size: 11, weight: .semibold)).foregroundColor(.white)
                        Image(systemName: "chevron.down").font(.system(size: 9)).foregroundColor(MilliTheme.textSecondary)
                    }
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
                }
                MilliCard {
                    HStack {
                        summaryCol(label: "TOTAL PAYOUTS", value: "$18,540.32", color: .white)
                        summaryCol(label: "PENDING BALANCE", value: "$2,341.68", color: .white)
                    }
                }
                HStack(spacing: 8) {
                    filterPill("All", active: true)
                    filterPill("Completed", active: false)
                    filterPill("Pending", active: false)
                    filterPill("Platform", active: false, chevron: true)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("RECENT PAYOUTS").font(.system(size: 12, weight: .bold)).kerning(1).foregroundColor(.white)
                    payoutRow(icon: "D", color: MilliTheme.red, name: "DoorDash", status: "Payout Completed", amount: "+$312.75", date: "Today, 8:24 AM")
                    payoutRow(icon: "U", color: .black, name: "Uber", status: "Payout Completed", amount: "+$245.80", date: "Yesterday, 11:48 PM")
                    payoutRow(icon: "S", color: MilliTheme.blue, name: "Spark", status: "Payout Completed", amount: "+$178.32", date: "May 6, 7:15 PM")
                    payoutRow(icon: "I", color: .white, name: "Instacart", status: "Payout Completed", amount: "+$156.42", date: "May 6, 1:03 PM")
                    payoutRow(icon: "A", color: MilliTheme.gold, name: "Amazon Flex", status: "Payout Completed", amount: "+$120.00", date: "May 5, 9:41 AM")
                }
                MilliCard(glow: true) {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel(text: "AUTOPILOT RECEIPT SUMMARY")
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Text("DoorDash Payout").font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                                    Image(systemName: "checkmark.seal.fill").font(.system(size: 11)).foregroundColor(MilliTheme.accent)
                                    Text("Verified").font(.system(size: 10, weight: .semibold)).foregroundColor(MilliTheme.accent)
                                }
                                Text("$312.75").font(.system(size: 22, weight: .bold)).foregroundColor(.white)
                                Text("May 7, 2025 at 8:24 AM").font(.system(size: 10)).foregroundColor(MilliTheme.textSecondary)
                            }
                            Spacer()
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(MilliTheme.accent.opacity(0.6), lineWidth: 1)
                                .frame(width: 54, height: 70)
                                .overlay(VStack(spacing: 3) {
                                    ForEach(0..<4, id: \.self) { _ in
                                        Rectangle().fill(Color.white.opacity(0.15)).frame(width: 34, height: 2)
                                    }
                                })
                        }
                    }
                }
            }
            .padding(MilliTheme.screenPadding)
        }
        .background(MilliTheme.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func summaryCol(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.system(size: 9, weight: .bold)).kerning(1).foregroundColor(MilliTheme.textSecondary)
            Text(value).font(.system(size: 18, weight: .bold)).foregroundColor(color)
            Text("This Month").font(.system(size: 9)).foregroundColor(MilliTheme.textTertiary)
        }
        Spacer()
    }

    @ViewBuilder
    private func filterPill(_ title: String, active: Bool, chevron: Bool = false) -> some View {
        HStack(spacing: 3) {
            Text(title).font(.system(size: 11, weight: .semibold))
            if chevron { Image(systemName: "chevron.down").font(.system(size: 8)) }
        }
        .foregroundColor(active ? MilliTheme.accent : MilliTheme.textSecondary)
        .padding(.horizontal, 12).padding(.vertical, 7)
        .background(Capsule().stroke(active ? MilliTheme.accent : Color.white.opacity(0.15), lineWidth: 1))
    }

    @ViewBuilder
    private func payoutRow(icon: String, color: Color, name: String, status: String, amount: String, date: String) -> some View {
        HStack(spacing: 10) {
            Circle().fill(color).frame(width: 32, height: 32)
                .overlay(Text(icon).font(.system(size: 13, weight: .bold)).foregroundColor(.white))
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                Text(status).font(.system(size: 10)).foregroundColor(MilliTheme.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(amount).font(.system(size: 14, weight: .bold)).foregroundColor(MilliTheme.accent)
                Text(date).font(.system(size: 9)).foregroundColor(MilliTheme.textSecondary)
            }
            Image(systemName: "chevron.right").font(.system(size: 11)).foregroundColor(MilliTheme.textTertiary)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(MilliTheme.card)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 0.5)))
    }
}

// MARK: - 10. Milli Tax Vault

struct TaxVaultScreen: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                ScreenTitleBar(title: "Milli Tax Vault", trailing: "shield")
                MilliCard {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            SectionLabel(text: "VAULT BALANCE")
                            Text("$7,128.45").font(.system(size: 28, weight: .bold)).foregroundColor(.white)
                            Text("Set aside for taxes").font(.system(size: 11)).foregroundColor(MilliTheme.textSecondary)
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Color.white.opacity(0.10))
                                    Capsule().fill(MilliTheme.accent).frame(width: geo.size.width * 0.28)
                                }
                            }.frame(height: 5)
                            Text("28% of annual target · $25,480 annual target")
                                .font(.system(size: 9)).foregroundColor(MilliTheme.textSecondary)
                        }
                        Spacer()
                        ProgressRing(progress: 0.82, label: "82%", sublabel: "Reserved")
                    }
                }
                MilliCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            SectionLabel(text: "AUDITABLE LEDGER")
                            Spacer()
                            Text("View all").font(.system(size: 11, weight: .semibold)).foregroundColor(MilliTheme.accent)
                        }
                        ledgerRow(icon: "arrow.triangle.2.circlepath", title: "Auto Transfer", sub: "From Checking •••• 3847", amount: "+$312.75", date: "Today, 8:24 AM")
                        ledgerRow(icon: "percent", title: "Quarterly Estimate", sub: "Q2 2025", amount: "+$1,820.00", date: "Jun 30, 2025")
                        ledgerRow(icon: "banknote", title: "Interest Earned", sub: "Vault Balance", amount: "+$18.42", date: "Jun 30, 2025")
                        ledgerRow(icon: "plus.circle", title: "Adjustment", sub: "Manual Deposit", amount: "+$250.00", date: "Jun 28, 2025")
                    }
                }
                HStack(spacing: 12) {
                    MilliCard {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionLabel(text: "TRANSFER / ADD FUNDS")
                            Text("Quickly move money into your Tax Vault.").font(.system(size: 10)).foregroundColor(MilliTheme.textSecondary)
                            OutlineButton(title: "Add Funds", icon: "wallet.pass", tint: MilliTheme.accent)
                            HStack {
                                Text("Auto Transfers").font(.system(size: 11)).foregroundColor(.white)
                                Spacer()
                                Text("On").font(.system(size: 11, weight: .semibold)).foregroundColor(MilliTheme.accent)
                                Image(systemName: "chevron.right").font(.system(size: 10)).foregroundColor(MilliTheme.textTertiary)
                            }
                        }
                    }
                    MilliCard {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionLabel(text: "UPCOMING QUARTERLY TAX")
                            Text("Q3 2025 Estimate").font(.system(size: 10, weight: .semibold)).foregroundColor(MilliTheme.accent)
                            Text("$3,102.00").font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                            Text("Due Sep 15, 2025").font(.system(size: 10)).foregroundColor(MilliTheme.textSecondary)
                            OutlineButton(title: "View Estimate", icon: "chevron.right", tint: MilliTheme.textPrimary)
                        }
                    }
                }
                MilliCard {
                    HStack(spacing: 10) {
                        Image(systemName: "lock.shield").foregroundColor(MilliTheme.accent)
                        VStack(alignment: .leading, spacing: 4) {
                            SectionLabel(text: "SAFETY & COMPLIANCE")
                            Text("Funds in the Milli Tax Vault are set aside exclusively for your tax obligations.")
                                .font(.system(size: 10)).foregroundColor(MilliTheme.textSecondary)
                            HStack(spacing: 12) {
                                ForEach(["Segregated", "FDIC-Insured", "Audit-Ready"], id: \.self) { item in
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark").font(.system(size: 9, weight: .bold)).foregroundColor(MilliTheme.accent)
                                        Text(item).font(.system(size: 10, weight: .medium)).foregroundColor(.white)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(MilliTheme.screenPadding)
        }
        .background(MilliTheme.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func ledgerRow(icon: String, title: String, sub: String, amount: String, date: String) -> some View {
        HStack(spacing: 10) {
            Circle().stroke(MilliTheme.accent, lineWidth: 1.2).frame(width: 30, height: 30)
                .overlay(Image(systemName: icon).font(.system(size: 12)).foregroundColor(MilliTheme.accent))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 12, weight: .semibold)).foregroundColor(.white)
                Text(sub).font(.system(size: 9)).foregroundColor(MilliTheme.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(amount).font(.system(size: 12, weight: .bold)).foregroundColor(MilliTheme.accent)
                Text(date).font(.system(size: 9)).foregroundColor(MilliTheme.textSecondary)
            }
        }
    }
}

// MARK: - 12. Active Trip (Mileage)

struct ActiveTripScreen: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: "chevron.left").foregroundColor(MilliTheme.textSecondary)
                    Spacer()
                    Text("Active Trip").font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                    Spacer()
                    Image(systemName: "ellipsis").foregroundColor(MilliTheme.textSecondary)
                }
                MilliCard {
                    HStack {
                        HStack(spacing: 6) {
                            Circle().fill(MilliTheme.accent).frame(width: 6, height: 6)
                            Text("LIVE").font(.system(size: 9, weight: .bold)).kerning(1).foregroundColor(MilliTheme.accent)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Capsule().stroke(MilliTheme.accent.opacity(0.7), lineWidth: 1))
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Tracking Active").font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                            Text("Since 8:24 AM").font(.system(size: 10)).foregroundColor(MilliTheme.textSecondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("00:28:47").font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                            Text("Drive Time").font(.system(size: 9)).foregroundColor(MilliTheme.textSecondary)
                        }
                    }
                }
                RouteMapPanel().frame(height: 180)
                HStack(spacing: 10) {
                    tripMetric(label: "CURRENT SPEED", value: "62", unit: "mph", icon: "speedometer")
                    tripMetric(label: "MILES TRACKED", value: "32.4", unit: "mi", icon: "point.topleft.down.curvedto.point.bottomright.up")
                    tripMetric(label: "EST. DEDUCTION", value: "$19.44", unit: "Potential", icon: "dollarsign.circle")
                }
                MilliCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            SectionLabel(text: "TRIP CLASSIFICATION")
                            Text("Business").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                            Text("Tax Deductible").font(.system(size: 10)).foregroundColor(MilliTheme.textSecondary)
                        }
                        Spacer()
                        OutlineButton(title: "Change", icon: "briefcase", tint: MilliTheme.textPrimary)
                    }
                }
                MilliCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            SectionLabel(text: "VEHICLE")
                            Text("Tesla Model 3").font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                            Text("2023 • Electric").font(.system(size: 10)).foregroundColor(MilliTheme.textSecondary)
                        }
                        Spacer()
                        OutlineButton(title: "Edit", tint: MilliTheme.textPrimary)
                    }
                }
                HStack(spacing: 10) {
                    controlButton(title: "Pause", icon: "pause.fill", tint: .white)
                    PrimaryButton(title: "Stop Trip", icon: "stop.fill")
                    controlButton(title: "Split Trip", icon: "arrow.triangle.swap", tint: .white)
                }
                MilliCard {
                    HStack {
                        statusItem(icon: "antenna.radiowaves.left.and.right", label: "GPS SIGNAL", value: "Strong")
                        Spacer()
                        statusItem(icon: "target", label: "ACCURACY", value: "±3 ft")
                        Spacer()
                        statusItem(icon: "checkmark.circle", label: "STATUS", value: "Recording")
                    }
                }
            }
            .padding(MilliTheme.screenPadding)
        }
        .background(MilliTheme.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func tripMetric(label: String, value: String, unit: String, icon: String) -> some View {
        MilliCard {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 13)).foregroundColor(MilliTheme.accent)
                Text(label).font(.system(size: 8, weight: .bold)).kerning(0.5).foregroundColor(MilliTheme.textSecondary)
                Text(value).font(.system(size: 17, weight: .bold)).foregroundColor(.white)
                Text(unit).font(.system(size: 9)).foregroundColor(MilliTheme.textTertiary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private func controlButton(title: String, icon: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 14))
            Text(title).font(.system(size: 10, weight: .semibold))
        }
        .foregroundColor(tint)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 14).fill(MilliTheme.surface)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.12), lineWidth: 0.5)))
    }

    @ViewBuilder
    private func statusItem(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon).font(.system(size: 12)).foregroundColor(MilliTheme.accent)
            Text(label).font(.system(size: 8, weight: .bold)).foregroundColor(MilliTheme.textSecondary)
            Text(value).font(.system(size: 11, weight: .semibold)).foregroundColor(.white)
        }
    }
}

// MARK: - 13. Trip Detail

struct TripDetailScreen: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: "chevron.left").foregroundColor(MilliTheme.textSecondary)
                    Spacer()
                    Text("Trip Detail").font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                    Spacer()
                    Image(systemName: "ellipsis").foregroundColor(MilliTheme.textSecondary)
                }
                MilliCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("WEDNESDAY, MAY 8, 2024.").font(.system(size: 10, weight: .bold)).kerning(1).foregroundColor(MilliTheme.textSecondary)
                        HStack {
                            Text("8:24 AM – 9:11 AM").font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                            Spacer()
                            Text("Business").font(.system(size: 9, weight: .bold)).foregroundColor(MilliTheme.accent)
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Capsule().stroke(MilliTheme.accent.opacity(0.7), lineWidth: 1))
                        }
                        HStack(spacing: 10) {
                            Circle().fill(MilliTheme.green).frame(width: 10, height: 10)
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Home").font(.system(size: 12, weight: .semibold)).foregroundColor(.white)
                                Text("1234 Oakridge Dr, San Francisco, CA").font(.system(size: 9)).foregroundColor(MilliTheme.textSecondary)
                            }
                        }
                        Rectangle().fill(MilliTheme.accent.opacity(0.5)).frame(width: 1.5, height: 14).padding(.leading, 4)
                        HStack(spacing: 10) {
                            Circle().fill(MilliTheme.accent).frame(width: 10, height: 10)
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Client Meeting").font(.system(size: 12, weight: .semibold)).foregroundColor(.white)
                                Text("456 Market St, San Francisco, CA").font(.system(size: 9)).foregroundColor(MilliTheme.textSecondary)
                            }
                        }
                    }
                }
                RouteMapPanel().frame(height: 150)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    detailMetric(label: "Total Miles", value: "23.4 mi", sub: "IRS Standard Rate · $0.670 / mile")
                    detailMetric(label: "Business Use", value: "100%", sub: "Fully Deductible")
                    detailMetric(label: "Drive Duration", value: "46 min", sub: "7:58 AM – 8:44 AM")
                    detailMetric(label: "Deduction Estimate", value: "$15.68", sub: "Potential Deduction", highlight: true)
                    detailMetric(label: "Gas Estimate", value: "$3.12", sub: "2.1 gal · $2.89 / gal")
                    detailMetric(label: "Notes", value: "Q2 strategy review with new client.", sub: "")
                }
                MilliCard {
                    HStack {
                        SectionLabel(text: "RECEIPTS")
                        Spacer()
                        Text("1 Attachment").font(.system(size: 10)).foregroundColor(MilliTheme.textSecondary)
                    }
                    .padding(.bottom, 10)
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.up.tray").foregroundColor(MilliTheme.accent)
                        Text("Add Receipt").font(.system(size: 12, weight: .semibold)).foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5])).foregroundColor(Color.white.opacity(0.25)))
                }
                PrimaryButton(title: "Export / Share Trip", icon: "square.and.arrow.up")
            }
            .padding(MilliTheme.screenPadding)
        }
        .background(MilliTheme.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func detailMetric(label: String, value: String, sub: String, highlight: Bool = false) -> some View {
        MilliCard {
            VStack(alignment: .leading, spacing: 4) {
                Text(label).font(.system(size: 10, weight: .semibold)).foregroundColor(MilliTheme.textSecondary)
                Text(value).font(.system(size: 15, weight: .bold)).foregroundColor(highlight ? MilliTheme.accent : .white)
                if !sub.isEmpty { Text(sub).font(.system(size: 9)).foregroundColor(MilliTheme.textTertiary) }
            }
        }
    }
}

// MARK: - 14. Offer Analyzer

struct OfferAnalyzerScreen: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    MilliLogoHeader(compact: true)
                    Spacer()
                    MilliCardVisual(rotated: true)
                }
                MilliCard {
                    VStack(alignment: .leading, spacing: 4) {
                        SectionLabel(text: "MILEAGE & MILLI CENTS™")
                        Text("Offer Analyzer").font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                        Text("We crunch the numbers. You keep more.").font(.system(size: 11)).foregroundColor(MilliTheme.textSecondary)
                    }
                }
                MilliCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            HStack(spacing: 6) {
                                Circle().fill(MilliTheme.green).frame(width: 7, height: 7)
                                SectionLabel(text: "ACTIVE TRIP")
                            }
                            Text("UberX").font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                            Spacer()
                            Text("Offer received 8:32 AM").font(.system(size: 9)).foregroundColor(MilliTheme.textSecondary)
                        }
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Pickup: LAX, Los Angeles").font(.system(size: 11)).foregroundColor(.white)
                                Text("Drop-off: Long Beach, CA").font(.system(size: 11)).foregroundColor(.white)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("$38.42 Offered").font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                                Text("+$21.18 Est. Profit").font(.system(size: 11, weight: .semibold)).foregroundColor(MilliTheme.green)
                            }
                        }
                        HStack {
                            Text("42.7 mi Total Distance").font(.system(size: 10)).foregroundColor(MilliTheme.textSecondary)
                            Spacer()
                            Text("1h 08m Est. Duration").font(.system(size: 10)).foregroundColor(MilliTheme.textSecondary)
                        }
                    }
                }
                MilliCard {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                SectionLabel(text: "BUSINESS MILEAGE")
                                Image(systemName: "info.circle").font(.system(size: 10)).foregroundColor(MilliTheme.textSecondary)
                            }
                            Text("42.7 mi").font(.system(size: 22, weight: .bold)).foregroundColor(.white)
                            Text("$28.15 Deduction Estimate").font(.system(size: 11)).foregroundColor(MilliTheme.textSecondary)
                            Text("$0.66/mi IRS Rate").font(.system(size: 10)).foregroundColor(MilliTheme.textTertiary)
                        }
                        Spacer()
                        ZStack(alignment: .bottomTrailing) {
                            RouteMapPanel().frame(width: 110, height: 80)
                            Text("42.7 mi").font(.system(size: 8, weight: .bold)).foregroundColor(MilliTheme.accent)
                                .padding(4).background(Capsule().fill(Color.black.opacity(0.7)))
                        }
                    }
                }
                HStack(spacing: 12) {
                    MilliCard {
                        VStack(alignment: .leading, spacing: 4) {
                            SectionLabel(text: "Gas & Return")
                            HStack(spacing: 4) { Image(systemName: "fuelpump").font(.system(size: 11)).foregroundColor(MilliTheme.accent) }
                            Text("$3.18 Est. Fuel Cost").font(.system(size: 12, weight: .semibold)).foregroundColor(.white)
                            Text("14.2 mi Return Distance").font(.system(size: 10)).foregroundColor(MilliTheme.textSecondary)
                        }
                    }
                    MilliCard {
                        VStack(spacing: 4) {
                            SectionLabel(text: "Profitability Score™")
                            ProgressRing(progress: 0.87, label: "87", sublabel: "Excellent")
                            Text("Top 15% of offers.").font(.system(size: 9)).foregroundColor(MilliTheme.textSecondary)
                        }.frame(maxWidth: .infinity)
                    }
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("SHOULD YOU TAKE THIS OFFER?").font(.system(size: 12, weight: .bold)).kerning(1).foregroundColor(.white)
                    HStack(spacing: 10) {
                        decisionButton(title: "GO", sub: "Highly Recommended", color: MilliTheme.green)
                        decisionButton(title: "MAYBE", sub: "Consider Factors", color: MilliTheme.gold)
                        decisionButton(title: "NO", sub: "Not Worth It", color: MilliTheme.red)
                    }
                }
            }
            .padding(MilliTheme.screenPadding)
        }
        .background(MilliTheme.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func decisionButton(title: String, sub: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title).font(.system(size: 16, weight: .heavy)).foregroundColor(color)
            Text(sub).font(.system(size: 8, weight: .semibold)).foregroundColor(MilliTheme.textSecondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 12).fill(MilliTheme.surface)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.6), lineWidth: 1)))
    }
}

// MARK: - 15. Expenses

struct ExpensesScreen: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    MilliMark(size: 22)
                    Spacer()
                    Text("Expenses").font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                    Spacer()
                    Image(systemName: "info.circle").foregroundColor(MilliTheme.textSecondary)
                }
                MilliCard {
                    HStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 4) {
                            SectionLabel(text: "TOTAL EXPENSES")
                            Text("$6,732.45").font(.system(size: 24, weight: .bold)).foregroundColor(.white)
                            HStack(spacing: 4) {
                                Text("This Month").font(.system(size: 10)).foregroundColor(MilliTheme.textSecondary)
                                Text("18% vs last month").font(.system(size: 10, weight: .semibold)).foregroundColor(MilliTheme.green)
                            }
                        }
                        Spacer()
                        ZStack {
                            DonutChart(segments: [(0.78, MilliTheme.accent), (0.22, Color(hex: 0xB8926A))])
                                .frame(width: 64, height: 64)
                            Text("78%").font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                        }
                    }
                }
                HStack(spacing: 12) {
                    MilliCard {
                        VStack(alignment: .leading, spacing: 2) {
                            SectionLabel(text: "DEDUCTIBLE")
                            Text("$5,243.18").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                            Text("78%").font(.system(size: 10)).foregroundColor(MilliTheme.textSecondary)
                        }
                    }
                    MilliCard {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("NON-DEDUCTIBLE").font(.system(size: 11, weight: .bold)).kerning(1.5).foregroundColor(MilliTheme.textSecondary)
                            Text("$1,489.27").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                            Text("22%").font(.system(size: 10)).foregroundColor(MilliTheme.textSecondary)
                        }
                    }
                }
                MilliCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            SectionLabel(text: "CATEGORY BREAKDOWN")
                            Spacer()
                            Text("View All").font(.system(size: 11, weight: .semibold)).foregroundColor(MilliTheme.accent)
                        }
                        categoryRow(icon: "fuelpump", name: "Fuel", amount: "$2,143.77", pct: "32%")
                        categoryRow(icon: "phone", name: "Phone", amount: "$896.45", pct: "13%")
                        categoryRow(icon: "wrench.and.screwdriver", name: "Maintenance", amount: "$1,278.22", pct: "19%")
                        categoryRow(icon: "road.lanes", name: "Tolls", amount: "$456.12", pct: "7%")
                        categoryRow(icon: "shippingbox", name: "Supplies", amount: "$678.43", pct: "10%")
                    }
                }
                MilliCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            SectionLabel(text: "RECENT EXPENSES")
                            Spacer()
                            Text("View All").font(.system(size: 11, weight: .semibold)).foregroundColor(MilliTheme.accent)
                        }
                        expenseRow(icon: "fuelpump", name: "Shell Fuel #12345", cat: "Fuel · Deductible", amount: "$68.45", date: "Today")
                        expenseRow(icon: "phone", name: "Verizon Wireless", cat: "Phone · Deductible", amount: "$89.99", date: "Yesterday")
                        expenseRow(icon: "wrench.and.screwdriver", name: "Jiffy Lube #112", cat: "Maintenance · Deductible", amount: "$74.50", date: "May 8, 2025")
                    }
                }
                PrimaryButton(title: "+ Add Expense")
                HStack(spacing: 12) {
                    MilliCard {
                        VStack(alignment: .leading, spacing: 4) {
                            SectionLabel(text: "CAPTURE RECEIPT")
                            Text("OCR Ready").font(.system(size: 10, weight: .semibold)).foregroundColor(MilliTheme.accent)
                            Text("Auto-categorize & extract details.").font(.system(size: 9)).foregroundColor(MilliTheme.textSecondary)
                            Spacer()
                            Image(systemName: "camera").font(.system(size: 16)).foregroundColor(MilliTheme.accent)
                        }
                    }
                    MilliCard {
                        VStack(alignment: .leading, spacing: 4) {
                            SectionLabel(text: "MONTHLY SPEND")
                            Text("$6,732.45").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                            Text("May 2025").font(.system(size: 9)).foregroundColor(MilliTheme.textSecondary)
                            Sparkline().frame(height: 30)
                        }
                    }
                }
            }
            .padding(MilliTheme.screenPadding)
        }
        .background(MilliTheme.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func categoryRow(icon: String, name: String, amount: String, pct: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 13)).foregroundColor(MilliTheme.accent).frame(width: 20)
            Text(name).font(.system(size: 12)).foregroundColor(.white)
            Spacer()
            Text(amount).font(.system(size: 12, weight: .semibold)).foregroundColor(.white)
            Text(pct).font(.system(size: 10)).foregroundColor(MilliTheme.textSecondary).frame(width: 32, alignment: .trailing)
        }
    }

    @ViewBuilder
    private func expenseRow(icon: String, name: String, cat: String, amount: String, date: String) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 6).fill(MilliTheme.surface).frame(width: 34, height: 34)
                .overlay(Image(systemName: icon).font(.system(size: 13)).foregroundColor(MilliTheme.accent))
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.system(size: 12, weight: .semibold)).foregroundColor(.white)
                Text(cat).font(.system(size: 9)).foregroundColor(MilliTheme.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(amount).font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                Text(date).font(.system(size: 9)).foregroundColor(MilliTheme.textSecondary)
            }
        }
    }
}

// MARK: - 16. Accounts & Connections

struct AccountsScreen: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    MilliMark(size: 22)
                    Spacer()
                    Text("Accounts & Connections").font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                    Spacer()
                    Image(systemName: "questionmark.circle").foregroundColor(MilliTheme.textSecondary)
                }
                MilliCard {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(text: "YOUR MILLI ACCOUNTS")
                        accountRow(icon: "M", iconColor: MilliTheme.accent, name: "MILLI OPERATING",
                                   sub: "Checking •••• 3847", amount: "$8,642.31")
                        accountRow(icon: "vault", iconColor: MilliTheme.chromeMid, name: "TAX VAULT",
                                   sub: "Set aside for taxes", amount: "$7,128.45")
                    }
                }
                MilliCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            SectionLabel(text: "LINKED BANK ACCOUNTS")
                            Spacer()
                            Text("View All").font(.system(size: 11, weight: .semibold)).foregroundColor(MilliTheme.accent)
                        }
                        linkedBankRow(name: "Chase Business Checking", masked: "•••• 8921", amount: "$14,230.10")
                        linkedBankRow(name: "Wells Fargo Business", masked: "•••• 6713", amount: "$3,452.67")
                    }
                }
                MilliCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            SectionLabel(text: "CONNECTED PLATFORMS")
                            Spacer()
                            Text("View All").font(.system(size: 11, weight: .semibold)).foregroundColor(MilliTheme.accent)
                        }
                        platformRow(name: "Uber", sub: "Payouts • Earnings")
                        platformRow(name: "DoorDash", sub: "Payouts")
                    }
                }
                HStack(spacing: 12) {
                    MilliCard {
                        VStack(alignment: .leading, spacing: 6) {
                            SectionLabel(text: "MILLI CARD")
                            MilliCardVisual()
                            HStack {
                                Text("Manage Card").font(.system(size: 11)).foregroundColor(.white)
                                Spacer()
                                Image(systemName: "chevron.right").font(.system(size: 10)).foregroundColor(MilliTheme.textTertiary)
                            }
                        }
                    }
                    MilliCard {
                        VStack(spacing: 6) {
                            SectionLabel(text: "CONNECTION HEALTH")
                            ProgressRing(progress: 1.0, label: "100%", lineWidth: 5)
                            Text("All systems go").font(.system(size: 10)).foregroundColor(.white)
                            Text("Last checked Today, 8:24 AM").font(.system(size: 8)).foregroundColor(MilliTheme.textSecondary)
                        }.frame(maxWidth: .infinity)
                    }
                }
                PrimaryButton(title: "+ Connect an Account")
                HStack(spacing: 6) {
                    Image(systemName: "lock").font(.system(size: 10)).foregroundColor(MilliTheme.textSecondary)
                    Text("Secure. Encrypted. You're in control.").font(.system(size: 10)).foregroundColor(MilliTheme.textSecondary)
                }.frame(maxWidth: .infinity)
            }
            .padding(MilliTheme.screenPadding)
        }
        .background(MilliTheme.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func accountRow(icon: String, iconColor: Color, name: String, sub: String, amount: String) -> some View {
        HStack(spacing: 10) {
            Circle().fill(MilliTheme.surface).frame(width: 34, height: 34)
                .overlay(Circle().stroke(iconColor.opacity(0.6), lineWidth: 1))
                .overlay(Text(icon).font(.system(size: 12, weight: .bold)).foregroundColor(iconColor))
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                Text(sub).font(.system(size: 9)).foregroundColor(MilliTheme.textSecondary)
            }
            Spacer()
            Text(amount).font(.system(size: 14, weight: .bold)).foregroundColor(.white)
            Image(systemName: "chevron.right").font(.system(size: 10)).foregroundColor(MilliTheme.textTertiary)
        }
    }

    @ViewBuilder
    private func linkedBankRow(name: String, masked: String, amount: String) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 6).fill(MilliTheme.blue.opacity(0.25)).frame(width: 32, height: 32)
                .overlay(Image(systemName: "building.columns").font(.system(size: 13)).foregroundColor(MilliTheme.blue))
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.system(size: 12, weight: .semibold)).foregroundColor(.white)
                Text(masked).font(.system(size: 9)).foregroundColor(MilliTheme.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(amount).font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                Text("Connected").font(.system(size: 9, weight: .semibold)).foregroundColor(MilliTheme.green)
            }
        }
    }

    @ViewBuilder
    private func platformRow(name: String, sub: String) -> some View {
        HStack(spacing: 10) {
            Circle().fill(MilliTheme.surface).frame(width: 30, height: 30)
                .overlay(Text(String(name.prefix(1))).font(.system(size: 12, weight: .bold)).foregroundColor(MilliTheme.textSecondary))
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.system(size: 12, weight: .semibold)).foregroundColor(.white)
                Text(sub).font(.system(size: 9)).foregroundColor(MilliTheme.textSecondary)
            }
            Spacer()
            Text("Connected").font(.system(size: 9, weight: .semibold)).foregroundColor(MilliTheme.green)
        }
    }
}

// MARK: - 17. Wealth Overview

struct WealthOverviewScreen: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    MilliMark(size: 22)
                    Spacer()
                    Text("Wealth Overview").font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                    Spacer()
                    Image(systemName: "info.circle").foregroundColor(MilliTheme.textSecondary)
                }
                MilliCard {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            SectionLabel(text: "TOTAL WEALTH")
                            Text("$128,473.56").font(.system(size: 24, weight: .bold)).foregroundColor(.white)
                            Text("All accounts · ↑ 18.6% vs last year").font(.system(size: 10)).foregroundColor(MilliTheme.accent)
                        }
                        Spacer()
                        ZStack {
                            Circle().stroke(MilliTheme.accent.opacity(0.4), lineWidth: 4).frame(width: 56, height: 56)
                            MilliMark(size: 18)
                        }
                    }
                }
                HStack(spacing: 12) {
                    MilliCard {
                        VStack(spacing: 6) {
                            SectionLabel(text: "Portfolio Allocation")
                            ZStack {
                                DonutChart(segments: [(0.70, MilliTheme.accent), (0.20, MilliTheme.chromeMid), (0.10, MilliTheme.gold)])
                                    .frame(width: 56, height: 56)
                                Text("70%").font(.system(size: 11, weight: .bold)).foregroundColor(.white)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                legendRow(color: MilliTheme.accent, label: "70% Investments")
                                legendRow(color: MilliTheme.chromeMid, label: "20% Cash")
                                legendRow(color: MilliTheme.gold, label: "10% Other")
                            }
                        }
                    }
                    VStack(spacing: 12) {
                        MilliCard {
                            VStack(alignment: .leading, spacing: 3) {
                                SectionLabel(text: "Cash Reserve")
                                Text("$18,247.31").font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                                Text("Available · 6.2 months runway").font(.system(size: 9)).foregroundColor(MilliTheme.textSecondary)
                            }
                        }
                        MilliCard {
                            VStack(alignment: .leading, spacing: 3) {
                                SectionLabel(text: "Retirement Balance")
                                Text("$54,821.17").font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                                Text("On track · ↑ 12.4% this year").font(.system(size: 9)).foregroundColor(MilliTheme.accent)
                            }
                        }
                    }
                }
                MilliCard {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            SectionLabel(text: "Wealth Performance")
                            Spacer()
                            Text("This Year").font(.system(size: 10, weight: .semibold)).foregroundColor(MilliTheme.textSecondary)
                        }
                        HStack(spacing: 10) {
                            Text("↑ 18.6%").font(.system(size: 20, weight: .bold)).foregroundColor(MilliTheme.accent)
                            Text("$20,173.65 Growth").font(.system(size: 11)).foregroundColor(MilliTheme.textSecondary)
                        }
                        Sparkline().frame(height: 50)
                    }
                }
                HStack(spacing: 12) {
                    MilliCard {
                        VStack(alignment: .leading, spacing: 4) {
                            SectionLabel(text: "Round-Ups & Contributions")
                            Text("$342.18").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                            Text("This month · ↑ 28% vs last month").font(.system(size: 9)).foregroundColor(MilliTheme.accent)
                            HStack(spacing: 3) {
                                ForEach([0.4, 0.7, 0.5, 0.9, 0.6, 1.0], id: \.self) { h in
                                    Capsule().fill(MilliTheme.accent.opacity(0.7)).frame(width: 6, height: CGFloat(h) * 24)
                                }
                            }.padding(.top, 4)
                        }
                    }
                    MilliCard {
                        VStack(alignment: .leading, spacing: 6) {
                            SectionLabel(text: "MILLI Card")
                            MilliCardVisual()
                            Text("Card Controls >").font(.system(size: 10, weight: .semibold)).foregroundColor(MilliTheme.accent)
                        }
                    }
                }
                MilliCard {
                    HStack(spacing: 10) {
                        MilliAICharacterView(size: 34)
                        VStack(alignment: .leading, spacing: 2) {
                            SectionLabel(text: "AI Insight")
                            Text("You're trending ahead of your goal by $2,410 this month.")
                                .font(.system(size: 11)).foregroundColor(MilliTheme.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.system(size: 11)).foregroundColor(MilliTheme.textTertiary)
                    }
                }
            }
            .padding(MilliTheme.screenPadding)
        }
        .background(MilliTheme.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func legendRow(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label).font(.system(size: 9)).foregroundColor(MilliTheme.textSecondary)
        }
    }
}

// MARK: - 18. Investing

struct InvestingScreen: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    MilliMark(size: 22)
                    Spacer()
                    Text("Investing").font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                    Spacer()
                    Image(systemName: "info.circle").foregroundColor(MilliTheme.textSecondary)
                }
                MilliCard {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel(text: "TOTAL ACCOUNT VALUE")
                        Text("$5,210.76").font(.system(size: 26, weight: .bold)).foregroundColor(.white)
                        Text("+$742.18 (16.58%) · All time return").font(.system(size: 11, weight: .semibold)).foregroundColor(MilliTheme.green)
                        Sparkline().frame(height: 60)
                        HStack(spacing: 6) {
                            ForEach(["1D", "1W", "1M", "3M", "6M", "1Y", "ALL"], id: \.self) { range in
                                Text(range).font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(range == "1Y" ? Color(hex: 0x04121A) : MilliTheme.textSecondary)
                                    .padding(.horizontal, 9).padding(.vertical, 4)
                                    .background(Capsule().fill(range == "1Y" ? MilliTheme.accent : Color.white.opacity(0.06)))
                            }
                        }
                    }
                }
                MilliCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            SectionLabel(text: "HOLDINGS")
                            Spacer()
                            Text("View All").font(.system(size: 11, weight: .semibold)).foregroundColor(MilliTheme.accent)
                        }
                        holdingRow(ticker: "VTI", name: "Vanguard Total Stock Market", value: "$2,103.45", gain: "+18.42%")
                        holdingRow(ticker: "VOO", name: "Vanguard S&P 500 ETF", value: "$1,310.22", gain: "+15.28%")
                        holdingRow(ticker: "QQQM", name: "Invesco NASDAQ 100 ETF", value: "$956.18", gain: "+20.11%")
                        holdingRow(ticker: "BND", name: "Vanguard Total Bond Market", value: "$480.91", gain: "+6.35%")
                        holdingRow(ticker: "GLD", name: "SPDR Gold Shares", value: "$360.00", gain: "+11.02%")
                    }
                }
                HStack(spacing: 12) {
                    MilliCard {
                        VStack(spacing: 6) {
                            SectionLabel(text: "Portfolio Mix")
                            ZStack {
                                DonutChart(segments: [(0.65, MilliTheme.accent), (0.15, MilliTheme.blue),
                                                     (0.12, MilliTheme.gold), (0.05, MilliTheme.green),
                                                     (0.03, MilliTheme.chromeMid)]).frame(width: 54, height: 54)
                            }
                            VStack(alignment: .leading, spacing: 1) {
                                ForEach([("US Stocks", "65%", MilliTheme.accent), ("Int'l Stocks", "15%", MilliTheme.blue),
                                         ("Bonds", "12%", MilliTheme.gold), ("Alternatives", "5%", MilliTheme.green),
                                         ("Cash", "3%", MilliTheme.chromeMid)], id: \.0) { item in
                                    HStack(spacing: 4) {
                                        Circle().fill(item.2).frame(width: 5, height: 5)
                                        Text("\(item.0) \(item.1)").font(.system(size: 8)).foregroundColor(MilliTheme.textSecondary)
                                    }
                                }
                            }
                        }
                    }
                    MilliCard {
                        VStack(spacing: 6) {
                            SectionLabel(text: "Risk Level")
                            Text("Moderate").font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                            ZStack {
                                Circle().trim(from: 0, to: 0.5).stroke(Color.white.opacity(0.1), lineWidth: 5)
                                    .rotationEffect(.degrees(180)).frame(width: 60, height: 60)
                                Circle().trim(from: 0, to: 0.28).stroke(MilliTheme.accent, lineWidth: 5)
                                    .rotationEffect(.degrees(180)).frame(width: 60, height: 60)
                            }
                            Text("Balanced growth with moderate risk.").font(.system(size: 8)).foregroundColor(MilliTheme.textSecondary)
                        }.frame(maxWidth: .infinity)
                    }
                }
                MilliCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            SectionLabel(text: "RECURRING CONTRIBUTION")
                            Text("$250 · Every week").font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                        }
                        Spacer()
                        Text("Edit").font(.system(size: 11, weight: .semibold)).foregroundColor(MilliTheme.accent)
                        HStack(spacing: 10) {
                            Image(systemName: "minus.circle").foregroundColor(MilliTheme.textSecondary)
                            Image(systemName: "plus.circle").foregroundColor(MilliTheme.accent)
                        }
                    }
                }
                MilliCard {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            SectionLabel(text: "INVESTMENT STRATEGY")
                            Spacer()
                            Text("Learn more").font(.system(size: 10)).foregroundColor(MilliTheme.accent)
                        }
                        Text("Choose your preferred approach.").font(.system(size: 10)).foregroundColor(MilliTheme.textSecondary)
                        HStack(spacing: 8) {
                            ForEach(["Conservative", "Moderate", "Aggressive"], id: \.self) { strategy in
                                Text(strategy).font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(strategy == "Moderate" ? Color(hex: 0x04121A) : MilliTheme.textSecondary)
                                    .frame(maxWidth: .infinity).padding(.vertical, 9)
                                    .background(Capsule().fill(strategy == "Moderate" ? MilliTheme.accent : Color.white.opacity(0.06)))
                            }
                        }
                    }
                }
            }
            .padding(MilliTheme.screenPadding)
        }
        .background(MilliTheme.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func holdingRow(ticker: String, name: String, value: String, gain: String) -> some View {
        HStack(spacing: 10) {
            Circle().fill(MilliTheme.surface).frame(width: 30, height: 30)
                .overlay(Text(ticker.prefix(1)).font(.system(size: 11, weight: .bold)).foregroundColor(MilliTheme.accent))
            VStack(alignment: .leading, spacing: 1) {
                Text(ticker).font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                Text(name).font(.system(size: 9)).foregroundColor(MilliTheme.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                Text(value).font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                Text(gain).font(.system(size: 10, weight: .semibold)).foregroundColor(MilliTheme.accent)
            }
        }
    }
}

// MARK: - 19. Retirement

struct RetirementScreen: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    MilliMark(size: 22)
                    Spacer()
                    Text("Retirement").font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                    Spacer()
                    Image(systemName: "info.circle").foregroundColor(MilliTheme.textSecondary)
                }
                MilliCard {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            SectionLabel(text: "PROJECTED RETIREMENT")
                            Text("2041").font(.system(size: 34, weight: .bold)).foregroundColor(.white)
                            Text("Age 65").font(.system(size: 11)).foregroundColor(MilliTheme.textSecondary)
                        }
                        Spacer()
                        ProgressRing(progress: 0.5, label: "19", sublabel: "Years to go")
                    }
                }
                MilliCard {
                    VStack(alignment: .leading, spacing: 6) {
                        SectionLabel(text: "TOTAL RETIREMENT BALANCE")
                        Text("$2,341,087.56").font(.system(size: 24, weight: .bold)).foregroundColor(.white)
                        Text("+ $342,587 (17.1%) this year").font(.system(size: 11, weight: .semibold)).foregroundColor(MilliTheme.green)
                        Sparkline().frame(height: 50)
                    }
                }
                HStack(spacing: 10) {
                    miniStat(label: "ANNUAL GROWTH", value: "7.2%", sub: "Average")
                    miniStat(label: "YOUR CONTRIBUTION", value: "15%", sub: "of Salary")
                    miniStat(label: "EMPLOYER MATCH", value: "4%", sub: "Full Match")
                }
                HStack(spacing: 12) {
                    MilliCard {
                        VStack(alignment: .leading, spacing: 3) {
                            SectionLabel(text: "TARGET INCOME")
                            Text("$120,000 /yr").font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                            Text("In today's dollars").font(.system(size: 9)).foregroundColor(MilliTheme.textSecondary)
                        }
                    }
                    MilliCard {
                        VStack(spacing: 4) {
                            SectionLabel(text: "RETIREMENT TARGET")
                            ProgressRing(progress: 0.82, label: "82%", lineWidth: 5)
                            Text("On track").font(.system(size: 10, weight: .semibold)).foregroundColor(MilliTheme.accent)
                        }.frame(maxWidth: .infinity)
                    }
                }
                MilliCard {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            SectionLabel(text: "10-YEAR FORECAST")
                            Spacer()
                            HStack(spacing: 10) {
                                legendDot(color: MilliTheme.accent, label: "Projected Balance")
                                legendDot(color: MilliTheme.textTertiary, label: "Target Range")
                            }
                        }
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.05)).frame(height: 90)
                            Sparkline(points: [0.1, 0.2, 0.3, 0.45, 0.55, 0.7, 0.85])
                                .padding(8).frame(height: 90)
                        }
                        HStack {
                            ForEach(["2024", "2028", "2032", "2036"], id: \.self) { year in
                                Text(year).font(.system(size: 9)).foregroundColor(MilliTheme.textTertiary)
                                if year != "2036" { Spacer() }
                            }
                        }
                        HStack {
                            ForEach(["$0", "$1M", "$2.5M", "$4M"], id: \.self) { s in
                                Text(s).font(.system(size: 8)).foregroundColor(MilliTheme.textTertiary)
                                if s != "$4M" { Spacer() }
                            }
                        }
                    }
                }
            }
            .padding(MilliTheme.screenPadding)
        }
        .background(MilliTheme.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func miniStat(label: String, value: String, sub: String) -> some View {
        MilliCard {
            VStack(spacing: 3) {
                Text(label).font(.system(size: 8, weight: .bold)).kerning(0.5).foregroundColor(MilliTheme.textSecondary)
                Text(value).font(.system(size: 17, weight: .bold)).foregroundColor(.white)
                Text(sub).font(.system(size: 9)).foregroundColor(MilliTheme.textTertiary)
            }.frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label).font(.system(size: 9)).foregroundColor(MilliTheme.textSecondary)
        }
    }
}

// MARK: - 20. Tree of Life Planner

struct TreeOfLifeScreen: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: "chevron.left").foregroundColor(MilliTheme.textSecondary)
                    Spacer()
                    Text("Tree of Life Planner").font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                    Spacer()
                    Image(systemName: "info.circle").foregroundColor(MilliTheme.textSecondary)
                }
                MilliCard {
                    VStack(alignment: .leading, spacing: 4) {
                        SectionLabel(text: "PROJECTED NET WORTH")
                        Text("$5,284,170").font(.system(size: 28, weight: .bold)).foregroundColor(.white)
                        Text("at age 65").font(.system(size: 11)).foregroundColor(MilliTheme.textSecondary)
                        Text("Today: $2,341,080").font(.system(size: 11, weight: .semibold)).foregroundColor(MilliTheme.accent)
                    }
                }
                ZStack {
                    RoundedRectangle(cornerRadius: 16).fill(
                        LinearGradient(colors: [Color(hex: 0x0A1220), Color(hex: 0x05090D)],
                                       startPoint: .top, endPoint: .bottom))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 0.5))
                    TreeIllustration().frame(height: 190)
                }
                HStack(spacing: 12) {
                    MilliCard {
                        VStack(alignment: .leading, spacing: 2) {
                            SectionLabel(text: "Contributions")
                            Text("$2.3M · 43%").font(.system(size: 15, weight: .bold)).foregroundColor(MilliTheme.accent)
                        }
                    }
                    MilliCard {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Growth").font(.system(size: 11, weight: .bold)).kerning(1).foregroundColor(MilliTheme.gold)
                            Text("$3.0M · 57%").font(.system(size: 15, weight: .bold)).foregroundColor(MilliTheme.gold)
                        }
                    }
                }
                MilliCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            SectionLabel(text: "KEY LIFE EVENTS")
                            Spacer()
                            Text("View All").font(.system(size: 11, weight: .semibold)).foregroundColor(MilliTheme.accent)
                        }
                        HStack(alignment: .top, spacing: 0) {
                            lifeEvent(icon: "heart.fill", title: "Marriage", age: "Age 28", date: "Jun 2026")
                            lifeEvent(icon: "figure.and.child.holdinghands", title: "First Child", age: "Age 31", date: "May 2029")
                            lifeEvent(icon: "house.fill", title: "Dream Home", age: "Age 33", date: "Aug 2031")
                            lifeEvent(icon: "figure.walk", title: "Retirement", age: "Age 65", date: "Mar 2063")
                        }
                    }
                }
                MilliCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            SectionLabel(text: "PLANNING ADJUSTMENTS")
                            Spacer()
                            Text("View All").font(.system(size: 11, weight: .semibold)).foregroundColor(MilliTheme.accent)
                        }
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Text("Savings Rate").font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                                    Text("15%").font(.system(size: 13, weight: .bold)).foregroundColor(MilliTheme.accent)
                                    Text("Recommended").font(.system(size: 8, weight: .bold)).foregroundColor(MilliTheme.accent)
                                        .padding(.horizontal, 6).padding(.vertical, 2)
                                        .background(Capsule().stroke(MilliTheme.accent.opacity(0.6), lineWidth: 1))
                                }
                                Text("On Track, great job! You're on track for your goals.")
                                    .font(.system(size: 10)).foregroundColor(MilliTheme.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "checkmark.circle.fill").foregroundColor(MilliTheme.accent)
                        }
                        Divider().overlay(Color.white.opacity(0.08))
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Text("Risk Tolerance").font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                                    Text("Moderate").font(.system(size: 13, weight: .bold)).foregroundColor(MilliTheme.accent)
                                }
                                Text("Balanced style.").font(.system(size: 10)).foregroundColor(MilliTheme.textSecondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("In 90 Days").font(.system(size: 11, weight: .semibold)).foregroundColor(.white)
                                Text("June 28, 2025").font(.system(size: 9)).foregroundColor(MilliTheme.textSecondary)
                                Image(systemName: "calendar").font(.system(size: 11)).foregroundColor(MilliTheme.accent)
                            }
                        }
                    }
                }
                PrimaryButton(title: "Run New Projection")
            }
            .padding(MilliTheme.screenPadding)
        }
        .background(MilliTheme.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func lifeEvent(icon: String, title: String, age: String, date: String) -> some View {
        VStack(spacing: 6) {
            Circle().fill(MilliTheme.surface).frame(width: 34, height: 34)
                .overlay(Circle().stroke(MilliTheme.accent.opacity(0.5), lineWidth: 1))
                .overlay(Image(systemName: icon).font(.system(size: 12)).foregroundColor(MilliTheme.accent))
            Text(title).font(.system(size: 10, weight: .semibold)).foregroundColor(.white)
            Text(age).font(.system(size: 9)).foregroundColor(MilliTheme.textSecondary)
            Text(date).font(.system(size: 8)).foregroundColor(MilliTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

/// Stylized luminous tree: cyan canopy dots, gold trunk/roots.
struct TreeIllustration: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                Path { p in
                    p.move(to: CGPoint(x: w/2, y: h * 0.35))
                    p.addLine(to: CGPoint(x: w/2 - 6, y: h * 0.75))
                    p.addLine(to: CGPoint(x: w/2 + 6, y: h * 0.75))
                    p.closeSubpath()
                }
                .fill(LinearGradient(colors: [MilliTheme.gold, Color(hex: 0x8A6A2A)], startPoint: .top, endPoint: .bottom))
                Path { p in
                    p.move(to: CGPoint(x: w/2, y: h * 0.75))
                    p.addLine(to: CGPoint(x: w/2 - 50, y: h * 0.95))
                    p.move(to: CGPoint(x: w/2, y: h * 0.75))
                    p.addLine(to: CGPoint(x: w/2 + 50, y: h * 0.95))
                    p.move(to: CGPoint(x: w/2, y: h * 0.75))
                    p.addLine(to: CGPoint(x: w/2, y: h * 0.97))
                }
                .stroke(Color(hex: 0xB08A3A), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                Path { p in
                    p.move(to: CGPoint(x: w/2, y: h * 0.45))
                    p.addLine(to: CGPoint(x: w/2 - 45, y: h * 0.25))
                    p.move(to: CGPoint(x: w/2, y: h * 0.45))
                    p.addLine(to: CGPoint(x: w/2 + 45, y: h * 0.25))
                    p.move(to: CGPoint(x: w/2, y: h * 0.40))
                    p.addLine(to: CGPoint(x: w/2, y: h * 0.15))
                }
                .stroke(Color(hex: 0xB08A3A), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                ForEach(0..<26, id: \.self) { i in
                    let angle = Double(i) * 2.4
                    let r = 40.0 + Double(i % 5) * 12
                    Circle()
                        .fill(MilliTheme.accent.opacity(i % 3 == 0 ? 0.9 : 0.35))
                        .frame(width: i % 4 == 0 ? 6 : 3, height: i % 4 == 0 ? 6 : 3)
                        .shadow(color: MilliTheme.accent.opacity(0.8), radius: 3)
                        .position(x: w/2 + CGFloat(cos(angle) * r),
                                  y: h * 0.22 + CGFloat(sin(angle) * r * 0.6))
                }
            }
        }
    }
}

// MARK: - 21. Planning Adjustments

struct PlanningAdjustmentsScreen: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: "chevron.left").foregroundColor(MilliTheme.textSecondary)
                    Spacer()
                    Text("Planning Adjustments").font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                    Spacer()
                    Image(systemName: "info.circle").foregroundColor(MilliTheme.textSecondary)
                }
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Optimize today. Elevate tomorrow.").font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                        Text("Small adjustments now can create extraordinary outcomes later.")
                            .font(.system(size: 11)).foregroundColor(MilliTheme.textSecondary)
                    }
                    Spacer()
                    TreeIllustration().frame(width: 70, height: 70)
                }
                MilliCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            SectionLabel(text: "ADJUSTMENT SUMMARY")
                            Spacer()
                            Text("All values in today's dollars").font(.system(size: 9)).foregroundColor(MilliTheme.textTertiary)
                        }
                        adjustmentRow(label: "Contribution Rate", from: "10%", to: "13%", benefit: "+3% of income")
                        adjustmentRow(label: "Retirement Age", from: "65", to: "66", benefit: "+1 Year")
                        adjustmentRow(label: "Monthly Target", from: "$3,200", to: "$3,600", benefit: "+$400 per month")
                        adjustmentRow(label: "Savings Rate", from: "15%", to: "18%", benefit: "+3% of income")
                        adjustmentRow(label: "Goal Timing", from: "On Track", to: "Ahead", benefit: "+2 Years advantage")
                    }
                }
                MilliCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            SectionLabel(text: "WEALTH PATH COMPARISON")
                            Spacer()
                            HStack(spacing: 10) {
                                HStack(spacing: 4) { Circle().fill(MilliTheme.accent).frame(width: 6, height: 6)
                                    Text("Current Path").font(.system(size: 9)).foregroundColor(MilliTheme.textSecondary) }
                                HStack(spacing: 4) { Circle().fill(MilliTheme.textTertiary).frame(width: 6, height: 6)
                                    Text("Recommended Path").font(.system(size: 9)).foregroundColor(MilliTheme.textSecondary) }
                            }
                        }
                        ZStack {
                            RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.04)).frame(height: 110)
                            VStack(alignment: .leading) {
                                Sparkline(points: [0.1, 0.25, 0.4, 0.55, 0.75, 0.95]).padding(10)
                                Spacer()
                            }.frame(height: 110)
                            VStack(alignment: .trailing) {
                                Spacer()
                                HStack { Spacer(); Text("$10.42M").font(.system(size: 11, weight: .bold)).foregroundColor(MilliTheme.accent) }
                                Text("$6.58M").font(.system(size: 10)).foregroundColor(MilliTheme.textTertiary)
                            }.padding(10)
                        }
                        HStack {
                            Text("Today").font(.system(size: 9)).foregroundColor(MilliTheme.textTertiary)
                            Spacer()
                            Text("Age 95").font(.system(size: 9)).foregroundColor(MilliTheme.textTertiary)
                        }
                        HStack(spacing: 12) {
                            outcomeTile(value: "+$3.84M", label: "Additional Wealth")
                            ProgressRing(progress: 0.58, label: "+58%", lineWidth: 5)
                            outcomeTile(value: "+2 Years", label: "Ahead of Plan")
                        }
                    }
                }
                MilliCard {
                    HStack(spacing: 10) {
                        MilliAICharacterView(size: 34)
                        VStack(alignment: .leading, spacing: 2) {
                            SectionLabel(text: "MILLI AI INSIGHT")
                            Text("These adjustments increase your probability of financial freedom to 92% and add $3.84M to your projected legacy.")
                                .font(.system(size: 10)).foregroundColor(MilliTheme.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.system(size: 11)).foregroundColor(MilliTheme.textTertiary)
                    }
                }
                PrimaryButton(title: "Apply Adjustments")
                Text("You can review or revert anytime.").font(.system(size: 10))
                    .foregroundColor(MilliTheme.textTertiary).frame(maxWidth: .infinity)
            }
            .padding(MilliTheme.screenPadding)
        }
        .background(MilliTheme.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func adjustmentRow(label: String, from: String, to: String, benefit: String) -> some View {
        HStack(spacing: 8) {
            Circle().stroke(MilliTheme.accent, lineWidth: 1).frame(width: 22, height: 22)
                .overlay(Image(systemName: "arrow.right").font(.system(size: 9)).foregroundColor(MilliTheme.accent))
            Text(label).font(.system(size: 12)).foregroundColor(.white)
            Spacer()
            Text(from).font(.system(size: 12)).foregroundColor(MilliTheme.textSecondary)
            Image(systemName: "arrow.right").font(.system(size: 9)).foregroundColor(MilliTheme.textTertiary)
            Text(to).font(.system(size: 12, weight: .bold)).foregroundColor(MilliTheme.accent)
            Text(benefit).font(.system(size: 9)).foregroundColor(MilliTheme.textTertiary)
        }
    }

    @ViewBuilder
    private func outcomeTile(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value).font(.system(size: 14, weight: .bold)).foregroundColor(MilliTheme.accent)
            Text(label).font(.system(size: 9)).foregroundColor(MilliTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.04)))
    }
}

// MARK: - 22. Milli AI Chat

struct MilliAIChatScreen: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    MilliMark(size: 22)
                    Spacer()
                    Text("MILLI AI").font(.system(size: 14, weight: .bold)).kerning(3).foregroundColor(.white)
                    Spacer()
                    Image(systemName: "shield").foregroundColor(MilliTheme.textSecondary)
                }
                MilliCard {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Hi Alex,").font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                            Text("I'm Milli AI.").font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                            Text("Your intelligent finance copilot. Here to simplify, protect, and help you grow.")
                                .font(.system(size: 11)).foregroundColor(MilliTheme.textSecondary)
                        }
                        Spacer()
                        MilliAICharacterView(size: 70)
                    }
                }
                chatBubble(ai: true, text: "Good morning, Alex! How can I help you with your money today?", time: "9:41 AM")
                chatBubble(ai: false, text: "How much should I set aside for quarterly taxes based on my income this year?", time: "9:41 AM")
                chatBubble(ai: true, text: "I recommend setting aside $7,184.51 for your next quarterly estimated tax payment. Want me to transfer funds or set up automated savings?", time: "9:41 AM")
                VStack(alignment: .leading, spacing: 8) {
                    Text("Try asking Milli AI").font(.system(size: 11, weight: .semibold)).foregroundColor(MilliTheme.textSecondary)
                    FlowChips(items: ["Estimate quarterly taxes", "Analyze an offer", "Review my tax vault", "Track a trip", "Plan retirement"])
                }
                HStack(spacing: 10) {
                    HStack {
                        Text("Ask Milli AI anything…").font(.system(size: 12)).foregroundColor(MilliTheme.textTertiary)
                        Spacer()
                        Image(systemName: "mic").font(.system(size: 13)).foregroundColor(MilliTheme.textSecondary)
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 22).fill(MilliTheme.surface)
                        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.10), lineWidth: 0.5)))
                    ZStack {
                        Circle().stroke(MilliTheme.accent, lineWidth: 1.5).frame(width: 40, height: 40)
                        Image(systemName: "paperplane.fill").font(.system(size: 14)).foregroundColor(MilliTheme.accent)
                    }
                }
                HStack(spacing: 6) {
                    Image(systemName: "lock").font(.system(size: 10)).foregroundColor(MilliTheme.textSecondary)
                    Text("Milli AI uses bank-level encryption. Your data stays private and secure.")
                        .font(.system(size: 10)).foregroundColor(MilliTheme.textSecondary)
                }.frame(maxWidth: .infinity)
                MilliCard {
                    HStack(spacing: 8) {
                        trustCol(icon: "lock.shield", title: "Private by Design", sub: "Your data is encrypted and unreadable.")
                        trustCol(icon: "doc.text.magnifyingglass", title: "Auditable Insights", sub: "Every recommendation is traceable.")
                        trustCol(icon: "brain", title: "Intelligent Copilot", sub: "Contextual help that gets smarter over time.")
                    }
                }
            }
            .padding(MilliTheme.screenPadding)
        }
        .background(MilliTheme.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func chatBubble(ai: Bool, text: String, time: String) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            if ai {
                Circle().fill(MilliTheme.surface).frame(width: 28, height: 28)
                    .overlay(MilliAICharacterView(size: 26))
            }
            VStack(alignment: ai ? .leading : .trailing, spacing: 3) {
                Text(text).font(.system(size: 12)).foregroundColor(.white)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 14)
                        .fill(ai ? MilliTheme.surface : Color(hex: 0x0A2A33))
                        .overlay(RoundedRectangle(cornerRadius: 14)
                            .stroke(ai ? Color.white.opacity(0.08) : MilliTheme.accent.opacity(0.5), lineWidth: 0.8)))
                HStack(spacing: 3) {
                    Text(time).font(.system(size: 8)).foregroundColor(MilliTheme.textTertiary)
                    if !ai { Image(systemName: "checkmark").font(.system(size: 8)).foregroundColor(MilliTheme.accent) }
                }
            }
            if !ai { Spacer(minLength: 40) } else { Spacer() }
        }
    }

    @ViewBuilder
    private func trustCol(icon: String, title: String, sub: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 14)).foregroundColor(MilliTheme.accent)
            Text(title).font(.system(size: 10, weight: .bold)).foregroundColor(.white).multilineTextAlignment(.center)
            Text(sub).font(.system(size: 8)).foregroundColor(MilliTheme.textSecondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

/// Wrapping chip row.
struct FlowChips: View {
    let items: [String]
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 8)], spacing: 8) {
            ForEach(items, id: \.self) { item in
                HStack(spacing: 6) {
                    Image(systemName: "sparkle").font(.system(size: 9)).foregroundColor(MilliTheme.accent)
                    Text(item).font(.system(size: 10, weight: .medium)).foregroundColor(.white).lineLimit(1)
                }
                .padding(.horizontal, 10).padding(.vertical, 8)
                .background(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
            }
        }
    }
}

// MARK: - 23. AI Action Confirmation

struct AIActionConfirmationScreen: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: "xmark").foregroundColor(MilliTheme.textSecondary)
                    Spacer()
                    VStack(spacing: 4) {
                        Image(systemName: "checkmark.shield.fill").font(.system(size: 22)).foregroundColor(MilliTheme.accent)
                            .shadow(color: MilliTheme.accent.opacity(0.7), radius: 6)
                        Text("AI Action Confirmation").font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                        Text("Review & Authorize").font(.system(size: 10)).foregroundColor(MilliTheme.textSecondary)
                    }
                    Spacer()
                    MilliAICharacterView(size: 34)
                }
                MilliCard {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(text: "ACTION TO AUTHORIZE")
                        HStack(alignment: .top) {
                            Text("Move $325.40 to ").font(.system(size: 17, weight: .bold)).foregroundColor(.white)
                                + Text("Milli Tax Vault™").font(.system(size: 17, weight: .bold)).foregroundColor(MilliTheme.accent)
                            Spacer()
                            Circle().stroke(MilliTheme.accent, lineWidth: 1.5).frame(width: 38, height: 38)
                                .overlay(Image(systemName: "arrow.triangle.2.circlepath").font(.system(size: 14)).foregroundColor(MilliTheme.accent))
                        }
                        detailKV(icon: "banknote", label: "From", value: "Milli Checking •••• 3847", sub: "Available Balance: $8,642.31")
                        detailKV(icon: "lock.shield", label: "To", value: "Milli Tax Vault™", sub: "Protected Savings Vault")
                        detailKV(icon: "dollarsign", label: "Amount", value: "$325.40", sub: "", highlight: true)
                        detailKV(icon: "clock", label: "When", value: "Today, Immediately", sub: "")
                        detailKV(icon: "tag", label: "Category", value: "Tax Savings Allocation", sub: "")
                        HStack {
                            Text("AI Recommendation").font(.system(size: 11)).foregroundColor(MilliTheme.textSecondary)
                            Spacer()
                            Text("Optimized").font(.system(size: 10, weight: .bold)).foregroundColor(MilliTheme.accent)
                                .padding(.horizontal, 10).padding(.vertical, 4)
                                .background(Capsule().stroke(MilliTheme.accent.opacity(0.7), lineWidth: 1))
                        }
                        Divider().overlay(Color.white.opacity(0.08))
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 4) {
                                    Image(systemName: "lock").font(.system(size: 10)).foregroundColor(MilliTheme.accent)
                                    Text("Protection").font(.system(size: 10, weight: .semibold)).foregroundColor(.white)
                                }
                                Text("Bank-grade encryption 256-bit AES").font(.system(size: 9)).foregroundColor(MilliTheme.textSecondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Audit Receipt ID").font(.system(size: 9)).foregroundColor(MilliTheme.textSecondary)
                                HStack(spacing: 4) {
                                    Text("RCP-2025-05-08-9A7F").font(.system(size: 10, weight: .semibold)).foregroundColor(.white)
                                    Image(systemName: "doc.on.doc").font(.system(size: 9)).foregroundColor(MilliTheme.textSecondary)
                                }
                            }
                        }
                    }
                }
                MilliCard {
                    HStack(spacing: 12) {
                        Image(systemName: "faceid").font(.system(size: 26)).foregroundColor(MilliTheme.accent)
                            .shadow(color: MilliTheme.accent.opacity(0.7), radius: 6)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Confirm with Face ID").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                            Text("Securely authorize this action").font(.system(size: 10)).foregroundColor(MilliTheme.textSecondary)
                        }
                        Spacer()
                        MilliAICharacterView(size: 40)
                    }
                }
                HStack(spacing: 12) {
                    Text("Cancel").font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 14).fill(MilliTheme.surface)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(MilliTheme.accent.opacity(0.4), lineWidth: 1)))
                    Text("Confirm & Move").font(.system(size: 14, weight: .semibold)).foregroundColor(Color(hex: 0x04121A))
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 14)
                            .fill(LinearGradient(colors: [MilliTheme.accent, MilliTheme.accentDeep],
                                                 startPoint: .leading, endPoint: .trailing)))
                }
                MilliCard {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill").font(.system(size: 20)).foregroundColor(MilliTheme.accent)
                                .shadow(color: MilliTheme.accent.opacity(0.8), radius: 5)
                            Text("Action Confirmed").font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                        }
                        Text("$325.40 moved to Milli Tax Vault™").font(.system(size: 12)).foregroundColor(.white)
                        Text("Your funds are protected.").font(.system(size: 10)).foregroundColor(MilliTheme.textSecondary)
                        Divider().overlay(Color.white.opacity(0.08))
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Completed").font(.system(size: 9)).foregroundColor(MilliTheme.textSecondary)
                                Text("Today, 9:41 AM").font(.system(size: 11, weight: .semibold)).foregroundColor(.white)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("New Vault Balance").font(.system(size: 9)).foregroundColor(MilliTheme.textSecondary)
                                Text("$4,875.62").font(.system(size: 11, weight: .bold)).foregroundColor(MilliTheme.accent)
                            }
                        }
                    }
                }
            }
            .padding(MilliTheme.screenPadding)
        }
        .background(MilliTheme.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func detailKV(icon: String, label: String, value: String, sub: String, highlight: Bool = false) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 12)).foregroundColor(MilliTheme.accent).frame(width: 20)
            VStack(alignment: .leading, spacing: 1) {
                Text(label).font(.system(size: 9, weight: .semibold)).foregroundColor(MilliTheme.textSecondary)
                Text(value).font(.system(size: 13, weight: .semibold)).foregroundColor(highlight ? MilliTheme.accent : .white)
                if !sub.isEmpty { Text(sub).font(.system(size: 9)).foregroundColor(MilliTheme.textTertiary) }
            }
            Spacer()
        }
    }
}

// MARK: - 24. Reports & Exports

struct ReportsScreen: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                ScreenTitleBar(title: "Reports & Exports")
                MilliCard {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.shield.fill").foregroundColor(MilliTheme.accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Bank-level security").font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                            Text("All exports are encrypted and securely delivered.").font(.system(size: 10)).foregroundColor(MilliTheme.textSecondary)
                        }
                    }
                }
                HStack(spacing: 10) {
                    filterDropdown(title: "This Year", icon: "calendar")
                    filterDropdown(title: "All Accounts", icon: "list.bullet")
                }
                reportRow(icon: "point.topleft.down.curvedto.point.bottomright.up", title: "Mileage Report",
                          status: "Updated", detail: "Jan 1 – May 31, 2025", value: "6,842 mi", label: "Total Mileage")
                reportRow(icon: "percent", title: "Quarterly Tax Summary",
                          status: "Updated", detail: "Q2 2025 · Apr 1 – Jun 30", value: "$2,341.08", label: "Estimated Deductions")
                reportRow(icon: "banknote", title: "Payout Report",
                          status: "Ready", detail: "May 1 – May 31, 2025", value: "$8,642.31", label: "Total Payouts")
                reportRow(icon: "receipt", title: "Expense Report",
                          status: "Updated", detail: "Jan 1 – May 31, 2025", value: "$3,102.45", label: "Total Expenses")
                reportRow(icon: "doc.text", title: "Financial Receipts",
                          status: "Ready", detail: "Latest 50 Transactions", value: "$1,247.33", label: "Total Receipts")
                reportRow(icon: "chart.line.uptrend.xyaxis", title: "Annual Summary",
                          status: "Updated", detail: "Year to Date · 2025", value: "$5,210.76", label: "Net Position")
                HStack(spacing: 6) {
                    Image(systemName: "lock").font(.system(size: 10)).foregroundColor(MilliTheme.textSecondary)
                    Text("Exports are encrypted and sent securely to your device.")
                        .font(.system(size: 10)).foregroundColor(MilliTheme.textSecondary)
                }.frame(maxWidth: .infinity)
            }
            .padding(MilliTheme.screenPadding)
        }
        .background(MilliTheme.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func filterDropdown(title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 11)).foregroundColor(MilliTheme.textSecondary)
            Text(title).font(.system(size: 12, weight: .semibold)).foregroundColor(.white)
            Image(systemName: "chevron.down").font(.system(size: 9)).foregroundColor(MilliTheme.textSecondary)
        }
        .padding(.horizontal, 14).padding(.vertical, 9)
        .background(RoundedRectangle(cornerRadius: 10).fill(MilliTheme.surface)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.12), lineWidth: 0.5)))
    }

    @ViewBuilder
    private func reportRow(icon: String, title: String, status: String, detail: String, value: String, label: String) -> some View {
        MilliCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    Image(systemName: icon).font(.system(size: 16)).foregroundColor(MilliTheme.accent)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(title).font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                            Text(status).font(.system(size: 8, weight: .bold)).foregroundColor(MilliTheme.accent)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Capsule().stroke(MilliTheme.accent.opacity(0.6), lineWidth: 1))
                        }
                        Text(detail).font(.system(size: 9)).foregroundColor(MilliTheme.textSecondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(value).font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                        Text(label).font(.system(size: 8)).foregroundColor(MilliTheme.textTertiary)
                    }
                }
                HStack(spacing: 8) {
                    Spacer()
                    exportButton(title: "PDF", color: MilliTheme.red)
                    exportButton(title: "CSV", color: MilliTheme.green)
                }
            }
        }
    }

    @ViewBuilder
    private func exportButton(title: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "doc.fill").font(.system(size: 9)).foregroundColor(color)
            Text(title).font(.system(size: 10, weight: .bold)).foregroundColor(color)
        }
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(Capsule().stroke(color.opacity(0.6), lineWidth: 1))
    }
}

// MARK: - 25. Financial Timeline

struct FinancialTimelineScreen: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                ScreenTitleBar(title: "Financial Timeline")
                MilliCard {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionLabel(text: "UPCOMING ACTIONS")
                        HStack {
                            upcomingCol(title: "Quarterly Payment", sub: "Due in 81 days", value: "EST. $1,248.00", highlight: true)
                            upcomingCol(title: "Annual Filing", sub: "Due in 160 days", value: "Form 1040", highlight: false)
                            upcomingCol(title: "Mileage Review", sub: "Due in 87 days", value: "87 new miles", highlight: true)
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 0) {
                    timelineEntry(icon: "arrow.down.circle", title: "Payout Received", sub: "Today, 8:24 AM", amount: "+$312.75", positive: true)
                    timelineEntry(icon: "percent", title: "Taxes Reserved", sub: "Today, 8:24 AM", amount: "–$74.38", positive: false)
                    timelineEntry(icon: "lock.shield", title: "Transferred to Milli Tax Vault", sub: "Today, 8:25 AM", amount: "–$74.38", positive: false)
                    timelineEntry(icon: "point.topleft.down.curvedto.point.bottomright.up", title: "Mileage Logged", sub: "87 miles · Business · Today, 9:11 AM", amount: "+$45.93", positive: true)
                    timelineEntry(icon: "receipt", title: "Expense Captured", sub: "Software Subscription · Today, 10:02 AM", amount: "–$28.00", positive: false)
                    timelineEntry(icon: "calendar.badge.exclamationmark", title: "Quarterly Payment Due", sub: "Est. due Jun 15, 2025", amount: "–$1,248.00", positive: false)
                    timelineEntry(icon: "chart.line.uptrend.xyaxis", title: "Investing Contribution", sub: "Automation · S&P 500 · Jun 20, 2025", amount: "–$250.00", positive: false)
                    timelineEntry(icon: "leaf", title: "Retirement Contribution", sub: "Roth IRA · Jun 30, 2025", amount: "–$300.00", positive: false)
                    timelineEntry(icon: "doc.text", title: "Annual Filing Milestone", sub: "Form 1040 · Oct 15, 2025", amount: "Upcoming", positive: true)
                }
                MilliCard {
                    HStack(spacing: 10) {
                        MilliAICharacterView(size: 34)
                        VStack(alignment: .leading, spacing: 2) {
                            SectionLabel(text: "MILLI AI INSIGHT")
                            Text("Great job staying ahead. You're projected to save $1,203 in taxes this year.")
                                .font(.system(size: 11)).foregroundColor(MilliTheme.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.system(size: 11)).foregroundColor(MilliTheme.textTertiary)
                    }
                }
            }
            .padding(MilliTheme.screenPadding)
        }
        .background(MilliTheme.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func upcomingCol(title: String, sub: String, value: String, highlight: Bool) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.system(size: 10, weight: .bold)).foregroundColor(.white)
            Text(sub).font(.system(size: 8)).foregroundColor(MilliTheme.textSecondary)
            Text(value).font(.system(size: 11, weight: .bold)).foregroundColor(highlight ? MilliTheme.accent : .white)
        }
        Spacer()
    }

    @ViewBuilder
    private func timelineEntry(icon: String, title: String, sub: String, amount: String, positive: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                Circle().fill(MilliTheme.surface).frame(width: 28, height: 28)
                    .overlay(Circle().stroke(MilliTheme.accent.opacity(0.6), lineWidth: 1))
                    .overlay(Image(systemName: icon).font(.system(size: 11)).foregroundColor(MilliTheme.accent))
                Rectangle().fill(MilliTheme.accent.opacity(0.25)).frame(width: 1.5, height: 26)
            }
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 12, weight: .semibold)).foregroundColor(.white)
                    Text(sub).font(.system(size: 9)).foregroundColor(MilliTheme.textSecondary)
                }
                Spacer()
                Text(amount).font(.system(size: 12, weight: .bold)).foregroundColor(positive ? MilliTheme.accent : .white)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 10).fill(MilliTheme.card)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.06), lineWidth: 0.5)))
            .padding(.bottom, 8)
        }
    }
}

// MARK: - 26. Settings & Security

struct SettingsScreen: View {
    @State private var biometric = true
    @State private var push = true
    @State private var emailUpdates = true
    @State private var analytics = true
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    MilliMark(size: 22)
                    Spacer()
                    Text("Settings & Security").font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                    Spacer()
                    Image(systemName: "checkmark.shield.fill").font(.system(size: 18)).foregroundColor(MilliTheme.accent)
                }
                MilliCard {
                    HStack(spacing: 12) {
                        Circle().fill(MilliTheme.surface).frame(width: 42, height: 42)
                            .overlay(Circle().stroke(MilliTheme.chromeMid.opacity(0.6), lineWidth: 1))
                            .overlay(Text("A").font(.system(size: 16, weight: .bold)).foregroundColor(.white))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Alex Morgan").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                            Text("alex.morgan@email.com").font(.system(size: 10)).foregroundColor(MilliTheme.textSecondary)
                            Text("MILLI Member since May 2024").font(.system(size: 9)).foregroundColor(MilliTheme.textTertiary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.system(size: 11)).foregroundColor(MilliTheme.textTertiary)
                    }
                }
                settingsSection(title: "SECURITY") {
                    settingsToggleRow(icon: "faceid", title: "Biometric Unlock", sub: "Unlock with Face ID", isOn: $biometric)
                    settingsRow(icon: "lock", title: "App Passcode", sub: "Change your passcode")
                    settingsRow(icon: "clock", title: "Session Timeout", sub: "Auto-lock after 5 minutes")
                }
                settingsSection(title: "NOTIFICATIONS") {
                    settingsToggleRow(icon: "bell", title: "Push Notifications", sub: "Manage push notification preferences", isOn: $push)
                    settingsToggleRow(icon: "envelope", title: "Email Updates", sub: "Receive important updates via email", isOn: $emailUpdates)
                }
                settingsSection(title: "CONNECTED & PRIVACY") {
                    settingsRow(icon: "laptopcomputer", title: "Connected Devices", sub: "Manage devices with account access", value: "3")
                    settingsRow(icon: "hand.raised", title: "Privacy Controls", sub: "Manage data sharing and visibility")
                    settingsToggleRow(icon: "chart.bar", title: "Analytics Preferences", sub: "Help improve MILLI with usage data", isOn: $analytics)
                }
                settingsSection(title: "DATA & ACTIVITY") {
                    settingsRow(icon: "arrow.down.circle", title: "Download Your Data", sub: "Export a copy of your data")
                    settingsRow(icon: "trash", title: "Delete Account Data", sub: "Permanently delete your data", tint: MilliTheme.red)
                    settingsRow(icon: "clock.arrow.circlepath", title: "Session History", sub: "Review recent account activity")
                }
                MilliCard {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.right.square").foregroundColor(MilliTheme.red)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Sign Out").font(.system(size: 13, weight: .semibold)).foregroundColor(MilliTheme.red)
                            Text("Sign out from this device").font(.system(size: 10)).foregroundColor(MilliTheme.red.opacity(0.7))
                        }
                        Spacer()
                    }
                }
                MilliCard {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.shield").foregroundColor(MilliTheme.accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Your security is our priority.").font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                            Text("MILLI uses bank-level encryption to keep data safe and private.")
                                .font(.system(size: 10)).foregroundColor(MilliTheme.textSecondary)
                        }
                    }
                }
            }
            .padding(MilliTheme.screenPadding)
        }
        .background(MilliTheme.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func settingsSection(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: title)
            MilliCard { VStack(spacing: 12) { content() } }
        }
    }

    @ViewBuilder
    private func settingsRow(icon: String, title: String, sub: String, value: String? = nil, tint: Color = .white) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 13)).foregroundColor(tint == .white ? MilliTheme.accent : tint)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.system(size: 12, weight: .semibold)).foregroundColor(tint)
                Text(sub).font(.system(size: 9)).foregroundColor(MilliTheme.textSecondary)
            }
            Spacer()
            if let value { Text(value).font(.system(size: 11, weight: .semibold)).foregroundColor(.white) }
            Image(systemName: "chevron.right").font(.system(size: 10)).foregroundColor(MilliTheme.textTertiary)
        }
    }

    @ViewBuilder
    private func settingsToggleRow(icon: String, title: String, sub: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 13)).foregroundColor(MilliTheme.accent)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.system(size: 12, weight: .semibold)).foregroundColor(.white)
                Text(sub).font(.system(size: 9)).foregroundColor(MilliTheme.textSecondary)
            }
            Spacer()
            MilliToggle(isOn: isOn)
        }
    }
}

// MARK: - 27. More Hub

struct MoreHubScreen: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                ScreenTitleBar(title: "More Hub")
                MilliCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 12) {
                            Circle().fill(MilliTheme.surface).frame(width: 44, height: 44)
                                .overlay(Text("AJ").font(.system(size: 14, weight: .bold)).foregroundColor(.white))
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text("Alex Johnson").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                                    Text("MILLI ELITE").font(.system(size: 7, weight: .bold)).kerning(1).foregroundColor(MilliTheme.accent)
                                        .padding(.horizontal, 6).padding(.vertical, 2)
                                        .background(Capsule().stroke(MilliTheme.accent.opacity(0.6), lineWidth: 1))
                                }
                                Text("Member since May 2024").font(.system(size: 9)).foregroundColor(MilliTheme.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.system(size: 11)).foregroundColor(MilliTheme.textTertiary)
                        }
                        Divider().overlay(Color.white.opacity(0.08))
                        HStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("MILLI CHECKING •••• 3847").font(.system(size: 8, weight: .bold)).foregroundColor(MilliTheme.textSecondary)
                                Text("$8,642.31").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                                Text("Available to Spend").font(.system(size: 9)).foregroundColor(MilliTheme.textSecondary)
                            }
                            Spacer()
                            VStack(spacing: 2) {
                                ProgressRing(progress: 0.82, lineWidth: 5, label: "82", sublabel: "Great")
                                Text("Tax Ready Score").font(.system(size: 8)).foregroundColor(MilliTheme.textSecondary)
                            }
                        }
                    }
                }
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    hubTile(icon: "percent", title: "Quarterly Taxes", sub: "Estimate & set aside")
                    hubTile(icon: "receipt", title: "Expenses", sub: "Track & categorize")
                    hubTile(icon: "building.columns", title: "Accounts", sub: "Manage your money")
                    hubTile(icon: "chart.bar", title: "Reports", sub: "Insights & analytics")
                    hubTile(icon: "doc.text", title: "Documents", sub: "Secure vault")
                    hubTile(icon: "lock.shield", title: "Security & Privacy", sub: "Protect what matters")
                    hubTile(icon: "bell", title: "Notifications", sub: "Alerts & updates", dot: true)
                    hubTile(icon: "creditcard", title: "Subscription", sub: "Manage your plan")
                    hubTile(icon: "questionmark.circle", title: "Support", sub: "Get help fast")
                    hubTile(icon: "gearshape", title: "Settings", sub: "Preferences")
                }
                MilliCard {
                    HStack(spacing: 10) {
                        Image(systemName: "doc.text").foregroundColor(MilliTheme.accent)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Legal").font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                            Text("Terms, policies & disclosures").font(.system(size: 10)).foregroundColor(MilliTheme.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.system(size: 11)).foregroundColor(MilliTheme.textTertiary)
                    }
                }
            }
            .padding(MilliTheme.screenPadding)
        }
        .background(MilliTheme.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func hubTile(icon: String, title: String, sub: String, dot: Bool = false) -> some View {
        MilliCard {
            HStack(spacing: 10) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon).font(.system(size: 16)).foregroundColor(MilliTheme.accent)
                    if dot { Circle().fill(MilliTheme.accent).frame(width: 5, height: 5).offset(x: 4, y: -4) }
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).font(.system(size: 12, weight: .semibold)).foregroundColor(.white)
                    Text(sub).font(.system(size: 9)).foregroundColor(MilliTheme.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 9)).foregroundColor(MilliTheme.textTertiary)
            }
        }
    }
}

// MARK: - Root view

struct MilliRootView: View {
    @State private var selectedTab: MilliScreensTab = .payouts
    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .payouts: PayoutsScreen()
                case .mileage: ActiveTripScreen()
                case .wealth:  WealthOverviewScreen()
                case .more:    MoreHubScreen()
                }
            }
            .padding(.bottom, MilliTheme.navHeight)
            MilliScreensNavBar(selectedTab: $selectedTab)
        }
        .background(MilliTheme.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }
}

// MARK: - Previews

struct MilliScreens_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SplashScreen()
            WelcomeScreen()
            CreateAccountScreen()
            TaxProfileOnboardingScreen()
            GigPlatformsScreen()
            AutopilotSetupScreen()
            HomeDashboardScreen()
            PayoutsScreen()
            TaxVaultScreen()
            ActiveTripScreen()
            TripDetailScreen()
            OfferAnalyzerScreen()
            ExpensesScreen()
            AccountsScreen()
            WealthOverviewScreen()
            InvestingScreen()
            RetirementScreen()
            TreeOfLifeScreen()
            PlanningAdjustmentsScreen()
            MilliAIChatScreen()
            AIActionConfirmationScreen()
            ReportsScreen()
            FinancialTimelineScreen()
            SettingsScreen()
            MoreHubScreen()
        }
    }
}
