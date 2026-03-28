import SwiftUI

struct JourneyView: View {
    @EnvironmentObject private var streakManager: StreakManager
    @State private var showAchievements = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()

                // Evolving tree visualization - the main focus
                treeVisualization

                // Simple level label
                VStack(spacing: 4) {
                    Text(streakManager.levelName)
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("\(streakManager.totalEntries) entries")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Minimal footer with achievements link
                Button {
                    showAchievements = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "medal.fill")
                            .foregroundStyle(Color.warmAccent)
                        Text("\(streakManager.unlockedAchievements.count) achievements")
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                }
                .padding(.bottom, 8)
            }
            .padding()
            .navigationTitle("Your Journey")
            .sheet(isPresented: $showAchievements) {
                AchievementsView()
            }
        }
    }

    private var treeVisualization: some View {
        ZStack {
            // Sky gradient background
            LinearGradient(
                colors: [Color.blue.opacity(0.15), Color.cyan.opacity(0.08)],
                startPoint: .top,
                endPoint: .bottom
            )

            // Ground
            VStack {
                Spacer()
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.brown.opacity(0.3), Color.brown.opacity(0.5)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 80)
            }

            // Grass
            VStack {
                Spacer()
                GrassView()
                    .frame(height: 40)
                    .offset(y: -60)
            }

            // The evolving tree
            TreeView(totalEntries: streakManager.totalEntries)

            // Decorations based on level
            decorations
        }
        .frame(maxWidth: .infinity)
        .frame(height: 400)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    @ViewBuilder
    private var decorations: some View {
        let entries = streakManager.totalEntries

        // Flowers appear at 25+ entries
        if entries >= 25 {
            FlowerView()
                .offset(x: -100, y: 80)
            FlowerView()
                .offset(x: 90, y: 85)
        }

        // Extra flowers at 50+
        if entries >= 50 {
            FlowerView()
                .offset(x: -60, y: 90)
            FlowerView()
                .offset(x: 110, y: 75)
        }

        // Butterflies at 100+
        if entries >= 100 {
            ButterflyView()
                .offset(x: 60, y: -60)
        }

        // Birds at 250+
        if entries >= 250 {
            BirdView()
                .offset(x: -80, y: -80)
        }

        // Sun at 500+
        if entries >= 500 {
            SunView()
                .offset(x: 100, y: -100)
        }
    }

}

// MARK: - Tree Components

struct TreeView: View {
    let totalEntries: Int

    var body: some View {
        ZStack {
            if totalEntries == 0 {
                // Just a seed
                SeedView()
            } else if totalEntries < 5 {
                // Sprout
                SproutView()
            } else if totalEntries < 10 {
                // Seedling
                SeedlingView()
            } else if totalEntries < 25 {
                // Small tree
                SmallTreeView()
            } else if totalEntries < 50 {
                // Medium tree
                MediumTreeView()
            } else if totalEntries < 100 {
                // Full tree
                FullTreeView()
            } else if totalEntries < 250 {
                // Tree with fruits
                FruitTreeView()
            } else {
                // Majestic tree
                MajesticTreeView()
            }
        }
    }
}

struct SeedView: View {
    var body: some View {
        VStack {
            Spacer()
            Circle()
                .fill(Color.brown)
                .frame(width: 15, height: 15)
                .offset(y: -60)
        }
    }
}

struct SproutView: View {
    var body: some View {
        VStack {
            Spacer()
            ZStack {
                // Stem
                Rectangle()
                    .fill(Color.green.opacity(0.8))
                    .frame(width: 4, height: 30)

                // Leaves
                Ellipse()
                    .fill(Color.green)
                    .frame(width: 20, height: 12)
                    .offset(x: -10, y: -20)
                    .rotationEffect(.degrees(-30))

                Ellipse()
                    .fill(Color.green)
                    .frame(width: 20, height: 12)
                    .offset(x: 10, y: -20)
                    .rotationEffect(.degrees(30))
            }
            .offset(y: -75)
        }
    }
}

struct SeedlingView: View {
    var body: some View {
        VStack {
            Spacer()
            ZStack {
                // Stem
                Rectangle()
                    .fill(Color.brown.opacity(0.7))
                    .frame(width: 8, height: 50)

                // Leaves
                ForEach(0..<4) { i in
                    Ellipse()
                        .fill(Color.green)
                        .frame(width: 25, height: 14)
                        .offset(x: i % 2 == 0 ? -15 : 15, y: -20 - CGFloat(i * 10))
                        .rotationEffect(.degrees(i % 2 == 0 ? -30 : 30))
                }
            }
            .offset(y: -85)
        }
    }
}

