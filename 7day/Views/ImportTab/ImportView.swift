import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ImportView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WeightEntry.date) private var entries: [WeightEntry]
    @Query(sort: \Block.startDate) private var blocks: [Block]

    @State private var csvText: String = ""
    @State private var importResult: ImportResult?
    @State private var showClearEntriesConfirm = false
    @State private var showClearBlocksConfirm = false
    @State private var showExportShare = false
    @State private var exportURL: URL?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    importSection
                    exportSection
                    dangerSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(AppColors.background)
            .navigationTitle("Import")
        }
    }

    // MARK: - Import

    private var importSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Import")
                .sectionLabel()

            VStack(alignment: .leading, spacing: 12) {
                Text("Paste CSV rows — one per line:")
                    .font(AppFonts.body())
                    .foregroundStyle(AppColors.textSecondary)

                Text("date, weight")
                    .font(AppFonts.monoBody())
                    .foregroundStyle(AppColors.textMuted)

                TextEditor(text: $csvText)
                    .font(AppFonts.monoBody())
                    .frame(minHeight: 140)
                    .padding(12)
                    .background(AppColors.background)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(AppColors.border, lineWidth: 1)
                    )

                if let result = importResult {
                    resultBanner(result)
                }

                HStack {
                    Button("Import") {
                        importCSV()
                    }
                    .buttonStyle(.primary)
                    .disabled(csvText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Button("Paste from Clipboard") {
                        if let clip = UIPasteboard.general.string {
                            csvText = clip
                        }
                    }
                    .buttonStyle(.outline)
                }
            }
            .cardStyle()
        }
    }

    // MARK: - Export

    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Export")
                .sectionLabel()

            VStack(alignment: .leading, spacing: 12) {
                Text("\(entries.count) entries")
                    .font(AppFonts.body())
                    .foregroundStyle(AppColors.textSecondary)

                Button("Export CSV") {
                    exportCSV()
                }
                .buttonStyle(.outline)
                .disabled(entries.isEmpty)
            }
            .cardStyle()
        }
        .sheet(isPresented: $showExportShare) {
            if let url = exportURL {
                ShareSheet(url: url)
            }
        }
    }

    // MARK: - Danger Zone

    private var dangerSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Danger Zone")
                .sectionLabel()

            VStack(alignment: .leading, spacing: 12) {
                Button("Clear All Entries") {
                    showClearEntriesConfirm = true
                }
                .font(.system(.body, design: .rounded, weight: .medium))
                .foregroundStyle(AppColors.negative)
                .confirmationDialog(
                    "Delete all \(entries.count) weight entries?",
                    isPresented: $showClearEntriesConfirm,
                    titleVisibility: .visible
                ) {
                    Button("Delete All Entries", role: .destructive) {
                        clearAllEntries()
                    }
                }

                Divider()

                Button("Clear All Blocks") {
                    showClearBlocksConfirm = true
                }
                .font(.system(.body, design: .rounded, weight: .medium))
                .foregroundStyle(AppColors.negative)
                .confirmationDialog(
                    "Delete all \(blocks.count) blocks?",
                    isPresented: $showClearBlocksConfirm,
                    titleVisibility: .visible
                ) {
                    Button("Delete All Blocks", role: .destructive) {
                        clearAllBlocks()
                    }
                }
            }
            .cardStyle()
        }
    }

    // MARK: - Result Banner

    @ViewBuilder
    private func resultBanner(_ result: ImportResult) -> some View {
        HStack(spacing: 8) {
            Image(systemName: result.errors.isEmpty ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
            VStack(alignment: .leading, spacing: 2) {
                Text("\(result.imported) imported, \(result.skipped) skipped")
                    .font(AppFonts.body())
                if !result.errors.isEmpty {
                    Text(result.errors.prefix(3).joined(separator: "\n"))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            Spacer()
        }
        .padding(12)
        .background(result.errors.isEmpty ? AppColors.positive.opacity(0.1) : AppColors.negative.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .foregroundStyle(result.errors.isEmpty ? AppColors.positive : AppColors.negative)
    }

    // MARK: - Import Logic

    private func importCSV() {
        let lines = csvText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        var imported = 0
        var skipped = 0
        var errors: [String] = []

        for line in lines {
            let parts = line.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            guard parts.count >= 2 else {
                skipped += 1
                errors.append("Bad format: \(line)")
                continue
            }

            guard let date = parseDate(parts[0]) else {
                skipped += 1
                errors.append("Bad date: \(parts[0])")
                continue
            }

            guard let weight = Double(parts[1]), weight > 0, weight < 1000 else {
                skipped += 1
                errors.append("Bad weight: \(parts[1])")
                continue
            }

            let targetDate = date.startOfDay
            if let existing = entries.first(where: { $0.date == targetDate }) {
                existing.weight = weight
            } else {
                context.insert(WeightEntry(date: targetDate, weight: weight))
            }
            imported += 1
        }

        importResult = ImportResult(imported: imported, skipped: skipped, errors: errors)
        if imported > 0 {
            csvText = ""
        }
    }

    private func parseDate(_ string: String) -> Date? {
        let iso = DateFormatter()
        iso.dateFormat = "yyyy-MM-dd"
        iso.locale = Locale(identifier: "en_US_POSIX")
        if let d = iso.date(from: string) { return d }

        let us = DateFormatter()
        us.dateFormat = "MM/dd/yyyy"
        us.locale = Locale(identifier: "en_US_POSIX")
        if let d = us.date(from: string) { return d }

        return nil
    }

    // MARK: - Export Logic

    private func exportCSV() {
        var csv = "date,weight\n"
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")

        for entry in entries {
            csv += "\(fmt.string(from: entry.date)),\(String(format: "%.1f", entry.weight))\n"
        }

        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("7day-export.csv")
        try? csv.write(to: tmp, atomically: true, encoding: .utf8)
        exportURL = tmp
        showExportShare = true
    }

    // MARK: - Clear Data

    private func clearAllEntries() {
        for entry in entries {
            context.delete(entry)
        }
    }

    private func clearAllBlocks() {
        for block in blocks {
            context.delete(block)
        }
    }
}

// MARK: - Supporting Types

private struct ImportResult {
    let imported: Int
    let skipped: Int
    let errors: [String]
}

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

#Preview {
    ImportView()
        .modelContainer(for: [WeightEntry.self, Block.self], inMemory: true)
}
