import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Log", systemImage: "scalemass") {
                LogView()
            }
            Tab("Progress", systemImage: "chart.xyaxis.line") {
                ProgressTabView()
            }
            Tab("Plan", systemImage: "calendar") {
                PlanView()
            }
            Tab("Import", systemImage: "square.and.arrow.down") {
                ImportView()
            }
        }
        .tint(AppColors.accent)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [WeightEntry.self, Block.self], inMemory: true)
}
