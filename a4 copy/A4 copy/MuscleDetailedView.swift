import SwiftUI
import SDWebImageSwiftUI

struct DetailedMuscleView: View {
    let exercise: Exercise
    @State private var loopCount: UInt = 100
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
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
            
            // Content that respects safe areas with EXTRA padding for notch
            ScrollView {
                // Add extra padding at the top to avoid the notch completely
                Color.clear.frame(height: 20)
                
                VStack(alignment: .leading, spacing: 20) {
                    // Back button and title row
                    HStack {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.black.opacity(0.2))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        Text(exercise.name.uppercased())
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Balance the layout with an invisible element of the same size
                        Color.clear.frame(width: 44, height: 44)
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    
                    // GIF area
                    ZStack {
                        Color(red: 0.1, green: 0.1, blue: 0.2)
                            .cornerRadius(12)
                        
                        VStack {
                            let sequentialId = ExerciseService.shared.getSequentialId(for: exercise.id)
                            let gifUrl = "http://34.59.215.239/api/gifs/\(sequentialId)/"
                            
                            AnimatedImage(url: URL(string: gifUrl))
                                .indicator(SDWebImageActivityIndicator.medium)
                                .transition(.fade)
                                .resizable()
                                .customLoopCount(loopCount)
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 200)
                                .cornerRadius(12)
                                .padding()
                        }
                    }
                    .padding(.horizontal)
                    
                    // Exercise details section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Exercise Details")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        HStack(spacing: 20) {
                            DetailItem(icon: "figure.walk", title: "Body Part", value: exercise.bodyPart.capitalized)
                            DetailItem(icon: "dumbbell.fill", title: "Equipment", value: exercise.equipment.capitalized)
                        }
                        
                        HStack(spacing: 20) {
                            DetailItem(icon: "target", title: "Target", value: exercise.target.capitalized)
                        }
                        
                        if !exercise.secondaryMuscles.isEmpty {
                            Text("Secondary Muscles")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.top, 8)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(exercise.secondaryMuscles, id: \.self) { muscle in
                                        Text(muscle.capitalized)
                                            .font(.subheadline)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.blue.opacity(0.3))
                                            .foregroundColor(.white)
                                            .cornerRadius(10)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(red: 0.15, green: 0.15, blue: 0.25).opacity(0.7))
                    )
                    .padding(.horizontal)
                    
                    // Instructions section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Instructions")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        ForEach(0..<exercise.instructions.count, id: \.self) { index in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(index + 1).")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                    .frame(width: 24, alignment: .center)
                                
                                Text(exercise.instructions[index])
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.9))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(red: 0.15, green: 0.15, blue: 0.25).opacity(0.7))
                    )
                    .padding(.horizontal)
                    
                    Spacer(minLength: 40)
                }
                .padding(.bottom)
            }
            // Add safeAreaInset for top to ensure content stays below notch
            .safeAreaInset(edge: .top) {
                Color.clear.frame(height: 1)
            }
        }
        .navigationBarHidden(true)
        .statusBar(hidden: false) // Explicitly show status bar to help with spacing
    }
}

struct DetailItem: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(Color.blue.opacity(0.8))
                    .font(.system(size: 12))
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Text(value)
                .font(.headline)
                .foregroundColor(.white)
        }
        .frame(minWidth: 100, alignment: .leading)
    }
}
