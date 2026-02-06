//
//  OnsenRobotMascot.swift
//  Vecka
//
//  情報デザイン: Animated robot mascot with TV body
//  Combines SF Symbol animations with Joho design principles
//
//  Features:
//  - Pulsing antenna with radio waves
//  - Blinking eyes
//  - Waving hand
//  - Bobbing hover animation
//  - Black borders, squircle shapes
//

import SwiftUI

/// 情報デザイン Robot Mascot - animated TV-head character
/// Inspired by classic robot mascots, styled for Japanese information design
struct OnsenRobotMascot: View {
    // MARK: - Configuration

    var size: CGFloat = 120
    var accentColor: Color = JohoColors.cyan
    var showAntenna: Bool = true
    var showHand: Bool = true

    @Environment(\.johoColorMode) private var colorMode
    @Environment(\.scenePhase) private var scenePhase

    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }
    private var shouldAnimate: Bool {
        scenePhase == .active && !AppEnvironment.disableAnimations
    }

    // MARK: - Animation State

    @State private var isActive = false  // Memory safety: prevents async callbacks after disappear
    @State private var isWaving = false
    @State private var isBlinking = false
    @State private var bobOffset: CGFloat = 0
    @State private var blinkTimer: Timer?

    // MARK: - Computed Dimensions

    private var bodyWidth: CGFloat { size * 0.7 }
    private var bodyHeight: CGFloat { size * 0.55 }
    private var eyeSize: CGFloat { size * 0.08 }
    private var eyeSpacing: CGFloat { size * 0.18 }
    private var antennaSize: CGFloat { size * 0.25 }
    private var handSize: CGFloat { size * 0.22 }
    private var borderWidth: CGFloat { max(2, size * 0.02) }
    private var cornerRadius: CGFloat { size * 0.12 }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Antenna (top, behind body)
            if showAntenna {
                antennaView
                    .offset(y: -bodyHeight * 0.55)
            }

            // Robot body (TV shape)
            robotBody
                .offset(y: bobOffset)

            // Waving hand (right side)
            if showHand {
                wavingHand
                    .offset(x: bodyWidth * 0.55, y: bodyHeight * 0.15 + bobOffset)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            isActive = true
            startAnimations()
        }
        .onDisappear {
            isActive = false
            stopAnimations()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                isActive = true
                startAnimations()
            } else {
                isActive = false
                stopAnimations()
            }
        }
    }

    // MARK: - Antenna View

    private var antennaView: some View {
        VStack(spacing: 0) {
            // Antenna ball
            Circle()
                .fill(accentColor)
                .frame(width: size * 0.08, height: size * 0.08)
                .overlay(Circle().stroke(colors.border, lineWidth: borderWidth * 0.5))

            // Antenna stick
            Rectangle()
                .fill(colors.primary)
                .frame(width: size * 0.025, height: size * 0.12)
        }
        .overlay(
            // Radio waves (情報デザイン: Semantic animation)
            Group {
                if shouldAnimate {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: antennaSize, weight: .medium))
                        .foregroundStyle(accentColor.opacity(0.7))
                        .symbolEffect(.variableColor.iterative.reversing, options: .repeating)
                        .offset(y: -size * 0.06)
                } else {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: antennaSize, weight: .medium))
                        .foregroundStyle(accentColor.opacity(0.7))
                        .offset(y: -size * 0.06)
                }
            }
        )
    }

    // MARK: - Robot Body (TV Shape)

    private var robotBody: some View {
        ZStack {
            // TV body shape (情報デザイン: squircle + border)
            Squircle(cornerRadius: cornerRadius)
                .fill(colors.surface)
                .frame(width: bodyWidth, height: bodyHeight)
                .overlay(
                    Squircle(cornerRadius: cornerRadius)
                        .stroke(colors.border, lineWidth: borderWidth)
                )

            // Screen area (slightly inset)
            Squircle(cornerRadius: cornerRadius * 0.7)
                .fill(accentColor.opacity(0.1))
                .frame(width: bodyWidth * 0.85, height: bodyHeight * 0.75)
                .overlay(
                    Squircle(cornerRadius: cornerRadius * 0.7)
                        .stroke(colors.border, lineWidth: borderWidth * 0.5)
                )

            // Face elements
            faceElements

            // Control buttons (情報デザイン: decorative detail)
            controlButtons
                .offset(y: bodyHeight * 0.35)
        }
    }

    // MARK: - Face Elements

    private var faceElements: some View {
        VStack(spacing: size * 0.06) {
            // Eyes
            HStack(spacing: eyeSpacing) {
                eyeView
                eyeView
            }
            .offset(y: -size * 0.02)

            // Mouth (simple smile)
            MascotMouth(curve: 0.4, isSurprised: false)
                .stroke(colors.primary, style: StrokeStyle(lineWidth: borderWidth, lineCap: .round))
                .frame(width: size * 0.2, height: size * 0.08)
        }
    }

    // MARK: - Eye View

    private var eyeView: some View {
        ZStack {
            // Eye background (surface)
            Circle()
                .fill(colors.surface)
                .frame(width: eyeSize * 1.4, height: eyeSize * 1.4)
                .overlay(Circle().stroke(colors.border, lineWidth: borderWidth * 0.5))

            // Pupil (blinks)
            Circle()
                .fill(colors.primary)
                .frame(width: eyeSize, height: eyeSize)
                .scaleEffect(y: isBlinking ? 0.1 : 1.0)
                .animation(.easeInOut(duration: 0.08), value: isBlinking)
        }
    }

    // MARK: - Control Buttons

    private var controlButtons: some View {
        HStack(spacing: size * 0.03) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(index == 1 ? accentColor : colors.primary.opacity(0.3))
                    .frame(width: size * 0.035, height: size * 0.035)
                    .overlay(Circle().stroke(colors.border, lineWidth: JohoDimensions.borderThin))
            }
        }
    }

    // MARK: - Waving Hand

    private var wavingHand: some View {
        Image(systemName: "hand.raised.fill")
            .font(.system(size: handSize, weight: .bold))
            .foregroundStyle(JohoColors.yellow)
            .background(
                Circle()
                    .fill(colors.surface)
                    .frame(width: handSize * 1.1, height: handSize * 1.1)
                    .overlay(Circle().stroke(colors.border, lineWidth: borderWidth * 0.6))
            )
            .rotationEffect(
                .degrees(isWaving ? -15 : 15),
                anchor: .bottom
            )
            .animation(
                shouldAnimate ? .easeInOut(duration: 0.4).repeatForever(autoreverses: true) : nil,
                value: isWaving
            )
    }

    // MARK: - Animations

    private func startAnimations() {
        guard shouldAnimate else { return }
        stopAnimations()

        // Bobbing hover
        withAnimation(
            .easeInOut(duration: 1.8).repeatForever(autoreverses: true)
        ) {
            bobOffset = size * 0.03
        }

        // Waving
        isWaving = true

        // Blinking
        startBlinkLoop()
    }

    private func stopAnimations() {
        blinkTimer?.invalidate()
        blinkTimer = nil
        bobOffset = 0
        isWaving = false
        isBlinking = false
    }

    private func startBlinkLoop() {
        let interval = Double.random(in: 2.5...5.0)

        blinkTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            triggerBlink()
        }
    }

    private func triggerBlink() {
        withAnimation(.easeOut(duration: 0.06)) {
            isBlinking = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [self] in
            guard isActive else { return }  // Memory safety: stop if view disappeared

            withAnimation(.easeIn(duration: 0.06)) {
                isBlinking = false
            }
            startBlinkLoop()
        }
    }
}

