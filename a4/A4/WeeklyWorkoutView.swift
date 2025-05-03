import SwiftUI
import SDWebImageSwiftUI

struct WeeklyWorkoutView: View {
    @EnvironmentObject var userModel: UserModel
    @State private var selectedTab = 0
    @State private var selectedDay = 0
    @State private var dayExercises: [String: [Exercise]] = [
        "Monday": [], "Tuesday": [], "Wednesday": [], "Thursday": [],
        "Friday": [], "Saturday": [], "Sunday": []
    ]
    @State private var posts: [WorkoutPost] = []
    @State private var isLoadingPosts = true
    @State private var postError: String? = nil
    @State private var isEditingWorkoutType = false
    @State private var editWorkoutType = ""
    @State private var showExerciseSelector = false
    @State private var showDayPicker = false
    @State private var workoutToShare: WorkoutDay? = nil
    @State private var dayToAssign = "Monday"
    
    let weekdays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    let workoutTypes = ["Chest", "Back", "Legs", "Shoulders", "Arms", "Core", "Push", "Pull", "Upper", "Lower", "Full Body", "Cardio", "Rest", "Custom"]
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.1),
                    Color(red: 0.1, green: 0.1, blue: 0.2)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                VStack(spacing: 2) {
                    Text("Weekly Workout Plan")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 0) {
                        TabButton(title: "My Plan", isSelected: selectedTab == 0) {
                            withAnimation {
                                selectedTab = 0
                            }
                        }
                        
                        TabButton(title: "Social", isSelected: selectedTab == 1) {
                            withAnimation {
                                selectedTab = 1
                                if posts.isEmpty {
                                    loadPosts()
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                .padding(.top)
                
                if selectedTab == 0 {
                    VStack(spacing: 0) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(0..<weekdays.count, id: \.self) { index in
                                    let day = weekdays[index]
                                    DayButton(
                                        day: day,
                                        type: userModel.workoutSchedule[day] ?? "Rest",
                                        isSelected: selectedDay == index
                                    ) {
                                        withAnimation {
                                            selectedDay = index
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                        }
                        
                        VStack(alignment: .leading, spacing: 16) {
                            let currentDay = weekdays[selectedDay]
                            let workoutType = userModel.workoutSchedule[currentDay] ?? "Rest"
                            
                            HStack {
                                if isEditingWorkoutType {
                                    Picker("Workout Type", selection: $editWorkoutType) {
                                        ForEach(workoutTypes, id: \.self) { type in
                                            Text(type)
                                                .foregroundColor(.white)
                                                .tag(type)
                                        }
                                    }
                                    .pickerStyle(WheelPickerStyle())
                                    .frame(height: 100)
                                    .clipped()
                                    
                                    Button(action: {
                                        userModel.workoutSchedule[currentDay] = editWorkoutType
                                        isEditingWorkoutType = false
                                    }) {
                                        Text("Save")
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(Color.blue)
                                            .cornerRadius(8)
                                    }
                                } else {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(currentDay)")
                                            .font(.headline)
                                            .foregroundColor(.gray)
                                        
                                        HStack {
                                            Text(workoutType)
                                                .font(.title2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                            
                                            Spacer()
                                            
                                            Button(action: {
                                                workoutToShare = WorkoutDay(
                                                    type: workoutType,
                                                    exercises: dayExercises[currentDay] ?? []
                                                )
                                                shareWorkout()
                                            }) {
                                                Image(systemName: "square.and.arrow.up")
                                                    .font(.title2)
                                                    .foregroundColor(.green)
                                                    .padding(.trailing, 8)
                                            }
                                            
                                            Button(action: {
                                                editWorkoutType = workoutType
                                                isEditingWorkoutType = true
                                            }) {
                                                Image(systemName: "pencil.circle")
                                                    .font(.title2)
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 12)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Exercises")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        showExerciseSelector = true
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "plus.circle.fill")
                                            Text("Add")
                                        }
                                        .foregroundColor(.blue)
                                    }
                                }
                                .padding(.horizontal)
                                
                                let currentExercises = dayExercises[currentDay] ?? []
                                
                                if currentExercises.isEmpty {
                                    VStack(spacing: 12) {
                                        if workoutType == "Rest" {
                                            Text("Rest Day")
                                                .font(.title3)
                                                .fontWeight(.medium)
                                                .foregroundColor(.gray)
                                                .padding(.vertical, 40)
                                        } else {
                                            Image(systemName: "dumbbell")
                                                .font(.system(size: 40))
                                                .foregroundColor(.gray.opacity(0.5))
                                                .padding()
                                            
                                            Text("No exercises added yet")
                                                .foregroundColor(.gray)
                                                .multilineTextAlignment(.center)
                                            
                                            Button(action: {
                                                showExerciseSelector = true
                                            }) {
                                                Text("Add Exercises")
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 20)
                                                    .padding(.vertical, 10)
                                                    .background(Color.blue.opacity(0.7))
                                                    .cornerRadius(10)
                                            }
                                            .padding(.top, 8)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 20)
                                } else {
                                    ScrollView {
                                        VStack(spacing: 12) {
                                            ForEach(currentExercises, id: \.id) { exercise in
                                                WorkoutExerciseRow(exercise: exercise, onDelete: {
                                                    removeExercise(day: currentDay, exerciseId: exercise.id)
                                                })
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                            
                            Spacer()
                        }
                    }
                } else {
                    SocialFeedView(
                        posts: $posts,
                        isLoading: $isLoadingPosts,
                        error: $postError,
                        onRefresh: loadPosts,
                        onCopyWorkout: { workout in
                            workoutToShare = workout
                            showDayPicker = true
                        }
                    )
                }
            }
        }
        .sheet(isPresented: $showExerciseSelector) {
            ExerciseSelectorView(onSelect: { exercise in
                addExercise(day: weekdays[selectedDay], exercise: exercise)
            })
            .background(Color.black.edgesIgnoringSafeArea(.all))
        }
        .actionSheet(isPresented: $showDayPicker) {
            ActionSheet(
                title: Text("Select Day"),
                message: Text("Choose which day to add this workout"),
                buttons: weekdayButtons
            )
        }
        .onAppear {
            loadSavedExercises()
        }
    }
    
    var weekdayButtons: [ActionSheet.Button] {
        var buttons = weekdays.map { day in
            ActionSheet.Button.default(Text(day)) {
                if let workout = workoutToShare {
                    userModel.workoutSchedule[day] = workout.type
                    dayExercises[day] = workout.exercises
                    saveExercises()
                    
                    if selectedTab == 1 {
                        selectedTab = 0
                        if let index = weekdays.firstIndex(of: day) {
                            selectedDay = index
                        }
                    }
                }
            }
        }
        
        buttons.append(.cancel())
        return buttons
    }
    
    func addExercise(day: String, exercise: Exercise) {
        var currentExercises = dayExercises[day] ?? []
        if !currentExercises.contains(where: { $0.id == exercise.id }) {
            currentExercises.append(exercise)
            dayExercises[day] = currentExercises
            saveExercises()
        }
    }
    
    func removeExercise(day: String, exerciseId: String) {
        var currentExercises = dayExercises[day] ?? []
        currentExercises.removeAll(where: { $0.id == exerciseId })
        dayExercises[day] = currentExercises
        saveExercises()
    }
    
    func loadPosts() {
        isLoadingPosts = true
        postError = nil
        
        Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in
            self.posts = [
                WorkoutPost(
                    id: "1",
                    username: "fitnessfan",
                    title: "My Push/Pull/Legs Split",
                    description: "This is my favorite PPL split for building strength and size.",
                    likes: 128,
                    workout: WorkoutDay(type: "Push", exercises: [
                        Exercise(
                            id: "1",
                            bodyPart: "chest",
                            equipment: "barbell",
                            gifUrl: "bench_press",
                            name: "Bench Press",
                            target: "pectorals",
                            secondaryMuscles: ["triceps", "shoulders"],
                            instructions: ["Lie on bench", "Lower bar to chest", "Push to starting position"]
                        ),
                        Exercise(
                            id: "2",
                            bodyPart: "shoulders",
                            equipment: "barbell",
                            gifUrl: "overhead_press",
                            name: "Overhead Press",
                            target: "deltoids",
                            secondaryMuscles: ["triceps", "traps"],
                            instructions: ["Stand with bar at shoulders", "Press overhead", "Lower to starting position"]
                        ),
                        Exercise(
                            id: "3",
                            bodyPart: "arms",
                            equipment: "cable",
                            gifUrl: "tricep_pushdown",
                            name: "Tricep Pushdown",
                            target: "triceps",
                            secondaryMuscles: [],
                            instructions: ["Stand at cable machine", "Push cable down", "Return to starting position"]
                        )
                    ])
                ),
                WorkoutPost(
                    id: "2",
                    username: "musclemaven",
                    title: "Ultimate Leg Day",
                    description: "Warning: You won't be able to walk after this one!",
                    likes: 95,
                    workout: WorkoutDay(type: "Legs", exercises: [
                        Exercise(
                            id: "4",
                            bodyPart: "legs",
                            equipment: "barbell",
                            gifUrl: "squats",
                            name: "Squats",
                            target: "quadriceps",
                            secondaryMuscles: ["glutes", "hamstrings", "lower back"],
                            instructions: ["Stand with bar on shoulders", "Squat down", "Return to starting position"]
                        ),
                        Exercise(
                            id: "5",
                            bodyPart: "legs",
                            equipment: "barbell",
                            gifUrl: "romanian_deadlift",
                            name: "Romanian Deadlift",
                            target: "hamstrings",
                            secondaryMuscles: ["glutes", "lower back"],
                            instructions: ["Hold bar at hip level", "Hinge at hips", "Return to starting position"]
                        ),
                        Exercise(
                            id: "6",
                            bodyPart: "legs",
                            equipment: "machine",
                            gifUrl: "leg_extensions",
                            name: "Leg Extensions",
                            target: "quadriceps",
                            secondaryMuscles: [],
                            instructions: ["Sit on machine", "Extend legs", "Lower to starting position"]
                        )
                    ])
                )
            ]
            
            self.isLoadingPosts = false
        }
    }
    
    func shareWorkout() {
        guard let workout = workoutToShare else { return }
        
        let currentDay = weekdays[selectedDay]
        let exercises = dayExercises[currentDay] ?? []
        
        print("Sharing workout: \(workout.type) with \(exercises.count) exercises")
        
        // This would be replaced with actual API call to share the workout
        // For example:
        /*
        let workoutData: [String: Any] = [
            "type": workout.type,
            "exercises": exercises.map { $0.id },
            "day": currentDay
        ]
        
        API.shareWorkout(workoutData) { result in
            // Handle result
        }
        */
    }
    
    func saveExercises() {
        if let encoded = try? JSONEncoder().encode(dayExercises) {
            UserDefaults.standard.set(encoded, forKey: "dayExercises")
        }
    }
    
    func loadSavedExercises() {
        if let savedExercisesData = UserDefaults.standard.data(forKey: "dayExercises"),
           let savedExercises = try? JSONDecoder().decode([String: [Exercise]].self, from: savedExercisesData) {
            self.dayExercises = savedExercises
        }
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .gray)
                
                Rectangle()
                    .fill(isSelected ? Color.blue : Color.clear)
                    .frame(height: 3)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity)
    }
}

struct DayButton: View {
    let day: String
    let type: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(day.prefix(3))
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .gray)
                
                Text(type)
                    .font(.caption)
                    .foregroundColor(isSelected ? .blue : .gray.opacity(0.7))
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ?
                          Color(red: 0.15, green: 0.15, blue: 0.25).opacity(0.7) :
                          Color(red: 0.1, green: 0.1, blue: 0.2).opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? Color.blue.opacity(0.8) : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
}

struct WorkoutExerciseRow: View {
    let exercise: Exercise
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Color(red: 0.1, green: 0.1, blue: 0.2)
                    .cornerRadius(8)
                
                if let url = URL(string: exercise.gifUrl) {
                    WebImage(url: url)
                        .resizable()
                        .indicator(.activity)
                        .transition(.fade)
                        .scaledToFit()
                        .cornerRadius(8)
                        .frame(width: 60, height: 60)
                } else {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                        .frame(width: 60, height: 60)
                }
            }
            .frame(width: 60, height: 60)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack(spacing: 6) {
                    Text(exercise.bodyPart.capitalized)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Circle()
                        .fill(Color.gray.opacity(0.6))
                        .frame(width: 4, height: 4)
                    
                    Text(exercise.equipment.capitalized)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                if !exercise.secondaryMuscles.isEmpty {
                    Text("Also works: \(exercise.secondaryMuscles.prefix(3).joined(separator: ", "))")
                        .font(.caption2)
                        .foregroundColor(.gray.opacity(0.8))
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red.opacity(0.8))
                    .padding(8)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.12, green: 0.12, blue: 0.2).opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct SocialFeedView: View {
    @Binding var posts: [WorkoutPost]
    @Binding var isLoading: Bool
    @Binding var error: String?
    let onRefresh: () -> Void
    let onCopyWorkout: (WorkoutDay) -> Void
    
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
                            WorkoutPostCard(post: post, onCopyWorkout: onCopyWorkout)
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

struct WorkoutPostCard: View {
    let post: WorkoutPost
    let onCopyWorkout: (WorkoutDay) -> Void
    
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
                
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red.opacity(0.8))
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

struct WorkoutDay: Codable {
    var type: String
    var exercises: [Exercise]
}

struct WorkoutPost: Identifiable {
    var id: String
    var username: String
    var title: String
    var description: String
    var likes: Int
    var workout: WorkoutDay
}

struct ExerciseSelectorView: View {
    let onSelect: (Exercise) -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @State private var exercises: [Exercise] = []
    @State private var isLoading = true
    @State private var searchText = ""
    @State private var errorMessage: String? = nil
    
    var filteredExercises: [Exercise] {
        if searchText.isEmpty {
            return exercises
        } else {
            return exercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search exercises", text: $searchText)
                            .foregroundColor(.white)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()
                    .background(Color(red: 0.15, green: 0.15, blue: 0.2))
                    .cornerRadius(10)
                    .padding()
                    
                    if isLoading {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Spacer()
                    } else if let error = errorMessage {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.orange)
                                .padding()
                            Text(error)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            Button(action: {
                                loadExercises()
                            }) {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Try Again")
                                }
                                .padding()
                                .background(Color.blue.opacity(0.7))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                        }
                        Spacer()
                    } else {
                        List(filteredExercises, id: \.id) { exercise in
                            ExerciseRow(exercise: exercise)
                                .onTapGesture {
                                    onSelect(exercise)
                                    presentationMode.wrappedValue.dismiss()
                                }
                                .listRowBackground(Color(red: 0.1, green: 0.1, blue: 0.15))
                        }
                        .listStyle(PlainListStyle())
                    }
                }
            }
            .navigationBarTitle("Select Exercise", displayMode: .inline)
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .onAppear {
                loadExercises()
            }
        }
    }
    
    func loadExercises() {
        isLoading = true
        errorMessage = nil
        
        ExerciseService.shared.fetchAllExercises { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let fetchedExercises):
                    // Use exercises directly with their original IDs from the API
                    self.exercises = fetchedExercises
                    
                    // Log some sample IDs for verification
                    if !fetchedExercises.isEmpty {
                        let sampleIds = fetchedExercises.prefix(5).map { $0.id }
                        print("Sample exercise IDs: \(sampleIds)")
                    }
                    
                    print("Loaded \(fetchedExercises.count) exercises")
                    
                case .failure(let error):
                    self.errorMessage = "Failed to load exercises: \(error.localizedDescription)"
                }
            }
        }
    }
}

