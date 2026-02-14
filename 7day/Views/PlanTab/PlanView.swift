import SwiftUI
import SwiftData

struct PlanView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WeightEntry.date) private var entries: [WeightEntry]
    @Query(sort: \Block.startDate, order: .reverse) private var blocks: [Block]

    // Form state
    @State private var blockType: BlockType = .cut
    @State private var startDate: Date = Date().startOfWeek
    @State private var weeksText: String = "12"
    @State private var startWeightText: String = ""
    @State private var rateText: String = "0.5"

    // UI state
    @State private var expandedBlockID: PersistentIdentifier?
    @State private var editingBlock: Block?
    @State private var deletingBlock: Block?
    @State private var showOverlapError: Bool = false

    // MARK: - Parsed Form Values

    private var parsedWeeks: Int? {
        guard let v = Int(weeksText), v >= 1, v <= 52 else { return nil }
        return v
    }

    private var parsedStartWeight: Double? {
        guard let v = Double(startWeightText), v > 0, v < 1000 else { return nil }
        return v
    }

    private var parsedRate: Double? {
        if blockType == .maintain { return 0 }
        guard let v = Double(rateText), v >= 0, v <= 10 else { return nil }
        return v
    }

    private var hasOverlap: Bool {
        guard let weeks = parsedWeeks else { return false }
        return WeightViewModel.blockOverlaps(
            startDate: startDate,
            weeks: weeks,
            existingBlocks: blocks
        )
    }

    private var canCreate: Bool {
        parsedWeeks != nil && parsedStartWeight != nil && parsedRate != nil
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    newBlockForm
                    blocksList
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(AppColors.background)
            .scrollDismissesKeyboard(.interactively)
            .toolbar(.hidden, for: .navigationBar)
        }
        .onAppear {
            prefillStartWeight()
            autoExpandActiveBlock()
        }
        .sheet(item: $editingBlock) { block in
            BlockEditForm(block: block, allBlocks: blocks)
        }
        .alert("Delete Block?", isPresented: Binding(
            get: { deletingBlock != nil },
            set: { if !$0 { deletingBlock = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let block = deletingBlock {
                    modelContext.delete(block)
                    if expandedBlockID == block.persistentModelID {
                        expandedBlockID = nil
                    }
                }
                deletingBlock = nil
            }
            Button("Cancel", role: .cancel) {
                deletingBlock = nil
            }
        } message: {
            if let block = deletingBlock {
                Text("This will permanently delete the \(block.type.rawValue) block starting \(block.startDate.shortDisplay). This cannot be undone.")
            }
        }
    }

    // MARK: - New Block Form

    private var newBlockForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("New Block")
                .sectionLabel()

            // Block type
            Picker("Type", selection: $blockType) {
                ForEach(BlockType.allCases, id: \.self) { bt in
                    Text(bt.rawValue.capitalized).tag(bt)
                }
            }
            .pickerStyle(.segmented)

            // Start date
            VStack(alignment: .leading, spacing: 6) {
                Text("Start Date")
                    .sectionLabel()
                DatePicker("Start", selection: $startDate, displayedComponents: .date)
                    .labelsHidden()
                    .onChange(of: startDate) { _, newValue in
                        startDate = newValue.startOfWeek
                        showOverlapError = false
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
                        .onChange(of: weeksText) { _, _ in showOverlapError = false }
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
                        .disabled(blockType == .maintain)
                    Text("%")
                        .font(AppFonts.body())
                        .foregroundStyle(AppColors.textMuted)
                }
            }
            .opacity(blockType == .maintain ? 0.4 : 1.0)

            // Preview
            if let sw = parsedStartWeight, let w = parsedWeeks, let r = parsedRate {
                Text(WeightViewModel.blockPreviewString(type: blockType, startWeight: sw, rate: r, weeks: w))
                    .font(AppFonts.monoBody())
                    .foregroundStyle(WeightViewModel.blockColor(for: blockType))
            }

            // Overlap warning (shown on attempted create)
            if showOverlapError {
                Label("Overlaps with an existing block.", systemImage: "exclamationmark.triangle.fill")
                    .font(AppFonts.body())
                    .foregroundStyle(AppColors.negative)
            }

            // Create button
            Button("Create Block") {
                if hasOverlap {
                    showOverlapError = true
                } else {
                    createBlock()
                }
            }
            .buttonStyle(.primary)
            .disabled(!canCreate)
            .frame(maxWidth: .infinity)
        }
        .cardStyle()
    }

    // MARK: - Blocks List

    @ViewBuilder
    private var blocksList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Blocks")
                .sectionLabel()
                .padding(.horizontal, 4)

            if blocks.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 36))
                        .foregroundStyle(AppColors.textMuted)
                    Text("No blocks yet")
                        .font(AppFonts.headline())
                        .foregroundStyle(AppColors.textPrimary)
                    Text("Create a block above to start tracking your cut, bulk, or maintain cycle.")
                        .font(AppFonts.body())
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(32)
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
            } else {
                ForEach(blocks) { block in
                    BlockCard(
                        block: block,
                        entries: entries,
                        isExpanded: expandedBlockID == block.persistentModelID,
                        onToggleExpand: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                if expandedBlockID == block.persistentModelID {
                                    expandedBlockID = nil
                                } else {
                                    expandedBlockID = block.persistentModelID
                                }
                            }
                        },
                        onEdit: { editingBlock = block },
                        onDelete: { deletingBlock = block }
                    )
                }
            }
        }
    }

    // MARK: - Actions

    private func createBlock() {
        guard let weeks = parsedWeeks,
              let startWeight = parsedStartWeight,
              let rate = parsedRate else { return }
        let block = Block(
            type: blockType,
            startDate: startDate,
            weeks: weeks,
            startWeight: startWeight,
            rate: rate
        )
        modelContext.insert(block)
        expandedBlockID = block.persistentModelID
        resetForm()
    }

    private func resetForm() {
        blockType = .cut
        startDate = Date().startOfWeek
        weeksText = "12"
        showOverlapError = false
        rateText = "0.5"
        prefillStartWeight()
    }

    private func prefillStartWeight() {
        if let avg = WeightViewModel.thisWeekAverage(from: entries) {
            startWeightText = String(format: "%.1f", avg.average)
        }
    }

    private func autoExpandActiveBlock() {
        if let active = blocks.first(where: \.isActive) {
            expandedBlockID = active.persistentModelID
        }
    }
}

#Preview {
    PlanView()
        .modelContainer(for: [WeightEntry.self, Block.self], inMemory: true)
}
