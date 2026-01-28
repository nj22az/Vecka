//
//  EditLandingTitleView.swift
//  Vecka
//

import SwiftUI

struct EditLandingTitleView: View {
    @Binding var title: String
    let onSave: (String) -> Void
    let onCancel: () -> Void
    @Environment(\.johoColorMode) private var colorMode

    @FocusState private var isFocused: Bool

    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: JohoDimensions.spacingLG) {
                    // Header
                    JohoPageHeader(
                        title: "Edit Title",
                        badge: "PERSONALIZE"
                    )
                    .padding(.horizontal, JohoDimensions.spacingLG)
                    .padding(.top, JohoDimensions.spacingSM)

                    // Input card
                    VStack(alignment: .leading, spacing: JohoDimensions.spacingMD) {
                        // Preview
                        VStack(spacing: JohoDimensions.spacingSM) {
                            Text("PREVIEW")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundStyle(JohoColors.black.opacity(0.5))

                            Text(title.isEmpty ? "ONSEN" : title.uppercased())
                                .font(.system(size: 24, weight: .black, design: .rounded))
                                .foregroundStyle(colors.primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(JohoDimensions.spacingMD)
                        .background(PageHeaderColor.landing.lightBackground)
                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                        .overlay(
                            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                                .stroke(colors.border, lineWidth: 1.5)
                        )

                        // Text field
                        VStack(alignment: .leading, spacing: JohoDimensions.spacingXS) {
                            Text("Your Title")
                                .font(JohoFont.labelSmall)
                                .foregroundStyle(colors.secondary)

                            TextField("Enter title (e.g., Nils Calendar)", text: $title)
                                .font(JohoFont.body)
                                .foregroundStyle(colors.primary)
                                .padding(JohoDimensions.spacingMD)
                                .background(colors.inputBackground)
                                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                                .overlay(
                                    Squircle(cornerRadius: JohoDimensions.radiusMedium)
                                        .stroke(colors.border, lineWidth: 1.5)
                                )
                                .focused($isFocused)
                        }

                        // Clear button (if not empty)
                        if !title.isEmpty {
                            Button {
                                title = ""
                                HapticManager.selection()
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.system(size: 12, weight: .bold))
                                    Text("Reset to Default (ONSEN)")
                                        .font(JohoFont.bodySmall)
                                }
                                .foregroundStyle(JohoColors.red)
                                .frame(maxWidth: .infinity)
                                .padding(JohoDimensions.spacingSM)
                            }
                            .buttonStyle(.plain)
                        }

                        // Suggestions
                        VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                            Text("SUGGESTIONS")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundStyle(JohoColors.black.opacity(0.5))

                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: JohoDimensions.spacingSM) {
                                suggestionButton("My Calendar")
                                suggestionButton("Family Hub")
                                suggestionButton("Life Planner")
                                suggestionButton("Daily")
                            }
                        }
                    }
                    .padding(JohoDimensions.spacingLG)
                    .background(colors.surface)
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
                    .overlay(
                        Squircle(cornerRadius: JohoDimensions.radiusLarge)
                            .stroke(colors.border, lineWidth: JohoDimensions.borderThick)
                    )
                    .padding(.horizontal, JohoDimensions.spacingLG)

                    Spacer(minLength: JohoDimensions.spacingXL)
                }
                .padding(.bottom, JohoDimensions.spacingXL)
            }
            .johoBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        onCancel()
                    } label: {
                        Text("×")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(JohoColors.red)
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        HapticManager.impact(.light)
                        onSave(title.trimmed)
                    } label: {
                        Text("○")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(Color(hex: "38A169"))
                    }
                }
            }
            .onAppear {
                isFocused = true
            }
        }
    }

    private func suggestionButton(_ text: String) -> some View {
        Button {
            title = text
            HapticManager.selection()
        } label: {
            Text(text)
                .font(JohoFont.bodySmall)
                .foregroundStyle(colors.primary)
                .frame(maxWidth: .infinity)
                .padding(JohoDimensions.spacingSM)
                .background(colors.inputBackground)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusSmall)
                        .stroke(JohoColors.black.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
