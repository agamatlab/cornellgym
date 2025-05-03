//
//  ProfileImageVIew.swift
//  A4
//
//  Created by Aghamatlab Akbarzade on 5/2/25.
//

import SwiftUI
import GoogleSignIn

// ProfileImageView Component
struct ProfileImageView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Group {
            if let imageUrl = authManager.profileImageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 70, height: 70)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        fallbackImage
                    @unknown default:
                        fallbackImage
                    }
                }
                .frame(width: 70, height: 70)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [themeManager.current.accent1, themeManager.current.highlight]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                )
                .shadow(color: Color.black.opacity(0.2), radius: 10)
            } else {
                fallbackImage
            }
        }
    }
    
    var fallbackImage: some View {
        Image(systemName: "person.crop.circle.fill")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 70, height: 70)
            .foregroundColor(themeManager.current.accent2)
            .background(themeManager.current.surface1)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [themeManager.current.accent1, themeManager.current.highlight]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
            )
            .shadow(color: Color.black.opacity(0.2), radius: 10)
    }
}
