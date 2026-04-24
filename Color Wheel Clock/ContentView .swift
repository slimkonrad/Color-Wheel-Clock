import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Int = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                ClockView()     .tag(0)
                TimerView()     .tag(1)
                StopwatchView() .tag(2)
                AlarmView()     .tag(3)
                BreathingView() .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            CustomTabBar(selectedTab: $selectedTab)
                .padding(.bottom, 28)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: Int

    let tabs: [(icon: String, label: String)] = [
        ("circle.dotted",        "clock"),
        ("timer",                "timer"),
        ("stopwatch",            "watch"),
        ("bell",                 "alarm"),
        ("wind",                 "breathe"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { i in
                TabBarButton(
                    icon:       tabs[i].icon,
                    label:      tabs[i].label,
                    isSelected: selectedTab == i
                ) {
                    withAnimation(.easeInOut(duration: 0.22)) { selectedTab = i }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.black.opacity(0.50))
                .overlay(Capsule().stroke(.white.opacity(0.10), lineWidth: 0.5))
        )
    }
}

struct TabBarButton: View {
    var icon:       String
    var label:      String
    var isSelected: Bool
    var action:     () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: isSelected ? .medium : .light))
                Text(label)
                    .font(.system(size: 8, weight: isSelected ? .medium : .light, design: .monospaced))
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.30))
            .frame(width: 58, height: 44)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? .white.opacity(0.12) : .clear)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.18), value: isSelected)
    }
}

#Preview {
    ContentView()
}
