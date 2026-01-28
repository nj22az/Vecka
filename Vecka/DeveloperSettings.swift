//
//  DeveloperSettings.swift
//  Vecka
//
//  Developer/Debug features for testing
//  情報デザイン (Jōhō Dezain) - Japanese Information Design
//

import SwiftUI
import SwiftData

// MARK: - Developer Settings View

struct DeveloperSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.johoColorMode) private var colorMode
    @Environment(\.dismiss) private var dismiss

    @State private var isGeneratingData = false
    @State private var showingResetConfirmation = false
    @State private var showingSuccessMessage = false
    @State private var successMessage = ""

    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: JohoDimensions.spacingLG) {
                    // Header
                    developerHeader
                        .padding(.horizontal, JohoDimensions.spacingLG)
                        .padding(.top, JohoDimensions.spacingSM)

                    // Dummy Data Section
                    dummyDataSection

                    // Debug Info Section
                    debugInfoSection

                    // Danger Zone
                    dangerZoneSection

                    Spacer(minLength: JohoDimensions.spacingXL)
                }
                .padding(.bottom, JohoDimensions.spacingXL)
            }
            .johoBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primary)
                }
            }
        }
        .alert("Reset All Data?", isPresented: $showingResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetAllData()
            }
        } message: {
            Text("This will delete ALL user data including contacts, memos, and custom holidays. This cannot be undone.")
        }
        .alert("Success", isPresented: $showingSuccessMessage) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(successMessage)
        }
    }

    // MARK: - Header

    private var developerHeader: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                HStack(spacing: JohoDimensions.spacingSM) {
                    Image(systemName: "hammer.fill")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(JohoColors.cyan)
                        .frame(width: 40, height: 40)
                        .background(JohoColors.cyan.opacity(0.2))
                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                        .overlay(
                            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                .stroke(JohoColors.black, lineWidth: 1.5)
                        )

                    Text("DEVELOPER")
                        .font(JohoFont.headline)
                        .foregroundStyle(colors.primary)
                }
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.vertical, JohoDimensions.spacingSM)
                .frame(maxWidth: .infinity, alignment: .leading)

                Rectangle()
                    .fill(JohoColors.black)
                    .frame(width: 1.5)

                HStack(spacing: 4) {
                    Text("DEBUG")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(JohoColors.red)
                }
                .frame(width: 80)
            }
            .frame(height: 56)
        }
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(colors.border, lineWidth: JohoDimensions.borderMedium)
        )
    }

    // MARK: - Dummy Data Section

    private var dummyDataSection: some View {
        VStack(alignment: .leading, spacing: JohoDimensions.spacingMD) {
            JohoPill(text: "TEST DATA", style: .whiteOnBlack, size: .small)

            VStack(spacing: JohoDimensions.spacingSM) {
                // Generate All Data
                Button {
                    generateAllDummyData()
                } label: {
                    HStack(spacing: JohoDimensions.spacingMD) {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(JohoColors.cyan)
                            .johoTouchTarget()
                            .background(JohoColors.cyan.opacity(0.2))
                            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                            .overlay(
                                Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                    .stroke(colors.border, lineWidth: 1)
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Generate All Test Data")
                                .font(JohoFont.headline)
                                .foregroundStyle(colors.primary)

                            Text("Contacts and memos (notes, expenses, trips)")
                                .font(JohoFont.caption)
                                .foregroundStyle(colors.secondary)
                        }

                        Spacer()

                        if isGeneratingData {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(colors.secondary)
                        }
                    }
                    .padding(JohoDimensions.spacingMD)
                    .background(colors.surface)
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                    .overlay(
                        Squircle(cornerRadius: JohoDimensions.radiusMedium)
                            .stroke(colors.border, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(isGeneratingData)

                // 情報デザイン: Organized by semantic category

                // ═══════════════════════════════════════════════════════════════
                // 今 NOW (Yellow) - Notes, Tasks, Pinned
                // ═══════════════════════════════════════════════════════════════
                categoryHeader(label: "今 NOW", color: JohoColors.yellow)

                HStack(spacing: JohoDimensions.spacingSM) {
                    miniGeneratorButton(
                        icon: "note.text",
                        label: "Notes",
                        color: JohoColors.yellow
                    ) {
                        generateDummyNotes()
                    }

                    miniGeneratorButton(
                        icon: "checklist",
                        label: "Tasks",
                        color: JohoColors.yellow
                    ) {
                        generateDummyTasks()
                    }

                    miniGeneratorButton(
                        icon: "pin.fill",
                        label: "Pinned",
                        color: JohoColors.yellow
                    ) {
                        generateDummyPinned()
                    }
                }

                // ═══════════════════════════════════════════════════════════════
                // 予定 SCHEDULED (Cyan) - Meetings, Trips
                // ═══════════════════════════════════════════════════════════════
                categoryHeader(label: "予定 SCHEDULED", color: JohoColors.cyan)

                HStack(spacing: JohoDimensions.spacingSM) {
                    miniGeneratorButton(
                        icon: "person.2.fill",
                        label: "Meetings",
                        color: JohoColors.cyan
                    ) {
                        generateDummyMeetings()
                    }

                    miniGeneratorButton(
                        icon: "airplane",
                        label: "Trips",
                        color: JohoColors.cyan
                    ) {
                        generateDummyTrips()
                    }

                    miniGeneratorButton(
                        icon: "star.fill",
                        label: "Holidays",
                        color: JohoColors.cyan
                    ) {
                        generateDummyHolidays()
                    }
                }

                // ═══════════════════════════════════════════════════════════════
                // 祝 CELEBRATION (Pink) - Birthdays, Countdowns
                // ═══════════════════════════════════════════════════════════════
                categoryHeader(label: "祝 CELEBRATION", color: JohoColors.pink)

                HStack(spacing: JohoDimensions.spacingSM) {
                    miniGeneratorButton(
                        icon: "birthday.cake.fill",
                        label: "Birthdays",
                        color: JohoColors.pink
                    ) {
                        generateDummyBirthdays()
                    }

                    miniGeneratorButton(
                        icon: "timer",
                        label: "Countdowns",
                        color: JohoColors.pink
                    ) {
                        generateDummyCountdowns()
                    }

                    // Placeholder for grid alignment
                    Color.clear
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                }

                // ═══════════════════════════════════════════════════════════════
                // 金 MONEY (Green) - Expenses
                // ═══════════════════════════════════════════════════════════════
                categoryHeader(label: "金 MONEY", color: JohoColors.green)

                HStack(spacing: JohoDimensions.spacingSM) {
                    miniGeneratorButton(
                        icon: "yensign.circle.fill",
                        label: "Expenses",
                        color: JohoColors.green
                    ) {
                        generateDummyExpenses()
                    }

                    // Placeholders for grid alignment
                    Color.clear
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)

                    Color.clear
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                }

                // ═══════════════════════════════════════════════════════════════
                // 人 PERSON (Purple) - Contacts
                // ═══════════════════════════════════════════════════════════════
                categoryHeader(label: "人 PERSON", color: JohoColors.purple)

                HStack(spacing: JohoDimensions.spacingSM) {
                    miniGeneratorButton(
                        icon: "person.crop.circle.fill",
                        label: "Contacts",
                        color: JohoColors.purple
                    ) {
                        generateDummyContacts()
                    }

                    // Placeholders for grid alignment
                    Color.clear
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)

                    Color.clear
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                }

                // Sample Images section
                Rectangle()
                    .fill(colors.border.opacity(0.5))
                    .frame(height: 1)
                    .padding(.vertical, JohoDimensions.spacingSM)

                // Assign Sample Avatars button
                Button {
                    assignSampleAvatarsToContacts()
                } label: {
                    HStack(spacing: JohoDimensions.spacingMD) {
                        Image(systemName: "photo.fill.on.rectangle.fill")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(JohoColors.purple)
                            .johoTouchTarget()
                            .background(JohoColors.purple.opacity(0.2))
                            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                            .overlay(
                                Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                    .stroke(colors.border, lineWidth: 1)
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Assign Sample Avatars")
                                .font(JohoFont.headline)
                                .foregroundStyle(colors.primary)

                            Text("Add colorful test avatars to contacts")
                                .font(JohoFont.caption)
                                .foregroundStyle(colors.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.secondary)
                    }
                    .padding(JohoDimensions.spacingMD)
                    .background(colors.surface)
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                    .overlay(
                        Squircle(cornerRadius: JohoDimensions.radiusMedium)
                            .stroke(colors.border, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                // Preview sample avatars
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: JohoDimensions.spacingSM) {
                        ForEach(0..<6, id: \.self) { index in
                            SampleAvatarPreview(index: index)
                                .johoTouchTarget()
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .padding(.vertical, JohoDimensions.spacingSM)
            }

            Text("Generate realistic test data for development and testing.")
                .font(JohoFont.caption)
                .foregroundStyle(colors.secondary)
                .padding(.horizontal, JohoDimensions.spacingSM)
        }
        .padding(JohoDimensions.spacingLG)
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusLarge)
                .stroke(colors.border, lineWidth: JohoDimensions.borderThick)
        )
        .padding(.horizontal, JohoDimensions.spacingLG)
    }

    private func miniGeneratorButton(
        icon: String,
        label: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            action()
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(color)

                Text(label)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, JohoDimensions.spacingMD)
            .background(color.opacity(0.1))
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
            .overlay(
                Squircle(cornerRadius: JohoDimensions.radiusSmall)
                    .stroke(color.opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    /// 情報デザイン: Category header for semantic grouping
    private func categoryHeader(label: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .overlay(Circle().stroke(JohoColors.black, lineWidth: 1))

            Text(label)
                .font(.system(size: 10, weight: .black, design: .rounded))
                .tracking(0.5)
                .foregroundStyle(colors.primary)

            Spacer()
        }
        .padding(.top, JohoDimensions.spacingSM)
    }

    // MARK: - Debug Info Section

    private var debugInfoSection: some View {
        VStack(alignment: .leading, spacing: JohoDimensions.spacingMD) {
            JohoPill(text: "DEBUG INFO", style: .whiteOnBlack, size: .small)

            // 情報デザイン: Stats header showing data counts by category
            dataStatsRow

            VStack(spacing: 1) {
                debugInfoRow(label: "App Version", value: "1.0.0")
                debugInfoRow(label: "Build", value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown")
                debugInfoRow(label: "Device", value: UIDevice.current.name)
                debugInfoRow(label: "iOS Version", value: UIDevice.current.systemVersion)
                debugInfoRow(label: "Color Mode", value: colorMode == .dark ? "Dark" : "Light")
            }
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
            .overlay(
                Squircle(cornerRadius: JohoDimensions.radiusMedium)
                    .stroke(colors.border, lineWidth: 1)
            )
        }
        .padding(JohoDimensions.spacingLG)
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusLarge)
                .stroke(colors.border, lineWidth: JohoDimensions.borderThick)
        )
        .padding(.horizontal, JohoDimensions.spacingLG)
    }

    private func debugInfoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(JohoFont.body)
                .foregroundStyle(colors.secondary)

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundStyle(colors.primary)
        }
        .padding(.horizontal, JohoDimensions.spacingMD)
        .padding(.vertical, JohoDimensions.spacingSM)
        .background(colors.inputBackground)
    }

    /// 情報デザイン: Stats row showing data counts by semantic category
    private var dataStatsRow: some View {
        let memoDescriptor = FetchDescriptor<Memo>()
        let contactDescriptor = FetchDescriptor<Contact>()
        let holidayDescriptor = FetchDescriptor<HolidayRule>()

        let memos = (try? modelContext.fetch(memoDescriptor)) ?? []
        let contactCount = (try? modelContext.fetchCount(contactDescriptor)) ?? 0
        let holidayCount = (try? modelContext.fetchCount(holidayDescriptor)) ?? 0

        // Count memos by type
        let notes = memos.filter { $0.type == .note && $0.isCountdown != true && $0.tripEndDate == nil }.count
        let expenses = memos.filter { $0.type == .expense }.count
        let trips = memos.filter { $0.type == .trip || $0.tripEndDate != nil }.count
        let countdowns = memos.filter { $0.isCountdown == true }.count

        return HStack(spacing: JohoDimensions.spacingSM) {
            // Notes (Yellow)
            statChip(count: notes, icon: "note.text", color: JohoColors.yellow)

            // Trips (Cyan)
            statChip(count: trips, icon: "airplane", color: JohoColors.cyan)

            // Countdowns (Pink)
            statChip(count: countdowns, icon: "timer", color: JohoColors.pink)

            // Expenses (Green)
            statChip(count: expenses, icon: "yensign.circle.fill", color: JohoColors.green)

            // Contacts (Purple)
            statChip(count: contactCount, icon: "person.crop.circle.fill", color: JohoColors.purple)

            // Holidays (Pink secondary)
            statChip(count: holidayCount, icon: "star.fill", color: JohoColors.pink.opacity(0.7))
        }
        .padding(JohoDimensions.spacingSM)
        .background(colors.surface.opacity(0.5))
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                .stroke(colors.border.opacity(0.5), lineWidth: 1)
        )
    }

    private func statChip(count: Int, icon: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(color)

            Text("\(count)")
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundStyle(colors.primary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }

    private func showSuccess(_ message: String) {
        successMessage = message
        showingSuccessMessage = true
    }

    // MARK: - Danger Zone

    private var dangerZoneSection: some View {
        VStack(alignment: .leading, spacing: JohoDimensions.spacingMD) {
            JohoPill(text: "DANGER ZONE", style: .whiteOnBlack, size: .small)

            Button {
                showingResetConfirmation = true
            } label: {
                HStack(spacing: JohoDimensions.spacingMD) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(JohoColors.red)
                        .johoTouchTarget()
                        .background(JohoColors.red.opacity(0.2))
                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                        .overlay(
                            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                .stroke(JohoColors.red, lineWidth: 1)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Reset All Data")
                            .font(JohoFont.headline)
                            .foregroundStyle(JohoColors.red)

                        Text("Delete everything and start fresh")
                            .font(JohoFont.caption)
                            .foregroundStyle(colors.secondary)
                    }

                    Spacer()

                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(JohoColors.red)
                }
                .padding(JohoDimensions.spacingMD)
                .background(JohoColors.red.opacity(0.05))
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusMedium)
                        .stroke(JohoColors.red.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            Text("This action cannot be undone. All your data will be permanently deleted.")
                .font(JohoFont.caption)
                .foregroundStyle(JohoColors.red.opacity(0.7))
                .padding(.horizontal, JohoDimensions.spacingSM)
        }
        .padding(JohoDimensions.spacingLG)
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusLarge)
                .stroke(JohoColors.red.opacity(0.3), lineWidth: JohoDimensions.borderThick)
        )
        .padding(.horizontal, JohoDimensions.spacingLG)
    }

    // MARK: - Data Generation Functions

    private func generateAllDummyData() {
        isGeneratingData = true

        Task {
            await MainActor.run {
                // 情報デザイン: Generate all memo types by category

                // 人 PERSON (Purple)
                generateDummyContacts()

                // 今 NOW (Yellow)
                generateDummyNotes()
                generateDummyTasks()
                generateDummyPinned()

                // 予定 SCHEDULED (Cyan)
                generateDummyMeetings()
                generateDummyTrips()

                // 祝 CELEBRATION (Pink)
                generateDummyCountdowns()
                generateDummyBirthdays()  // Requires contacts

                // 金 MONEY (Green)
                generateDummyExpenses()

                isGeneratingData = false
                successMessage = "Generated complete test data for all categories!"
                showingSuccessMessage = true
                HapticManager.notification(.success)
            }
        }
    }

    private func generateDummyContacts() {
        let firstNames = ["Emma", "Liam", "Olivia", "Noah", "Ava", "Ethan", "Sophia", "Mason", "Isabella", "James", "Mia", "Alexander", "Charlotte", "Benjamin", "Amelia"]
        let lastNames = ["Andersson", "Johansson", "Karlsson", "Nilsson", "Eriksson", "Larsson", "Olsson", "Persson", "Svensson", "Gustafsson", "Pettersson", "Jonsson", "Jansson", "Hansson", "Bengtsson"]
        let companies = ["Spotify", "IKEA", "Volvo", "Ericsson", "H&M", "Klarna", "King", "Mojang", "Electrolux", "Scania"]

        for _ in 0..<10 {
            let firstName = firstNames.randomElement() ?? "Test"
            let lastName = lastNames.randomElement() ?? "User"
            let company = companies.randomElement()

            // Create phone number
            let phone = ContactPhoneNumber(
                label: ["mobile", "work", "home"].randomElement() ?? "mobile",
                value: "+46 70 \(Int.random(in: 100...999)) \(Int.random(in: 10...99)) \(Int.random(in: 10...99))"
            )

            // Create email
            let email = ContactEmailAddress(
                label: "work",
                value: "\(firstName.lowercased()).\(lastName.lowercased())@\(company?.lowercased() ?? "test").se"
            )

            let contact = Contact(
                givenName: firstName,
                familyName: lastName,
                organizationName: Bool.random() ? company : nil,
                phoneNumbers: [phone],
                emailAddresses: [email],
                birthday: Bool.random() ? Calendar.current.date(byAdding: .year, value: -Int.random(in: 20...60), to: Date()) : nil,
                group: [ContactGroup.family, .friends, .work, .other].randomElement() ?? .other
            )

            modelContext.insert(contact)
        }

        try? modelContext.save()
        successMessage = "Generated 10 test contacts!"
        showingSuccessMessage = true
        HapticManager.notification(.success)
    }

    private func generateDummyNotes() {
        let noteContents = [
            "Morning standup - design team 情報デザイン",
            "Code review: SwiftUI performance",
            "Call dentist for appointment",
            "Shopping: milk, bread, eggs, coffee",
            "Prepare presentation for Friday",
            "Update project documentation",
            "Book flight tickets for vacation",
            "Research new Swift 6 features",
            "Fix bug in calendar view",
            "Plan birthday surprise for Lisa"
        ]

        let calendar = Calendar.current
        for content in noteContents {
            let daysAgo = Int.random(in: 0...30)
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()

            let memo = Memo.quick(content, date: date)
            modelContext.insert(memo)
        }

        try? modelContext.save()
        successMessage = "Generated 10 test memos!"
        showingSuccessMessage = true
        HapticManager.notification(.success)
    }

    private func generateDummyExpenses() {
        let expenses: [(description: String, minAmount: Double, maxAmount: Double)] = [
            ("Lunch at restaurant", 80, 250),
            ("Uber ride", 50, 200),
            ("Netflix subscription", 99, 99),
            ("New headphones", 500, 2000),
            ("Electricity bill", 300, 800),
            ("Gym membership", 299, 499),
            ("Coffee at Espresso House", 35, 75),
            ("Train ticket to Malmö", 150, 400),
            ("Movie tickets", 100, 200),
            ("Weekly groceries", 500, 1200)
        ]

        let calendar = Calendar.current
        for expense in expenses {
            let daysAgo = Int.random(in: 0...30)
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()

            let memo = Memo.withAmount(
                expense.description,
                amount: Double.random(in: expense.minAmount...expense.maxAmount).rounded(),
                currency: "SEK",
                date: date
            )
            modelContext.insert(memo)
        }

        try? modelContext.save()
        successMessage = "Generated 10 test expenses!"
        showingSuccessMessage = true
        HapticManager.notification(.success)
    }

    private func generateDummyTrips() {
        // 情報デザイン: Realistic trips with proper start/end dates
        let trips: [(city: String, country: String, duration: Int, purpose: String)] = [
            ("Tokyo", "Japan", 10, "vacation"),
            ("Paris", "France", 5, "business"),
            ("New York", "USA", 7, "conference"),
            ("London", "UK", 3, "family"),
            ("Barcelona", "Spain", 4, "vacation"),
            ("Stockholm", "Sweden", 2, "business"),
            ("Ho Chi Minh City", "Vietnam", 14, "vacation"),
            ("Copenhagen", "Denmark", 3, "weekend")
        ]

        let calendar = Calendar.current
        for trip in trips.prefix(5) {
            let startOffset = Int.random(in: -30...90)
            let startDate = calendar.date(byAdding: .day, value: startOffset, to: Date()) ?? Date()
            let endDate = calendar.date(byAdding: .day, value: trip.duration, to: startDate) ?? startDate

            // 情報デザイン: Use proper Memo.trip() factory with all fields
            let memo = Memo.trip(
                "\(trip.city) trip",
                startDate: startDate,
                endDate: endDate,
                destination: "\(trip.city), \(trip.country)",
                purpose: trip.purpose
            )
            modelContext.insert(memo)
        }

        try? modelContext.save()
        successMessage = "Generated 5 test trips with dates!"
        showingSuccessMessage = true
        HapticManager.notification(.success)
    }

    private func generateDummyCountdowns() {
        // 情報デザイン: Countdowns with proper icons and colors
        let countdowns: [(title: String, days: Int, icon: String, color: String?)] = [
            ("Summer Vacation", 45, "sun.max.fill", "A5F3FC"),      // Cyan
            ("Birthday Party", 12, "birthday.cake.fill", "FECDD3"), // Pink
            ("Conference Talk", 30, "mic.fill", "E9D5FF"),          // Purple
            ("Product Launch", 60, "rocket.fill", "BBF7D0"),        // Green
            ("Wedding Anniversary", 90, "heart.fill", "FECDD3"),    // Pink
            ("Christmas", 340, "gift.fill", "FECDD3"),              // Pink
            ("New Year", 365, "sparkles", "FFE566"),                // Yellow
            ("Midsommar", 150, "leaf.fill", "BBF7D0")               // Green
        ]

        let calendar = Calendar.current
        for countdown in countdowns.prefix(5) {
            let targetDate = calendar.date(byAdding: .day, value: countdown.days, to: Date()) ?? Date()

            // 情報デザイン: Use proper Memo.countdown() factory
            let memo = Memo.countdown(
                countdown.title,
                targetDate: targetDate,
                icon: countdown.icon,
                colorHex: countdown.color
            )
            modelContext.insert(memo)
        }

        try? modelContext.save()
        successMessage = "Generated 5 countdown events!"
        showingSuccessMessage = true
        HapticManager.notification(.success)
    }

    // MARK: - New Generators (情報デザイン: Complete memo coverage)

    private func generateDummyMeetings() {
        // 情報デザイン: Scheduled appointments with person links
        let meetings: [(title: String, person: String?, hours: Int)] = [
            ("Team Standup", nil, 1),
            ("Client Review", "Emma Larsson", 2),
            ("Design Review", "Liam Andersson", 1),
            ("1:1 with Manager", "Sofia Nilsson", 1),
            ("Sprint Planning", nil, 2),
            ("Product Demo", "Marcus Eriksson", 1),
            ("Interview Candidate", "External", 1),
            ("Lunch with Lisa", "Lisa Svensson", 1)
        ]

        let calendar = Calendar.current
        for meeting in meetings.prefix(5) {
            let daysOffset = Int.random(in: 0...14)
            let date = calendar.date(byAdding: .day, value: daysOffset, to: Date()) ?? Date()

            // Random hour between 9 and 16
            let hour = Int.random(in: 9...16)
            var components = calendar.dateComponents([.year, .month, .day], from: date)
            components.hour = hour
            components.minute = [0, 15, 30, 45].randomElement() ?? 0
            let time = calendar.date(from: components) ?? date

            let memo = Memo.meeting(
                meeting.title,
                date: date,
                time: time,
                person: meeting.person,
                duration: TimeInterval(meeting.hours * 3600)
            )
            modelContext.insert(memo)
        }

        try? modelContext.save()
        successMessage = "Generated 5 scheduled meetings!"
        showingSuccessMessage = true
        HapticManager.notification(.success)
    }

    private func generateDummyPinned() {
        // 情報デザイン: Important pinned memos for dashboard
        let pinnedItems = [
            "Remember to call mom on Sunday",
            "Project deadline: March 15",
            "Gym membership expires next month",
            "Passport renewal needed",
            "Annual review scheduled"
        ]

        for text in pinnedItems.prefix(3) {
            let memo = Memo.pinned(text)
            modelContext.insert(memo)
        }

        try? modelContext.save()
        successMessage = "Generated 3 pinned memos!"
        showingSuccessMessage = true
        HapticManager.notification(.success)
    }

    private func generateDummyBirthdays() {
        // 情報デザイン: Birthday memos linked to contacts
        let descriptor = FetchDescriptor<Contact>()
        guard let contacts = try? modelContext.fetch(descriptor), !contacts.isEmpty else {
            successMessage = "No contacts found. Generate contacts first!"
            showingSuccessMessage = true
            return
        }

        let calendar = Calendar.current
        var createdCount = 0

        for contact in contacts.prefix(5) {
            // Generate a birthday in the next 365 days
            let daysUntil = Int.random(in: 1...365)
            let birthdayDate = calendar.date(byAdding: .day, value: daysUntil, to: Date()) ?? Date()

            let memo = Memo.birthday(
                contact.displayName,
                date: birthdayDate,
                contactID: contact.id
            )
            modelContext.insert(memo)
            createdCount += 1
        }

        try? modelContext.save()
        successMessage = "Generated \(createdCount) birthday memos!"
        showingSuccessMessage = true
        HapticManager.notification(.success)
    }

    private func generateDummyTasks() {
        // 情報デザイン: Task memos with priorities
        let tasks: [(text: String, priority: MemoPriority)] = [
            ("Review pull request", .high),
            ("Update documentation", .normal),
            ("Clean up old branches", .low),
            ("Write unit tests", .high),
            ("Refactor database layer", .normal),
            ("Fix accessibility issues", .high),
            ("Update dependencies", .low),
            ("Code review feedback", .normal)
        ]

        let calendar = Calendar.current
        for task in tasks.prefix(5) {
            let daysOffset = Int.random(in: 0...7)
            let date = calendar.date(byAdding: .day, value: daysOffset, to: Date()) ?? Date()

            let memo = Memo.task(task.text, date: date, priority: task.priority)
            modelContext.insert(memo)
        }

        try? modelContext.save()
        successMessage = "Generated 5 task memos!"
        showingSuccessMessage = true
        HapticManager.notification(.success)
    }

    private func generateDummyHolidays() {
        // Custom user holidays
        let holidays = [
            ("Company Retreat", 3, 15),
            ("Team Building Day", 5, 20),
            ("Hackathon", 6, 10)
        ]

        for (name, month, day) in holidays {
            let rule = HolidayRule(
                name: name,
                region: "CUSTOM",
                isBankHoliday: false,
                symbolName: "building.2.fill",
                type: .fixed,
                month: month,
                day: day,
                isSystemDefault: false,
                isEnabled: true
            )
            modelContext.insert(rule)
        }

        try? modelContext.save()
        successMessage = "Generated 3 custom holidays!"
        showingSuccessMessage = true
        HapticManager.notification(.success)
    }

    private func resetAllData() {
        // Delete all user data
        do {
            try modelContext.delete(model: Contact.self)
            try modelContext.delete(model: Memo.self)
            try modelContext.delete(model: HolidayRule.self, where: #Predicate { $0.region == "custom" })
            try modelContext.save()

            successMessage = "All data has been reset!"
            showingSuccessMessage = true
            HapticManager.notification(.warning)
        } catch {
            Log.e("Failed to reset data: \(error)")
        }
    }

    private func assignSampleAvatarsToContacts() {
        // Fetch all contacts
        let descriptor = FetchDescriptor<Contact>()
        guard let contacts = try? modelContext.fetch(descriptor), !contacts.isEmpty else {
            successMessage = "No contacts found. Generate contacts first!"
            showingSuccessMessage = true
            return
        }

        var assignedCount = 0
        for (index, contact) in contacts.enumerated() {
            // Generate avatar with contact's initials
            let initials = contact.initials
            if let image = SampleImageGenerator.generateAvatar(
                size: CGSize(width: 200, height: 200),
                colorIndex: index % 10,
                patternIndex: index % 6,
                initials: initials
            ) {
                contact.imageData = image.jpegData(compressionQuality: 0.8)
                contact.modifiedAt = Date()
                assignedCount += 1
            }
        }

        try? modelContext.save()
        successMessage = "Assigned avatars to \(assignedCount) contacts!"
        showingSuccessMessage = true
        HapticManager.notification(.success)
    }
}

