import SwiftUI
import Alamofire
import SDWebImageSwiftUI

extension ShaderFunction {
    static let rippleEffect = ShaderFunction(
        library: .bundle(.main),
        name: "ripple"
    )
}

struct ExerciseView: View {
    @State private var exercise: Exercise
    @Environment(\.colorScheme) var colorScheme
    
    init(exercise: Exercise) {
        _exercise = State(initialValue: exercise)
    }
    
    func updateExercise(with newExercise: Exercise) {
        exercise = newExercise
    }
    
    @State private var time: CGFloat = 0
    
    // Add timer for animation
    let timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    
    @State public var loopCount : UInt = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with exercise name
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
            
            // Main content
            HStack(alignment: .top, spacing: 16) {
                // Get a sequential numeric ID for this exercise
                let sequentialId = ExerciseService.shared.getSequentialId(for: exercise.id)
                let gifUrl = "http://34.59.215.239/api/gifs/\(sequentialId)/"

                // GIF with a subtle border for white backgrounds
                AnimatedImage(url: URL(string: gifUrl))
                    .indicator(SDWebImageActivityIndicator.medium)
                    .transition(.fade)
                    .resizable()
                    .customLoopCount(loopCount)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .background(Color.white) // White background for GIF
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
                    .onAppear {
                        print("AnimatedImage appeared with URL: \(gifUrl) for exercise ID: \(exercise.id), sequential ID: \(sequentialId)")
                    }
                    // Temporarily comment out the ripple effect to see if that's causing issues
                    .basicRippleEffect(time: time)
                    .onReceive(timer) { _ in
                        if loopCount > 0 {
                            withAnimation {
                                time += 0.01
                            }
                        }
                    }
                    .onTapGesture {
                        loopCount = 100
                        time = 0 // Reset time to start ripple from beginning
                    }
                
                // Exercise details
                VStack(alignment: .leading, spacing: 6) {
                    // Target muscle group
                    HStack(spacing: 6) {
                        Image(systemName: "target")
                            .foregroundColor(Color.purple.opacity(0.9))
                            .font(.system(size: 14))
                        Text(exercise.target.capitalized)
                            .font(.subheadline)
                            .foregroundColor(Color.white)
                    }
                    
                    // Body part
                    HStack(spacing: 6) {
                        Image(systemName: "figure.walk")
                            .foregroundColor(Color.cyan.opacity(0.9))
                            .font(.system(size: 14))
                        Text(exercise.bodyPart.capitalized)
                            .font(.subheadline)
                            .foregroundColor(Color.white)
                    }
                    
                    // Equipment
                    HStack(spacing: 6) {
                        Image(systemName: "dumbbell.fill")
                            .foregroundColor(Color.orange.opacity(0.9))
                            .font(.system(size: 14))
                        Text(exercise.equipment.capitalized)
                            .font(.subheadline)
                            .foregroundColor(Color.white)
                    }
                    
                    // Secondary muscles chip view
                    if !exercise.secondaryMuscles.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(exercise.secondaryMuscles, id: \.self) { muscle in
                                    Text(muscle.capitalized)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.3))
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(
            // Radial gradient starting from lower left
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(hex: "2C3E50").opacity(0.9), // Lighter shade
                    Color(hex: "1A1A2E")               // Darker shade
                ]),
                center: .bottomLeading,
                startRadius: 100,
                endRadius: 400
            )
        )
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .onTapGesture {
            loopCount = 100
        }
    }
}

extension View {
    func basicRippleEffect(time: CGFloat) -> some View {
        return self
            .scaleEffect(1.0 + 0.02 * sin(time * 5))
            .animation(.easeInOut(duration: 0.5), value: time)
    }
}

#if DEBUG
struct ExerciseView_Previews: PreviewProvider {
    static let sampleExercise = Exercise(
        id: "1",
        bodyPart: "chest",
        equipment: "barbell",
        gifUrl: "https://example.com/bench-press.gif",
        name: "Barbell Bench Press",
        target: "pectorals",
        secondaryMuscles: ["triceps", "shoulders", "core"],
        instructions: [
            "Lie on a flat bench with your feet firmly on the ground.",
            "Grip the barbell slightly wider than shoulder-width.",
            "Lower the barbell to your mid-chest.",
            "Press the barbell back up to the starting position.",
            "Repeat for desired reps."
        ]
    )
    
    static var previews: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .edgesIgnoringSafeArea(.all)
            
            ExerciseView(exercise: sampleExercise)
        }
        .preferredColorScheme(.dark)
    }
}
#endif
