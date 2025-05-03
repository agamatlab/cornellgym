import SwiftUI
import SceneKit

struct HumanModelView: View {
    @Binding var selectedMuscle: String?
    
    var body: some View {
        SceneView(
            scene: createScene(),
            options: [.allowsCameraControl, .autoenablesDefaultLighting]
        )
        .edgesIgnoringSafeArea(.all)
    }
    
    func createScene() -> SCNScene {
        // Create a basic scene
        let scene = SCNScene()
        
        // Try to load the human anatomy model if available
        if let anatomyModelURL = Bundle.main.url(forResource: "HumanAnatomy", withExtension: "scn", subdirectory: "Models"),
           let anatomyScene = try? SCNScene(url: anatomyModelURL, options: nil) {
            // If the model is found, add it to our scene
            scene.rootNode.addChildNode(anatomyScene.rootNode)
            
            // Update highlighting based on selection
            if let muscleName = selectedMuscle {
                highlightMuscle(named: muscleName, in: scene)
            }
        } else {
            // Add a placeholder if model isn't found
            let boxGeometry = SCNBox(width: 1, height: 2, length: 0.5, chamferRadius: 0)
            let boxNode = SCNNode(geometry: boxGeometry)
            boxNode.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
            scene.rootNode.addChildNode(boxNode)
            
            // Add text to indicate missing model
            let textGeometry = SCNText(string: "Model not found", extrusionDepth: 0.1)
            let textNode = SCNNode(geometry: textGeometry)
            textNode.scale = SCNVector3(0.1, 0.1, 0.1)
            textNode.position = SCNVector3(x: -1, y: 0.5, z: 0.5)
            scene.rootNode.addChildNode(textNode)
        }
        
        return scene
    }
    
    func highlightMuscle(named muscleName: String, in scene: SCNScene) {
        // Reset any previous highlighting
        scene.rootNode.enumerateChildNodes { node, _ in
            if let material = node.geometry?.firstMaterial {
                material.transparency = 1.0
            }
        }
        
        // Find the node corresponding to the muscle and highlight it
        scene.rootNode.enumerateChildNodes { node, _ in
            if node.name == muscleName || node.name?.contains(muscleName) == true {
                if let material = node.geometry?.firstMaterial {
                    // Create a highlighted appearance
                    material.diffuse.contents = UIColor.red
                    
                    // Optional: Make other muscles semi-transparent
                    scene.rootNode.enumerateChildNodes { otherNode, _ in
                        if otherNode != node, otherNode.name != nil, let otherMaterial = otherNode.geometry?.firstMaterial {
                            otherMaterial.transparency = 0.3
                        }
                    }
                }
            }
        }
    }
}