// MARK: - Sample Avatar Preview

struct SampleAvatarPreview: View {
    let index: Int
    @Environment(\.johoColorMode) private var colorMode

    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    private let avatarColors: [(Color, Color)] = [
        (Color(hex: "#FF6B6B"), Color(hex: "#FFE66D")),
        (Color(hex: "#4ECDC4"), Color(hex: "#556270")),
        (Color(hex: "#45B7D1"), Color(hex: "#96CEB4")),
        (Color(hex: "#DDA0DD"), Color(hex: "#98D8C8")),
        (Color(hex: "#F7DC6F"), Color(hex: "#82E0AA")),
        (Color(hex: "#BB8FCE"), Color(hex: "#85C1E9")),
    ]

    var body: some View {
        let colorPair = avatarColors[index % avatarColors.count]
        let pattern = SampleImageGenerator.PatternType.allCases[index % 6]

        SampleAvatarView(
            primaryColor: colorPair.0,
            secondaryColor: colorPair.1,
            pattern: pattern,
            initials: nil
        )
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(colors.border, lineWidth: 1)
        )
    }
}

// MARK: - Sample Image Generator

struct SampleImageGenerator {
    /// Generates a variety of sample avatar images for testing
    /// Uses geometric patterns, gradients, and colors to create diverse test images