// MARK: - Compact Robot Mascot (for headers)

/// Smaller version for header compartments
struct CompactRobotMascot: View {
    var size: CGFloat = 44
    var accentColor: Color = JohoColors.cyan

    @Environment(\.johoColorMode) private var colorMode
    @Environment(\.scenePhase) private var scenePhase

    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }
    private var shouldAnimate: Bool {
        scenePhase == .active && !AppEnvironment.disableAnimations
    }

    @State private var isActive = false  // Memory safety: prevents async callbacks after disappear
    @State private var isBlinking = false
    @State private var blinkTimer: Timer?

    var body: some View {
        ZStack {
            // Simple squircle body
            Squircle(cornerRadius: size * 0.2)
                .fill(colors.surface)
                .frame(width: size, height: size)
                .overlay(
                    Squircle(cornerRadius: size * 0.2)
                        .stroke(colors.border, lineWidth: 1.5)
                )

            // Screen tint
            Squircle(cornerRadius: size * 0.15)
                .fill(accentColor.opacity(0.15))
                .frame(width: size * 0.8, height: size * 0.7)

            // Eyes
            HStack(spacing: size * 0.18) {
                Circle()
                    .fill(colors.primary)
                    .frame(width: size * 0.12, height: size * 0.12)
                    .scaleEffect(y: isBlinking ? 0.1 : 1.0)

                Circle()
                    .fill(colors.primary)
                    .frame(width: size * 0.12, height: size * 0.12)
                    .scaleEffect(y: isBlinking ? 0.1 : 1.0)
            }
            .offset(y: -size * 0.05)
            .animation(.easeInOut(duration: 0.08), value: isBlinking)

            // Smile
            MascotMouth(curve: 0.35, isSurprised: false)
                .stroke(colors.primary, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                .frame(width: size * 0.25, height: size * 0.1)
                .offset(y: size * 0.12)

            // Antenna indicator
            Circle()
                .fill(accentColor)
                .frame(width: size * 0.1, height: size * 0.1)
                .overlay(Circle().stroke(colors.border, lineWidth: JohoDimensions.borderThin))
                .offset(y: -size * 0.42)
        }
        .onAppear {
            isActive = true
            if shouldAnimate {
                startBlinking()
            }
        }
        .onDisappear {
            isActive = false
            blinkTimer?.invalidate()
            blinkTimer = nil
            isBlinking = false
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                isActive = true
                if shouldAnimate {
                    startBlinking()
                }
            } else {
                isActive = false
                blinkTimer?.invalidate()
                blinkTimer = nil
                isBlinking = false
            }
        }
    }

    private func startBlinking() {
        let interval = Double.random(in: 3.0...6.0)
        blinkTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [self] _ in
            guard isActive else { return }  // Memory safety: stop if view disappeared

            withAnimation(.easeOut(duration: 0.06)) { isBlinking = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
                guard isActive else { return }  // Memory safety: stop if view disappeared

                withAnimation(.easeIn(duration: 0.06)) { isBlinking = false }
                startBlinking()
            }
        }
    }
}

