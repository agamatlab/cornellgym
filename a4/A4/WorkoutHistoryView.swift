//
//  WorkoutHistoryView.swift
//  HackProject
//
//  Created by Aghamatlab Akbarzade on 4/24/25.
//

import SwiftUI

struct WorkoutHistoryView: View {
    @EnvironmentObject var userModel: UserModel
    @State private var selectedWeek: Int = 0
    @State private var showingWorkoutEditor = false
    @State private var selectedDay: String = ""
    @State private var selectedDate: Date = Date()
    
    // Current week dates
    let calendar = Calendar.current
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    headerView
                    
                    // Weekly calendar view
                    weekCalendarView
                    
                    // Workout history cards
                    workoutHistorySection
                    
                    // Stats section
                    statsSection
                }
                .padding(.horizontal)
                .padding(.bottom, 100) // Extra padding for tab bar
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color("2E3440"),
                        Color("242933")
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
            )
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button(action: {
                    // Toggle edit mode
                }) {
                    Text("Edit")
                        .foregroundColor(Color("88C0D0"))
                        .fontWeight(.medium)
                }
            )
            .sheet(isPresented: $showingWorkoutEditor) {
                WorkoutEditorView(
                    day: selectedDay,
                    date: selectedDate,
                    currentWorkout: userModel.workoutSchedule[calendar.weekdaySymbols[calendar.component(.weekday, from: selectedDate) - 1]] ?? "Rest",
                    onSave: { workoutType in
                        let weekday = calendar.weekdaySymbols[calendar.component(.weekday, from: selectedDate) - 1]
                        userModel.workoutSchedule[weekday] = workoutType
                    }
                )
            }
        }
    }
    
    // MARK: - Header View
    var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Workout Schedule")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Color("ECEFF4"))
            
            Text("Plan and track your training")
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(Color("D8DEE9"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 20)
    }
    
    // MARK: - Week Calendar View
    var weekCalendarView: some View {
        VStack(spacing: 15) {
            // Week navigation
            HStack {
                Button(action: {
                    withAnimation {
                        selectedWeek -= 1
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(Color("81A1C1"))
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Spacer()
                
                Text(weekRangeText)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(Color("ECEFF4"))
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        selectedWeek += 1
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color("81A1C1"))
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .padding(.horizontal, 6)
            
            // Days of the week
            HStack(spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { day in
                    let date = getDateForDay(day)
                    let isToday = calendar.isDateInToday(date)
                    let workoutType = userModel.workoutSchedule[day] ?? "Rest"
                    
                    DayButton(
                        day: day,
                        date: calendar.component(.day, from: date),
                        workoutType: workoutType,
                        isToday: isToday,
                        onTap: {
                            selectedDay = day
                            selectedDate = date
                            showingWorkoutEditor = true
                        }
                    )
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("3B4252"))
                    .shadow(color: Color.black.opacity(0.1), radius: 10)
            )
        }
    }
    
    // MARK: - Workout History Section
    var workoutHistorySection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Recent Workouts")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(Color("88C0D0"))
            
            ForEach(0..<min(recentWorkouts.count, 3), id: \.self) { index in
                let workout = recentWorkouts[index]
                WorkoutHistoryCard(workout: workout)
            }
            
            Button(action: {
                // View more action
            }) {
                Text("View All Workouts")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(Color("88C0D0"))
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color("4C566A"), lineWidth: 1)
                    )
            }
        }
    }
    
    // MARK: - Stats Section
    var statsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Weekly Stats")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(Color("88C0D0"))
            
            HStack(spacing: 15) {
                StatCard(value: "4", label: "Workouts", icon: "figure.walk")
                StatCard(value: "160", label: "Minutes", icon: "clock.fill")
            }
            
            HStack(spacing: 15) {
                StatCard(value: "28", label: "Sets", icon: "repeat")
                StatCard(value: "2", label: "Rest Days", icon: "bed.double.fill")
            }
        }
    }
    
    // MARK: - Helper Methods
    var daysOfWeek: [String] {
        return calendar.weekdaySymbols
    }
    
    var weekRangeText: String {
        let currentDate = Date()
        let weekStartDate = calendar.date(byAdding: .day, value: selectedWeek * 7, to: startOfWeek(for: currentDate))!
        let weekEndDate = calendar.date(byAdding: .day, value: 6, to: weekStartDate)!
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        
        return "\(dateFormatter.string(from: weekStartDate)) - \(dateFormatter.string(from: weekEndDate))"
    }
    
    func startOfWeek(for date: Date) -> Date {
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components)!
    }
    
    func getDateForDay(_ day: String) -> Date {
        let currentDate = Date()
        let weekStartDate = calendar.date(byAdding: .day, value: selectedWeek * 7, to: startOfWeek(for: currentDate))!
        
        let weekdayIndex = calendar.weekdaySymbols.firstIndex(of: day)!
        return calendar.date(byAdding: .day, value: weekdayIndex, to: weekStartDate)!
    }
    
    // Sample data for recent workouts
    var recentWorkouts: [WorkoutHistoryItem] {
        return [
            WorkoutHistoryItem(
                id: 1,
                date: Date().addingTimeInterval(-86400),
                type: "Arms",
                duration: 45,
                exercises: 4,
                sets: 12,
                notes: "Great pump today! Increased bicep curl weight."
            ),
            WorkoutHistoryItem(
                id: 2,
                date: Date().addingTimeInterval(-86400 * 2),
                type: "Chest",
                duration: 50,
                exercises: 5,
                sets: 15,
                notes: "Bench press PR: 225 lbs x 5 reps"
            ),
            WorkoutHistoryItem(
                id: 3,
                date: Date().addingTimeInterval(-86400 * 3),
                type: "Legs",
                duration: 60,
                exercises: 6,
                sets: 18,
                notes: "Focused on quad development"
            ),
            WorkoutHistoryItem(
                id: 4,
                date: Date().addingTimeInterval(-86400 * 5),
                type: "Back",
                duration: 55,
                exercises: 5,
                sets: 15,
                notes: "Pull-up improvement: 12 reps bodyweight"
            )
        ]
    }
}

