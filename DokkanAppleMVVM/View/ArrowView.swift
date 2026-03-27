// ArrowView.swift
import SwiftUI

struct ArrowView: View {
    enum Direction {
        case left, right
    }
    
    let direction: Direction
    @State private var isAnimating = false
    
    var body: some View {
        Image(systemName: direction == .right ? "arrow.right" : "arrow.left")
            .font(.system(size: 20, weight: .medium))
            .foregroundColor(Color.white.opacity(0.6))
            .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
            .overlay(
                Image(systemName: direction == .right ? "arrow.right" : "arrow.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.3))
                    .offset(x: direction == .right ? 4 : -4)
                    .opacity(isAnimating ? 0.8 : 0.2)
            )
            .onAppear {
                withAnimation(
                    Animation.easeInOut(duration: 0.8)
                        .repeatForever(autoreverses: true)
                ) {
                    isAnimating = true
                }
            }
    }
}
