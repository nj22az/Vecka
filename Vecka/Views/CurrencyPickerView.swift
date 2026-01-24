//
//  CurrencyPickerView.swift
//  Vecka
//

import SwiftUI

struct CurrencyPickerView: View {
    @Binding var selectedCurrency: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.johoColorMode) private var colorMode

    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        ScrollView {
            VStack(spacing: JohoDimensions.spacingLG) {
                // Header
                JohoPageHeader(
                    title: "Base Currency",
                    badge: "SELECT"
                )
                .padding(.horizontal, JohoDimensions.spacingLG)
                .padding(.top, JohoDimensions.spacingSM)

                // Currency list
                VStack(spacing: JohoDimensions.spacingSM) {
                    ForEach(CurrencyDefinition.defaultCurrencies) { currency in
                        Button {
                            selectedCurrency = currency.code
                            HapticManager.selection()
                            dismiss()
                        } label: {
                            HStack(spacing: JohoDimensions.spacingMD) {
                                // Currency symbol zone
                                Text(currency.symbol)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(colors.primary)
                                    .johoTouchTarget()
                                    .background(selectedCurrency == currency.code ? SectionZone.expenses.background : JohoColors.inputBackground)
                                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                                    .overlay(
                                        Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                            .stroke(colors.border, lineWidth: selectedCurrency == currency.code ? JohoDimensions.borderMedium : JohoDimensions.borderThin)
                                    )

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(currency.code)
                                        .font(JohoFont.headline)
                                        .foregroundStyle(colors.primary)

                                    Text(currency.name)
                                        .font(JohoFont.body)
                                        .foregroundStyle(colors.secondary)
                                }

                                Spacer()

                                if selectedCurrency == currency.code {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(colors.primary)
                                }
                            }
                            .padding(JohoDimensions.spacingMD)
                            .background(colors.surface)
                            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                            .overlay(
                                Squircle(cornerRadius: JohoDimensions.radiusMedium)
                                    .stroke(colors.border, lineWidth: selectedCurrency == currency.code ? JohoDimensions.borderThick : JohoDimensions.borderMedium)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, JohoDimensions.spacingLG)

                Spacer(minLength: JohoDimensions.spacingXL)
            }
            .padding(.bottom, JohoDimensions.spacingXL)
        }
        .johoBackground()
        .toolbar(.hidden, for: .navigationBar)
    }
}
