import SwiftUI
import UniformTypeIdentifiers

// MARK: - DocumentsView
// Native document center for tax documents, receipts and generated reports.
// File import is real and local to the current session; secure cloud persistence,
// OCR and tax-filing partner delivery remain explicit production integrations.

struct DocumentsView: View {
    var onBack: () -> Void = {}

    @State private var selectedCategory: DocumentCategory = .taxDocuments
    @State private var documents: [MilliDocument] = MilliDocument.seeded
    @State private var showImporter = false
    @State private var importErrorMessage: String?

    private var visibleDocuments: [MilliDocument] {
        documents.filter { $0.category == selectedCategory }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 10) {
                header
                categoryControl
                documentSummary
                documentList
                importButton
                securityDisclosure
            }
            .padding(.horizontal, MilliSpacing.screenHorizontal)
            .padding(.top, 8)
            .padding(.bottom, MilliSpacing.bottomContentClearance)
        }
        .background(MilliColors.background.ignoresSafeArea())
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.pdf, .image, .commaSeparatedText, .plainText],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        .alert("Document Import", isPresented: Binding(
            get: { importErrorMessage != nil },
            set: { if !$0 { importErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { importErrorMessage = nil }
        } message: {
            Text(importErrorMessage ?? "")
        }
    }

    private var header: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MilliColors.textSecondary)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color.white.opacity(0.035)))
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Documents")
                .font(MilliFont.screenTitle)
                .foregroundStyle(MilliColors.textPrimary)

            Spacer()

            Image(systemName: "folder.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(MilliColors.cyanGlow)
                .frame(width: 34, height: 34)
        }
    }

    private var categoryControl: some View {
        HStack(spacing: 3) {
            ForEach(DocumentCategory.allCases) { category in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        selectedCategory = category
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: category.icon)
                            .font(.system(size: 12, weight: .semibold))
                        Text(category.shortTitle)
                            .font(MilliFont.caption)
                            .lineLimit(1)
                    }
                    .foregroundStyle(selectedCategory == category ? MilliColors.blackGlass : MilliColors.cyanGlow.opacity(0.82))
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(selectedCategory == category ? MilliColors.cyanGlow : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(MilliColors.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.05), lineWidth: 0.7)
                }
        )
    }

    private var documentSummary: some View {
        HStack(spacing: 0) {
            summaryMetric("DOCUMENTS", "\(visibleDocuments.count)")
            Rectangle().fill(Color.white.opacity(0.06)).frame(width: 1, height: 38)
            summaryMetric("READY", "\(visibleDocuments.filter(\.isReady).count)")
            Rectangle().fill(Color.white.opacity(0.06)).frame(width: 1, height: 38)
            summaryMetric("NEEDS REVIEW", "\(visibleDocuments.filter { !$0.isReady }.count)")
        }
        .milliCard(padding: 12)
    }

    private func summaryMetric(_ title: String, _ value: String) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(MilliFont.caption)
                .foregroundStyle(MilliColors.textTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text(value)
                .font(MilliFont.numericSmall)
                .monospacedDigit()
                .foregroundStyle(MilliColors.textPrimary)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var documentList: some View {
        if visibleDocuments.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: selectedCategory.icon)
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(MilliColors.cyanGlow)
                Text("No \(selectedCategory.shortTitle.lowercased()) yet")
                    .font(MilliFont.bodyMedium)
                    .foregroundStyle(MilliColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 34)
            .milliCard()
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text(selectedCategory.sectionTitle)
                    .sectionHeaderStyle()

                VStack(spacing: 0) {
                    ForEach(Array(visibleDocuments.enumerated()), id: \.element.id) { index, document in
                        documentRow(document)
                        if index < visibleDocuments.count - 1 {
                            Divider().overlay(Color.white.opacity(0.05)).padding(.leading, 52)
                        }
                    }
                }
                .background(MilliCardBackground(showGlow: true))
            }
        }
    }

    private func documentRow(_ document: MilliDocument) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(document.category.color.opacity(0.09))
                    .frame(width: 34, height: 38)
                Image(systemName: document.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(document.category.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(document.name)
                    .font(MilliFont.headlineSmall)
                    .foregroundStyle(MilliColors.textPrimary)
                    .lineLimit(1)
                Text("\(document.detail) • \(document.date.formatted(date: .abbreviated, time: .omitted))")
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                Text(document.isReady ? "Ready" : "Review")
                    .font(MilliFont.caption)
                    .foregroundStyle(document.isReady ? MilliColors.positive : MilliColors.warning)
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(MilliColors.textTertiary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .accessibilityElement(children: .combine)
    }

    private var importButton: some View {
        Button {
            showImporter = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.down.fill")
                Text("Import Document")
            }
            .font(MilliFont.headlineSmall)
            .foregroundStyle(MilliColors.blackGlass)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(MilliColors.cyanGlow)
                    .shadow(color: MilliColors.cyanGlow.opacity(0.20), radius: 8)
            )
        }
        .buttonStyle(.plain)
    }

    private var securityDisclosure: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(MilliColors.positive)
                .padding(.top, 1)

            Text("Imports are added to the current local document state. Production encrypted storage, OCR extraction, cloud sync and tax-partner delivery require their respective verified services before Milli will represent them as active.")
                .font(MilliFont.caption)
                .foregroundStyle(MilliColors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .milliCard(padding: 11)
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            let name = url.deletingPathExtension().lastPathComponent.isEmpty ? "Imported Document" : url.deletingPathExtension().lastPathComponent
            let detail = url.pathExtension.isEmpty ? "Imported file" : url.pathExtension.uppercased()

            documents.insert(
                MilliDocument(
                    name: name,
                    detail: detail,
                    date: Date(),
                    category: selectedCategory,
                    isReady: false,
                    icon: iconForImportedURL(url)
                ),
                at: 0
            )

        case .failure(let error):
            importErrorMessage = error.localizedDescription
        }
    }

    private func iconForImportedURL(_ url: URL) -> String {
        switch url.pathExtension.lowercased() {
        case "pdf": return "doc.richtext.fill"
        case "png", "jpg", "jpeg", "heic": return "photo.fill"
        case "csv": return "tablecells.fill"
        default: return "doc.fill"
        }
    }
}

