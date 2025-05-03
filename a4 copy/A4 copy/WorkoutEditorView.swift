import SwiftUI

struct WorkoutEditorView: View {
    @EnvironmentObject var userModel: UserModel
    @EnvironmentObject var themeManager: ThemeManager
    
    // To support use in TabView, we'll make these properties optional
    var day: String
    var date: Date
    var currentWorkout: String
    var onSave: (String) -> Void
    
    @State private var selectedWorkoutType: String
    @State private var customWorkoutName: String = ""
    @State private var isCustom: Bool = false
    @Environment(\.presentationMode) var presentationMode
    
    // Default initializer for TabView usage
    init() {
        let today = Calendar.current.component(.weekday, from: Date())
        let weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        let currentDay = weekdays[today - 1]
        
        self.day = currentDay
        self.date = Date()
        self.currentWorkout = "Rest"
        self.onSave = { _ in }
        
        // Initialize the state properties
        _selectedWorkoutType = State(initialValue: "Rest")
        _isCustom = State(initialValue: false)
        _customWorkoutName = State(initialValue: "")
    }
    
    // Full initializer for direct usage
    init(day: String, date: Date, currentWorkout: String, onSave: @escaping (String) -> Void) {
        self.day = day
        self.date = date
        self.currentWorkout = currentWorkout
        self.onSave = onSave
        
        // Initialize state properties
        _selectedWorkoutType = State(initialValue: currentWorkout)
        _isCustom = State(initialValue: !Self.predefinedWorkoutTypes.contains(currentWorkout))
        _customWorkoutName = State(initialValue: !Self.predefinedWorkoutTypes.contains(currentWorkout) ? currentWorkout : "")
    }
    
    // Make workout types static so they can be accessed from init
    static let predefinedWorkoutTypes = [
        "Push", "Pull", "Legs",
        "Chest", "Back", "Shoulders", "Arms", "Legs", "Core",
        "Upper Body", "Lower Body",
        "Cardio", "HIIT", "Rest"
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    headerSection
                    
                    workoutTypeSelector
                    
                    if isCustom {
                        customWorkoutSection
                    }
                    
                    workoutScheduleSection
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
            .navigationBarTitle("Edit Workout", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(themeManager.current.accent1),
                
                trailing: Button("Save") {
                    if isCustom {
                        onSave(customWorkoutName.isEmpty ? "Custom" : customWorkoutName)
                    } else {
                        onSave(selectedWorkoutType)
                    }
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(themeManager.current.accent1)
                .fontWeight(.medium)
            )
        }
        .onAppear {
            // Update values from userModel if needed
            if currentWorkout == "Rest" && day != "" {
                if let workout = userModel.workoutSchedule[day] {
                    selectedWorkoutType = workout
                    isCustom = !Self.predefinedWorkoutTypes.contains(workout)
                    customWorkoutName = !Self.predefinedWorkoutTypes.contains(workout) ? workout : ""
                }
            }
        }
    }
    
    // MARK: - Header Section
    var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(day)")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(themeManager.current.textPrimary)
            
