//
//  ProfileView.swift
//  HackProject
//
//  Created by Aghamatlab Akbarzade on 4/26/25.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var userModel: UserModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingThemeSettings = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Profile header
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
                    
                    // Settings sections
                    settingsSection
                    
                    // App settings section
                    appSettingsSection
                    
                    // About section
                    aboutSection
                }
                .padding()
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
            .sheet(isPresented: $showingThemeSettings) {
                ThemeSettingsView()
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
            }
            .background(themeManager.current.surface1)
            .cornerRadius(12)
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
            .preferredColorScheme(.dark)
    }
}
