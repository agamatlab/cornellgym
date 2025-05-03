import SwiftUI

struct HomeView: View {
    @EnvironmentObject var userModel: UserModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var authManager: AuthManager
    @State private var currentDate = Date()
    
    var body: some View {
        // Remove NavigationView since it's already provided by MainTabView
        ScrollView(){
            ZStack(alignment: .top) {
                // Main screen background
                
                // Top gradient with rounded corners - simplified structure
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.05, green: 0.15, blue: 0.3), // Darker metallic blue
                        Color(red: 0.0, green: 0.3, blue: 0.4)    // Darker cyan
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 440)
                .clipShape(
                    RoundedCorner(radius: 30, corners: .allCorners)
                )
                .ignoresSafeArea(edges: [.top, .horizontal])
                
                // Content
                
                VStack(alignment: .leading, spacing: 25) {
                    // Welcome section with user image
                    VStack(alignment:.leading, spacing: 25){
                        welcomeSection
                        
                        // Today's workout section
                        todayWorkoutSection
                            
                    }
                    .padding(.bottom, 30)
                    
                    // Recommended exercises
                    recommendedExercisesSection
        
                }
                .padding(.horizontal)
                .padding(.bottom, 100) // Extra padding for tab bar
                
            }
            .ignoresSafeArea(.container, edges: .top)// Ensure the entire view ignores the top safe area
        }
        .ignoresSafeArea(.container, edges: .top)// Ensure the entire view ignores the top safe area
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
    }
    
    // MARK: - Welcome Section
    var welcomeSection: some View {
        HStack(spacing: 20) {
            // Use ProfileImageView instead of hardcoded Image
            ProfileImageView()
                .environmentObject(authManager)
                .environmentObject(themeManager)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Welcome back,")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(themeManager.current.textSecondary)
                
                Text(userModel.name)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.current.textPrimary)
            }
            
            Spacer()
        }
        .padding(.top, 80)
        .padding(.bottom, 10)
    }
    
    // MARK: - Today's Workout Section
    var todayWorkoutSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Today's Focus")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.current.accent1)
                
                Spacer()
                
                Text(currentDateFormatted)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(themeManager.current.accent2)
            }
            
            // Today's workout card
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Image(systemName: getWorkoutIcon())
                        .font(.system(size: 36))
                        .foregroundColor(getWorkoutColor())
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text(todayWorkout)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.current.textPrimary)
                        
                        Text("Focus on form and controlled movements")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(themeManager.current.textSecondary.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(themeManager.current.surface3)
                }
                
                Divider()
                    .background(themeManager.current.divider)
                
                HStack {
                    workoutStatItem(value: "45", label: "Minutes", icon: "clock.fill")
                    
                    Divider()
                        .frame(height: 40)
                        .background(themeManager.current.divider)
                    
                    workoutStatItem(value: "4", label: "Exercises", icon: "dumbbell.fill")
                    
                    Divider()
                        .frame(height: 40)
                        .background(themeManager.current.divider)
                    
                    workoutStatItem(value: "Medium", label: "Intensity", icon: "flame.fill")
                }
            }
            .padding(20)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        themeManager.current.surface1.opacity(0.7),
                        themeManager.current.surface2.opacity(0.5)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.2), radius: 10)
        }
    }
    
    // MARK: - Recommended Exercises Section
    var recommendedExercisesSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Recommended Exercises")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(themeManager.current.accent1)
            
            ForEach(getRecommendedExercises(), id: \.name) { exercise in
                HStack(spacing: 15) {
                    // Exercise image placeholder
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    getMuscleColorForExercise(exercise.muscle).opacity(0.4),
                                    getMuscleColorForExercise(exercise.muscle).opacity(0.1)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 70, height: 70)
                        .overlay(
                            Image(systemName: exercise.icon)
                                .font(.system(size: 24))
                                .foregroundColor(getMuscleColorForExercise(exercise.muscle))
                        )
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text(exercise.name)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(themeManager.current.textPrimary)
                        
                        Text(exercise.muscle)
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(themeManager.current.accent2)
                        
                        Text("Sets: \(exercise.sets) • Reps: \(exercise.reps)")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(themeManager.current.textSecondary.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        // Set this muscle as selected for detailed view
                        userModel.selectedMuscle = exercise.muscle
                    }) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 22))
                            .foregroundColor(themeManager.current.highlight)
                    }
                }
                .padding(15)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(themeManager.current.surface1)
                )
                .shadow(color: Color.black.opacity(0.1), radius: 5)
            }
        }
    }
    
    // MARK: - Helper Views
    func workoutStatItem(value: String, label: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(themeManager.current.accent1)
                .font(.system(size: 16))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.current.textPrimary)
                
                Text(label)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(themeManager.current.textSecondary.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Helper Methods
    var currentDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: currentDate)
    }
    
    var todayWorkout: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        let weekday = formatter.string(from: currentDate)
        return userModel.workoutSchedule[weekday] ?? "Rest"
    }
    
    func getWorkoutIcon() -> String {
        switch todayWorkout {
        case "Chest":
            return "figure.arms.open"
        case "Back":
            return "figure.stand"
        case "Legs":
            return "figure.walk"
        case "Shoulders":
            return "figure.arms.open"
        case "Arms":
            return "figure.strengthtraining.traditional"
        case "Core":
            return "figure.core.training"
        default:
            return "figure.cooldown"
        }
    }
    
    func getWorkoutColor() -> Color {
        switch todayWorkout {
        case "Chest":
            return themeManager.current.chestColor
        case "Back":
            return themeManager.current.backColor
        case "Legs":
            return themeManager.current.legsColor
        case "Shoulders":
            return themeManager.current.shouldersColor
        case "Arms":
            return themeManager.current.armsColor
        case "Core":
            return themeManager.current.coreColor
        default:
            return themeManager.current.restColor
        }
    }
    
    struct Exercise {
        let name: String
        let muscle: String
        let sets: Int
        let reps: String
        let icon: String
    }
    
    func getRecommendedExercises() -> [Exercise] {
        switch todayWorkout {
        case "Chest":
            return [
                Exercise(name: "Bench Press", muscle: "Pectoralis major", sets: 4, reps: "8-12", icon: "figure.arms.open"),
                Exercise(name: "Incline Dumbbell Press", muscle: "Pectoralis major", sets: 3, reps: "10-12", icon: "figure.arms.open"),
                Exercise(name: "Cable Fly", muscle: "Pectoralis major", sets: 3, reps: "12-15", icon: "figure.arms.open")
            ]
        case "Back":
            return [
                Exercise(name: "Pull-Ups", muscle: "Latissimus dorsi", sets: 4, reps: "8-12", icon: "figure.arms.open"),
                Exercise(name: "Bent Over Rows", muscle: "Trapezius (upper)", sets: 3, reps: "10-12", icon: "figure.stand"),
                Exercise(name: "Lat Pulldown", muscle: "Latissimus dorsi", sets: 3, reps: "12-15", icon: "figure.arms.open")
            ]
        case "Legs":
            return [
                Exercise(name: "Squats", muscle: "Quadriceps", sets: 4, reps: "8-12", icon: "figure.walk"),
                Exercise(name: "Romanian Deadlift", muscle: "Hamstrings", sets: 3, reps: "10-12", icon: "figure.walk"),
                Exercise(name: "Leg Press", muscle: "Quadriceps", sets: 3, reps: "12-15", icon: "figure.walk"),
                Exercise(name: "Calf Raises", muscle: "Gastrocnemius", sets: 4, reps: "15-20", icon: "figure.walk")
            ]
        case "Shoulders":
            return [
                Exercise(name: "Overhead Press", muscle: "Deltoid", sets: 4, reps: "8-12", icon: "figure.arms.open"),
                Exercise(name: "Lateral Raises", muscle: "Deltoid", sets: 3, reps: "12-15", icon: "figure.arms.open"),
                Exercise(name: "Face Pulls", muscle: "Deltoid", sets: 3, reps: "12-15", icon: "figure.arms.open")
            ]
        case "Arms":
            return [
                Exercise(name: "Barbell Curls", muscle: "Biceps brachii", sets: 4, reps: "8-12", icon: "figure.strengthtraining.traditional"),
                Exercise(name: "Tricep Pushdowns", muscle: "Triceps brachii", sets: 3, reps: "10-12", icon: "figure.strengthtraining.traditional"),
                Exercise(name: "Hammer Curls", muscle: "Biceps brachii", sets: 3, reps: "12-15", icon: "figure.strengthtraining.traditional"),
                Exercise(name: "Skull Crushers", muscle: "Triceps brachii", sets: 3, reps: "12-15", icon: "figure.strengthtraining.traditional")
            ]
        case "Core":
            return [
                Exercise(name: "Plank", muscle: "Rectus abdominis", sets: 3, reps: "30-60s", icon: "figure.core.training"),
                Exercise(name: "Russian Twists", muscle: "External oblique", sets: 3, reps: "15-20", icon: "figure.core.training"),
                Exercise(name: "Leg Raises", muscle: "Rectus abdominis", sets: 3, reps: "12-15", icon: "figure.core.training")
            ]
        default:
            return [
                Exercise(name: "Light Walking", muscle: "Full Body", sets: 1, reps: "20-30m", icon: "figure.walk"),
                Exercise(name: "Stretching", muscle: "Full Body", sets: 1, reps: "15-20m", icon: "figure.cooldown"),
                Exercise(name: "Foam Rolling", muscle: "Full Body", sets: 1, reps: "10-15m", icon: "figure.cooldown")
            ]
        }
    }
    
    func getMuscleColorForExercise(_ muscle: String) -> Color {
        if muscle.contains("Biceps") || muscle.contains("Triceps") || muscle.contains("Deltoid") || muscle.contains("Brachialis") {
            return themeManager.current.armsColor // Arms color
        } else if muscle.contains("Pectoralis") {
            return themeManager.current.chestColor // Chest color
        } else if muscle.contains("Quadriceps") || muscle.contains("Hamstrings") || muscle.contains("Gastrocnemius") || muscle.contains("Soleus") {
            return themeManager.current.legsColor // Legs color
        } else if muscle.contains("Trapezius") || muscle.contains("Latissimus") {
            return themeManager.current.backColor // Back color
        } else if muscle.contains("abdominis") || muscle.contains("oblique") {
            return themeManager.current.coreColor // Core color
        } else {
            return themeManager.current.restColor // Default color
        }
    }
}

// MARK: - RoundedCorner Shape for Specific Corners
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        let userModel = UserModel()
        let themeManager = ThemeManager()
        let authManager = AuthManager()
        
        return HomeView()
            .environmentObject(userModel)
            .environmentObject(themeManager)
            .environmentObject(authManager)
    }
}
