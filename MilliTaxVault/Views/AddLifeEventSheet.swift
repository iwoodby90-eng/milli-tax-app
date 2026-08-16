import SwiftUI

// MARK: - LifePlanningEvent
// Shared planning model used by Tree of Life and the add-event workflow.

struct LifePlanningEvent: Identifiable, Equatable {
    let id: UUID
    var type: LifeEventType
    var targetDate: Date
    var estimatedCost: Double
    var notes: String

    init(
        id: UUID = UUID(),
        type: LifeEventType,
        targetDate: Date,
        estimatedCost: Double,
        notes: String = ""
    ) {
        self.id = id
        self.type = type
        self.targetDate = targetDate
        self.estimatedCost = estimatedCost
        self.notes = notes
    }
}

enum LifeEventType: String, CaseIterable, Identifiable {
    case homePurchase = "Buy a home"
    case vehicle = "New car"
    case marriage = "Wedding"
    case child = "Baby"
    case businessLaunch = "Business launch"
    case education = "Education"
    case retirement = "Retire"
    case emergencyFund = "Emergency fund"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .homePurchase: return "house.fill"
        case .vehicle: return "car.fill"
        case .marriage: return "person.2.fill"
        case .child: return "heart.fill"
        case .businessLaunch: return "briefcase.fill"
        case .education: return "graduationcap.fill"
        case .retirement: return "sun.horizon.fill"
        case .emergencyFund: return "shield.fill"
        }
    }
}

// MARK: - AddLifeEventSheet

struct AddLifeEventSheet: View {
    @Environment(\.dismiss) private var dismiss

    var onSave: (LifePlanningEvent) -> Void = { _ in }

    @State private var eventType: LifeEventType = .homePurchase
    @State private var targetDate: Date = Calendar.current.date(byAdding: .year, value: 3, to: Date()) ?? Date()
    @State private var estimatedCost: String = ""
    @State private var notes: String = ""

    private var parsedCost: Double? {
        let cleaned = estimatedCost
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Double(cleaned), value > 0 else { return nil }
        return value
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MilliColors.background.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 18) {
                        eventTypeSection
                        targetDateSection
                        estimatedCostSection
                        notesSection
                        saveButton
                    }
                    .padding(.horizontal, MilliSpacing.screenHorizontal)
                    .padding(.top, 20)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Add Life Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(MilliColors.cyanGlow)
                }
            }
        }
        .presentationDetents([.large])
        .preferredColorScheme(.dark)
    }

    private var eventTypeSection: some View {
        formSection(title: "EVENT TYPE") {
            Menu {
                ForEach(LifeEventType.allCases) { type in
                    Button {
                        eventType = type
                    } label: {
                        Label(type.rawValue, systemImage: type.icon)
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: eventType.icon)
                        .foregroundStyle(MilliColors.cyanGlow)
                        .frame(width: 22)
                    Text(eventType.rawValue)
                        .font(MilliFont.bodyMedium)
                        .foregroundStyle(MilliColors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(MilliColors.textTertiary)
                }
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(fieldBackground)
            }
        }
    }

    private var targetDateSection: some View {
        formSection(title: "TARGET DATE") {
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(MilliColors.cyanGlow)
                DatePicker(
                    "Target date",
                    selection: $targetDate,
                    in: Date()...,
                    displayedComponents: .date
                )
                .labelsHidden()
                .datePickerStyle(.compact)
                .tint(MilliColors.cyanGlow)
                Spacer()
            }
            .padding(.horizontal, 14)
            .frame(height: 48)
            .background(fieldBackground)
        }
    }

    private var estimatedCostSection: some View {
        formSection(title: "ESTIMATED COST / TARGET") {
            HStack(spacing: 8) {
                Text("$")
                    .font(MilliFont.headlineSmall)
                    .foregroundStyle(MilliColors.textSecondary)
                TextField("0", text: $estimatedCost)
                    .keyboardType(.decimalPad)
                    .font(MilliFont.numericMedium)
                    .monospacedDigit()
                    .foregroundStyle(MilliColors.textPrimary)
            }
            .padding(.horizontal, 14)
            .frame(height: 48)
            .background(fieldBackground)
        }
    }

    private var notesSection: some View {
        formSection(title: "NOTES") {
            TextField("Optional planning details", text: $notes, axis: .vertical)
                .lineLimit(3...5)
                .font(MilliFont.bodyMedium)
                .foregroundStyle(MilliColors.textPrimary)
                .padding(14)
                .background(fieldBackground)
        }
    }

    private var saveButton: some View {
        Button {
            guard let cost = parsedCost else { return }
            onSave(
                LifePlanningEvent(
                    type: eventType,
                    targetDate: targetDate,
                    estimatedCost: cost,
                    notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            )
            dismiss()
        } label: {
            Text("Add to Tree of Life")
                .font(MilliFont.headlineSmall)
                .foregroundStyle(MilliColors.blackGlass)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(parsedCost == nil ? MilliColors.textTertiary : MilliColors.cyanGlow)
                        .shadow(
                            color: parsedCost == nil ? .clear : MilliColors.cyanGlow.opacity(0.20),
                            radius: 8
                        )
                )
        }
        .buttonStyle(.plain)
        .disabled(parsedCost == nil)
        .padding(.top, 4)
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(MilliColors.graphiteSurface)
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.white.opacity(0.07), lineWidth: 0.7)
            }
    }

    private func formSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .sectionHeaderStyle()
            content()
        }
    }
}

#Preview {
    AddLifeEventSheet()
}
