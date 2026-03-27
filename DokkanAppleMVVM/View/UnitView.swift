// UnitView.swift
import SwiftUI

struct UnitView: View {
    let unit: Unit
    
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(unit.isBeingDragged ? Color.yellow : Color.orange)
            .frame(width: unit.width, height: unit.height)
            .overlay(
                VStack(spacing: 4) {
                    Text(getUnitSymbol())
                        .foregroundColor(Color.white)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if unit.isBeingDragged {
                        Image(systemName: "arrow.left.and.right")
                            .font(.caption)
                            .foregroundColor(Color.white)
                            .opacity(0.8)
                    }
                }
            )
            .shadow(radius: unit.isBeingDragged ? 10 : 3)
            .scaleEffect(unit.isBeingDragged ? 1.05 : 1.0)
            .animation(.easeOut(duration: 0.2), value: unit.isBeingDragged)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: unit.center)
    }
    
    private func getUnitSymbol() -> String {
        switch unit.positionType {
        case .left:
            return "◀︎"
        case .center:
            return "⬤"
        case .right:
            return "▶︎"
        }
    }
}
