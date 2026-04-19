// TeamUnitView.swift
// Vista de cada unidad arrastrable en el turno activo

import SwiftUI

struct TeamUnitView: View {
    let unit: TeamUnit
    let slotIndex: Int          // 0, 1, 2
    let isAnimatingEvent: Bool
    let isHit: Bool
    
    @EnvironmentObject var vm: BattleViewModel
    
    var body: some View {
        ZStack {
            // MARK: Card background
            RoundedRectangle(cornerRadius: 14)
                .fill(unit.color.opacity(unit.isBeingDragged ? 1.0 : 0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(unit.isBeingDragged ? Color.white : Color.white.opacity(0.3), lineWidth: unit.isBeingDragged ? 2.5 : 1)
                )
                .shadow(color: unit.color.opacity(0.7), radius: unit.isBeingDragged ? 16 : 6, x: 0, y: 4)
            
            // Hit flash overlay
            if isHit {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.red.opacity(0.6))
                    .transition(.opacity)
            }
            
            // MARK: Content
            VStack(spacing: 3) {
                // Symbol / letter
                Text(unit.symbol)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(Color.white)
                
                // Name
                Text(unit.name)
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.9))
                    .lineLimit(1)
                
                Divider().background(Color.white.opacity(0.3)).padding(.horizontal, 6)
                
                // ATK
                statRow(label: "ATK", value: shortNum(unit.effectiveAtk), color: Color.yellow)
                // DEF
                statRow(label: "DEF", value: shortNum(unit.effectiveDef), color: Color.blue)
                
                // Archetype badge
                Text(unit.archetype.rawValue)
                    .font(.system(size: 7, weight: .bold, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.7))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(4)
                
                // SA effect
                if unit.saEffect != .none {
                    Text(unit.saEffect.rawValue)
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(Color.orange)
                }
            }
            .padding(5)
        }
        .frame(width: 72, height: 110)
        .scaleEffect(unit.isBeingDragged ? 1.08 : (isAnimatingEvent ? 1.04 : 1.0))
        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: unit.isBeingDragged)
        .animation(.easeOut(duration: 0.15), value: isAnimatingEvent)
        .animation(.easeInOut(duration: 0.15), value: isHit)
    }
    
    private func statRow(label: String, value: String, color: Color) -> some View {
        HStack(spacing: 2) {
            Text(label)
                .font(.system(size: 7, weight: .bold))
                .foregroundColor(color.opacity(0.8))
            Spacer()
            Text(value)
                .font(.system(size: 8, weight: .black, design: .monospaced))
                .foregroundColor(Color.white)
        }
        .padding(.horizontal, 5)
    }
    
    private func shortNum(_ n: Int) -> String {
        if n >= 1_000_000 { return String(format: "%.1fM", Double(n) / 1_000_000) }
        if n >= 1_000    { return String(format: "%.0fK", Double(n) / 1_000) }
        return "\(n)"
    }
}
