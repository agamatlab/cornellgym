import SwiftUI

// Updated model to match API response
struct MealRecommendation: Codable {
    let recommendations: String
}

// UserDefaults extension for storing user preferences
extension UserDefaults {
    private enum Keys {
        static let selectedGoal = "selectedGoal"
    }
    
    var selectedGoal: String? {
        get {
            return string(forKey: Keys.selectedGoal)
        }
        set {
            setValue(newValue, forKey: Keys.selectedGoal)
        }
    }
}

class APIService: ObservableObject {
    @Published var isLoading = false
    @Published var recommendations: String?
    @Published var error: Error?
    
    func fetchMealRecommendations(goal: String) {
        isLoading = true
        
        // Fixed URL format with proper double slash after http:
        guard let url = URL(string: "http://34.59.215.239/api/dining/top-meals/") else {
            isLoading = false
            error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            return
        }
        
        let requestBody = ["goal": goal]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            isLoading = false
            error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to create request body"])
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Use the actual session token from UserDefaults
        if let sessionToken = UserDefaults.standard.string(forKey: "sessionToken") {
            request.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")
        } else {
            print("Warning: No session token found in UserDefaults")
            // Proceed without token, or handle as needed
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                // Print HTTP response status for debugging
                if let httpResponse = response as? HTTPURLResponse {
                    print("HTTP Status: \(httpResponse.statusCode)")
                    
                    // Check for unauthorized status
                    if httpResponse.statusCode == 401 {
                        self?.error = NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "Unauthorized: Please log in again"])
                        return
                    }
                }
                
                if let error = error {
                    print("Network Error: \(error.localizedDescription)")
                    self?.error = error
                    return
                }
                
                guard let data = data else {
                    print("No data received from server")
                    self?.error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])
                    return
                }
                
                // Print raw response for debugging
                print("Raw response: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
                
                do {
                    let decodedResponse = try JSONDecoder().decode(MealRecommendation.self, from: data)
                    self?.recommendations = decodedResponse.recommendations
                    
                    // Remember the successful response
                    UserDefaults.standard.selectedGoal = goal
                } catch {
                    print("Decoding Error: \(error)")
                    self?.error = error
                }
            }
        }.resume()
    }
}

// MARK: - Improved Markdown Formatting Components

// Helper structure for processed paragraphs
struct ProcessedParagraph: Identifiable {
    let id = UUID()
    let view: AnyView
    
    init<V: View>(view: V) {
        self.view = AnyView(view)
    }
}

// Improved FormattedText view for displaying markdown-formatted content
struct FormattedText: View {
    let text: String
    @State private var displayedText = ""
    @State private var timer: Timer?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            ForEach(processedParagraphs, id: \.id) { paragraph in
                paragraph.view
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            startTypewriterEffect()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func startTypewriterEffect() {
        displayedText = ""
        let characters = Array(text)
        var currentIndex = 0
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.015, repeats: true) { timer in
            if currentIndex < characters.count {
                displayedText.append(characters[currentIndex])
                currentIndex += 1
            } else {
                timer.invalidate()
            }
        }
    }
    
    private var processedParagraphs: [ProcessedParagraph] {
        let lines = displayedText.components(separatedBy: "\n")
        var result: [ProcessedParagraph] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }
            