    private static let avatarColors: [(Color, Color)] = [
        (Color(hex: "#FF6B6B"), Color(hex: "#FFE66D")),  // Coral to Yellow
        (Color(hex: "#4ECDC4"), Color(hex: "#556270")),  // Teal to Gray
        (Color(hex: "#45B7D1"), Color(hex: "#96CEB4")),  // Blue to Mint
        (Color(hex: "#DDA0DD"), Color(hex: "#98D8C8")),  // Plum to Seafoam
        (Color(hex: "#F7DC6F"), Color(hex: "#82E0AA")),  // Yellow to Green
        (Color(hex: "#BB8FCE"), Color(hex: "#85C1E9")),  // Purple to Blue
        (Color(hex: "#F1948A"), Color(hex: "#F8C471")),  // Pink to Orange
        (Color(hex: "#73C6B6"), Color(hex: "#5DADE2")),  // Teal to Sky
        (Color(hex: "#FAD7A0"), Color(hex: "#EDBB99")),  // Peach to Sand
        (Color(hex: "#D7BDE2"), Color(hex: "#A9CCE3")),  // Lavender to Light Blue
    ]

    private static let patterns: [PatternType] = [
        .diagonal, .circles, .waves, .dots, .stripes, .geometric
    ]

    enum PatternType: CaseIterable {
        case diagonal, circles, waves, dots, stripes, geometric
    }

