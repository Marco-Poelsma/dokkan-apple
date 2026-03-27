// AttackSlotIndicatorView.swift
// Muestra visualmente cuántos ataques del enemigo caen en cada slot del turno

import SwiftUI

/// Fila de indicadores de ataque enemigo entre las unidades activas
/// Slots: 0=antes slot1 | 1=entre slot1-2 | 2=entre slot2-3 | 3=tras slot3
struct AttackSlotIndicatorRow: View {
    let screenWidth: CGFloat
    let bottomY: CGFloat          // Y center de las unidades
    @EnvironmentObject var vm: BattleViewModel
    
    // X positions matching unit slots
    var leftX: CGFloat   { screenWidth / 4 }
    var centerX: CGFloat { screenWidth / 2 }
    var rightX: CGFloat  { screenWidth * 3 / 4 }
    
    var body: some View {
        ZStack {
            // Slot 0: before leftmost unit (slightly left of it)
            slotBubble(slot: 0)
                .position(x: leftX - 46, y: bottomY - 64)
            
            // Slot 1: between left and center
            slotBubble(slot: 1)
                .position(x: (leftX + centerX) / 2, y: bottomY - 64)
            
            // Slot 2: between center and right
            slotBubble(slot: 2)
                .position(x: (centerX + rightX) / 2, y: bottomY - 64)
            
            // Slot 3: after rightmost unit
            slotBubble(slot: 3)
                .position(x: rightX + 46, y: bottomY - 64)
        }
    }
    
    @ViewBuilder
    private func slotBubble(slot: Int) -> some View {
        let count = vm.enemyAttackCount(atSlot: slot)
        if count > 0 {
            AttackBubble(count: count, isBig: count > 1)
        } else {
            Color.clear.frame(width: 28, height: 28)
        }
    }
}

struct AttackBubble: View {
    let count: Int
    let isBig: Bool
    @State private var pulse = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(isBig ? Color.red.opacity(0.85) : Color.orange.opacity(0.8))
                .frame(width: isBig ? 32 : 26, height: isBig ? 32 : 26)
                .shadow(color: (isBig ? Color.red : Color.orange).opacity(0.6), radius: pulse ? 10 : 4)
                .scaleEffect(pulse ? 1.08 : 1.0)
                .animation(Animation.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: pulse)
            
            VStack(spacing: 0) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 8, weight: .black))
                    .foregroundColor(.white)
                Text("\(count)")
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            }
        }
        .onAppear { pulse = true }
    }
}
