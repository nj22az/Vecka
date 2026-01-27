//
//  JohoMascot.swift (formerly KaomojiMascot.swift)
//  Vecka
//
//  情報デザイン: Animated geometric mascot using SF Symbols + shapes
//  Pure code-based rendering with smooth animations
//
//  Features:
//  - Blinking eyes (scale animation)
//  - Bobbing body (vertical offset)
//  - Multiple moods/expressions
//  - 情報デザイン compliant styling
//  - Onsen transformation (face becomes hot spring pool)
//  - SF Symbol animations (wiggle, bounce, breathe, variableColor)
//  - Floating accessories (sparkles, hearts, steam)
//

import SwiftUI

// MARK: - Animation Models (情報デザイン)

/// Steam puff for onsen mode - rises and fades
struct SteamPuff: Identifiable {
    let id = UUID()
    var xOffset: CGFloat
    var yOffset: CGFloat = 0
    var opacity: Double = 1.0
    var scale: CGFloat = 0.5
}

/// Floating heart for happy reactions
struct FloatingHeart: Identifiable {
    let id = UUID()
    var xOffset: CGFloat
    var yOffset: CGFloat = 0
    var opacity: Double = 1.0
    var rotation: Double = 0
}

// MARK: - Mascot Mood (Database-Ready)

/// Mascot mood/emotion state - can be driven by database or time of day
enum MascotMood: String, CaseIterable, Codable {
    case happy      // Default - friendly smile
    case excited    // Wide eyes, big smile
    case calm       // Relaxed, small smile
    case sleepy     // Droopy eyes, neutral mouth
    case surprised  // Wide eyes, O mouth

    // Page-specific moods (情報デザイン context-aware)
    case onsen      // ♨️ Onsen/hot spring eyes - for landing page
    case starry     // ★ Star eyes - for special days page
    case calendar   // 📅 Normal with calendar accent - for calendar page
    case contacts   // 👥 Friendly wink - for contacts page
    case settings   // ⚙️ Curious look - for settings page

    /// Eye scale multiplier (1.0 = normal, larger = wider eyes)
    var eyeScale: CGFloat {
        switch self {
        case .happy, .calendar: return 1.0
        case .excited, .starry: return 1.3
        case .calm, .settings: return 0.9
        case .sleepy: return 0.7
        case .surprised: return 1.4
        case .onsen: return 1.1
        case .contacts: return 1.0
        }
    }

    /// Mouth curvature (positive = smile, negative = frown, 0 = neutral)
    var mouthCurve: CGFloat {
        switch self {
        case .happy, .calendar: return 0.3
        case .excited, .starry: return 0.5
        case .calm: return 0.2
        case .sleepy: return 0.0
        case .surprised: return -0.1  // Slight O shape
        case .onsen: return 0.6  // Relaxed happy
        case .contacts: return 0.4  // Friendly
        case .settings: return 0.25  // Curious
        }
    }

    /// Whether to show blush circles
    var showBlush: Bool {
        switch self {
        case .happy, .excited, .onsen, .contacts: return true
        default: return false
        }
    }

    /// Special eye type (nil = normal circles)
    var specialEyeType: SpecialEyeType? {
        switch self {
        case .onsen: return .onsen
        case .starry: return .star
        case .contacts: return .wink
        default: return nil
        }
    }

    /// SF Symbol for mood indicator (optional decorative element)
    var accentSymbol: String? {
        switch self {
        case .excited: return "sparkle"
        case .sleepy: return "moon.zzz"
        case .surprised: return "exclamationmark"
        case .starry: return "star.fill"
        case .calendar: return "calendar"
        case .settings: return "gearshape"
        default: return nil
        }
    }
}

/// Special eye rendering types for page-specific mascots
enum SpecialEyeType {
    case onsen  // ♨️ wavy steam lines
    case star   // ★ star shapes
    case wink   // One eye closed (^) one open
}

// MARK: - Joho Mascot View

/// Animated geometric mascot for the Onsen landing page
/// 情報デザイン compliant: shapes + SF Symbols, black borders, animated
struct JohoMascot: View {
    // MARK: - Properties

    var mood: MascotMood = .happy
    var size: CGFloat = 44
    var borderWidth: CGFloat = 1.5
    var showBob: Bool = true
    var showBlink: Bool = true
    var autoOnsen: Bool = false  // Enable random ♨️ transformation

