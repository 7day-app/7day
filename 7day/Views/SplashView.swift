import SwiftUI
import SwiftData

struct SplashView: View {
    @State private var logoOpacity: Double = 0
    @State private var taglineOpacity: Double = 0
    @State private var logoScale: Double = 0.8
    @State private var isFinished = false

    var body: some View {
        if isFinished {
            ContentView()
        } else {
            splash
        }
    }

    private var splash: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: 28) {
                // Logo mark — matches the SVG icon
                HStack(alignment: .lastTextBaseline, spacing: 0) {
                    Text("7")
                        .font(.custom("Nunito-ExtraBold", size: 84))
                        .foregroundStyle(AppColors.textPrimary)

                    Text("d")
                        .font(.custom("Nunito-ExtraBold", size: 84))
                        .foregroundStyle(AppColors.textPrimary)

                    Circle()
                        .fill(AppColors.accent)
                        .frame(width: 14, height: 14)
                        .offset(y: -8)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                // Tagline
                Text("the weekly average is your true weight")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(AppColors.textMuted)
                    .tracking(0.3)
                    .opacity(taglineOpacity)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                logoOpacity = 1
                logoScale = 1
            }

            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                taglineOpacity = 1
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                withAnimation(.easeIn(duration: 0.25)) {
                    logoOpacity = 0
                    taglineOpacity = 0
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    isFinished = true
                }
            }
        }
    }
}

#Preview {
    SplashView()
        .modelContainer(for: [WeightEntry.self, Block.self], inMemory: true)
}