    /// Generates a sample avatar image with the given parameters
    @MainActor
    static func generateAvatar(
        size: CGSize = CGSize(width: 200, height: 200),
        colorIndex: Int? = nil,
        patternIndex: Int? = nil,
        initials: String? = nil
    ) -> UIImage? {
        let colors = avatarColors[safe: colorIndex ?? Int.random(in: 0..<avatarColors.count)] ?? avatarColors[0]
        let pattern = patterns[safe: patternIndex ?? Int.random(in: 0..<patterns.count)] ?? .diagonal

        let view = SampleAvatarView(
            primaryColor: colors.0,
            secondaryColor: colors.1,
            pattern: pattern,
            initials: initials
        )
        .frame(width: size.width, height: size.height)

        let renderer = ImageRenderer(content: view)
        renderer.scale = 2.0  // Retina
        return renderer.uiImage
    }

    /// Generates multiple diverse sample avatars
    @MainActor
    static func generateAvatarSet(count: Int = 10) -> [UIImage] {
        var images: [UIImage] = []
        for i in 0..<count {
            if let image = generateAvatar(
                colorIndex: i % avatarColors.count,
                patternIndex: i % patterns.count
            ) {
                images.append(image)
            }
        }
        return images
    }
}

// Safe array subscript
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Sample Avatar View