    @Environment(\.johoColorMode) private var colorMode

    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    // MARK: - State

    @State private var isActive = false  // Memory safety: prevents async callbacks after disappear
    @State private var isBlinking = false
    @State private var bobOffset: CGFloat = 0
    @State private var blinkTimer: Timer?
    @State private var eyeLookTimer: Timer?
    @State private var onsenTimer: Timer?
    @State private var eyeOffset: CGPoint = .zero  // Eye movement offset
    @State private var isOnsenMode = false  // Currently showing ♨️ face
    @State private var onsenPhase: CGFloat = 0  // Animation phase for steam
    @State private var sparkleVisible = false  // SF Symbol sparkle animation
    @State private var heartBounce = false  // Heart bounce trigger
    @State private var steamPuffs: [SteamPuff] = []  // Rising steam clouds
    @State private var waterRipple: CGFloat = 0  // Water ripple animation
    @State private var wiggleTrigger = false  // Tap wiggle effect
    @State private var floatingHearts: [FloatingHeart] = []  // Rising hearts

    /// Current displayed mood (may be overridden by onsen mode)
    private var displayedMood: MascotMood {
        isOnsenMode ? .onsen : mood
    }

    // MARK: - Computed Dimensions

    private var eyeSize: CGFloat { size * 0.12 * displayedMood.eyeScale }
    private var eyeSpacing: CGFloat { size * 0.22 }
    private var eyeVerticalOffset: CGFloat { size * -0.08 }
    private var mouthWidth: CGFloat { size * 0.28 }
    private var mouthVerticalOffset: CGFloat { size * 0.12 }
    private var blushSize: CGFloat { size * 0.1 }
    private var cornerRadius: CGFloat { size * 0.18 }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Floating hearts (情報デザイン: Happy reaction)
            ForEach(floatingHearts) { heart in
                Image(systemName: "heart.fill")
                    .font(.system(size: size * 0.12, weight: .bold))
                    .foregroundStyle(JohoColors.pink)
                    .offset(x: heart.xOffset, y: heart.yOffset)
                    .opacity(heart.opacity)
                    .rotationEffect(.degrees(heart.rotation))
            }

            // Steam puffs (情報デザイン: Onsen atmosphere)
            ForEach(steamPuffs) { puff in
                Image(systemName: "cloud.fill")
                    .font(.system(size: size * 0.18, weight: .medium))
                    .foregroundStyle(JohoColors.cyan.opacity(0.6))
                    .symbolEffect(.variableColor.iterative, options: .repeating.speed(0.5))
                    .offset(x: puff.xOffset, y: puff.yOffset)
                    .opacity(puff.opacity)
                    .scaleEffect(puff.scale)
            }

            // Container squircle (情報デザイン: surface + border)
            Squircle(cornerRadius: cornerRadius)
                .fill(isOnsenMode ? JohoColors.cyan.opacity(0.3) : colors.surface)
                .overlay(
                    Squircle(cornerRadius: cornerRadius)
                        .stroke(colors.border, lineWidth: borderWidth)
                )
                .frame(width: size, height: size)

            // Onsen water effect (情報デザイン: Hot spring pool)
            if isOnsenMode {
                onsenPoolView
            }

            // Face elements
            faceView
                .offset(y: showBob ? bobOffset : 0)

