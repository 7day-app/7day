import SwiftUI
import SwiftData

struct BlockEditForm: View {
    @Environment(\.dismiss) private var dismiss
    let block: Block
    let allBlocks: [Block]

    @State private var type: BlockType
    @State private var startDate: Date
    @State private var weeksText: String
    @State private var startWeightText: String
    @State private var rateText: String

    init(block: Block, allBlocks: [Block]) {
        self.block = block
        self.allBlocks = allBlocks
        _type = State(initialValue: block.type)
        _startDate = State(initialValue: block.startDate)
        _weeksText = State(initialValue: "\(block.weeks)")
        _startWeightText = State(initialValue: String(format: "%.1f", block.startWeight))
        _rateText = State(initialValue: String(format: "%.1f", block.rate))
    }

    private var parsedWeeks: Int? {
        guard let v = Int(weeksText), v >= 1, v <= 52 else { return nil }
        return v
    }

    private var parsedStartWeight: Double? {
        guard let v = Double(startWeightText), v > 0, v < 1000 else { return nil }
        return v
    }

    private var parsedRate: Double? {
        if type == .maintain { return 0 }
        guard let v = Double(rateText), v >= 0, v <= 10 else { return nil }
        return v
    }

    private var hasOverlap: Bool {
        guard let weeks = parsedWeeks else { return false }
        return WeightViewModel.blockOverlaps(
            startDate: startDate,
            weeks: weeks,
            existingBlocks: allBlocks,
            excluding: block
        )
    }

    private var canSave: Bool {
        parsedWeeks != nil && parsedStartWeight != nil && parsedRate != nil && !hasOverlap
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    formCard
                    previewSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(AppColors.background)
            .navigationTitle("Edit Block")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - Form

    private var formCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Block type
            VStack(alignment: .leading, spacing: 6) {
                Text("Type")
                    .sectionLabel()
                Picker("Type", selection: $type) {
                    ForEach(BlockType.allCases, id: \.self) { bt in
                        Text(bt.rawValue.capitalized).tag(bt)
                    }
                }
                .pickerStyle(.segmented)
            }

            // Start date
            VStack(alignment: .leading, spacing: 6) {
                Text("Start Date")
                    .sectionLabel()
                DatePicker("Start", selection: $startDate, displayedComponents: .date)
                    .labelsHidden()
                    .onChange(of: startDate) { _, newValue in
                        startDate = newValue.startOfWeek
                    }
            }

            // Weeks
            VStack(alignment: .leading, spacing: 6) {
                Text("Weeks")
                    .sectionLabel()
                HStack {
                    TextField("12", text: $weeksText)
                        .font(AppFonts.monoBody())
                        .keyboardType(.numberPad)
                        .frame(width: 60)
                    Stepper("", value: Binding(
                        get: { parsedWeeks ?? 12 },
                        set: { weeksText = "\($0)" }
                    ), in: 1...52)
                    .labelsHidden()
                }
            }

            // Starting weight
            VStack(alignment: .leading, spacing: 6) {
                Text("Starting Weight")
                    .sectionLabel()
                HStack(spacing: 8) {
                    TextField("185.0", text: $startWeightText)
                        .font(AppFonts.monoBody())
                        .keyboardType(.decimalPad)
                        .frame(width: 80)
                    Text("lbs")
                        .font(AppFonts.body())
                        .foregroundStyle(AppColors.textMuted)
                }
            }

            // Rate
            VStack(alignment: .leading, spacing: 6) {
                Text("Rate (% per week)")
                    .sectionLabel()
                HStack(spacing: 8) {
                    TextField("0.5", text: $rateText)
                        .font(AppFonts.monoBody())
                        .keyboardType(.decimalPad)
                        .frame(width: 80)
                        .disabled(type == .maintain)
                    Text("%")
                        .font(AppFonts.body())
                        .foregroundStyle(AppColors.textMuted)
                }
            }
            .opacity(type == .maintain ? 0.4 : 1.0)
        }
        .cardStyle()
    }

    // MARK: - Preview

    @ViewBuilder
    private var previewSection: some View {
        if let sw = parsedStartWeight, let w = parsedWeeks, let r = parsedRate {
            Text(WeightViewModel.blockPreviewString(type: type, startWeight: sw, rate: r, weeks: w))
                .font(AppFonts.monoBody())
                .foregroundStyle(WeightViewModel.blockColor(for: type))
                .frame(maxWidth: .infinity)
                .cardStyle()
        }

        if hasOverlap {
            Label("This block overlaps with an existing block.", systemImage: "exclamationmark.triangle.fill")
                .font(AppFonts.body())
                .foregroundStyle(AppColors.negative)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
        }
    }

    // MARK: - Save

    private func save() {
        guard let weeks = parsedWeeks,
              let startWeight = parsedStartWeight,
              let rate = parsedRate else { return }
        block.type = type
        block.startDate = startDate.startOfWeek
        block.weeks = weeks
        block.startWeight = startWeight
        block.rate = rate
        dismiss()
    }
}
