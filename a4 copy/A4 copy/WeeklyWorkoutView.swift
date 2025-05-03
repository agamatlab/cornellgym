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
    
    @State private var isSharing = false
    @State private var shareError: String? = nil
    @State private var showShareAlert = false
    @State private var showShareSuccess = false
    
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
                                                HStack {
                                                    if isSharing {
                                                        ProgressView()
                                                            .progressViewStyle(CircularProgressViewStyle(tint: .green))
                                                            .scaleEffect(0.8)
                                                    } else {
                                                        Image(systemName: "square.and.arrow.up")
                                                            .font(.title2)
                                                    }
                                                    
                                                    if showShareSuccess {
                                                        Text("Shared!")
                                                            .font(.caption)
                                                            .foregroundColor(.green)
                                                    }
                                                }
                                                .foregroundColor(.green)
                                                .padding(.trailing, 8)
                                            }
                                            .disabled(isSharing)
                                            .alert(isPresented: $showShareAlert) {
                                                Alert(
                                                    title: Text("Share Error"),
                                                    message: Text(shareError ?? "Unknown error occurred"),
                                                    dismissButton: .default(Text("OK"))
                                                )
                                            }
                                            .overlay(
                                                Group {
                                                    if showShareSuccess {
                                                        VStack {
                                                            HStack {
                                                                Image(systemName: "checkmark.circle.fill")
                                                                    .foregroundColor(.green)
                                                                
                                                                Text("Workout shared successfully!")
                                                                    .foregroundColor(.white)
                                                                    .font(.subheadline)
                                                                
                                                                Spacer()
                                                                
                                                                Button(action: {
                                                                    withAnimation {
                                                                        showShareSuccess = false
                                                                    }
                                                                }) {
                                                                    Image(systemName: "xmark")
                                                                        .font(.caption)
                                                                        .foregroundColor(.white.opacity(0.7))
                                                                }
                                                            }
                                                            .padding()
                                                            .background(Color.black.opacity(0.7))
                                                            .cornerRadius(10)
                                                            .padding()
                                                            .onAppear {
                                                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                                                    withAnimation {
                                                                        showShareSuccess = false
                                                                    }
                                                                }
                                                            }
                                                        }
                                                        .transition(.move(edge: .top))
                                                        .zIndex(1)
                                                    }
                                                }
                                            )
                                            
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
            print("Adding exercise with ID: \(exercise.id) to \(day)")
            
            let sequentialId = ExerciseService.shared.getSequentialId(for: exercise.id)
            print("Mapped to sequential ID: \(sequentialId)")
            
            currentExercises.append(exercise)
            dayExercises[day] = currentExercises
            saveExercises()
            syncExercisesToServer(day: day)
        }
    }
    
    func removeExercise(day: String, exerciseId: String) {
        var currentExercises = dayExercises[day] ?? []
        
        print("Removing exercise with ID: \(exerciseId) from \(day)")
        
        currentExercises.removeAll(where: { $0.id == exerciseId })
        dayExercises[day] = currentExercises
        saveExercises()
        syncExercisesToServer(day: day)
    }
    
    func syncExercisesToServer(day: String) {
        guard let sessionToken = UserDefaults.standard.string(forKey: "sessionToken") else {
            print("Cannot sync - no session token")
            return
        }
        
        let exercises = dayExercises[day] ?? []
        
        let workoutData: [String: Any] = [
            "name": "\(day) Workout",
            "description": "My workout for \(day)",
            "duration": 60,
            "exercises": exercises.map { $0.id },
            "exercise_plan": exercises.reduce(into: [String: Any]()) { result, exercise in
                result[exercise.id] = [
                    "sets": 3,
                    "reps": 12,
                    "weight": 0
                ]
            }
        ]
        
        print("Would sync \(exercises.count) exercises for \(day) to server")
        print("Exercise IDs: \(exercises.map { $0.id })")
    }
    
    func shareWorkout() {
        guard let workout = workoutToShare else { return }
        
        let currentDay = weekdays[selectedDay]
        let exercises = dayExercises[currentDay] ?? []
        
        if exercises.isEmpty {
            shareError = "Cannot share an empty workout. Please add exercises first."
            showShareAlert = true
            return
        }
        
        isSharing = true
        shareError = nil
        
        let exerciseNames = exercises.prefix(3).map { $0.name.capitalized }.joined(separator: ", ")
        let additionalExercises = exercises.count > 3 ? " and \(exercises.count - 3) more" : ""
        
        let workoutData: [String: Any] = [
            "name": "\(workout.type) Workout",
            "description": "My \(workout.type) workout for \(currentDay)",
            "duration": 60,
            "exercises": exercises.map { $0.id },
            "exercise_plan": exercises.reduce(into: [String: Any]()) { result, exercise in
                result[exercise.id] = [
                    "sets": 3,
                    "reps": 12,
                    "weight": 0
                ]
            }
        ]
        
        guard let workoutJSON = try? JSONSerialization.data(withJSONObject: workoutData) else {
            isSharing = false
            shareError = "Failed to prepare workout data"
            showShareAlert = true
            return
        }
        
        var workoutRequest = URLRequest(url: URL(string: "http://34.59.215.239/api/workouts/")!)
        workoutRequest.httpMethod = "POST"
        workoutRequest.httpBody = workoutJSON
        workoutRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let sessionToken = UserDefaults.standard.string(forKey: "sessionToken") {
            workoutRequest.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")
        } else {
            isSharing = false
            shareError = "You must be logged in to share workouts"
            showShareAlert = true
            return
        }
        
        URLSession.shared.dataTask(with: workoutRequest) { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    self.isSharing = false
                    self.shareError = error?.localizedDescription ?? "Failed to create workout"
                    self.showShareAlert = true
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                DispatchQueue.main.async {
                    self.isSharing = false
                    self.shareError = "Server returned an error: \(String(describing: (response as? HTTPURLResponse)?.statusCode))"
                    self.showShareAlert = true
                }
                return
            }
            
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let workoutId = json["id"] as? Int else {
                DispatchQueue.main.async {
                    self.isSharing = false
                    self.shareError = "Failed to parse workout response"
                    self.showShareAlert = true
                }
                return
            }
            
            let userName = self.userModel.name
            let contentWithExercises = "Check out my \(workout.type) workout featuring \(exerciseNames)\(additionalExercises)!"
            
            let postData: [String: Any] = [
                "title": "\(workout.type) Workout for \(currentDay)",
                "content": contentWithExercises,
                "workout_id": workoutId,
                "user_name": userName,
                "user_email": self.userModel.email
            ]
            
            guard let postJSON = try? JSONSerialization.data(withJSONObject: postData) else {
                DispatchQueue.main.async {
                    self.isSharing = false
                    self.shareError = "Failed to prepare post data"
                    self.showShareAlert = true
                }
                return
            }
            
            var postRequest = URLRequest(url: URL(string: "http://34.59.215.239/api/posts/")!)
            postRequest.httpMethod = "POST"
            postRequest.httpBody = postJSON
            postRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            if let sessionToken = UserDefaults.standard.string(forKey: "sessionToken") {
                postRequest.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")
            }
            
            URLSession.shared.dataTask(with: postRequest) { postData, postResponse, postError in
                DispatchQueue.main.async {
                    self.isSharing = false
                    
                    guard let postData = postData, postError == nil else {
                        self.shareError = postError?.localizedDescription ?? "Failed to share post"
                        self.showShareAlert = true
                        return
                    }
                    
                    guard let httpResponse = postResponse as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                        self.shareError = "Server returned an error: \(String(describing: (postResponse as? HTTPURLResponse)?.statusCode))"
                        self.showShareAlert = true
                        return
                    }
                    
                    self.showShareSuccess = true
                    
                    if self.selectedTab == 0 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            withAnimation {
                                self.selectedTab = 1
                                self.loadPosts()
                            }
                        }
                    } else {
                        self.loadPosts()
                    }
                }
            }.resume()
        }.resume()
    }
    
    func loadPosts() {
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            isLoadingPosts = true
            postError = nil
            
            Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in
                ExerciseService.shared.exerciseIndexMap = [:]
                ExerciseService.shared.nextIndex = 1
                
                self.posts = [
                    WorkoutPost(
                        id: "1",
                        username: "fitnessfan",
                        title: "My Push/Pull/Legs Split",
                        description: "This is my favorite PPL split for building strength and size.",
                        likes: 0,
                        workout: WorkoutDay(type: "Push", exercises: [
                            Exercise(
                                id: "exercise_1",
                                bodyPart: "chest",
                                equipment: "barbell",
                                gifUrl: "bench_press",
                                name: "Bench Press",
                                target: "pectorals",
                                secondaryMuscles: ["triceps", "shoulders"],
                                instructions: ["Lie on bench", "Lower bar to chest", "Push to starting position"]
                            ),
                            Exercise(
                                id: "exercise_2",
                                bodyPart: "shoulders",
                                equipment: "barbell",
                                gifUrl: "overhead_press",
                                name: "Overhead Press",
                                target: "deltoids",
                                secondaryMuscles: ["triceps", "traps"],
                                instructions: ["Stand with bar at shoulders", "Press overhead", "Lower to starting position"]
                            ),
                            Exercise(
                                id: "exercise_3",
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
                        likes: 0,
                        workout: WorkoutDay(type: "Legs", exercises: [
                            Exercise(
                                id: "exercise_4",
                                bodyPart: "legs",
                                equipment: "barbell",
                                gifUrl: "squats",
                                name: "Squats",
                                target: "quadriceps",
                                secondaryMuscles: ["glutes", "hamstrings", "lower back"],
                                instructions: ["Stand with bar on shoulders", "Squat down", "Return to starting position"]
                            ),
                            Exercise(
                                id: "exercise_5",
                                bodyPart: "legs",
                                equipment: "barbell",
                                gifUrl: "romanian_deadlift",
                                name: "Romanian Deadlift",
                                target: "hamstrings",
                                secondaryMuscles: ["glutes", "lower back"],
                                instructions: ["Hold bar at hip level", "Hinge at hips", "Return to starting position"]
                            ),
                            Exercise(
                                id: "exercise_6",
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
                
                for post in self.posts {
                    for exercise in post.workout.exercises {
                        _ = ExerciseService.shared.getSequentialId(for: exercise.id)
                    }
                }
                
                self.isLoadingPosts = false
            }
        } else {
            loadPostsFromAPI()
        }
    }
    
    func loadPostsFromAPI() {
        isLoadingPosts = true
        postError = nil
        
        guard let url = URL(string: "http://34.59.215.239/api/posts/") else {
            isLoadingPosts = false
            postError = "Invalid API URL"
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let sessionToken = UserDefaults.standard.string(forKey: "sessionToken") {
            request.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoadingPosts = false
                
                guard let data = data, error == nil else {
                    self.postError = error?.localizedDescription ?? "Failed to load posts"
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    self.postError = "Server returned an error: \(String(describing: (response as? HTTPURLResponse)?.statusCode))"
                    return
                }
                
                guard let postsArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                    self.postError = "Failed to parse posts response"
                    return
                }
                
                var workoutPosts: [WorkoutPost] = []
                
                for postData in postsArray {
                    guard let id = postData["id"] as? Int,
                          let title = postData["title"] as? String,
                          let content = postData["content"] as? String,
                          let createdBy = postData["created_by"] as? Int,
                          let workoutId = postData["workout_id"] as? Int else {
                        continue
                    }
                    
                    let username = postData["user_name"] as? String ?? "user\(createdBy)"
                    
                    self.fetchWorkoutDetails(workoutId: workoutId) { workout in
                        if let workout = workout {
                            let post = WorkoutPost(
                                id: "\(id)",
                                username: username,
                                title: title,
                                description: content,
                                likes: 0,
                                workout: workout
                            )
                            
                            workoutPosts.append(post)
                            
                            if workoutPosts.count == postsArray.count {
                                self.posts = workoutPosts
                            }
                        }
                    }
                }
                
                if postsArray.isEmpty {
                    self.posts = []
                }
            }
        }.resume()
    }
    
    func fetchWorkoutDetails(workoutId: Int, completion: @escaping (WorkoutDay?) -> Void) {
        guard let url = URL(string: "http://34.59.215.239/api/workouts/\(workoutId)/") else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let sessionToken = UserDefaults.standard.string(forKey: "sessionToken") {
            request.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard
                let data = data, error == nil,
                let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode),
                let workoutData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let name = workoutData["name"] as? String,
                let exerciseIds = workoutData["exercises"] as? [String]
            else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            let workoutType = name.contains("Push")   ? "Push"
                             : name.contains("Pull")  ? "Pull"
                             : name.contains("Legs")  ? "Legs"
                             : name.contains("Chest") ? "Chest"
                             : name.contains("Back")  ? "Back"
                             : name.contains("Shoulder") ? "Shoulders"
                             : name.contains("Arm")   ? "Arms"
                             : name.contains("Core")  ? "Core"
                             : "Custom"
            
            // Fetch full exercise details and preserve order
            ExerciseService.shared.fetchAllExercises { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let allExercises):
                        let exercises = exerciseIds.compactMap { id in
                            allExercises.first { $0.id == id }
                        }
                        let workout = WorkoutDay(type: workoutType, exercises: exercises)
                        completion(workout)
                        
                    case .failure:
                        completion(nil)
                    }
                }
            }
        }.resume()
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
                
                let sequentialId = ExerciseService.shared.getSequentialId(for: exercise.id)
                let gifUrl = "http://34.59.215.239/api/gifs/\(sequentialId)/"
                
                WebImage(url: URL(string: gifUrl))
                    .resizable()
                    .indicator(.activity)
                    .transition(.fade)
                    .scaledToFit()
                    .cornerRadius(8)
                    .frame(width: 60, height: 60)
                    .onAppear {
                        print("Loading GIF from URL: \(gifUrl) for exercise ID: \(exercise.id), sequential ID: \(sequentialId)")
                    }
            }
            .frame(width: 60, height: 60)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name.capitalized)
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
                    Text("Also works: \(exercise.secondaryMuscles.prefix(3).map { $0.capitalized }.joined(separator: ", "))")
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
                // Anonymous profile icon
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.white)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Anonymous")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("Shared a \(post.workout.type) workout")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                Spacer()
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

                ForEach(post.workout.exercises.indices, id: \.self) { index in
                    let exercise = post.workout.exercises[index]
                    HStack {
                        Circle()
                            .fill(Color.blue.opacity(0.3))
                            .frame(width: 8, height: 8)

                        Text(exercise.name.capitalized)
                            .font(.subheadline)
                            .foregroundColor(.white)

                        Spacer()

                        Text(exercise.target.capitalized)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 2)
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
                    self.exercises = fetchedExercises
                    
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
                
                let sequentialId = ExerciseService.shared.getSequentialId(for: exercise.id)
                let gifUrl = "http://34.59.215.239/api/gifs/\(sequentialId)/"
                
                WebImage(url: URL(string: gifUrl))
                    .resizable()
                    .indicator(.activity)
                    .transition(.fade)
                    .scaledToFit()
                    .cornerRadius(8)
                    .frame(width: 50, height: 50)
                    .onAppear {
                        print("Loading GIF from URL: \(gifUrl) for exercise ID: \(exercise.id), sequential ID: \(sequentialId)")
                    }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name.capitalized)
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
