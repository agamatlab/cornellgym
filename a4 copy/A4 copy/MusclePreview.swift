import SwiftUI

struct InteractiveMuscleStackView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedMuscle: Int? = nil
    @State private var isShowingDetailView: Bool = false
    @State private var dragLocation: CGPoint = .zero
    @State private var hoveredMuscle: Int? = nil
    @State private var previewFrame: CGRect = .zero
    
    // Constants
    let maxLayers = 24
    let previewSize: CGFloat = 100
    let previewPadding: CGFloat = 20
    let detailViewSize: CGFloat = 600
    
    var body: some View {
        ZStack {
            // Main stack
            ZStack {
                // Background
                Color.black.edgesIgnoringSafeArea(.all)
                
                // Muscle layers
                ForEach(1...maxLayers, id: \.self) { layerNum in
                    Image("\(layerNum)")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 800)
                        .opacity(getOpacityForLayer(layerNum))
                }
                
                // Top layer - outlines
                Image("outlines")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 800)
                    .colorInvert()
            }
            
            // Preview thumbnail in bottom right
            GeometryReader { geometry in
                previewView
                    .frame(width: previewSize, height: previewSize)
                    .position(x: geometry.size.width - previewSize/2 - previewPadding,
                              y: geometry.size.height - previewSize/2 - previewPadding)
                    .onAppear {
                        // Store the preview's frame for accurate hit testing
                        previewFrame = CGRect(
                            x: geometry.size.width - previewSize - previewPadding,
                            y: geometry.size.height - previewSize - previewPadding,
                            width: previewSize,
                            height: previewSize
                        )
                    }
            }
            
            // Detail view overlay (shown during touch)
            if isShowingDetailView {
                detailView
            }
        }
    }
    
    // Preview thumbnail view
    var previewView: some View {
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
                    .opacity(selectedMuscle == layerNum ? 1.0 : 0.1)
            }
            
            // Outline
            Image("outlines")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: previewSize, height: previewSize)
                .colorInvert()
        }
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(themeManager.current.accent1, lineWidth: 2)
        )
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    // Only process if we're within the preview bounds
                    if previewFrame.contains(value.location) {
                        // Show detail view if not already showing
                        if !isShowingDetailView {
                            isShowingDetailView = true
                            
                            // Set initial position to center
                            let screenCenter = CGPoint(
                                x: UIScreen.main.bounds.width / 2,
                                y: UIScreen.main.bounds.height / 2
                            )
                            dragLocation = screenCenter
                        }
                        
                        // Calculate relative position within preview (0-1 range)
                        let relativeX = (value.location.x - previewFrame.minX) / previewFrame.width
                        let relativeY = (value.location.y - previewFrame.minY) / previewFrame.height
                        
                        // Calculate detail view bounds
                        let detailViewCenter = CGPoint(
                            x: UIScreen.main.bounds.width / 2,
                            y: UIScreen.main.bounds.height / 2
                        )
                        let detailViewMinX = detailViewCenter.x - (detailViewSize / 2)
                        let detailViewMinY = detailViewCenter.y - (detailViewSize / 2)
                        
                        // Map to detail view coordinates
                        let mappedX = detailViewMinX + (relativeX * detailViewSize)
                        let mappedY = detailViewMinY + (relativeY * detailViewSize)
                        
                        // Update pointer position
                        dragLocation = CGPoint(x: mappedX, y: mappedY)
                        
                        // Determine hovered muscle based on relative position
                        hoveredMuscle = getMuscleFromRelativePosition(relativeX, relativeY)
                    }
                }
                .onEnded { _ in
                    if hoveredMuscle != nil {
                        selectedMuscle = hoveredMuscle
                        hoveredMuscle = nil
                    }
                    isShowingDetailView = false
                }
        )
    }
    
    // Detail view overlay that appears during touch
    var detailView: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.8)
                .edgesIgnoringSafeArea(.all)
            
            // Larger muscle stack with hover effect
            ZStack {
                // Muscle layers
                ForEach(1...maxLayers, id: \.self) { layerNum in
                    Image("\(layerNum)")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: detailViewSize)
                        .opacity(getDetailOpacityForLayer(layerNum))
                }
                
                // Outlines
                Image("outlines")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: detailViewSize)
                    .colorInvert()
                
                // Pointer indicator
                Circle()
                    .fill(themeManager.current.accent1)
                    .frame(width: 20, height: 20)
                    .position(dragLocation)
            }
            
            // Instruction text
            VStack {
                Spacer()
                
                Text("Move your finger over the preview to highlight different muscles")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                    .padding(.bottom, 20)
            }
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.2), value: isShowingDetailView)
    }
    
    // Helper function to determine opacity for each muscle layer
    func getOpacityForLayer(_ layer: Int) -> Double {
        if selectedMuscle == layer {
            return 1.0 // Selected muscle is fully visible
        } else if selectedMuscle == nil {
            return 0.1 // When no selection, show all muscles at low opacity
        } else {
            return 0.05 // Non-selected muscles are very faint
        }
    }
    
    // Helper function to determine opacity during detail view
    func getDetailOpacityForLayer(_ layer: Int) -> Double {
        if hoveredMuscle == layer {
            return 1.0 // Hovered muscle is fully visible
        } else if selectedMuscle == layer && hoveredMuscle == nil {
            return 0.7 // Currently selected muscle
        } else {
            return 0.05 // Other muscles are very faint
        }
    }
    
    // Determine which muscle is being hovered based on relative position
    func getMuscleFromRelativePosition(_ relativeX: CGFloat, _ relativeY: CGFloat) -> Int? {
        // Upper body region (0-30%)
        if relativeY < 0.3 {
            if relativeY < 0.15 {
                // Head/neck area
                if relativeX < 0.35 {
                    return 1 // Left upper shoulder/neck
                } else if relativeX < 0.65 {
                    return 2 // Neck/head
                } else {
                    return 3 // Right upper shoulder/neck
                }
            } else {
                // Shoulders/upper chest
                if relativeX < 0.25 {
                    return 4 // Left outer shoulder
                } else if relativeX < 0.45 {
                    return 5 // Left inner shoulder/chest
                } else if relativeX < 0.55 {
                    return 6 // Upper chest
                } else if relativeX < 0.75 {
                    return 7 // Right inner shoulder/chest
                } else {
                    return 8 // Right outer shoulder
                }
            }
        }
        // Mid upper body (30-45%)
        else if relativeY < 0.45 {
            if relativeX < 0.3 {
                return 9 // Left upper arm
            } else if relativeX < 0.45 {
                return 10 // Left side chest
            } else if relativeX < 0.55 {
                return 11 // Mid chest
            } else if relativeX < 0.7 {
                return 12 // Right side chest
            } else {
                return 13 // Right upper arm
            }
        }
        // Mid body (45-60%)
        else if relativeY < 0.6 {
            if relativeX < 0.3 {
                return 14 // Left forearm
            } else if relativeX < 0.45 {
                return 15 // Left oblique/ribs
            } else if relativeX < 0.55 {
                return 16 // Abs
            } else if relativeX < 0.7 {
                return 17 // Right oblique/ribs
            } else {
                return 18 // Right forearm
            }
        }
        // Lower body (60-100%)
        else {
            if relativeY < 0.75 {
                // Upper legs/hips
                if relativeX < 0.45 {
                    return 19 // Left hip/upper thigh
                } else {
                    return 20 // Right hip/upper thigh
                }
            } else if relativeY < 0.9 {
                // Mid legs
                if relativeX < 0.45 {
                    return 21 // Left lower thigh/knee
                } else {
                    return 22 // Right lower thigh/knee
                }
            } else {
                // Lower legs
                if relativeX < 0.45 {
                    return 23 // Left calf/ankle
                } else {
                    return 24 // Right calf/ankle
                }
            }
        }
    }
}

struct InteractiveMuscleStackView_Previews: PreviewProvider {
    static var previews: some View {
        InteractiveMuscleStackView()
            .environmentObject(ThemeManager())
    }
}
