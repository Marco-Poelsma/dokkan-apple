// HPBarView.swift
// Barras de vida - del equipo (una sola barra) y del enemigo (10 barras)

import SwiftUI

// MARK: - Team HP bar
struct TeamHPBarView: View {
    let current: Int
    let max: Int
    let shake: Bool
    
    var fraction: Double { max > 0 ? Double(current) / Double(max) : 0 }
    
    var barColor: Color {
        switch fraction {
        case 0.5...: return Color(red: 0.2, green: 0.85, blue: 0.35)
        case 0.25..<0.5: return Color(red: 0.95, green: 0.75, blue: 0.1)
        default: return Color(red: 0.95, green: 0.25, blue: 0.25)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text("TEAM HP")
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.7))
                Spacer()
                Text("\(current) / \(max)")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.white.opacity(0.8))
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.white.opacity(0.12))
                    
                    RoundedRectangle(cornerRadius: 5)
                        .fill(barColor)
                        .frame(width: geo.size.width * CGFloat(fraction))
                        .animation(.easeOut(duration: 0.4))
                }
            }
            .frame(height: 12)
        }
        .offset(x: shake ? CGFloat.random(in: -4...4) : 0)
        .animation(shake ? Animation.easeInOut(duration: 0.05).repeatCount(5, autoreverses: true) : .default)
    }
}

// MARK: - Enemy HP bars (10 discrete bars)
struct EnemyHPBarsView: View {
    @ObservedObject var enemy: Enemy
    let shake: Bool
    let flashHit: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(enemy.name.uppercased())
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundColor(enemy.color)
                Spacer()
                Text("\(enemy.remainingHP) HP")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.white.opacity(0.7))
            }
            
            HStack(spacing: 3) {
                // CORREGIDO: Mostrar las barras en orden inverso (de derecha a izquierda)
                ForEach(Array((0..<enemy.totalBars)), id: \.self) { barIdx in
                    EnemyBarSegment(
                        barIndex: barIdx,
                        currentBars: enemy.currentBars,
                        totalBars: enemy.totalBars,
                        currentBarFraction: enemy.currentBarHP,
                        enemyColor: enemy.color,
                        flashHit: flashHit
                    )
                }
            }
        }
        .offset(x: shake ? CGFloat.random(in: -3...3) : 0)
        .animation(shake ? Animation.easeInOut(duration: 0.04).repeatCount(6, autoreverses: true) : .default)
    }
}

struct EnemyBarSegment: View {
    let barIndex: Int
    let currentBars: Int
    let totalBars: Int
    let currentBarFraction: Double
    let enemyColor: Color
    let flashHit: Bool
    
    // Ahora el índice 0 es la barra más a la derecha (la primera en vaciarse)
    var barNumber: Int { barIndex }  // 0 = derecha, 9 = izquierda
    
    var state: BarState {
        // Las barras se vacían desde la derecha (índice 0 es la primera)
        if barNumber >= currentBars {
            return .empty
        }
        if barNumber == currentBars - 1 {
            return .partial
        }
        return .full
    }
    
    enum BarState { case full, partial, empty }
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.10))
                
                switch state {
                case .full:
                    RoundedRectangle(cornerRadius: 3)
                        .fill(enemyColor)
                        .overlay(flashHit ? RoundedRectangle(cornerRadius: 3).fill(Color.white.opacity(0.5)) : nil)
                case .partial:
                    RoundedRectangle(cornerRadius: 3)
                        .fill(enemyColor)
                        .frame(width: geo.size.width * CGFloat(currentBarFraction))
                        .animation(.easeOut(duration: 0.35))
                        .overlay(flashHit ? RoundedRectangle(cornerRadius: 3).fill(Color.white.opacity(0.5)) : nil)
                case .empty:
                    EmptyView()
                }
            }
        }
        .frame(height: 14)
        .animation(.easeOut(duration: 0.3))
    }
}