struct SampleAvatarView: View {
    let primaryColor: Color
    let secondaryColor: Color
    let pattern: SampleImageGenerator.PatternType
    let initials: String?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background (solid color per 情報デザイン)
                primaryColor

                // Pattern overlay
                patternView(for: geometry.size)
                    .opacity(0.3)

                // Initials if provided
                if let initials = initials, !initials.isEmpty {
                    Text(initials.prefix(2).uppercased())
                        .font(.system(size: min(geometry.size.width, geometry.size.height) * 0.4, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                }
            }
        }
        .clipShape(Circle())
    }

    @ViewBuilder
    private func patternView(for size: CGSize) -> some View {
        switch pattern {
        case .diagonal:
            DiagonalStripes(spacing: 12)
                .stroke(Color.white, lineWidth: 3)
        case .circles:
            ConcentricCircles(count: 4)
                .stroke(Color.white, lineWidth: 2)
        case .waves:
            WavePattern(amplitude: 10, frequency: 3)
                .stroke(Color.white, lineWidth: 2)
        case .dots:
            DotPattern(dotSize: 6, spacing: 16)
                .fill(Color.white)
        case .stripes:
            HorizontalStripes(spacing: 14)
                .stroke(Color.white, lineWidth: 3)
        case .geometric:
            GeometricPattern()
                .stroke(Color.white, lineWidth: 2)
        }
    }
}

