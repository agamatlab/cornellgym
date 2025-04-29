import SwiftUI

@main
struct AnatomyExplorerApp: App {
    @StateObject private var userModel = UserModel()
    @StateObject private var themeManager = ThemeManager() // Initialize theme manager
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(userModel)
                .environmentObject(themeManager) // Add theme manager as environment object
                .preferredColorScheme(.dark)
            
        }
    }
}

struct AnatomyExplorerApp_Previews: PreviewProvider {
    static var previews: some View {
        // Create preview instances
        let previewUserModel = UserModel()
        let previewThemeManager = ThemeManager()
        
        return MainTabView()
            .environmentObject(previewUserModel)
            .environmentObject(previewThemeManager)
            .preferredColorScheme(.dark)
    }
}


// User model to store user information
class UserModel: ObservableObject {
    @Published var name: String = "Alex"
    @Published var selectedMuscle: String? = nil
    @Published var workoutSchedule: [String: String] = [
        "Monday": "Chest",
        "Tuesday": "Back",
        "Wednesday": "Legs",
        "Thursday": "Shoulders",
        "Friday": "Arms",
        "Saturday": "Core",
        "Sunday": "Rest"
    ]
    
    // You can add more user properties here
}

// Main tab view that manages the navigation
struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var previousTab = 0
    @EnvironmentObject var userModel: UserModel
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(0)
                    .transition(.opacity)
           
                
                ContentView()
                    .tag(1)
                    .transition(.opacity)
                
                WorkoutEditorView(
                    day: "Monday", // Current day or default
                    date: Date(),  // Current date
                    currentWorkout: userModel.workoutSchedule["Monday"] ?? "Rest", // Default workout
                    onSave: { newWorkout in
                        // Update the workout in your model
                        self.userModel.workoutSchedule["Monday"] = newWorkout
                    }
                )
                .tag(2)
                .transition(.opacity)
                
                ProfileView()
                    .tag(3)
                    .transition(.opacity)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .edgesIgnoringSafeArea(.vertical)
            .animation(.easeInOut, value: selectedTab)
            
            CustomTabBar(selectedTab: $selectedTab, previousTab: $previousTab)
        }
        .edgesIgnoringSafeArea(.bottom)
    }
}

// Custom tab bar with animation
struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @Binding var previousTab: Int
    @Namespace private var tabAnimation
    @EnvironmentObject var themeManager: ThemeManager
    
    let tabItems = [
        TabItem(icon: "house.fill", title: "Home"),
        TabItem(icon: "figure.stand", title: "Anatomy"),
        TabItem(icon: "chart.bar.fill", title: "History"),
        TabItem(icon: "person.fill", title: "Profile")
    ]
    
    var body: some View {
        HStack {
            ForEach(0..<tabItems.count, id: \.self) { index in
                let item = tabItems[index]
                VStack(spacing: 0) {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            previousTab = selectedTab
                            selectedTab = index
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: item.icon)
                                .font(.system(size: 22))
                            
                            Text(item.title)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(selectedTab == index ? themeManager.current.accent1 : themeManager.current.surface3)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(
                            ZStack {
                                if selectedTab == index {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(themeManager.current.surface1)
                                        .matchedGeometryEffect(id: "tab_background", in: tabAnimation)
                                        .frame(height: 60)
                                }
                            }
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 12)
        .frame(height: 80)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    themeManager.current.background1,
                    themeManager.current.background2
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 5)
        .padding(.horizontal)
    }
}

struct TabItem {
    let icon: String
    let title: String
}