// MARK: - Supporting Views

// Day Button for Week Calendar
struct DayButton: View {
    let day: String
    let date: Int
    let workoutType: String
    let isToday: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Text(day.prefix(3))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(isToday ? Color("ECEFF4") : Color("D8DEE9").opacity(0.8))
                
                Text("\(date)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(isToday ? Color("ECEFF4") : Color("D8DEE9"))
                
                getWorkoutIcon(for: workoutType)
                    .font(.system(size: 20))
                    .foregroundColor(getWorkoutColor(for: workoutType))
            }
            .padding(.vertical, 10)
            .frame(height: 90)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isToday ? Color("434C5E") : Color.clear)
                    .opacity(isToday ? 0.6 : 0)
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
        default:
            iconName = "figure.cooldown"
        }
        
        return Image(systemName: iconName)
    }
    
    func getWorkoutColor(for type: String) -> Color {
        switch type.lowercased() {
        case "chest", "push":
            return Color("A3BE8C")
        case "back", "pull":
            return Color("EBCB8B")
        case "legs":
            return Color("B48EAD")
        case "shoulders":
            return Color("88C0D0")
        case "arms":
            return Color("BF616A")
        case "core":
            return Color("D08770")
        default:
            return Color("81A1C1")
        }
    }
}

// Workout History Card
struct WorkoutHistoryCard: View {
    let workout: WorkoutHistoryItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(formattedDate(workout.date))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(Color("81A1C1"))
                    
                    Text(workout.type)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(Color("ECEFF4"))
                }
                
                Spacer()
                
                workoutTypeIcon
                    .font(.system(size: 30))
                    .foregroundColor(getWorkoutColor(for: workout.type))
                    .frame(width: 60, height: 60)
                    .background(
                        Circle()
                            .fill(Color("3B4252"))
                    )
            }
            
            Divider()
                .background(Color("434C5E"))
            
            HStack(spacing: 0) {
                workoutStat(value: "\(workout.duration)", unit: "min", icon: "clock.fill")
                workoutStat(value: "\(workout.exercises)", unit: "exrc", icon: "dumbbell.fill")
                workoutStat(value: "\(workout.sets)", unit: "sets", icon: "repeat")
            }
            
            if !workout.notes.isEmpty {
                Text(workout.notes)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(Color("D8DEE9").opacity(0.8))
                    .padding(.top, 5)
            }
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color("3B4252"),
                            Color("434C5E")
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.black.opacity(0.1), radius: 10)
        )
    }
    
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }
    
    var workoutTypeIcon: some View {
        let iconName: String
        
        switch workout.type.lowercased() {
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
        default:
            iconName = "figure.cooldown"
        }
        
        return Image(systemName: iconName)
    }
    
    func getWorkoutColor(for type: String) -> Color {
        switch type.lowercased() {
        case "chest", "push":
            return Color("A3BE8C")
        case "back", "pull":
            return Color("EBCB8B")
        case "legs":
            return Color("B48EAD")
        case "shoulders":
            return Color("88C0D0")
        case "arms":
            return Color("BF616A")
        case "core":
            return Color("D08770")
        default:
            return Color("81A1C1")
        }
    }
    
    func workoutStat(value: String, unit: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(Color("88C0D0"))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(Color("ECEFF4"))
                
                Text(unit)
                    .font(.system(size: 10, design: .rounded))
                    .foregroundColor(Color("D8DEE9").opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// Stat Card
struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(Color("88C0D0"))
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(Color("3B4252"))
                )
            
            VStack(alignment: .leading, spacing: 5) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(Color("ECEFF4"))
                
                Text(label)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(Color("D8DEE9").opacity(0.8))
            }
            
            Spacer()
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("434C5E"))
                .shadow(color: Color.black.opacity(0.1), radius: 5)
        )
        .frame(maxWidth: .infinity)
    }
}

// Workout History Item Model
struct WorkoutHistoryItem {
    let id: Int
    let date: Date
    let type: String
    let duration: Int
    let exercises: Int
    let sets: Int
    let notes: String
}