private enum DocumentCategory: String, CaseIterable, Identifiable {
    case taxDocuments
    case receipts
    case reports

    var id: String { rawValue }

    var shortTitle: String {
        switch self {
        case .taxDocuments: return "Tax Docs"
        case .receipts: return "Receipts"
        case .reports: return "Reports"
        }
    }

    var sectionTitle: String {
        switch self {
        case .taxDocuments: return "TAX DOCUMENTS"
        case .receipts: return "RECEIPTS"
        case .reports: return "GENERATED REPORTS"
        }
    }

    var icon: String {
        switch self {
        case .taxDocuments: return "doc.text.fill"
        case .receipts: return "receipt.fill"
        case .reports: return "chart.bar.doc.horizontal.fill"
        }
    }

    var color: Color {
        switch self {
        case .taxDocuments: return MilliColors.cyanGlow
        case .receipts: return MilliColors.warning
        case .reports: return MilliColors.deepCyan
        }
    }
}

private struct MilliDocument: Identifiable {
    let id = UUID()
    let name: String
    let detail: String
    let date: Date
    let category: DocumentCategory
    let isReady: Bool
    let icon: String

    static var seeded: [MilliDocument] {
        let calendar = Calendar.current
        let now = Date()
        func date(daysAgo: Int) -> Date {
            calendar.date(byAdding: .day, value: -daysAgo, to: now) ?? now
        }

        return [
            MilliDocument(name: "Income Summary", detail: "PDF", date: date(daysAgo: 2), category: .taxDocuments, isReady: true, icon: "doc.richtext.fill"),
            MilliDocument(name: "Quarterly Estimate", detail: "PDF", date: date(daysAgo: 5), category: .taxDocuments, isReady: true, icon: "doc.text.fill"),
            MilliDocument(name: "Fuel Stop", detail: "$68.42", date: date(daysAgo: 0), category: .receipts, isReady: true, icon: "receipt.fill"),
            MilliDocument(name: "Vehicle Service", detail: "$89.75", date: date(daysAgo: 1), category: .receipts, isReady: true, icon: "receipt.fill"),
            MilliDocument(name: "Parking Receipt", detail: "$24.60", date: date(daysAgo: 3), category: .receipts, isReady: false, icon: "receipt.fill"),
            MilliDocument(name: "Deduction Report", detail: "PDF", date: date(daysAgo: 1), category: .reports, isReady: true, icon: "chart.bar.doc.horizontal.fill"),
            MilliDocument(name: "Trip Export", detail: "CSV", date: date(daysAgo: 4), category: .reports, isReady: true, icon: "tablecells.fill")
        ]
    }
}

// Legacy compatibility wrapper while the old duplicate dashboard is retired.
struct DashboardView: View {
    var body: some View {
        DocumentsView()
    }
}

#Preview {
    DocumentsView()
        .preferredColorScheme(.dark)
}
