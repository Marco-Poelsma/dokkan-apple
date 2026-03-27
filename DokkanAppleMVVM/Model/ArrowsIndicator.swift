// ArrowsIndicator.swift
import SwiftUI

struct ArrowsIndicator: View {
    let screenWidth = UIScreen.main.bounds.width
    let screenHeight = UIScreen.main.bounds.height
    let bottomOffset: CGFloat = 100
    let arrowSize: CGFloat = 30
    
    var body: some View {
        ZStack {
            // Flecha izquierda -> centro
            ArrowView(direction: .right)
                .position(
                    x: (screenWidth / 4 + screenWidth / 2) / 2,
                    y: screenHeight - bottomOffset
                )
            
            // Flecha centro -> derecha
            ArrowView(direction: .right)
                .position(
                    x: (screenWidth / 2 + screenWidth * 3 / 4) / 2,
                    y: screenHeight - bottomOffset
                )
            
            // Flecha derecha -> centro (izquierda)
            ArrowView(direction: .left)
                .position(
                    x: (screenWidth / 2 + screenWidth * 3 / 4) / 2,
                    y: screenHeight - bottomOffset
                )
            
            // Flecha centro -> izquierda
            ArrowView(direction: .left)
                .position(
                    x: (screenWidth / 4 + screenWidth / 2) / 2,
                    y: screenHeight - bottomOffset
                )
        }
    }
}
