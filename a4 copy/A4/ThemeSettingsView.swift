//
//  ThemeSettingsView.swift
//  HackProject
//
//  Created by Aghamatlab Akbarzade on 4/26/25.
//

import SwiftUI

struct ThemeSettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedTheme: String = "Nord"
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Theme Settings")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(themeManager.current.textPrimary)
            
            VStack(alignment: .leading, spacing: 20) {
                Text("Select Theme")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(themeManager.current.accent1)
                
                VStack(spacing: 15) {
                    themeButton(title: "Nord", isSelected: selectedTheme == "Nord") {
                        selectedTheme = "Nord"
                        themeManager.switchTheme(to: .nord)
                    }
                    
                    themeButton(title: "Dark", isSelected: selectedTheme == "Dark") {
                        selectedTheme = "Dark"
                        themeManager.switchTheme(to: .dark)
                    }
                    
                    // Add more theme options here
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(themeManager.current.surface1)
            )
            
            // Color preview section
            VStack(alignment: .leading, spacing: 20) {
                Text("Theme Preview")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(themeManager.current.accent1)
                
                colorPreviewSection
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(themeManager.current.surface1)
            )
            
            Spacer()
        }
        .padding()
        .navigationTitle("Theme Settings")
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
    }
    
    // Theme button
    private func themeButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(themeManager.current.textPrimary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(themeManager.current.success)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(themeManager.current.surface3)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(themeManager.current.surface2)
                    .shadow(color: isSelected ? themeManager.current.accent1.opacity(0.3) : Color.clear, radius: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? themeManager.current.accent1 : Color.clear, lineWidth: 1)
            )
        }
    }
    
    // Color preview section
    private var colorPreviewSection: some View {
        VStack(spacing: 15) {
            // Primary colors
            HStack(spacing: 10) {
                colorBox(color: themeManager.current.background1, title: "BG1")
                colorBox(color: themeManager.current.background2, title: "BG2")
                colorBox(color: themeManager.current.surface1, title: "Surface1")
                colorBox(color: themeManager.current.surface2, title: "Surface2")
            }
            
            // Text and accent colors
            HStack(spacing: 10) {
                colorBox(color: themeManager.current.textPrimary, title: "Text1")
                colorBox(color: themeManager.current.textSecondary, title: "Text2")
                colorBox(color: themeManager.current.accent1, title: "Accent1")
                colorBox(color: themeManager.current.accent2, title: "Accent2")
            }
            
            // Function colors
            HStack(spacing: 10) {
                colorBox(color: themeManager.current.success, title: "Success")
                colorBox(color: themeManager.current.warning, title: "Warning")
                colorBox(color: themeManager.current.error, title: "Error")
                colorBox(color: themeManager.current.highlight, title: "Highlight")
            }
            
            // Muscle group colors
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    colorBox(color: themeManager.current.chestColor, title: "Chest")
                    colorBox(color: themeManager.current.backColor, title: "Back")
                    colorBox(color: themeManager.current.legsColor, title: "Legs")
                    colorBox(color: themeManager.current.shouldersColor, title: "Shoulder")
                    colorBox(color: themeManager.current.armsColor, title: "Arms")
                    colorBox(color: themeManager.current.coreColor, title: "Core")
                }
            }
        }
    }
    
    // Color box with label
    private func colorBox(color: Color, title: String) -> some View {
        VStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(height: 40)
                .shadow(color: Color.black.opacity(0.1), radius: 2)
            
            Text(title)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(themeManager.current.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ThemeSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ThemeSettingsView()
            .environmentObject(ThemeManager())
            .preferredColorScheme(.dark)
    }
}
