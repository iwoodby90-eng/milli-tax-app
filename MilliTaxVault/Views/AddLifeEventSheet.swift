import SwiftUI

// MARK: - AddLifeEventSheet — Form for adding new life events
struct AddLifeEventSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var eventType: String = "Home Purchase"
    @State private var targetDate: Date = Date()
    @State private var estimatedCost: String = ""
    @State private var notes: String = ""
    
    private let eventTypes = [
        "Home Purchase",
        "Marriage",
        "Business Launch",
        "Education",
        "Child",
        "Retirement",
        "Emergency Fund"
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0A0A0C").ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Event Type
                        formSection(title: "EVENT TYPE") {
                            Menu {
                                ForEach(eventTypes, id: \.self) { type in
                                    Button(type) { eventType = type }
                                }
                            } label: {
                                HStack {
                                    Text(eventType)
                                        .font(.system(size: 15))
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12))
                                        .foregroundStyle(MilliColors.textMuted)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(Color(hex: "12141A"))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                        )
                                )
                            }
                        }
                        
                        // Target Date
                        formSection(title: "TARGET DATE") {
                            DatePicker("", selection: $targetDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .tint(MilliColors.cyan)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(Color(hex: "12141A"))
                                )
                        }
                        
                        // Estimated Cost
                        formSection(title: "ESTIMATED COST") {
                            TextField("$0", text: $estimatedCost)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 15))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(Color(hex: "12141A"))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                        )
                                )
                        }
                        
                        // Notes
                        formSection(title: "NOTES") {
                            TextField("Additional details...", text: $notes, axis: .vertical)
                                .lineLimit(3...6)
                                .font(.system(size: 15))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(Color(hex: "12141A"))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                        )
                                )
                        }
                        
                        // Save Button
                        Button(action: { dismiss() }) {
                            Text("Save Event")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(MilliColors.obsidian)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(MilliColors.cyan)
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, MilliLayout.screenMargin)
                    .padding(.top, 24)
                }
            }
            .navigationTitle("Add Life Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(MilliColors.cyan)
                }
            }
        }
        .presentationDetents([.large])
    }
    
    private func formSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(MilliColors.textSecondary)
                .tracking(0.5)
            content()
        }
    }
}

#Preview {
    AddLifeEventSheet()
}
