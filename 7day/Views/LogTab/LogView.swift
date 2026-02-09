import SwiftUI
import SwiftData

struct LogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WeightEntry.date, order: .reverse) private var allEntries: [WeightEntry]
    @Query private var blocks: [Block]
    @State private var vm = WeightViewModel()
    @FocusState private var isWeightFieldFocused: Bool

    private var recentEntries: [WeightEntry] {
        Array(allEntries.prefix(14))
    }

    private var thisWeek: WeekAverage? {
        WeightViewModel.thisWeekAverage(from: allEntries)
    }

    private var lastWeek: WeekAverage? {
        WeightViewModel.lastWeekAverage(from: allEntries)
    }

    private var activeBlock: Block? {
        WeightViewModel.activeBlock(from: blocks)
    }

    private var currentGoal: Double? {
        WeightViewModel.currentGoal(block: activeBlock)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    weightInputCard
                    weekSummary
                    vsLastWeek
                    recentEntriesSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(AppColors.background)
            .scrollDismissesKeyboard(.interactively)
            .keyboardInput()
            .toolbar(.hidden, for: .navigationBar)
        }
        .onAppear {
            isWeightFieldFocused = true
        }
        .sheet(item: $vm.editingEntry) { entry in
            editSheet(for: entry)
        }
    }

    // MARK: - Weight Input Card

    private var weightInputCard: some View {
        VStack(spacing: 16) {
            DatePicker(
                "Date",
                selection: $vm.selectedDate,
                in: ...Date().startOfDay,
                displayedComponents: .date
            )
            .font(AppFonts.body())
            .foregroundStyle(AppColors.textSecondary)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                TextField("0.0", text: $vm.weightText)
                    .font(AppFonts.weightInput())
                    .foregroundStyle(AppColors.textPrimary)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .focused($isWeightFieldFocused)

                Text("lbs")
                    .font(AppFonts.body())
                    .foregroundStyle(AppColors.textMuted)
            }

            Button("Log Weight") {
                vm.logWeight(context: modelContext, existingEntries: allEntries)
                isWeightFieldFocused = true
            }
            .buttonStyle(.primary)
            .disabled(!vm.canLog)
            .frame(maxWidth: .infinity)
        }
        .cardStyle()
    }

    // MARK: - Week Summary

    @ViewBuilder
    private var weekSummary: some View {
        WeekSummaryCard(
            weekAverage: thisWeek,
            goalWeight: currentGoal,
            blockType: activeBlock?.type,
            weekRangeString: WeekKey(Date()).rangeString
        )
    }

    // MARK: - vs Last Week

    @ViewBuilder
    private var vsLastWeek: some View {
        if let current = thisWeek, let last = lastWeek {
            let delta = current.average - last.average
            HStack {
                Text("vs Last Week")
                    .sectionLabel()
                Spacer()
                Text(WeightViewModel.deltaString(delta))
                    .font(AppFonts.monoBody())
                    .foregroundStyle(
                        WeightViewModel.deltaColor(delta: delta, blockType: activeBlock?.type)
                    )
            }
            .cardStyle()
        }
    }

    // MARK: - Recent Entries

    @ViewBuilder
    private var recentEntriesSection: some View {
        if !recentEntries.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent Entries")
                    .sectionLabel()
                    .padding(.horizontal, 4)

                VStack(spacing: 0) {
                    ForEach(Array(recentEntries.enumerated()), id: \.element.persistentModelID) { index, entry in
                        Button {
                            vm.beginEditing(entry)
                        } label: {
                            entryRow(entry)
                        }
                        .buttonStyle(.plain)

                        if index < recentEntries.count - 1 {
                            Divider()
                                .padding(.horizontal, 22)
                        }
                    }
                }
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
            }
        }
    }

    private func entryRow(_ entry: WeightEntry) -> some View {
        HStack {
            Text(entry.date.shortDisplay)
                .font(AppFonts.body())
                .foregroundStyle(AppColors.textSecondary)
            Spacer()
            Text(String(format: "%.1f", entry.weight))
                .font(AppFonts.monoBody())
                .foregroundStyle(AppColors.textPrimary)
            Text("lbs")
                .font(AppFonts.body())
                .foregroundStyle(AppColors.textMuted)
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(AppColors.textMuted)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    // MARK: - Edit Sheet

    private func editSheet(for entry: WeightEntry) -> some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text(entry.date.shortDisplay)
                    .font(AppFonts.headline())
                    .foregroundStyle(AppColors.textSecondary)

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    TextField("0.0", text: $vm.editWeightText)
                        .font(AppFonts.weeklyAverage())
                        .foregroundStyle(AppColors.textPrimary)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)

                    Text("lbs")
                        .font(AppFonts.body())
                        .foregroundStyle(AppColors.textMuted)
                }

                Spacer()

                Button {
                    vm.deleteEntry(entry, context: modelContext)
                    vm.editingEntry = nil
                } label: {
                    Label("Delete Entry", systemImage: "trash")
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundStyle(AppColors.negative)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(AppColors.negative.opacity(0.3), lineWidth: 1)
                        )
                }
            }
            .padding(24)
            .background(AppColors.background)
            .keyboardInput()
            .navigationTitle("Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        vm.editingEntry = nil
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let newWeight = vm.parsedEditWeight {
                            vm.updateEntry(entry, newWeight: newWeight, context: modelContext)
                        }
                        vm.editingEntry = nil
                    }
                    .disabled(vm.parsedEditWeight == nil)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    LogView()
        .modelContainer(for: [WeightEntry.self, Block.self], inMemory: true)
}
