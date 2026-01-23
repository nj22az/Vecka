//
//  MemoEditorView.swift
//  Vecka
//
//  情報デザイン (Jōhō Dezain) - Paper Planner Style
//  Write something. Add details if you need them.
//  No categories. No complexity. Just write.
//

import SwiftUI
import SwiftData

struct MemoEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.johoColorMode) private var colorMode
    @Environment(\.dismiss) private var dismiss

    // Input
    let existingMemo: Memo?
    let initialDate: Date

    // Core state
    @State private var text: String = ""
    @State private var date: Date = Date()
    @State private var priority: MemoPriority = .normal

    // Optional details (progressive disclosure)
    @State private var amount: String = ""
    @State private var currency: String = "SEK"
    @State private var place: String = ""
    @State private var person: String = ""

    // Expansion state
    @State private var showAmount = false
    @State private var showPlace = false
    @State private var showPerson = false

    // UI state
    @State private var showDatePicker = false
    @State private var showDeleteConfirm = false
    @FocusState private var isTextFocused: Bool

    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }
    private var isEditing: Bool { existingMemo != nil }

    init(date: Date = Date(), existingMemo: Memo? = nil) {
        self.initialDate = date
        self.existingMemo = existingMemo
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            header

            VStack(spacing: 0) {
                contentCard
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .background(JohoColors.black)
        .onAppear { loadExisting() }
        .presentationBackground(JohoColors.black)
        .presentationDragIndicator(.hidden)
        .sheet(isPresented: $showDatePicker) {
            datePickerSheet
                .presentationBackground(JohoColors.black)
                .presentationDetents([.medium])
        }
        .alert("Delete?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) { deleteMemo() }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button("Cancel") { dismiss() }
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(JohoColors.white)
                .frame(minWidth: 44, minHeight: 44)

            Spacer()

            Text(isEditing ? "Edit" : "Memo")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(JohoColors.white)

            Spacer()

            Button("Save") { saveMemo() }
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(canSave ? JohoColors.white : JohoColors.white.opacity(0.4))
                .frame(minWidth: 44, minHeight: 44)
                .disabled(!canSave)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(JohoColors.black)
    }

    // MARK: - Content Card

    private var contentCard: some View {
        VStack(spacing: 0) {
            // Main text field
            textField
                .padding(12)

            divider

            // Date row
            dateRow
                .padding(12)

            divider

            // Priority row
            priorityRow
                .padding(12)

            divider

            // Add details section
            detailChips
                .padding(12)

            // Expanded detail fields
            if showAmount {
                divider
                amountField
                    .padding(12)
            }

            if showPlace {
                divider
                placeField
                    .padding(12)
            }

            if showPerson {
                divider
                personField
                    .padding(12)
            }

            // Delete button
            if isEditing {
                divider
                deleteButton
            }
        }
        .background(colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(colors.border, lineWidth: 2)
        )
    }

    private var divider: some View {
        Rectangle()
            .fill(colors.border)
            .frame(height: 1)
    }

    // MARK: - Text Field

    private var textField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("MEMO")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(colors.secondary)

            TextField("Write something...", text: $text, axis: .vertical)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(colors.primary)
                .lineLimit(3...6)
                .focused($isTextFocused)
        }
    }

    // MARK: - Date Row

    private var dateRow: some View {
        HStack {
            Text("DATE")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(colors.secondary)

            Spacer()

            Button {
                showDatePicker = true
                HapticManager.impact(.light)
            } label: {
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(colors.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(JohoColors.black, lineWidth: 1.5)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Priority Row

    private var priorityRow: some View {
        HStack {
            Text("PRIORITY")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(colors.secondary)

            Spacer()

            HStack(spacing: 0) {
                ForEach(MemoPriority.allCases, id: \.self) { p in
                    Button {
                        priority = p
                        HapticManager.selection()
                    } label: {
                        Text(p.symbol)
                            .font(.system(size: 18))
                            .frame(width: 44, height: 36)
                            .background(priority == p ? JohoColors.yellow : colors.surface)
                    }
                    .buttonStyle(.plain)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(colors.border, lineWidth: 1)
            )
        }
    }

    // MARK: - Detail Chips (Progressive Disclosure)

    private var detailChips: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ADD DETAILS")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(colors.secondary)

            HStack(spacing: 8) {
                detailChip("yensign.circle", "Amount", isActive: showAmount, color: JohoColors.green) {
                    withAnimation(.easeInOut(duration: 0.2)) { showAmount.toggle() }
                }

                detailChip("mappin", "Place", isActive: showPlace, color: JohoColors.cyan) {
                    withAnimation(.easeInOut(duration: 0.2)) { showPlace.toggle() }
                }

                detailChip("person", "Person", isActive: showPerson, color: JohoColors.purple) {
                    withAnimation(.easeInOut(duration: 0.2)) { showPerson.toggle() }
                }
            }
        }
    }

    private func detailChip(_ icon: String, _ label: String, isActive: Bool, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: {
            action()
            HapticManager.selection()
        }) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                Text(label)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
            }
            .foregroundStyle(isActive ? colors.surfaceInverted : colors.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(isActive ? color : colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(JohoColors.black, lineWidth: isActive ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Detail Fields

    private var amountField: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("AMOUNT")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.secondary)
                TextField("0", text: $amount)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .keyboardType(.decimalPad)
                    .foregroundStyle(colors.primary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("CURRENCY")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.secondary)
                Picker("", selection: $currency) {
                    Text("SEK").tag("SEK")
                    Text("EUR").tag("EUR")
                    Text("USD").tag("USD")
                }
                .pickerStyle(.segmented)
            }
            .frame(width: 140)
        }
        .padding(10)
        .background(JohoColors.green.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var placeField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("PLACE")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(colors.secondary)
            TextField("Where...", text: $place)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(colors.primary)
        }
        .padding(10)
        .background(JohoColors.cyan.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var personField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("PERSON")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(colors.secondary)
            TextField("Who...", text: $person)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(colors.primary)
        }
        .padding(10)
        .background(JohoColors.purple.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    // MARK: - Delete Button

    private var deleteButton: some View {
        Button {
            showDeleteConfirm = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("Delete")
            }
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundStyle(JohoColors.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Date Picker Sheet

    private var datePickerSheet: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Cancel") { showDatePicker = false }
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(JohoColors.white)
                Spacer()
                Text("Date")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoColors.white)
                Spacer()
                Button("Done") { showDatePicker = false }
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoColors.white)
            }
            .padding(16)
            .background(JohoColors.black)

            DatePicker("", selection: $date, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()
                .padding(16)
                .background(colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(colors.border, lineWidth: 2)
                )
                .padding(8)

            Spacer()
        }
        .background(JohoColors.black)
    }

    // MARK: - Validation

    private var canSave: Bool {
        !text.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Load / Save

    private func loadExisting() {
        guard let memo = existingMemo else {
            date = initialDate
            return
        }

        text = memo.text
        date = memo.date
        priority = memo.priority

        // Optional details
        if let amt = memo.amount {
            amount = String(format: "%.2f", amt)
            showAmount = true
        }
        currency = memo.currency ?? "SEK"

        if let p = memo.place, !p.isEmpty {
            place = p
            showPlace = true
        }

        if let per = memo.person, !per.isEmpty {
            person = per
            showPerson = true
        }
    }

    private func saveMemo() {
        let memo = existingMemo ?? Memo(text: text, date: date)

        memo.text = text
        memo.date = date
        memo.priority = priority

        // Optional details
        memo.amount = showAmount ? Double(amount) : nil
        memo.currency = showAmount ? currency : nil
        memo.place = showPlace && !place.isEmpty ? place : nil
        memo.person = showPerson && !person.isEmpty ? person : nil

        if existingMemo == nil {
            modelContext.insert(memo)
        }

        try? modelContext.save()
        HapticManager.notification(.success)
        dismiss()
    }

    private func deleteMemo() {
        guard let memo = existingMemo else { return }
        modelContext.delete(memo)
        try? modelContext.save()
        HapticManager.notification(.warning)
        dismiss()
    }
}

#Preview {
    MemoEditorView(date: Date())
        .modelContainer(for: Memo.self, inMemory: true)
}
