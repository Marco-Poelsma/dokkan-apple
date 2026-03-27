// QueueUnitView.swift
// Vista pequeña y desaturada de las unidades en cola (no activas)

import SwiftUI

struct QueueUnitView: View {
    let unit: TeamUnit
    let queuePosition: Int   // visual order in the queue row
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(unit.color.opacity(0.35))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                )
            
            VStack(spacing: 2) {
                Text(unit.symbol)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.65))
                
                Text(unit.name)
                    .font(.system(size: 7, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.5))
                    .lineLimit(1)
                
                Text(unit.archetype.rawValue)
                    .font(.system(size: 6, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.4))
                    .lineLimit(1)
            }
            .padding(4)
        }
        .frame(width: 50, height: 60)
        .saturation(0.4)
    }
}
