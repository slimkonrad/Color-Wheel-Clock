import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Int = 0

    var body: some View {
        ZStack(alignment: .bottom) {

            // Background — deep near-black
            Color(red: 0.04, green: 0.04, blue: 0.05)
                .ignoresSafeArea()

            // Subtle noise grain overlay
            Rectangle()
                .fill(.white.opacity(0.015))
                .ignoresSafeArea()

            // Content
            TabView(selection: $selectedTab) {
                ClockView()
                    .tag(0)
                TimerView()
                    .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Custom minimal tab bar
            CustomTabBar(selectedTab: $selectedTab)
                .padding(.bottom, 28)
        }
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: Int

    var body: some View {
        HStack(spacing: 0) {
            TabBarButton(title: "clock",
                         icon: "circle.dotted",
                         isSelected: selectedTab == 0) {
                withAnimation(.easeInOut(duration: 0.25)) { selectedTab = 0 }
            }
            TabBarButton(title: "timer",
                         icon: "timer",
                         isSelected: selectedTab == 1) {
                withAnimation(.easeInOut(duration: 0.25)) { selectedTab = 1 }
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.white.opacity(0.07))
                .overlay(
                    Capsule().stroke(.white.opacity(0.08), lineWidth: 0.5)
                )
        )
    }
}

struct TabBarButton: View {
    var title: String
    var icon: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: isSelected ? .medium : .light))
                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .medium : .light,
                                  design: .monospaced))
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.35))
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? .white.opacity(0.12) : .clear)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

#Preview {
    ContentView()
}
