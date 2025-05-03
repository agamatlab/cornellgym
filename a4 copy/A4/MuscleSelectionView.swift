import SwiftUI
import SDWebImageSwiftUI

struct MuscleSelectionWithPreviewView: View {
    @State private var exercises: [Exercise] = []
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    
    @State private var searchText = ""
    @State private var selectedBodyPart: String? = nil
    @State private var selectedEquipment: String? = nil
    @State private var selectedTarget: String? = nil
    @State private var showFilters = false
    
    @State private var selectedExercise: Exercise? = nil
    @State private var showExerciseDetail = false
    
    private var bodyParts: [String] {
        return Array(Set(exercises.map { $0.bodyPart })).sorted()
    }
    
    private var equipmentTypes: [String] {
        return Array(Set(exercises.map { $0.equipment })).sorted()
    }
    
    private var targetMuscles: [String] {
        return Array(Set(exercises.map { $0.target })).sorted()
    }
    
    private var filteredExercises: [Exercise] {
        exercises.filter { exercise in
            let matchesSearch = searchText.isEmpty ||
                exercise.name.localizedCaseInsensitiveContains(searchText)
            
            let matchesBodyPart = selectedBodyPart == nil ||
                exercise.bodyPart == selectedBodyPart
            
            let matchesEquipment = selectedEquipment == nil ||
                exercise.equipment == selectedEquipment
            
            let matchesTarget = selectedTarget == nil ||
                exercise.target == selectedTarget
            
            return matchesSearch && matchesBodyPart && matchesEquipment && matchesTarget
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background that ignores safe areas
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.1),
                        Color(red: 0.1, green: 0.1, blue: 0.2)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
                
                // Content that respects safe areas with extra padding for notch
                VStack(spacing: 0) {
                    // Add extra padding at the top
                    Color.clear.frame(height: 20)
                    
                    // Title now in a container with background for better visibility
                    Text("Exercise Library")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.vertical, 15)
                        .frame(maxWidth: .infinity)
                        .background(Color.black.opacity(0.2))
                    
                    HStack(spacing: 6) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                                .font(.system(size: 14))
                                .padding(.leading, 6)
                            
                            TextField("Search exercises", text: $searchText)
                                .foregroundColor(.white)
                                .font(.system(size: 14))
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                            
                            if !searchText.isEmpty {
                                Button(action: {
                                    searchText = ""
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 14))
                                }
                                .padding(.trailing, 6)
                            }
                        }
                        .padding(.vertical, 8)
                        .background(Color(red: 0.1, green: 0.1, blue: 0.18).opacity(0.6))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        
                        Button(action: {
                            withAnimation {
                                showFilters.toggle()
                            }
                        }) {
                            Image(systemName: showFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                                .foregroundColor(showFilters ? Color.blue.opacity(0.8) : .white)
                                .font(.system(size: 18))
                                .frame(width: 36, height: 36)
                                .background(Color(red: 0.1, green: 0.1, blue: 0.18).opacity(0.6))
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    
                    if showFilters {
                        VStack(spacing: 12) {
                            FilterSection(
                                title: "Body Part",
                                icon: "figure.walk",
                                options: bodyParts,
                                selectedOption: $selectedBodyPart
                            )
                            
                            Divider()
                                .background(Color.gray.opacity(0.3))
                                .padding(.horizontal)
                            
                            FilterSection(
                                title: "Equipment",
                                icon: "dumbbell.fill",
                                options: equipmentTypes,
                                selectedOption: $selectedEquipment
                            )
                            
                            Divider()
                                .background(Color.gray.opacity(0.3))
                                .padding(.horizontal)
                            
                            FilterSection(
                                title: "Target Muscle",
                                icon: "target",
                                options: targetMuscles,
                                selectedOption: $selectedTarget
                            )
                            
                            Button(action: {
                                withAnimation {
                                    selectedBodyPart = nil
                                    selectedEquipment = nil
                                    selectedTarget = nil
                                    searchText = ""
                                }
                            }) {
                                HStack {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.system(size: 12))
                                    Text("Reset All Filters")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.blue.opacity(0.7),
                                            Color.purple.opacity(0.7)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(10)
                            }
                            .padding(.top, 4)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 8)
                        .background(Color(red: 0.1, green: 0.1, blue: 0.18).opacity(0.8))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 3)
                        .padding(.horizontal, 12)
                        .padding(.top, 8)
                    }
                    
                    if isLoading {
                        Spacer()
                        VStack(spacing: 12) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color.blue.opacity(0.8)))
                            Text("Loading exercises...")
                                .foregroundColor(.white)
                                .font(.headline)
                        }
                        .padding()
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
                        .padding()
                        Spacer()
                    } else if filteredExercises.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 50))
                                .foregroundColor(.gray.opacity(0.7))
                                .padding()
                            
                            Text(exercises.isEmpty ? "No exercises found" : "No exercises match your filters")
                                .foregroundColor(.gray)
                                .font(.headline)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            if !exercises.isEmpty {
                                Button(action: {
                                    withAnimation {
                                        selectedBodyPart = nil
                                        selectedEquipment = nil
                                        selectedTarget = nil
                                        searchText = ""
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.counterclockwise")
                                        Text("Clear Filters")
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color.blue.opacity(0.7))
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                                .padding(.top, 8)
                            }
                        }
                        Spacer()
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green.opacity(0.8))
                                .font(.system(size: 14))
                            
                            Text("\(filteredExercises.count) exercises found")
                                .foregroundColor(.gray.opacity(0.9))
                                .font(.subheadline)
                                .padding(.bottom,5)
                            
                            Spacer()
                            
                            if selectedBodyPart != nil || selectedEquipment != nil || selectedTarget != nil || !searchText.isEmpty {
                                Text("Filtered")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.2))
                                    .foregroundColor(.blue.opacity(0.8))
                                    .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 12)
                        
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVStack(spacing: 16) {
                                ForEach(filteredExercises, id: \.id) { exercise in
                                    ExerciseCard(exercise: exercise)
                                        .frame(width: UIScreen.main.bounds.width - 24)
                                        .onTapGesture {
                                            selectedExercise = exercise
                                            showExerciseDetail = true
                                        }
                                }
                            }
                            .padding(.vertical, 16)
                        }
                    }
                }
                .safeAreaInset(edge: .top) {
                    // Extra safe area inset for the notch
                    Color.clear.frame(height: 1)
                }
                .safeAreaInset(edge: .bottom) {
                    // Bottom padding for safe area
                    Color.clear.frame(height: 1)
                }
                
                // Navigation link for detail view
                NavigationLink(
                    destination: selectedExercise.map { DetailedMuscleView(exercise: $0) },
                    isActive: $showExerciseDetail,
                    label: { EmptyView() }
                )
                .hidden()
            }
            .navigationBarHidden(true)
            .statusBar(hidden: false) // Explicitly show status bar to help with spacing
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            loadExercises()
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
                    if fetchedExercises.isEmpty {
                        self.errorMessage = "No exercises found on the server."
                    } else {
                        var updatedExercises = fetchedExercises
                        
                        for index in 0..<updatedExercises.count {
                            print(index)
                            updatedExercises[index].id = String(index + 1)
                        }
                        
                        self.exercises = updatedExercises
                    }
                case .failure(let error):
                    self.errorMessage = "Failed to load exercises: \(error.localizedDescription)"
                }
            }
        }
    }
}