// MARK: - Pattern Shapes

struct DiagonalStripes: Shape {
    let spacing: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let count = Int(max(rect.width, rect.height) / spacing) + 10

        for i in -count...count {
            let x = CGFloat(i) * spacing
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x + rect.height, y: rect.height))
        }

        return path
    }
}

struct HorizontalStripes: Shape {
    let spacing: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let count = Int(rect.height / spacing) + 1

        for i in 0..<count {
            let y = CGFloat(i) * spacing
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: rect.width, y: y))
        }

        return path
    }
}

struct ConcentricCircles: Shape {
    let count: Int

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let maxRadius = min(rect.width, rect.height) / 2

        for i in 1...count {
            let radius = maxRadius * CGFloat(i) / CGFloat(count)
            path.addEllipse(in: CGRect(
                x: center.x - radius,
                y: center.y - radius,
                width: radius * 2,
                height: radius * 2
            ))
        }

        return path
    }
}

struct WavePattern: Shape {
    let amplitude: CGFloat
    let frequency: Int

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let waveHeight = rect.height / CGFloat(frequency + 1)

        for i in 1...frequency {
            let y = waveHeight * CGFloat(i)
            path.move(to: CGPoint(x: 0, y: y))

            for x in stride(from: 0, through: rect.width, by: 2) {
                let newY = y + sin(x * .pi / 30) * amplitude
                path.addLine(to: CGPoint(x: x, y: newY))
            }
        }