            // Floating sparkle (情報デザイン: Playful SF Symbol animation)
            if sparkleVisible {
                Image(systemName: "sparkle")
                    .font(.system(size: size * 0.15, weight: .medium))
                    .foregroundStyle(JohoColors.cyan)
                    .symbolEffect(.variableColor.iterative.reversing, options: .repeating)
                    .offset(x: size * -0.35, y: size * -0.35)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: size, height: size)
        .symbolEffect(.wiggle, options: .nonRepeating, value: wiggleTrigger)
        .onTapGesture {
            // Tap wiggle + exit onsen mode (情報デザイン: Interactive feedback)
            wiggleTrigger.toggle()
            HapticManager.selection()

            if isOnsenMode {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isOnsenMode = false
                    steamPuffs.removeAll()
                }
            } else {
                // Spawn a floating heart on tap when happy
                if mood == .happy || mood == .excited {
                    spawnFloatingHeart()
                }
            }
        }
        .onAppear {
            isActive = true
            startAnimations()
        }
        .onDisappear {
            isActive = false
            stopAnimations()
        }
        .accessibilityLabel("Mascot")
        .accessibilityHidden(true)
    }

    // MARK: - Onsen Pool View (情報デザイン: Hot spring transformation)

    private var onsenPoolView: some View {
        ZStack {
            // Water surface with ripple effect
            // 情報デザイン: Solid color, no gradients
            Ellipse()
                .fill(JohoColors.cyan.opacity(0.4))
                .frame(width: size * 0.7, height: size * 0.25)
                .overlay(
                    Ellipse()
                        .stroke(colors.border, lineWidth: borderWidth * 0.5)
                )
                .offset(y: size * 0.15)
                .scaleEffect(1.0 + waterRipple * 0.05)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: waterRipple)

            // Steam rising from water (SF Symbol)
            HStack(spacing: size * 0.08) {
                Image(systemName: "humidity.fill")
                    .font(.system(size: size * 0.14, weight: .medium))
                    .foregroundStyle(JohoColors.cyan.opacity(0.7))
                    .symbolEffect(.variableColor.iterative.reversing, options: .repeating.speed(0.3))

                Image(systemName: "humidity.fill")
                    .font(.system(size: size * 0.18, weight: .medium))
                    .foregroundStyle(JohoColors.cyan.opacity(0.8))
                    .symbolEffect(.variableColor.iterative, options: .repeating.speed(0.4))

                Image(systemName: "humidity.fill")
                    .font(.system(size: size * 0.14, weight: .medium))
                    .foregroundStyle(JohoColors.cyan.opacity(0.7))
                    .symbolEffect(.variableColor.iterative.reversing, options: .repeating.speed(0.35))
            }
            .offset(y: size * -0.05)

            // ♨️ Onsen symbol (情報デザイン: Semantic indicator)
            Text("♨️")
                .font(.system(size: size * 0.2))
                .offset(y: size * 0.32)
        }
    }

    // MARK: - Face View

    private var faceView: some View {
        ZStack {
            // In onsen mode, show relaxed eyes peeking above water
            if isOnsenMode {
                // Relaxed/closed eyes (^_^) above the water
                HStack(spacing: eyeSpacing) {
                    // Closed eye arc (^)
                    WinkEyeShape()
                        .stroke(colors.primary, style: StrokeStyle(lineWidth: size * 0.035, lineCap: .round))
                        .frame(width: eyeSize * 1.3, height: eyeSize * 0.6)

                    WinkEyeShape()
                        .stroke(colors.primary, style: StrokeStyle(lineWidth: size * 0.035, lineCap: .round))
                        .frame(width: eyeSize * 1.3, height: eyeSize * 0.6)
                }
                .offset(y: size * -0.12)
            } else {
                // Normal face view
                // Eyes - with look-around offset
                HStack(spacing: eyeSpacing) {
                    eyeView(isLeft: true)
                    eyeView(isLeft: false)
                }
                .offset(x: eyeOffset.x, y: eyeVerticalOffset + eyeOffset.y)

                // Blush circles (mood-dependent)
                if displayedMood.showBlush {
                    HStack(spacing: eyeSpacing * 1.8) {
                        blushView
                        blushView
                    }
                    .offset(y: eyeVerticalOffset + eyeSize * 1.2)
                }

                // Mouth
                mouthView
                    .offset(y: mouthVerticalOffset)

                // Accent symbol (mood-dependent sparkle/zzz) - with SF Symbol effects
                if let symbol = displayedMood.accentSymbol {
                    Image(systemName: symbol)
                        .font(.system(size: size * 0.12, weight: .bold))
                        .foregroundStyle(colors.primary.opacity(0.5))
                        .symbolEffect(.bounce, options: .repeating.speed(0.3), value: heartBounce)
                        .offset(x: size * 0.28, y: size * -0.28)
                }
            }
        }
    }

    // MARK: - Eye View

    @ViewBuilder
    private func eyeView(isLeft: Bool) -> some View {
        if let specialType = displayedMood.specialEyeType {
            specialEyeView(type: specialType, isLeft: isLeft)
        } else {
            // Normal circle eyes
            Circle()
                .fill(colors.primary)
                .frame(width: eyeSize, height: eyeSize)
                .scaleEffect(y: isBlinking ? 0.1 : 1.0)
                .animation(.easeInOut(duration: 0.08), value: isBlinking)
        }
    }

    // MARK: - Special Eye Views

    @ViewBuilder
    private func specialEyeView(type: SpecialEyeType, isLeft: Bool) -> some View {
        switch type {
        case .onsen:
            // ♨️ Onsen steam wavy eyes
            OnsenEyeShape()
                .stroke(colors.primary, style: StrokeStyle(lineWidth: size * 0.025, lineCap: .round))
                .frame(width: eyeSize * 1.2, height: eyeSize * 1.4)
                .scaleEffect(y: isBlinking ? 0.1 : 1.0)
                .animation(.easeInOut(duration: 0.08), value: isBlinking)

        case .star:
            // ★ Star eyes
            Image(systemName: "star.fill")
                .font(.system(size: eyeSize * 1.1, weight: .bold))
                .foregroundStyle(colors.primary)
                .scaleEffect(y: isBlinking ? 0.1 : 1.0)
                .animation(.easeInOut(duration: 0.08), value: isBlinking)

        case .wink:
            // Wink - left eye open, right eye closed (^)
            if isLeft {
                Circle()
                    .fill(colors.primary)
                    .frame(width: eyeSize, height: eyeSize)
                    .scaleEffect(y: isBlinking ? 0.1 : 1.0)
                    .animation(.easeInOut(duration: 0.08), value: isBlinking)
            } else {
                // Closed eye arc (^)
                WinkEyeShape()
                    .stroke(colors.primary, style: StrokeStyle(lineWidth: size * 0.03, lineCap: .round))
                    .frame(width: eyeSize * 1.2, height: eyeSize * 0.6)
            }
        }
    }

    // MARK: - Blush View

    private var blushView: some View {
        Circle()
            .fill(Color(hex: "FECDD3").opacity(0.6))  // Soft pink
            .frame(width: blushSize, height: blushSize)
    }

    // MARK: - Mouth View

    private var mouthView: some View {
        MascotMouth(curve: displayedMood.mouthCurve, isSurprised: displayedMood == .surprised)
            .stroke(colors.primary, style: StrokeStyle(lineWidth: size * 0.04, lineCap: .round))
            .frame(width: mouthWidth, height: mouthWidth * 0.5)
    }

    // MARK: - Animation Control

    private func startAnimations() {
        // Bobbing animation
        if showBob {
            withAnimation(
                Animation.easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true)
            ) {
                bobOffset = size * 0.025
            }
        }

        // Blinking with timer
        if showBlink {
            startBlinkLoop()
        }

        // Eye look-around animation
        startEyeLookLoop()

        // Auto-onsen transformation (情報デザイン: Surprise delight)
        if autoOnsen {
            startOnsenLoop()
        }

        // Sparkle animation (random appearance)
        startSparkleLoop()

        // Trigger heart bounce periodically
        heartBounce = true
    }

    private func stopAnimations() {
        blinkTimer?.invalidate()
        blinkTimer = nil
        eyeLookTimer?.invalidate()
        eyeLookTimer = nil
        onsenTimer?.invalidate()
        onsenTimer = nil
    }

    // MARK: - Onsen Transformation Animation

    private func startOnsenLoop() {
        // Random interval before transforming to onsen (8-20 seconds)
        let interval = Double.random(in: 8.0...20.0)

        onsenTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            triggerOnsenTransform()
        }
    }

    private func triggerOnsenTransform() {
        // Transform to ♨️ onsen face
        withAnimation(.easeInOut(duration: 0.2)) {
            isOnsenMode = true
        }

        // Start water ripple animation
        startWaterRipple()

        // Spawn steam puffs
        spawnSteamPuffs()

        // Stay in onsen mode for 4-8 seconds, then return to normal
        let duration = Double.random(in: 4.0...8.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [self] in
            guard isActive else { return }  // Memory safety: stop if view disappeared

            withAnimation(.easeInOut(duration: 0.2)) {
                isOnsenMode = false
                waterRipple = 0
            }

            // Clear steam puffs
            withAnimation(.easeOut(duration: 0.5)) {
                steamPuffs.removeAll()
            }

            // Continue the loop
            if autoOnsen {
                startOnsenLoop()
            }
        }
    }

    // MARK: - Sparkle Animation (SF Symbol magic)

    private func startSparkleLoop() {
        // Random interval before showing sparkle (5-15 seconds)
        let interval = Double.random(in: 5.0...15.0)

        DispatchQueue.main.asyncAfter(deadline: .now() + interval) { [self] in
            guard isActive else { return }  // Memory safety: stop if view disappeared

            // Show sparkle
            withAnimation(.easeInOut(duration: 0.2)) {
                sparkleVisible = true
            }

            // Hide after 2-4 seconds
            let displayDuration = Double.random(in: 2.0...4.0)
            DispatchQueue.main.asyncAfter(deadline: .now() + displayDuration) { [self] in
                guard isActive else { return }  // Memory safety: stop if view disappeared

                withAnimation(.easeOut(duration: 0.3)) {
                    sparkleVisible = false
                }

                // Continue the loop
                startSparkleLoop()
            }
        }
    }

    // MARK: - Floating Heart Animation (情報デザイン: Happy reaction)

    private func spawnFloatingHeart() {
        let xOffset = CGFloat.random(in: -size * 0.3...size * 0.3)
        let heart = FloatingHeart(xOffset: xOffset)

        withAnimation(.easeInOut(duration: 0.2)) {
            floatingHearts.append(heart)
        }

        // Animate heart rising and fading
        withAnimation(.easeOut(duration: 1.5)) {
            if let index = floatingHearts.firstIndex(where: { $0.id == heart.id }) {
                floatingHearts[index].yOffset = -size * 0.8
                floatingHearts[index].opacity = 0
                floatingHearts[index].rotation = Double.random(in: -30...30)
            }
        }

        // Remove heart after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { [self] in
            guard isActive else { return }  // Memory safety: stop if view disappeared
            floatingHearts.removeAll { $0.id == heart.id }
        }
    }

    // MARK: - Steam Puff Animation (情報デザイン: Onsen atmosphere)

    private func spawnSteamPuffs() {
        // Spawn 3 steam puffs at different positions
        for i in 0..<3 {
            let xOffset = CGFloat(i - 1) * size * 0.2
            var puff = SteamPuff(xOffset: xOffset)
            puff.yOffset = size * 0.1

            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.3) { [self] in
                guard isActive else { return }  // Memory safety: stop if view disappeared

                withAnimation(.easeInOut(duration: 0.2)) {
                    steamPuffs.append(puff)
                }

                // Animate puff rising and fading
                withAnimation(.easeOut(duration: 2.5)) {
                    if let index = steamPuffs.firstIndex(where: { $0.id == puff.id }) {
                        steamPuffs[index].yOffset = -size * 0.6
                        steamPuffs[index].opacity = 0
                        steamPuffs[index].scale = 1.2
                    }
                }
            }
        }

        // Continue spawning while in onsen mode
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [self] in
            guard isActive else { return }  // Memory safety: stop if view disappeared

            if isOnsenMode {
                // Clean up old puffs
                steamPuffs.removeAll { $0.opacity < 0.1 }
                spawnSteamPuffs()
            }
        }
    }

    private func startWaterRipple() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            waterRipple = 1.0
        }
    }

    // MARK: - Eye Look Animation

    private func startEyeLookLoop() {
        let interval = Double.random(in: 2.0...4.0)

        eyeLookTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            lookAround()
        }
    }

    private func lookAround() {
        // Random direction to look
        let maxOffset = size * 0.04
        let randomX = CGFloat.random(in: -maxOffset...maxOffset)
        let randomY = CGFloat.random(in: -maxOffset * 0.5...maxOffset * 0.5)

        withAnimation(.easeInOut(duration: 0.3)) {
            eyeOffset = CGPoint(x: randomX, y: randomY)
        }

        // Return to center after a moment
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0.5...1.5)) { [self] in
            guard isActive else { return }  // Memory safety: stop if view disappeared

            withAnimation(.easeInOut(duration: 0.4)) {
                eyeOffset = .zero
            }

            // Continue the loop
            startEyeLookLoop()
        }
    }

    private func startBlinkLoop() {
        let interval = Double.random(in: 3.0...6.0)

        blinkTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            triggerBlink()
        }
    }

    private func triggerBlink() {
        withAnimation(.easeOut(duration: 0.06)) {
            isBlinking = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
            guard isActive else { return }  // Memory safety: stop if view disappeared

            withAnimation(.easeIn(duration: 0.06)) {
                isBlinking = false
            }

            if showBlink {
                startBlinkLoop()
            }
        }
    }
}

