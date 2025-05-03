//
//  AnimatedText.swift
//  A4
//
//  Created by Aghamatlab Akbarzade on 5/2/25.
//

import SwiftUI

struct AnimatedTextView: View {
    let text: String
    @State private var characters: [AnimatedCharacter] = []
    @State private var opacity: Double = 0
    @State private var xOffset: CGFloat = 0 // Start centered
    @State private var yOffset: CGFloat = 0 // Start centered
    @State private var moveToLeft: Bool = false
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(characters) { character in
                Text(character.value)
                    .font(.system(size: 32))
                    .foregroundStyle(character.isAnimating ? .pink : .blue)
                    .fontWeight(character.isAnimating ? .black : .bold)
                    .scaleEffect(character.isAnimating ? 1.2 : 1.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.6), value: character.isAnimating)
            }
        }
        .opacity(opacity)
        .offset(y: yOffset)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.6)) {
                    moveToLeft = true
                    xOffset = -UIScreen.main.bounds.width/2 + 100 // Move to left side with padding
                    yOffset = -200
                }
            }
            
            characters = Array(text).enumerated().map { index, char in
                AnimatedCharacter(id: index, value: String(char))
            }
            
            // Start with fade in
            withAnimation(.easeIn(duration: 0.5)) {
                opacity = 1.0
            }
            
            // Animate each character with a delay
            for (index, _) in characters.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05 * Double(index)) {
                    withAnimation {
                        characters[index].isAnimating = true
                    }
                    
                    // Reset after a delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation {
                            characters[index].isAnimating = false
                        }
                    }
                }
            }
            
            // Set up repeating animation
            setupRepeatingAnimation()
        }
    }
    
    private func setupRepeatingAnimation() {
        // After all characters have animated once, restart the animation
        let totalDuration = Double(text.count) * 0.05 + 1.0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) {
            for (index, _) in characters.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05 * Double(index)) {
                    withAnimation {
                        characters[index].isAnimating = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation {
                            characters[index].isAnimating = false
                        }
                    }
                }
            }
            
            // Continue the animation loop
            setupRepeatingAnimation()
        }
    }
}

struct AnimatedCharacter: Identifiable {
    let id: Int
    let value: String
    var isAnimating = false
}

struct BlurryWelcomeText: View {
    @State private var opacity: Double = 0
    @State private var blurRadius: CGFloat = 20
    @State private var scale: CGFloat = 0.8
    @State private var yOffset: CGFloat = 100
    
    var body: some View {
        Text("WELCOME TO")
            .font(.system(size: 48, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .opacity(opacity)
            .blur(radius: blurRadius)
            .scaleEffect(scale)
            .offset(y: -250)
            .onAppear {
                // First fade in and reduce blur
                withAnimation(.easeOut(duration: 2.0)) {
                    opacity = 0.8
                    blurRadius = 0
                    scale = 1.0
                    yOffset = 50
                }
            }
    }
}
