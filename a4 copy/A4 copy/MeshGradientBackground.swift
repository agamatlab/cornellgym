//
//  Untitled.swift
//  A4
//
//  Created by Aghamatlab Akbarzade on 5/2/25.
//

// MeshGradientBackground.swift
import SwiftUI

struct MeshGradientBackground: View {
    @State private var animation1 = false
    @State private var animation2 = false
    @State private var animation3 = false
    @State private var animation4 = false
    @State private var animation5 = false
    
    // Color palette
    let deepBlue = Color(red: 0.02, green: 0.04, blue: 0.18)
    let midnightPurple = Color(red: 0.09, green: 0.04, blue: 0.25)
    let deepTeal = Color(red: 0.04, green: 0.15, blue: 0.25)
    let spaceBlue = Color(red: 0.03, green: 0.07, blue: 0.22)
    let cosmicPurple = Color(red: 0.15, green: 0.06, blue: 0.35)
    let azureAccent = Color(red: 0.08, green: 0.27, blue: 0.45)
    
    var body: some View {
        ZStack {
            // Base background color
            Color.black.edgesIgnoringSafeArea(.all)
            
            // Main dynamic mesh gradient
            MeshGradient(
                width: 5, // Increased grid density for smoother transitions
                height: 5,
                points: [
                    // Row 1 - more complex point animations
                    [0.0, 0.0],
                    [0.25, animation1 ? 0.07 : 0.0],
                    [0.5, animation2 ? 0.05 : -0.05],
                    [0.75, animation3 ? 0.03 : 0.08],
                    [1.0, 0.0],
                    
                    // Row 2
                    [animation2 ? 0.03 : -0.02, 0.25],
                    [animation4 ? 0.3 : 0.2, animation1 ? 0.3 : 0.2],
                    [animation3 ? 0.45 : 0.55, animation5 ? 0.2 : 0.3],
                    [animation1 ? 0.7 : 0.8, animation4 ? 0.3 : 0.2],
                    [animation5 ? 0.97 : 1.02, 0.25],
                    
                    // Row 3 - more dramatic movement
                    [animation3 ? -0.05 : 0.05, 0.5],
                    [animation5 ? 0.25 : 0.35, animation2 ? 0.55 : 0.45],
                    [animation1 ? 0.55 : 0.45, animation3 ? 0.45 : 0.55],
                    [animation2 ? 0.75 : 0.65, animation4 ? 0.55 : 0.45],
                    [animation4 ? 1.05 : 0.95, 0.5],
                    
                    // Row 4
                    [animation5 ? 0.05 : -0.05, 0.75],
                    [animation1 ? 0.2 : 0.3, animation3 ? 0.8 : 0.7],
                    [animation4 ? 0.45 : 0.55, animation2 ? 0.7 : 0.8],
                    [animation3 ? 0.8 : 0.7, animation5 ? 0.8 : 0.7],
                    [animation2 ? 0.95 : 1.05, 0.75],
                    
                    // Row 5
                    [0.0, 1.0],
                    [0.25, animation2 ? 0.93 : 1.03],
                    [0.5, animation4 ? 0.97 : 1.03],
                    [0.75, animation1 ? 0.95 : 1.05],
                    [1.0, 1.0]
                ],
                colors: [
                    // More sophisticated color arrangement with subtle transitions
                    deepBlue, spaceBlue, spaceBlue, spaceBlue, midnightPurple,
                    deepBlue, animation1 ? azureAccent.opacity(0.8) : deepTeal, deepTeal, animation3 ? cosmicPurple.opacity(0.8) : deepTeal, midnightPurple,
                    spaceBlue, animation5 ? azureAccent.opacity(0.7) : deepTeal, animation2 ? azureAccent.opacity(0.6) : deepTeal, animation4 ? cosmicPurple.opacity(0.7) : deepTeal, spaceBlue,
                    deepTeal, animation2 ? cosmicPurple.opacity(0.6) : deepTeal, animation3 ? azureAccent.opacity(0.5) : deepTeal, animation1 ? cosmicPurple.opacity(0.6) : deepTeal, midnightPurple,
                    deepTeal, spaceBlue, midnightPurple, midnightPurple, deepBlue
                ]
            )
            .opacity(0.9)
            .blur(radius: 40) // Increased blur for smoother transitions
            .rotationEffect(Angle(degrees: animation5 ? 2 : -2)) // Subtle rotation
            .scaleEffect(animation1 ? 1.05 : 1.0) // Subtle breathing effect
            
            // Enhanced overlay elements
            ZStack {
                // Primary glow
                Circle()
                    .fill(azureAccent.opacity(0.2))
                    .frame(width: 400, height: 400)
                    .offset(x: animation3 ? -100 : 100, y: animation4 ? 80 : -80)
                    .blur(radius: 90)
                
                // Secondary glow
                Circle()
                    .fill(cosmicPurple.opacity(0.15))
                    .frame(width: 500, height: 500)
                    .offset(x: animation1 ? 120 : -120, y: animation5 ? -100 : 100)
                    .blur(radius: 100)
                
                // Moving highlight
                Ellipse()
                    .fill(azureAccent.opacity(0.12))
                    .frame(width: 300, height: 200)
                    .rotationEffect(Angle(degrees: animation2 ? 45 : -45))
                    .offset(x: animation4 ? -80 : 80, y: animation1 ? 30 : -30)
                    .blur(radius: 70)
                
                // Accent highlight
                Ellipse()
                    .fill(cosmicPurple.opacity(0.1))
                    .frame(width: 250, height: 350)
                    .rotationEffect(Angle(degrees: animation5 ? -30 : 30))
                    .offset(x: animation3 ? 90 : -90, y: animation2 ? -50 : 50)
                    .blur(radius: 80)
                
                // Small focal point that moves more dramatically
                Circle()
                    .fill(azureAccent.opacity(0.3))
                    .frame(width: 120, height: 120)
                    .offset(x: animation1 ? 150 : -150, y: animation3 ? -180 : 180)
                    .blur(radius: 40)
                    .opacity(animation4 ? 0.7 : 0.4) // Pulsing effect
            }
        }
        .onAppear {
            // More varied animation timings and curves for increased dynamism
            withAnimation(.easeInOut(duration: 13).repeatForever(autoreverses: true)) {
                animation1.toggle()
            }
            
            withAnimation(.easeInOut(duration: 17).repeatForever(autoreverses: true)) {
                animation2.toggle()
            }
            
            withAnimation(.easeInOut(duration: 19).repeatForever(autoreverses: true)) {
                animation3.toggle()
            }
            
            // Add subtle spring animations for more organic movement
            withAnimation(.spring(response: 20, dampingFraction: 0.7).repeatForever(autoreverses: true)) {
                animation4.toggle()
            }
            
            withAnimation(.spring(response: 23, dampingFraction: 0.7).repeatForever(autoreverses: true)) {
                animation5.toggle()
            }
        }
    }
}