struct SmallTreeView: View {
    var body: some View {
        VStack {
            Spacer()
            ZStack {
                // Trunk
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.brown.opacity(0.8), Color.brown],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 20, height: 80)

                // Foliage
                Circle()
                    .fill(Color.green.opacity(0.9))
                    .frame(width: 80, height: 80)
                    .offset(y: -70)
            }
            .offset(y: -100)
        }
    }
}

struct MediumTreeView: View {
    var body: some View {
        VStack {
            Spacer()
            ZStack {
                // Trunk
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.brown.opacity(0.8), Color.brown],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 25, height: 100)

                // Branches
                Rectangle()
                    .fill(Color.brown.opacity(0.7))
                    .frame(width: 40, height: 8)
                    .offset(x: -25, y: -50)
                    .rotationEffect(.degrees(-20))

                Rectangle()
                    .fill(Color.brown.opacity(0.7))
                    .frame(width: 40, height: 8)
                    .offset(x: 25, y: -60)
                    .rotationEffect(.degrees(20))

                // Foliage
                Circle()
                    .fill(Color.green.opacity(0.85))
                    .frame(width: 100, height: 100)
                    .offset(y: -90)

                Circle()
                    .fill(Color.green.opacity(0.9))
                    .frame(width: 60, height: 60)
                    .offset(x: -40, y: -60)

                Circle()
                    .fill(Color.green.opacity(0.9))
                    .frame(width: 60, height: 60)
                    .offset(x: 40, y: -70)
            }
            .offset(y: -110)
        }
    }
}

struct FullTreeView: View {
    var body: some View {
        VStack {
            Spacer()
            ZStack {
                // Trunk
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.brown.opacity(0.7), Color.brown],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 30, height: 110)

                // Roots
                ForEach(0..<3) { i in
                    Rectangle()
                        .fill(Color.brown.opacity(0.6))
                        .frame(width: 25, height: 8)
                        .offset(x: CGFloat(i - 1) * 20, y: 50)
                        .rotationEffect(.degrees(Double(i - 1) * 20))
                }

                // Main foliage
                Ellipse()
                    .fill(Color.green.opacity(0.85))
                    .frame(width: 140, height: 120)
                    .offset(y: -100)

                // Additional foliage clusters
                Circle()
                    .fill(Color.green.opacity(0.9))
                    .frame(width: 70, height: 70)
                    .offset(x: -50, y: -70)

                Circle()
                    .fill(Color.green.opacity(0.9))
                    .frame(width: 70, height: 70)
                    .offset(x: 50, y: -80)

                Circle()
                    .fill(Color.green.opacity(0.95))
                    .frame(width: 50, height: 50)
                    .offset(y: -140)
            }
            .offset(y: -110)
        }
    }
}

struct FruitTreeView: View {
    var body: some View {
        VStack {
            Spacer()
            ZStack {
                // Trunk
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.brown.opacity(0.7), Color.brown],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 35, height: 120)

                // Main foliage
                Ellipse()
                    .fill(Color.green.opacity(0.85))
                    .frame(width: 160, height: 130)
                    .offset(y: -110)

                // Additional foliage
                Circle()
                    .fill(Color.green.opacity(0.9))
                    .frame(width: 80, height: 80)
                    .offset(x: -55, y: -75)

                Circle()
                    .fill(Color.green.opacity(0.9))
                    .frame(width: 80, height: 80)
                    .offset(x: 55, y: -85)

                Circle()
                    .fill(Color.green.opacity(0.95))
                    .frame(width: 60, height: 60)
                    .offset(y: -155)

                // Fruits
                ForEach(0..<5) { i in
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)
                        .offset(
                            x: CGFloat.random(in: -50...50),
                            y: CGFloat.random(in: (-130)...(-80))
                        )
                }
            }
            .offset(y: -110)
        }
    }
}

