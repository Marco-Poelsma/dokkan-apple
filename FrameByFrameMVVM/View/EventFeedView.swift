// EventFeedView.swift
// Overlay que muestra el evento de combate actual animado

import SwiftUI

struct EventFeedView: View {
    let event: BattleEvent?
    
    var body: some View {
        Group {
            if let ev = event {
                eventCard(ev)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .opacity
                    ))
                    .id(ev.id)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: event?.id)
    }
    
    private func eventCard(_ ev: BattleEvent) -> some View {
        HStack(spacing: 8) {
            // Icon
            Image(systemName: iconName(ev))
                .font(.system(size: 18, weight: .black))
                .foregroundColor(iconColor(ev))
            
            Text(ev.description)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            // SA glow badge
            if isSA(ev) {
                Text("SA!")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.yellow)
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(cardBackground(ev))
                .shadow(color: shadowColor(ev), radius: 12, x: 0, y: 4)
        )
        .padding(.horizontal, 16)
    }
    
    private func isSA(_ ev: BattleEvent) -> Bool {
        if case .unitAttacks(_, _, let t, _, _) = ev.kind, t == .superAttack { return true }
        return false
    }
    
    private func iconName(_ ev: BattleEvent) -> String {
        switch ev.kind {
        case .unitAttacks(_, _, let t, _, let dodged):
            if dodged { return "xmark.circle.fill" }
            switch t {
            case .superAttack: return "bolt.circle.fill"
            case .additionalAttack: return "plus.circle.fill"
            case .normal: return "sword"
            }
        case .enemyAttacks(_, _, _, let dodged):
            return dodged ? "wind" : "exclamationmark.triangle.fill"
        }
    }
    
    private func iconColor(_ ev: BattleEvent) -> Color {
        switch ev.kind {
        case .unitAttacks(let u, _, let t, _, _):
            return t == .superAttack ? .yellow : u.color
        case .enemyAttacks(_, _, _, let dodged):
            return dodged ? .green : .red
        }
    }
    
    private func cardBackground(_ ev: BattleEvent) -> Color {
        switch ev.kind {
        case .unitAttacks(_, _, let t, _, _):
            return t == .superAttack ? Color(red: 0.18, green: 0.14, blue: 0.05) : Color(red: 0.1, green: 0.12, blue: 0.22)
        case .enemyAttacks(_, _, _, let dodged):
            return dodged ? Color(red: 0.05, green: 0.18, blue: 0.10) : Color(red: 0.22, green: 0.05, blue: 0.05)
        }
    }
    
    private func shadowColor(_ ev: BattleEvent) -> Color {
        switch ev.kind {
        case .unitAttacks(_, _, let t, _, _):
            return t == .superAttack ? Color.yellow.opacity(0.5) : Color.blue.opacity(0.3)
        case .enemyAttacks(_, _, _, let dodged):
            return dodged ? Color.green.opacity(0.3) : Color.red.opacity(0.5)
        }
    }
}

// MARK: - Attack Flash Animation (full screen flash for SA)
struct SAFlashView: View {
    let color: Color
    @State private var opacity: Double = 0.5
    
    var body: some View {
        color
            .ignoresSafeArea()
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 0.4)) { opacity = 0 }
            }
    }
}