            // Create the appropriate text view based on line format
            let view = createTextView(for: trimmed)
            result.append(ProcessedParagraph(view: view))
        }
        
        return result
    }
    
    @ViewBuilder
    private func createTextView(for line: String) -> some View {
        if line.hasPrefix("# ") {
            // Header 1
            Text(line.replacingOccurrences(of: "# ", with: "").replacingOccurrences(of: "\\*\\*(.+?)\\*\\*", with: "$1", options: .regularExpression))
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .padding(.top, 8)
        } else if line.hasPrefix("## ") {
            // Header 2
            Text(line.replacingOccurrences(of: "## ", with: "").replacingOccurrences(of: "\\*\\*(.+?)\\*\\*", with: "$1", options: .regularExpression))
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
        } else if line.hasPrefix("### ") {
            // Header 3
            Text(line.replacingOccurrences(of: "### ", with: "").replacingOccurrences(of: "\\*\\*(.+?)\\*\\*", with: "$1", options: .regularExpression))
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
        } else if line.hasPrefix("- ") || line.hasPrefix("* ") {
            // Bullet point
            HStack(alignment: .top, spacing: 8) {
                Text("•")
                    .foregroundColor(.green)
                processBoldText(line.replacingOccurrences(of: "^[\\-\\*]\\s+", with: "", options: .regularExpression))
            }
            .padding(.leading, 4)
        } else if line.range(of: "^\\d+\\.\\s+", options: .regularExpression) != nil {
            // Numbered list
            let number = line.range(of: "^\\d+\\.", options: .regularExpression).map { String(line[$0]) } ?? "1."
            let content = line.replacingOccurrences(of: "^\\d+\\.\\s+", with: "", options: .regularExpression)
            
            HStack(alignment: .top, spacing: 8) {
                Text(number)
                    .foregroundColor(.green)
                    .frame(width: 25, alignment: .leading)
                processBoldText(content)
            }
        } else {
            // Regular paragraph
            processBoldText(line)
        }
    }
    

    private func processBoldText(_ text: String) -> Text {
        if text.contains("**") {
            // Process bold text using a simpler approach
            let components = text.components(separatedBy: "**")
            
            var textView = Text("")
            
            for (index, component) in components.enumerated() {
                if component.isEmpty { continue }
                
                if index % 2 == 1 {
                    // Bold text (odd indices)
                    textView = textView + Text(component).bold()
                } else {
                    // Regular text (even indices)
                    textView = textView + Text(component)
                }
            }
            
            return textView.foregroundColor(.white)
        } else {
            return Text(text).foregroundColor(.white)
        }
    }
}

// MARK: - UI Components

struct AnimatedGradientBackground: View {
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.0, green: 0.7, blue: 1.0),
                            Color(red: 0.5, green: 0.2, blue: 0.8),
                            Color(red: 0.8, green: 0.1, blue: 0.4),
                            Color(red: 0.0, green: 0.7, blue: 1.0)
                        ]),
                        center: .center
                    )
                )
                .frame(width: 200, height: 200)
                .rotationEffect(Angle(degrees: rotation))
                .blur(radius: 20)
            
            Circle()
                .stroke(Color.white.opacity(0.5), lineWidth: 2)
                .frame(width: 130, height: 130)
            
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                .frame(width: 170, height: 170)
            
            Image(systemName: "figure.run")
                .font(.system(size: 50))
                .foregroundColor(.white)
        }
        .onAppear {
            withAnimation(Animation.linear(duration: 10).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

struct GoalSelectionButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .black : .white)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(isSelected ? .black : .white)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.green : Color(white: 0.2))
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(isSelected ? Color.green : Color(white: 0.4), lineWidth: 1)
            )
        }
    }
}

// MARK: - Main View

struct EateryView: View {
    @StateObject private var apiService = APIService()
    @State private var selectedGoal = ""
    @State private var isSubmitted = false
    
    // Options for meal goals
    let goalOptions = [
        (title: "Cutting", icon: "flame.fill"),
        (title: "Bulking", icon: "dumbbell.fill")
    ]
    
