import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var userModel: UserModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var authManager: AuthManager
    @State private var showingThemeSettings = false
    @State private var showLogoutConfirmation = false
    
    var body: some View {
        // Use NavigationStack instead of NavigationView for better iOS compatibility
        NavigationStack {
            ScrollView {
                // This spacer ensures proper top spacing on all devices
                Spacer()
                    .frame(height: 20)
                
                VStack(spacing: 30) {
                    // Profile header with improved spacing
                    VStack(spacing: 15) {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .foregroundColor(themeManager.current.accent2)
                            .padding()
                        
                        Text(userModel.name)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.current.textPrimary)
                    }
                    .padding(.vertical, 20)
                    .padding(.top, 20) // Additional top padding for the header
                    
                    // Settings sections
                    settingsSection
                    
                    // App settings section
                    appSettingsSection
                    
                    // About section
                    aboutSection
                }
                .padding()
                .padding(.bottom, 80) // Bottom padding for tab bar
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        themeManager.current.background1,
                        themeManager.current.background2
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
            )
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline) // Make title inline for better spacing
            .sheet(isPresented: $showingThemeSettings) {
                ThemeSettingsView()
            }
            .alert(isPresented: $showLogoutConfirmation) {
                Alert(
                    title: Text("Logout"),
                    message: Text("Are you sure you want to logout?"),
                    primaryButton: .destructive(Text("Logout")) {
                        authManager.logout()
                    },
                    secondaryButton: .cancel()
                )
            }
            // This ensures content respects safe areas
            .edgesIgnoringSafeArea([.bottom])
            .safeAreaInset(edge: .top) {
                Color.clear.frame(height: 0)
            }
        }
    }
    
    // MARK: - Settings Section
    var settingsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Account Settings")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(themeManager.current.accent1)
            
            VStack(spacing: 2) {
                settingItem(icon: "person.fill", title: "Edit Profile") {
                    // Navigate to edit profile
                }
                
                Divider()
                    .background(themeManager.current.divider)
                
                settingItem(icon: "bell.fill", title: "Notifications") {
                    // Navigate to notifications
                }
                
                Divider()
                    .background(themeManager.current.divider)
                
                settingItem(icon: "lock.fill", title: "Privacy") {
                    // Navigate to privacy settings
                }
                
                Divider()
                    .background(themeManager.current.divider)
                
                // Logout Button
                logoutButton
            }
            .background(themeManager.current.surface1)
            .cornerRadius(12)
        }
    }
    
    // Logout button
    var logoutButton: some View {
        Button(action: {
            showLogoutConfirmation = true
        }) {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .frame(width: 30)
                    .foregroundColor(.red)
                
                Text("Logout")
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(.red)
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
    }
    
    // MARK: - App Settings Section
    var appSettingsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("App Settings")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(themeManager.current.accent1)
            
            VStack(spacing: 2) {
                settingItem(icon: "paintbrush.fill", title: "Theme Settings") {
                    showingThemeSettings = true
                }
                
                Divider()
                    .background(themeManager.current.divider)
                
                settingItem(icon: "gear", title: "Preferences") {
                    // Navigate to app preferences
                }
                
                Divider()
                    .background(themeManager.current.divider)
                
                settingItem(icon: "square.and.arrow.down", title: "Download Data") {
                    // Handle data download
                }
            }
            .background(themeManager.current.surface1)
            .cornerRadius(12)
        }
    }
    
    // MARK: - About Section
    var aboutSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("About")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(themeManager.current.accent1)
            
            VStack(spacing: 2) {
                settingItem(icon: "questionmark.circle", title: "Help & Support") {
                    // Navigate to help
                }
                
                Divider()
                    .background(themeManager.current.divider)
                
                settingItem(icon: "doc.text", title: "Terms of Service") {
                    // Show terms
                }
                
                Divider()
                    .background(themeManager.current.divider)
                
                settingItem(icon: "shield", title: "Privacy Policy") {
                    // Show privacy policy
                }
            }
            .background(themeManager.current.surface1)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Helper Views
    func settingItem(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 30)
                    .foregroundColor(themeManager.current.accent2)
                
                Text(title)
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(themeManager.current.textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(themeManager.current.surface3)
                    .font(.system(size: 14))
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(UserModel())
            .environmentObject(ThemeManager())
            .environmentObject(AuthManager())
            .preferredColorScheme(.dark)
    }
}