        return path
    }
}

struct DotPattern: Shape {
    let dotSize: CGFloat
    let spacing: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        for x in stride(from: spacing/2, through: rect.width, by: spacing) {
            for y in stride(from: spacing/2, through: rect.height, by: spacing) {
                path.addEllipse(in: CGRect(
                    x: x - dotSize/2,
                    y: y - dotSize/2,
                    width: dotSize,
                    height: dotSize
                ))
            }
        }

        return path
    }
}

struct GeometricPattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let size = min(rect.width, rect.height)
        let center = CGPoint(x: rect.midX, y: rect.midY)

        // Draw a hexagon
        let corners = 6
        let radius = size * 0.35

        for i in 0..<corners {
            let angle = (CGFloat(i) * 2 * .pi / CGFloat(corners)) - .pi / 2
            let point = CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            )

            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()

        // Add inner triangle
        let innerRadius = size * 0.2
        for i in 0..<3 {
            let angle = (CGFloat(i) * 2 * .pi / 3) - .pi / 2
            let point = CGPoint(
                x: center.x + cos(angle) * innerRadius,
                y: center.y + sin(angle) * innerRadius
            )

            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()

        return path
    }
}

#Preview {
    DeveloperSettingsView()
        .modelContainer(for: [Contact.self, Memo.self, HolidayRule.self])
}

#Preview("Sample Avatars") {
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 16) {
        ForEach(0..<10, id: \.self) { index in
            SampleAvatarView(
                primaryColor: Color(hex: "#FF6B6B"),
                secondaryColor: Color(hex: "#4ECDC4"),
                pattern: SampleImageGenerator.PatternType.allCases[index % 6],
                initials: ["AB", "CD", "EF", "GH", "IJ", "KL", "MN", "OP", "QR", "ST"][index]
            )
            .frame(width: 80, height: 80)
        }
    }
    .padding()
}
