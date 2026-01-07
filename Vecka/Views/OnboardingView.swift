//
//  OnboardingView.swift
//  Vecka
//
//  情報デザイン: Simple onboarding flow for first-time users
//  Clean, informative, follows Japanese information design principles
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var hasCompletedOnboarding: Bool

    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "calendar.badge.clock",
            iconColor: JohoColors.cyan,
            title: "ISO 8601 Week Numbers",
            subtitle: "Track time the way professionals do",
            description: "WeekGrid displays weeks using the international ISO 8601 standard. Week 1 starts on the first Monday of the year containing at least 4 days."
        ),
        OnboardingPage(
            icon: "square.grid.3x3.fill",
            iconColor: JohoColors.yellow,
            title: "Organized Information",
            subtitle: "Everything in its place",
            description: "Notes, trips, expenses, contacts, and special days - all organized with color-coded sections. Each color has meaning: yellow for today, cyan for events, pink for holidays."
        ),
        OnboardingPage(
            icon: "star.fill",
            iconColor: JohoColors.pink,
            title: "Special Days",
            subtitle: "Never miss what matters",
            description: "Track holidays from multiple countries, birthdays, and custom celebrations. Create your own special days with symbols and repeating rules."
        ),
        OnboardingPage(
            icon: "arrow.triangle.2.circlepath",
            iconColor: JohoColors.purple,
            title: "Sync Everywhere",
            subtitle: "Your data, your devices",
            description: "iCloud sync keeps your notes, expenses, and contacts updated across all your Apple devices automatically."
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Page content
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    OnboardingPageView(page: page)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Bottom controls
            VStack(spacing: JohoDimensions.spacingMD) {
                // Page indicators
                HStack(spacing: JohoDimensions.spacingSM) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? JohoColors.black : JohoColors.black.opacity(0.2))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, JohoDimensions.spacingSM)

                // Action button
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentPage += 1
                        }
                    } else {
                        completeOnboarding()
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "Continue" : "Get Started")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(JohoColors.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, JohoDimensions.spacingMD)
                        .background(JohoColors.black)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding(.horizontal, JohoDimensions.spacingLG)

                // Skip button (only on non-last pages)
                if currentPage < pages.count - 1 {
                    Button {
                        completeOnboarding()
                    } label: {
                        Text("Skip")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(JohoColors.black.opacity(0.6))
                    }
                    .padding(.top, JohoDimensions.spacingXS)
                }
            }
            .padding(.bottom, JohoDimensions.spacingXL)
        }
        .background(JohoColors.white)
    }

    private func completeOnboarding() {
        hasCompletedOnboarding = true
        dismiss()
    }
}

// MARK: - Onboarding Page Model

struct OnboardingPage {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let description: String
}

// MARK: - Onboarding Page View

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: JohoDimensions.spacingLG) {
            Spacer()

            // Icon (情報デザイン: Bordered icon zone)
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(page.iconColor.opacity(0.2))
                    .frame(width: 120, height: 120)

                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(JohoColors.black, lineWidth: 2)
                    .frame(width: 120, height: 120)

                Image(systemName: page.icon)
                    .font(.system(size: 48, weight: .medium))
                    .foregroundStyle(JohoColors.black)
            }

            // Title
            Text(page.title)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(JohoColors.black)
                .multilineTextAlignment(.center)
                .padding(.top, JohoDimensions.spacingMD)

            // Subtitle
            Text(page.subtitle)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(JohoColors.black.opacity(0.7))
                .multilineTextAlignment(.center)

            // Description (情報デザイン: Info box with border)
            Text(page.description)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(JohoColors.black.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(JohoDimensions.spacingMD)
                .background(JohoColors.black.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(JohoColors.black.opacity(0.1), lineWidth: 1)
                )
                .padding(.horizontal, JohoDimensions.spacingLG)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, JohoDimensions.spacingLG)
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