struct MajesticTreeView: View {
    var body: some View {
        VStack {
            Spacer()
            ZStack {
                // Large trunk
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.brown.opacity(0.6), Color.brown],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 45, height: 130)

                // Roots
                ForEach(0..<5) { i in
                    Rectangle()
                        .fill(Color.brown.opacity(0.5))
                        .frame(width: 30, height: 10)
                        .offset(x: CGFloat(i - 2) * 18, y: 60)
                        .rotationEffect(.degrees(Double(i - 2) * 15))
                }

                // Main foliage - large
                Ellipse()
                    .fill(Color.green.opacity(0.8))
                    .frame(width: 180, height: 150)
                    .offset(y: -120)

                // Side foliage
                Circle()
                    .fill(Color.green.opacity(0.85))
                    .frame(width: 90, height: 90)
                    .offset(x: -65, y: -80)

                Circle()
                    .fill(Color.green.opacity(0.85))
                    .frame(width: 90, height: 90)
                    .offset(x: 65, y: -90)

                Circle()
                    .fill(Color.green.opacity(0.9))
                    .frame(width: 70, height: 70)
                    .offset(y: -170)

                // Golden fruits
                ForEach(0..<7) { i in
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 14, height: 14)
                        .offset(
                            x: cos(Double(i) * 0.9) * 50,
                            y: -100 - sin(Double(i) * 0.9) * 40
                        )
                }
            }
            .offset(y: -110)
        }
    }
}

// MARK: - Decoration Components

struct GrassView: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                let width = geo.size.width
                for i in stride(from: 0, to: width, by: 8) {
                    let height = CGFloat.random(in: 15...25)
                    path.move(to: CGPoint(x: i, y: 30))
                    path.addLine(to: CGPoint(x: i + 2, y: 30 - height))
                    path.addLine(to: CGPoint(x: i + 4, y: 30))
                }
            }
            .fill(Color.green.opacity(0.7))
        }
    }
}

struct FlowerView: View {
    let petalColor = Color.pink

    var body: some View {
        ZStack {
            // Stem
            Rectangle()
                .fill(Color.green)
                .frame(width: 3, height: 20)
                .offset(y: 10)

            // Petals
            ForEach(0..<5) { i in
                Ellipse()
                    .fill(petalColor)
                    .frame(width: 10, height: 6)
                    .offset(y: -6)
                    .rotationEffect(.degrees(Double(i) * 72))
            }

            // Center
            Circle()
                .fill(Color.yellow)
                .frame(width: 6, height: 6)
        }
        .scaleEffect(0.8)
    }
}

struct ButterflyView: View {
    @State private var fluttering = false

    var body: some View {
        HStack(spacing: 0) {
            // Left wing
            Ellipse()
                .fill(Color.purple.opacity(0.8))
                .frame(width: 15, height: 10)
                .rotationEffect(.degrees(fluttering ? -20 : 20))

            // Body
            Capsule()
                .fill(Color.black)
                .frame(width: 3, height: 12)

            // Right wing
            Ellipse()
                .fill(Color.purple.opacity(0.8))
                .frame(width: 15, height: 10)
                .rotationEffect(.degrees(fluttering ? 20 : -20))
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true)) {
                fluttering = true
            }
        }
    }
}

struct BirdView: View {
    var body: some View {
        ZStack {
            // Body
            Ellipse()
                .fill(Color.blue)
                .frame(width: 20, height: 12)

            // Head
            Circle()
                .fill(Color.blue)
                .frame(width: 10, height: 10)
                .offset(x: 8, y: -3)

            // Beak
            Triangle()
                .fill(Color.orange)
                .frame(width: 6, height: 4)
                .offset(x: 15, y: -3)

            // Wing
            Ellipse()
                .fill(Color.blue.opacity(0.7))
                .frame(width: 12, height: 8)
                .offset(x: -2, y: -4)
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.closeSubpath()
        }
    }
}

struct SunView: View {
    var body: some View {
        ZStack {
            // Rays
            ForEach(0..<8) { i in
                Rectangle()
                    .fill(Color.yellow.opacity(0.6))
                    .frame(width: 3, height: 15)
                    .offset(y: -25)
                    .rotationEffect(.degrees(Double(i) * 45))
            }

            // Sun body
            Circle()
                .fill(Color.yellow)
                .frame(width: 30, height: 30)
        }
    }
}

// MARK: - Achievements View

struct AchievementsView: View {
    @EnvironmentObject private var streakManager: StreakManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(AchievementManager.allAchievements) { achievement in
                        AchievementCard(
                            achievement: achievement,
                            isUnlocked: streakManager.unlockedAchievements.contains(achievement.id)
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    let isUnlocked: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? Color.warmAccent.opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(width: 60, height: 60)

                Image(systemName: achievement.icon)
                    .font(.title)
                    .foregroundStyle(isUnlocked ? Color.warmAccent : Color.gray.opacity(0.4))
            }

            Text(achievement.title)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .foregroundStyle(isUnlocked ? .primary : .secondary)

            Text(achievement.description)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(isUnlocked ? Color.warmCardBackground : Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(isUnlocked ? Color.warmAccent.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

#Preview {
    JourneyView()
        .environmentObject(StreakManager())
}