struct ExerciseCard: View {
    let exercise: Exercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(exercise.name.uppercased())
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            HStack(alignment: .top, spacing: 16) {
                let sequentialId = ExerciseService.shared.getSequentialId(for: exercise.id)
                let gifUrl = "http://34.59.215.239/api/gifs/\(sequentialId)/"

                AnimatedImage(url: URL(string: gifUrl))
                    .indicator(SDWebImageActivityIndicator.medium)
                    .transition(.fade)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "target")
                            .foregroundColor(Color.purple.opacity(0.9))
                            .font(.system(size: 14))
                        Text(exercise.target.capitalized)
                            .font(.subheadline)
                            .foregroundColor(Color.white)
                    }
                    
                    HStack(spacing: 6) {
                        Image(systemName: "figure.walk")
                            .foregroundColor(Color.cyan.opacity(0.9))
                            .font(.system(size: 14))
                        Text(exercise.bodyPart.capitalized)
                            .font(.subheadline)
                            .foregroundColor(Color.white)
                    }
                    
                    HStack(spacing: 6) {
                        Image(systemName: "dumbbell.fill")
                            .foregroundColor(Color.orange.opacity(0.9))
                            .font(.system(size: 14))
                        Text(exercise.equipment.capitalized)
                            .font(.subheadline)
                            .foregroundColor(Color.white)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.trailing, 8)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.15, green: 0.15, blue: 0.25).opacity(0.9),
                    Color(red: 0.1, green: 0.1, blue: 0.18)
                ]),
                center: .bottomLeading,
                startRadius: 100,
                endRadius: 400
            )
        )
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

struct FilterSection: View {
    let title: String
    let icon: String
    let options: [String]
    @Binding var selectedOption: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(Color.blue.opacity(0.8))
                    .font(.system(size: 14))
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 10)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(options, id: \.self) { option in
                        FilterChip(
                            title: option.capitalized,
                            isSelected: selectedOption == option,
                            action: {
                                withAnimation {
                                    if selectedOption == option {
                                        selectedOption = nil
                                    } else {
                                        selectedOption = option
                                    }
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Group {
                        if isSelected {
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        } else {
                            Color(red: 0.17, green: 0.24, blue: 0.31).opacity(0.6)
                        }
                    }
                )
                .foregroundColor(isSelected ? .white : .gray.opacity(0.9))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isSelected ?
                                Color.blue.opacity(0.8) :
                                Color.gray.opacity(0.3),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
