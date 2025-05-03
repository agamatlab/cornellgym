//
//  SocialFeed.swift
//  A4
//
//  Created by Aghamatlab Akbarzade on 5/2/25.
//

import SwiftUI

struct SocialFeedView: View {
    @Binding var posts: [WorkoutPost]
    @Binding var isLoading: Bool
    @Binding var error: String?
    let onRefresh: () -> Void
    let onCopyWorkout: (WorkoutDay) -> Void
    let onLikePost: (String) -> Void
    let onUnlikePost: (String) -> Void
    
    var body: some View {
        ZStack {
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.blue.opacity(0.8)))
                    Text("Loading workouts...")
                        .foregroundColor(.white)
                        .font(.headline)
                }
            } else if let errorMessage = error {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                        .padding()
                    Text(errorMessage)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button(action: onRefresh) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Try Again")
                        }
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
            } else if posts.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.gray.opacity(0.7))
                        .padding()
                    Text("No workouts found")
                        .foregroundColor(.white)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button(action: onRefresh) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Refresh")
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.blue.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.top, 8)
                }
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(posts, id: \.id) { post in
                            WorkoutPostCard(
                                post: post,
                                onCopyWorkout: onCopyWorkout,
                                onLike: onLikePost,
                                onUnlike: onUnlikePost
                            )
                        }
                    }
                    .padding()
                }
            }
        }
    }
}