// MARK: - Previews

#Preview("Onsen Robot Mascot") {
    VStack(spacing: 32) {
        OnsenRobotMascot(size: 160, accentColor: JohoColors.cyan)

        Text("Tap to interact")
            .font(JohoFont.caption)
            .foregroundStyle(JohoColors.white.opacity(0.6))
    }
    .padding(40)
    .background(JohoColors.black)
}

#Preview("Robot Mascot - Colors") {
    HStack(spacing: 24) {
        OnsenRobotMascot(size: 100, accentColor: JohoColors.cyan)
        OnsenRobotMascot(size: 100, accentColor: JohoColors.yellow)
        OnsenRobotMascot(size: 100, accentColor: JohoColors.pink)
    }
    .padding(32)
    .background(JohoColors.black)
}

#Preview("Compact Robot - Header") {
    HStack(spacing: 0) {
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

        Rectangle()
            .fill(Color.black)
            .frame(width: 1.5)

        CompactRobotMascot(size: 44, accentColor: JohoColors.cyan)
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

#Preview("Robot vs Joho Mascot") {
    HStack(spacing: 32) {
        VStack {
            OnsenRobotMascot(size: 100)
            Text("Robot").font(.caption)
        }
        VStack {
            JohoMascot(mood: .happy, size: 100)
            Text("Joho").font(.caption)
        }
    }
    .padding(32)
    .background(Color(white: 0.1))
}