// MARK: - Mascot Mouth Shape

/// Custom shape for mascot mouth with variable curvature
struct MascotMouth: Shape {
    var curve: CGFloat  // Positive = smile, negative = frown, 0 = straight
    var isSurprised: Bool

    var animatableData: CGFloat {
        get { curve }
        set { curve = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()

        if isSurprised {
            // O-shaped mouth for surprised
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let radius = min(rect.width, rect.height) * 0.35
            path.addEllipse(in: CGRect(
                x: center.x - radius,
                y: center.y - radius * 0.8,
                width: radius * 2,
                height: radius * 1.6
            ))
        } else {
            // Curved line mouth
            let startX = rect.minX
            let endX = rect.maxX
            let midX = rect.midX
            let baseY = rect.midY
            let curveOffset = rect.height * curve

            path.move(to: CGPoint(x: startX, y: baseY))
            path.addQuadCurve(
                to: CGPoint(x: endX, y: baseY),
                control: CGPoint(x: midX, y: baseY + curveOffset)
            )
        }

        return path
    }
}

// MARK: - Special Eye Shapes

/// ♨️ Onsen steam wavy eye shape
struct OnsenEyeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Three wavy steam lines (like ♨️)
        let lineSpacing = rect.width / 3.5
        let amplitude = rect.height * 0.15
        let waveCount = 2

