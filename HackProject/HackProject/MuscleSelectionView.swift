import SwiftUI

struct MuscleSelectionWithPreviewView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedMuscle: String? = nil
    @State private var selectedMuscleLayer: Int? = nil
    @State private var searchText = ""
    
    // Constants
    let maxLayers = 24
    let previewSize: CGFloat = 100
    let previewPadding: CGFloat = 20
    
    // Muscle mapping (layer number to muscle name)
    let muscleMapping: [Int: String] = [
        1: "Sternocleidomastoid",
        2: "Trapezius (upper)",
        3: "Deltoid",
        4: "Pectoralis major",
        5: "Biceps brachii",
        6: "Rectus abdominis",
        7: "External oblique",
        8: "Quadriceps",
        9: "Gastrocnemius",
        10: "Triceps brachii",
        11: "Serratus anterior",
        12: "Brachialis",
        13: "Hamstrings",
        14: "Soleus",
        15: "Platysma",
        // Add more mappings as needed
    ]
    
    // Reverse mapping (muscle name to layer number)
    var layerMapping: [String: Int] {
        var result: [String: Int] = [:]
        for (layer, muscle) in muscleMapping {
            result[muscle] = layer
        }
        return result
    }
    
    // Muscle groups categorized
    let muscleGroups = [
        "Head & Neck": ["Sternocleidomastoid", "Trapezius (upper)", "Platysma"],
        "Torso": ["Pectoralis major", "Serratus anterior", "Rectus abdominis", "External oblique"],
        "Arms": ["Biceps brachii", "Triceps brachii", "Deltoid", "Brachialis"],
        "Legs": ["Quadriceps", "Hamstrings", "Gastrocnemius", "Soleus"]
    ]
    
    // Filtered muscle groups based on search
    var filteredMuscleGroups: [String: [String]] {
        if searchText.isEmpty {
            return muscleGroups
        }
        
        var filtered: [String: [String]] = [:]
        for (group, muscles) in muscleGroups {
            let matchingMuscles = muscles.filter { $0.lowercased().contains(searchText.lowercased()) }
            if !matchingMuscles.isEmpty {
                filtered[group] = matchingMuscles
            }
        }
        return filtered
    }
    
    var body: some View {
        ZStack {
            // Main content with search and list
            VStack {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(themeManager.current.textSecondary)
                    TextField("Search muscles...", text: $searchText)
                        .foregroundColor(themeManager.current.textPrimary)
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(themeManager.current.background2)
                )
                .padding(.horizontal)
                .padding(.top)
                
                // Muscle list
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // List muscle groups
                        ForEach(Array(filteredMuscleGroups.keys.sorted()), id: \.self) { group in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(group)
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                                    .foregroundColor(themeManager.current.accent2)
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 8)
                                
                                // List muscles in group
                                ForEach(filteredMuscleGroups[group] ?? [], id: \.self) { muscle in
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            selectedMuscle = muscle
                                            selectedMuscleLayer = layerMapping[muscle]
                                        }
                                    }) {
                                        HStack {
                                            Circle()
                                                .fill(getMuscleColor(for: group))
                                                .frame(width: 8, height: 8)
                                            
                                            Text(muscle)
                                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                                .foregroundColor(selectedMuscle == muscle ?
                                                                themeManager.current.textPrimary :
                                                                themeManager.current.textSecondary)
                                            
                                            Spacer()
                                            
                                            if selectedMuscle == muscle {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(themeManager.current.success)
                                                    .font(.system(size: 16))
                                            }
                                        }
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 16)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(selectedMuscle == muscle ?
                                                      getMuscleColor(for: group).opacity(0.3) :
                                                      Color.clear)
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.bottom, 10)
                        }
                        
                        // Show a message if no muscles match the search
                        if filteredMuscleGroups.isEmpty {
                            VStack {
                                Text("No muscles found matching '\(searchText)'")
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundColor(themeManager.current.textSecondary)
                                    .padding()
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 30)
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 8)
                }
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
            
            // Preview thumbnail in bottom right
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    ZStack {
                        // Background
                        Color.black
                            .frame(width: previewSize, height: previewSize)
                            .cornerRadius(10)
                        
                        // Muscle layers
                        ForEach(1...maxLayers, id: \.self) { layerNum in
                            Image("\(layerNum)")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: previewSize, height: previewSize)
                                .opacity(getOpacityForLayer(layerNum))
                        }
                        
                        // Outline
                        Image("outlines")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: previewSize, height: previewSize)
                            .colorInvert()
                            
                        // Instructions if no selection
                        if selectedMuscleLayer == nil {
                            Text("Select a muscle from the list")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(6)
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(5)
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(themeManager.current.accent1, lineWidth: 2)
                    )
                }
                .padding(previewPadding)
            }
            
            // Selected muscle name overlay for the preview
            if let muscleName = selectedMuscle {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack {
                            Text(muscleName)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(6)
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(5)
                                .padding(.bottom, 4)
                            
                            Spacer()
                                .frame(height: previewSize)
                        }
                        .padding(.trailing, previewPadding)
                    }
                    .padding(.bottom, previewSize + previewPadding)
                }
            }
        }
    }
    
    // Helper function to determine opacity for each muscle layer
    func getOpacityForLayer(_ layer: Int) -> Double {
        if layer == selectedMuscleLayer {
            return 1.0 // Selected muscle is fully visible
        } else if selectedMuscleLayer == nil {
            return 0.1 // When no selection, show all muscles at low opacity
        } else {
            return 0.05 // Non-selected muscles are very faint
        }
    }
    
    // Function to get color based on muscle group
    func getMuscleColor(for group: String) -> Color {
        switch group {
        case "Head & Neck":
            return themeManager.current.error // Red color for head/neck
        case "Torso":
            return themeManager.current.chestColor // Green for torso
        case "Arms":
            return themeManager.current.armsColor // Yellow for arms
        case "Legs":
            return themeManager.current.legsColor // Purple for legs
        default:
            return themeManager.current.accent2 // Default blue
        }
    }
}

struct MuscleSelectionWithPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        MuscleSelectionWithPreviewView()
            .environmentObject(ThemeManager())
    }
}