struct ExerciseRow: View {
    let exercise: Exercise
    
    var body: some View {
        HStack {
            ZStack {
                Color(red: 0.15, green: 0.15, blue: 0.2)
                    .frame(width: 50, height: 50)
                    .cornerRadius(8)
                
                if let url = URL(string: exercise.gifUrl) {
                    WebImage(url: url)
                        .resizable()
                        .indicator(.activity)
                        .transition(.fade)
                        .scaledToFit()
                        .cornerRadius(8)
                        .frame(width: 50, height: 50)
                } else {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .foregroundColor(.gray)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .foregroundColor(.white)
                    .font(.headline)
                
                HStack {
                    Text(exercise.bodyPart.capitalized)
                        .foregroundColor(.gray)
                        .font(.caption)
                    
                    Text("•")
                        .foregroundColor(.gray)
                        .font(.caption)
                    
                    Text(exercise.equipment.capitalized)
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }
            
            Spacer()
            
            Image(systemName: "plus.circle")
                .foregroundColor(.blue)
        }
        .padding(.vertical, 4)
    }
}

struct WeeklyWorkoutView_Previews: PreviewProvider {
    static var previews: some View {
        let previewUserModel = UserModel()
        previewUserModel.name = "Preview User"
        previewUserModel.workoutSchedule = [
            "Monday": "Chest",
            "Tuesday": "Back",
            "Wednesday": "Legs",
            "Thursday": "Shoulders",
            "Friday": "Arms",
            "Saturday": "Core",
            "Sunday": "Rest"
        ]
        
        return WeeklyWorkoutView()
            .environmentObject(previewUserModel)
            .preferredColorScheme(.dark)
    }
}