        for i in 0..<3 {
            let xOffset = rect.minX + lineSpacing * CGFloat(i) + lineSpacing * 0.5
            let startY = rect.maxY
            let endY = rect.minY

            path.move(to: CGPoint(x: xOffset, y: startY))

            let segmentHeight = (startY - endY) / CGFloat(waveCount * 2)
            for j in 0..<(waveCount * 2) {
                let currentY = startY - segmentHeight * CGFloat(j + 1)
                let controlX = xOffset + (j % 2 == 0 ? amplitude : -amplitude)
                let controlY = currentY + segmentHeight * 0.5
                path.addQuadCurve(
                    to: CGPoint(x: xOffset, y: currentY),
                    control: CGPoint(x: controlX, y: controlY)
                )
            }
        }

        return path
    }
}

/// Wink eye shape (^) - closed eye arc
struct WinkEyeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Arc from left to right, curving upward (^)
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control: CGPoint(x: rect.midX, y: rect.minY)
        )

        return path
    }
}

// MARK: - Legacy Alias (Backward Compatibility)

/// Alias for backward compatibility with existing code
typealias KaomojiMascot = JohoMascot

// MARK: - Previews

#Preview("Joho Mascot - All Moods") {
    VStack(spacing: 24) {
        HStack(spacing: 20) {
            VStack {
                JohoMascot(mood: .happy, size: 64)
                Text("Happy").font(.caption)
            }
            VStack {
                JohoMascot(mood: .excited, size: 64)
                Text("Excited").font(.caption)
            }
            VStack {
                JohoMascot(mood: .calm, size: 64)
                Text("Calm").font(.caption)
            }
        }
        HStack(spacing: 20) {
            VStack {
                JohoMascot(mood: .sleepy, size: 64)
                Text("Sleepy").font(.caption)
            }
            VStack {
                JohoMascot(mood: .surprised, size: 64)
                Text("Surprised").font(.caption)
            }
        }
    }
    .padding(24)
    .background(Color(white: 0.1))
}

#Preview("Mascot Sizes") {
    HStack(spacing: 16) {
        JohoMascot(mood: .happy, size: 32)
        JohoMascot(mood: .happy, size: 44)
        JohoMascot(mood: .happy, size: 56)
        JohoMascot(mood: .happy, size: 72)
    }
    .padding()
    .background(Color(white: 0.1))
}

#Preview("Mascot in Header Context") {
    HStack(spacing: 0) {
        // Simulated header left side
        HStack(spacing: 8) {
            Image(systemName: "house.fill")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(JohoColors.cyan)
                .frame(width: 40, height: 40)
                .background(JohoColors.cyan.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            Text("ONSEN")
                .font(.system(size: 16, weight: .black, design: .rounded))
        }
        .padding(.horizontal, 12)

        Spacer()

        // Vertical wall
        Rectangle()
            .fill(Color.black)
            .frame(width: 1.5)

        // Mascot in right compartment
        JohoMascot(mood: .happy, size: 44)
            .padding(.horizontal, 12)
    }
    .frame(height: 56)
    .background(Color.white)
    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    .overlay(
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(Color.black, lineWidth: 2)
    )
    .padding()
    .background(Color(white: 0.1))
}