            Text(formattedDate)
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(themeManager.current.textSecondary)
        }
    }
    
    // MARK: - Workout Type Selector
    var workoutTypeSelector: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Workout Type")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(themeManager.current.accent1)
            
            // Three main workout types (Push/Pull/Legs)
            HStack(spacing: 10) {
                ForEach(["Push", "Pull", "Legs"], id: \.self) { type in
                    WorkoutTypeButton(
                        type: type,
                        isSelected: selectedWorkoutType == type && !isCustom,
                        action: {
                            selectedWorkoutType = type
                            isCustom = false
                        }
                    )
                }
            }
            
            Divider()
                .background(themeManager.current.divider)
                .padding(.vertical, 10)
            
            // Specific muscle group workouts
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(["Chest", "Back", "Shoulders", "Arms", "Core", "Cardio", "Rest"], id: \.self) { type in
                    WorkoutTypeButton(
                        type: type,
                        isSelected: selectedWorkoutType == type && !isCustom,
                        action: {
                            selectedWorkoutType = type
                            isCustom = false
                        }
                    )
                    .frame(height: 50)
                }
                
                // Custom workout button
                WorkoutTypeButton(
                    type: "Custom",
                    isSelected: isCustom,
                    action: {
                        isCustom = true
                        selectedWorkoutType = "Custom"
                    }
                )
                .frame(height: 50)
            }
        }
    }
    
    // MARK: - Custom Workout Section
    var customWorkoutSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Custom Workout Name")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(themeManager.current.accent1)
            
            TextField("Enter workout name", text: $customWorkoutName)
                .padding()
                .background(themeManager.current.surface1)
                .cornerRadius(10)
                .foregroundColor(themeManager.current.textPrimary)
        }
    }
    
    // MARK: - Workout Schedule Section
    var workoutScheduleSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Weekly Schedule")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(themeManager.current.accent1)
            
            VStack(spacing: 15) {
                ScheduleInfoCard(
                    title: "Apply to all \(day)s",
                    description: "Set this workout for every \(day) in your schedule",
                    iconName: "calendar"
                )
                
                ScheduleInfoCard(
                    title: "Create Workout Template",
                    description: "Save this as a template for future use",
                    iconName: "doc.text"
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views

// Workout Type Button
struct WorkoutTypeButton: View {
    let type: String
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            HStack {
                getWorkoutIcon(for: type)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? themeManager.current.textPrimary : getWorkoutColor(for: type))
                
                Text(type)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .medium, design: .rounded))
                    .foregroundColor(isSelected ? themeManager.current.textPrimary : themeManager.current.textSecondary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(themeManager.current.success)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? getWorkoutColor(for: type).opacity(0.3) : themeManager.current.surface1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? getWorkoutColor(for: type) : Color.clear, lineWidth: 1)
            )
        }
    }
    
    func getWorkoutIcon(for type: String) -> some View {
        let iconName: String
        
        switch type.lowercased() {
        case "chest", "push":
            iconName = "figure.arms.open"
        case "back", "pull":
            iconName = "figure.arms.open"
        case "legs":
            iconName = "figure.walk"
        case "shoulders":
            iconName = "figure.arms.open"
        case "arms":
            iconName = "figure.strengthtraining.traditional"
        case "core":
            iconName = "figure.core.training"
        case "cardio":
            iconName = "heart.fill"
        case "hiit":
            iconName = "timer"
        case "upper body":
            iconName = "figure.arms.open"
        case "lower body":
            iconName = "figure.walk"
        case "custom":
            iconName = "pencil"
        case "rest":
            iconName = "figure.cooldown"
        default:
            iconName = "figure.mixed.cardio"
        }
        
        return Image(systemName: iconName)
    }
    
    func getWorkoutColor(for type: String) -> Color {
        switch type.lowercased() {
        case "chest", "push":
            return themeManager.current.chestColor
        case "back", "pull":
            return themeManager.current.backColor
        case "legs", "lower body":
            return themeManager.current.legsColor
        case "shoulders", "upper body":
            return themeManager.current.shouldersColor
        case "arms":
            return themeManager.current.armsColor
        case "core":
            return themeManager.current.coreColor
        case "cardio", "hiit":
            return themeManager.current.error
        case "custom":
            return themeManager.current.accent2
        case "rest":
            return themeManager.current.restColor.opacity(0.7)
        default:
            return themeManager.current.accent2
        }
    }
}

// Schedule Info Card
struct ScheduleInfoCard: View {
    let title: String
    let description: String
    let iconName: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: {
            // Action to be implemented
        }) {
            HStack(spacing: 15) {
                Image(systemName: iconName)
                    .font(.system(size: 20))
                    .foregroundColor(themeManager.current.accent1)
                    .frame(width: 40, height: 40)
                    .background(themeManager.current.surface1)
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(themeManager.current.textPrimary)
                    
                    Text(description)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(themeManager.current.textSecondary.opacity(0.8))
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.current.surface3)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.current.surface2.opacity(0.5))
            )
        }
    }
}
