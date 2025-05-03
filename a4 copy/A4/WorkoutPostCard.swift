import SwiftUI

struct WorkoutPostCard: View {
    let post: WorkoutPost
    let onCopyWorkout: (WorkoutDay) -> Void
    let onLike: (String) -> Void
    let onUnlike: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [.blue, .purple]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(post.username.prefix(1).uppercased())
                            .font(.headline)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.username)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Shared a \(post.workout.type) workout")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: {
                    if post.likedByUser {
                        onUnlike(post.id)
                    } else {
                        onLike(post.id)
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: post.likedByUser ? "heart.fill" : "heart")
                            .foregroundColor(post.likedByUser ? .red.opacity(0.8) : .gray)
                        Text("\(post.likes)")
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                }
            }
            
            Text(post.title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(post.description)
                .font(.body)
                .foregroundColor(.gray.opacity(0.9))
                .lineLimit(2)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(post.workout.type) Workout")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(post.workout.exercises.count) exercises")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                ForEach(post.workout.exercises.prefix(3), id: \.id) { exercise in
                    HStack {
                        Circle()
                            .fill(Color.blue.opacity(0.3))
                            .frame(width: 8, height: 8)
                        
                        Text(exercise.name)
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text(exercise.target.capitalized)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 2)
                }
                
                if post.workout.exercises.count > 3 {
                    Text("+ \(post.workout.exercises.count - 3) more exercises")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 4)
                }
            }
            .padding()
            .background(Color(red: 0.13, green: 0.13, blue: 0.22).opacity(0.6))
            .cornerRadius(12)
            
            HStack {
                Spacer()
                
                Button(action: {
                    onCopyWorkout(post.workout)
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Save to My Plan")
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.1, green: 0.1, blue: 0.2).opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        )
    }
}
