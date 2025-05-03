import SwiftUI
import GoogleSignIn

// Authentication manager to handle login state
class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var userId: String? = nil
    @Published var userEmail: String? = nil
    @Published var firstName: String? = nil
    @Published var lastName: String? = nil
    @Published var profileImageUrl: String? = nil
    
    init() {
        checkSavedCredentials()
    }
    
    func checkSavedCredentials() {
        if let sessionToken = UserDefaults.standard.string(forKey: "sessionToken") {
            isAuthenticated = true
            userId = UserDefaults.standard.string(forKey: "userId")
            userEmail = UserDefaults.standard.string(forKey: "userEmail")
            firstName = UserDefaults.standard.string(forKey: "firstName")
            lastName = UserDefaults.standard.string(forKey: "lastName")
            profileImageUrl = UserDefaults.standard.string(forKey: "profileImageUrl")
        }
    }
    
    func login(sessionToken: String, userData: [String: Any]) {
        UserDefaults.standard.set(sessionToken, forKey: "sessionToken")
        
        if let userId = userData["id"] as? String {
            UserDefaults.standard.set(userId, forKey: "userId")
            self.userId = userId
        }
        
        if let email = userData["email"] as? String {
            UserDefaults.standard.set(email, forKey: "userEmail")
            self.userEmail = email
        }
        
        if let firstName = userData["first_name"] as? String {
            UserDefaults.standard.set(firstName, forKey: "firstName")
            self.firstName = firstName
        }
        
        if let lastName = userData["last_name"] as? String {
            UserDefaults.standard.set(lastName, forKey: "lastName")
            self.lastName = lastName
        }
        
        if let profileImageUrl = userData["picture"] as? String {
            UserDefaults.standard.set(profileImageUrl, forKey: "profileImageUrl")
            self.profileImageUrl = profileImageUrl
        }
        
        isAuthenticated = true
    }
    
    func logout() {
        // Sign out of Google
        GIDSignIn.sharedInstance.signOut()
        
        UserDefaults.standard.removeObject(forKey: "sessionToken")
        UserDefaults.standard.removeObject(forKey: "userId")
        UserDefaults.standard.removeObject(forKey: "userEmail")
        UserDefaults.standard.removeObject(forKey: "firstName")
        UserDefaults.standard.removeObject(forKey: "lastName")
        UserDefaults.standard.removeObject(forKey: "profileImageUrl")
        UserDefaults.standard.removeObject(forKey: "updateToken")
        
        userId = nil
        userEmail = nil
        firstName = nil
        lastName = nil
        profileImageUrl = nil
        isAuthenticated = false
    }
}

@main
struct AnatomyExplorerApp: App {
    @StateObject private var userModel = UserModel()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var authManager = AuthManager()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isAuthenticated {
                    // Use onAppear to update the user model
                    MainTabView()
                        .onAppear {
                            if let firstName = authManager.firstName {
                                userModel.name = firstName
                            }
                            if let userId = authManager.userId {
                                userModel.userId = userId
                            }
                            if let email = authManager.userEmail {
                                userModel.email = email
                            }
                        }
                } else {
                    LoginView(onLoginSuccess: { sessionToken, userData in
                        // Update user model with Google user data
                        if let firstName = userData["first_name"] as? String {
                            userModel.name = firstName
                        }
                        if let userId = userData["id"] as? String {
                            userModel.userId = userId
                        }
                        if let email = userData["email"] as? String {
                            userModel.email = email
                        }
                        
                        // Now login with the auth manager
                        authManager.login(sessionToken: sessionToken, userData: userData)
                    })
                }
            }
            .environmentObject(userModel)
            .environmentObject(themeManager)
            .environmentObject(authManager)
            .preferredColorScheme(.dark)
        }
    }
}

class UserModel: ObservableObject {
    @Published var name: String = "User"
    @Published var userId: String = ""
    @Published var email: String = ""
    @Published var username: String = ""
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
}

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var previousTab = 0
    @EnvironmentObject var userModel: UserModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(0)
                    .transition(.opacity)
           
                MuscleSelectionWithPreviewView()
                    .tag(1)
                    .transition(.opacity)
                
                WeeklyWorkoutView()
                    .environmentObject(userModel)
                    .tag(2)
                    .transition(.opacity)
                
                // Add EateryView as the 4th tab
                EateryView()
                    .tag(3)
                    .transition(.opacity)
                
                ProfileView()
                    .tag(4)
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

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @Binding var previousTab: Int
    @Namespace private var tabAnimation
    @EnvironmentObject var themeManager: ThemeManager
    
    // Updated tabItems array with new Eatery tab
    let tabItems = [
        TabItem(icon: "house.fill", title: "Home"),
        TabItem(icon: "figure.stand", title: "Anatomy"),
        TabItem(icon: "chart.bar.fill", title: "History"),
        TabItem(icon: "fork.knife", title: "Eatery"),    // Added Eatery tab with fork.knife icon
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
        .padding(.bottom, 15)
    }
}

struct TabItem {
    let icon: String
    let title: String
}

struct AnatomyExplorerApp_Previews: PreviewProvider {
    static var previews: some View {
        let userModel = UserModel()
        let themeManager = ThemeManager()
        let authManager = AuthManager()
        
        // Set up auth manager as if user is logged in
        authManager.isAuthenticated = true
        authManager.firstName = "Alex"
        authManager.userId = "123456"
        authManager.userEmail = "alex@example.com"
        
        // Update userModel with auth data
        userModel.name = authManager.firstName ?? "User"
        userModel.userId = authManager.userId ?? ""
        userModel.email = authManager.userEmail ?? ""
        
        return MainTabView()
            .environmentObject(userModel)
            .environmentObject(themeManager)
            .environmentObject(authManager)
            .preferredColorScheme(.dark)
    }
}