    // Format text for display with appropriate headers
    private func formatResponseText(_ text: String, goal: String) -> String {
        // Add appropriate header based on goal
        let header = goal.lowercased() == "cutting" ?
            "# 🔥 Cutting Meal Plan\n\n" :
            "# 💪 Bulking Meal Plan\n\n"
        
        // Format the recommendations
        var formattedText = header + text
        
        // Enhance formatting - add bold to nutritional terms
        formattedText = formattedText.replacingOccurrences(
            of: "(protein|carbs|carbohydrates|fats|calories)",
            with: "**$1**",
            options: [.regularExpression, .caseInsensitive]
        )
        
        return formattedText
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .edgesIgnoringSafeArea(.all)
            
            // Content
            ScrollView {
                VStack(spacing: 25) {
                    VStack {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 40))
                            .foregroundColor(.green)
                        
                        Text("GYM MEAL PLANNER")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .kerning(2)
                    }
                    .padding(.top, 20)
                    
                    if !isSubmitted {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("SELECT YOUR GOAL")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.gray)
                                .kerning(1.5)
                            
                            VStack(spacing: 15) {
                                ForEach(goalOptions, id: \.title) { option in
                                    GoalSelectionButton(
                                        title: option.title,
                                        icon: option.icon,
                                        isSelected: selectedGoal == option.title.lowercased()
                                    ) {
                                        selectedGoal = option.title.lowercased()
                                    }
                                }
                            }
                            
                            Button(action: {
                                if !selectedGoal.isEmpty {
                                    isSubmitted = true
                                    apiService.fetchMealRecommendations(goal: selectedGoal)
                                }
                            }) {
                                HStack {
                                    Image(systemName: "arrow.right.circle.fill")
                                    Text("GET MEAL PLAN")
                                }
                                .font(.headline)
                                .foregroundColor(.black)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(selectedGoal.isEmpty ? Color.gray : Color.green)
                                .cornerRadius(15)
                            }
                            .disabled(selectedGoal.isEmpty)
                        }
                        .padding(25)
                        .background(Color(white: 0.1))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(white: 0.3), lineWidth: 1)
                        )
                        .padding(.horizontal)
                    } else {
                        if apiService.isLoading {
                            VStack(spacing: 25) {
                                AnimatedGradientBackground()
                                
                                Text("Finding optimal meals...")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.top, 20)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(30)
                        } else if let recommendations = apiService.recommendations {
                            VStack(alignment: .leading, spacing: 20) {
                                HStack {
                                    Image(systemName: selectedGoal == "cutting" ? "flame.fill" : "dumbbell.fill")
                                        .foregroundColor(.green)
                                    
                                    Text(selectedGoal.uppercased())
                                        .font(.headline)
                                        .foregroundColor(.green)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                                .padding(.bottom, 5)
                                
                                Divider()
                                    .background(Color(white: 0.3))
                                
                                ScrollView {
                                    // Use the improved FormattedText component
                                    FormattedText(text: formatResponseText(recommendations, goal: selectedGoal))
                                        .padding(.vertical, 10)
                                }
                                
                                Button(action: {
                                    isSubmitted = false
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.counterclockwise")
                                        Text("NEW SELECTION")
                                    }
                                    .font(.headline)
                                    .foregroundColor(.black)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.green)
                                    .cornerRadius(15)
                                }
                                .padding(.top, 5)
                            }
                            .padding(25)
                            .background(Color(white: 0.1))
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color(white: 0.3), lineWidth: 1)
                            )
                            .padding(.horizontal)
                        } else if let error = apiService.error {
                            VStack(spacing: 20) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.orange)
                                    .padding()
                                
                                Text("Error: \(error.localizedDescription)")
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.orange)
                                
                                Button(action: {
                                    isSubmitted = false
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.counterclockwise")
                                        Text("GO BACK")
                                    }
                                    .font(.headline)
                                    .foregroundColor(.black)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.orange)
                                    .cornerRadius(15)
                                }
                            }
                            .padding(25)
                            .background(Color(white: 0.1))
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.orange.opacity(0.5), lineWidth: 1)
                            )
                            .padding(.horizontal)
                        }
                    }
                    
                    Spacer(minLength: 100) // Extra space for tab bar
                }
                .padding(.top)
            }
        }
        .onAppear {
            // Load saved goal if available
            if let savedGoal = UserDefaults.standard.selectedGoal {
                selectedGoal = savedGoal
            }
        }
    }
}

// Preview
struct EateryView_Previews: PreviewProvider {
    static var previews: some View {
        EateryView()
            .preferredColorScheme(.dark)
    }
}
