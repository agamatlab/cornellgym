import SwiftUI

struct ContentView: View {
    @State private var selectedMuscle: String? = nil
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    // Left panel - Muscle selection list
                    MuscleSelectionWithPreviewView()
                        .frame(width: max(geometry.size.width * 0.22, 220))
                    
                    // Main view - 3D model instead of placeholder
                    ZStack {
                        // Enhanced gradient background
                        LinearGradient(
                            gradient: Gradient(colors: [
                                themeManager.current.background1,
                                themeManager.current.background2,
                                themeManager.current.background3
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        
                        // Radial accent gradient
                        RadialGradient(
                            gradient: Gradient(colors: [
                                themeManager.current.surface1.opacity(0.6),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 5,
                            endRadius: geometry.size.width * 0.6
                        )
                        
                        // The 3D human model view
                        HumanModelView(selectedMuscle: $selectedMuscle)
                            .opacity(0.8) // Allow some of the background to show through
                        
                        // Selection information overlay
                        if let muscle = selectedMuscle {
                            VStack(spacing: 30) {
                                Text("Selected Muscle Group")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(themeManager.current.accent2)
                                
                                Text(muscle)
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(themeManager.current.textPrimary)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        themeManager.current.surface1,
                                                        themeManager.current.surface2
                                                    ]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .shadow(color: Color.black.opacity(0.3), radius: 10)
                                    )
                            }
                            .offset(y: -geometry.size.height * 0.2)
                        } else {
                            VStack(spacing: 30) {
                                Image(systemName: "person.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: min(geometry.size.width * 0.15, 120), height: min(geometry.size.width * 0.15, 120))
                                    .foregroundColor(themeManager.current.accent2.opacity(0.6))
                                
                                Text("Select a muscle group to highlight")
                                    .font(.system(size: 20, weight: .medium, design: .rounded))
                                    .foregroundColor(themeManager.current.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                            }
                            .padding(30)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                themeManager.current.background1.opacity(0.7),
                                                themeManager.current.surface1.opacity(0.7)
                                            ]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .shadow(color: Color.black.opacity(0.2), radius: 15)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                themeManager.current.accent1.opacity(0.3),
                                                themeManager.current.highlight.opacity(0.3)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                        }
                    }
                    .frame(width: geometry.size.width * 0.55)
                    
                    // Right panel - Detail view (only shows when muscle is selected)
                    if let muscle = selectedMuscle {
                        EnhancedMuscleDetailView(muscleName: muscle)
                            .frame(width: max(geometry.size.width * 0.23, 240))
                    } else {
                        Spacer() // Maintain layout when no muscle is selected
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Human Anatomy Explorer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        selectedMuscle = nil
                    } label: {
                        Text("Reset")
                            .fontWeight(.medium)
                            .foregroundColor(themeManager.current.accent1)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(themeManager.current.surface2)
                            )
                    }
                }
            }
            .preferredColorScheme(.dark)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .edgesIgnoringSafeArea(.all)
    }
}

// Enhanced Muscle Detail View
struct EnhancedMuscleDetailView: View {
    let muscleName: String
    @EnvironmentObject var themeManager: ThemeManager
    
    func getDescription() -> String {
        switch muscleName {
        case "Biceps brachii":
            return "The biceps brachii is a large muscle located on the front of the upper arm. It has two heads and functions primarily to flex the elbow and supinate the forearm."
        case "Quadriceps":
            return "The quadriceps femoris is a group of four muscles located in the front of the thigh. They work together to extend the knee and flex the hip."
        case "Deltoid":
            return "The deltoid muscle is a rounded, triangular muscle located on the uppermost part of the arm and the top of the shoulder. It's responsible for arm abduction, extension, and flexion."
        case "Pectoralis major":
            return "The pectoralis major is a thick, fan-shaped muscle located at the chest. It's responsible for movement of the shoulder joint, including flexion, adduction, and rotation of the humerus."
        default:
            return "This muscle is part of the human musculoskeletal system. Select different muscles to learn more about their function and anatomy."
        }
    }
    
    func getFunctions() -> [String] {
        switch muscleName {
        case "Biceps brachii":
            return ["Flexes the elbow joint", "Supinates the forearm", "Stabilizes the shoulder joint"]
        case "Quadriceps":
            return ["Extends the knee", "Stabilizes the patella", "Flexes the hip (rectus femoris)"]
        case "Deltoid":
            return ["Abducts the arm", "Helps with arm flexion", "Aids in arm extension", "Stabilizes the shoulder"]
        case "Pectoralis major":
            return ["Adducts the arm", "Rotates the arm medially", "Flexes the shoulder joint"]
        default:
            return ["Movement", "Stability", "Posture"]
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                // Title with gradient background
                VStack(alignment: .leading, spacing: 8) {
                    Text("Muscle Information")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(themeManager.current.accent1)
                    
                    Text(muscleName)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.current.textPrimary)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            themeManager.current.surface1,
                            themeManager.current.surface2
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                
                // Description
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(themeManager.current.success)
                        
                        Text("Description")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(themeManager.current.success)
                    }
                    
                    Text(getDescription())
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(themeManager.current.textSecondary)
                        .lineSpacing(6)
                        .padding(.top, 4)
                }
                .padding(20)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            themeManager.current.background1,
                            themeManager.current.surface1
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(12)
                
                // Functions
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(themeManager.current.warning)
                        
                        Text("Functions")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(themeManager.current.warning)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(getFunctions(), id: \.self) { function in
                            HStack(alignment: .top, spacing: 12) {
                                Circle()
                                    .fill(themeManager.current.highlight)
                                    .frame(width: 8, height: 8)
                                    .padding(.top, 6)
                                
                                Text(function)
                                    .font(.system(size: 16, design: .rounded))
                                    .foregroundColor(themeManager.current.textSecondary)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(20)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            themeManager.current.background1,
                            themeManager.current.surface1
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(12)
                
                Spacer(minLength: 20)
            }
            .padding(16)
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
        )
    }
}
