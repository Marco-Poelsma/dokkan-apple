// BattleView.swift
// Vista principal de batalla - reemplaza ContentView

import SwiftUI

struct BattleView: View {
    @EnvironmentObject var vm: BattleViewModel
    
    let screenWidth  = UIScreen.main.bounds.width
    let screenHeight = UIScreen.main.bounds.height
    let unitBottomOffset: CGFloat = 160   // Y center de las unidades activas
    
    var unitBottomY: CGFloat { screenHeight - unitBottomOffset }
    
    // Which active slot index (0-2) is being animated
    var animatingSlotIndex: Int? {
        guard let ev = vm.animatingEvent else { return nil }
        if case .unitAttacks(let u, _, _, _, _) = ev.kind {
            return vm.activeSlotIndices.firstIndex(where: { vm.roster[$0].id == u.id })
        }
        return nil
    }
    
    var isSAFlashing: Bool {
        guard let ev = vm.animatingEvent else { return false }
        if case .unitAttacks(_, _, let t, _, _) = ev.kind { return t == .superAttack }
        return false
    }
    
    var body: some View {
        ZStack {
            // ── Background ────────────────────────────────────────────────
            backgroundGradient
            
            // ── SA flash ─────────────────────────────────────────────────
            if isSAFlashing {
                SAFlashView(color: Color.yellow)
                    .allowsHitTesting(false)
            }
            
            // ── Main layout ───────────────────────────────────────────────
            VStack(spacing: 0) {
                // Enemy section (top ~30%)
                enemySection
                    .padding(.top, 50)
                    .padding(.horizontal, 14)
                
                Spacer()
                
                // Event feed (middle)
                EventFeedView(event: vm.animatingEvent)
                    .frame(maxWidth: .infinity)
                
                Spacer()
                
                // Queue units row
                queueRow
                    .padding(.horizontal, 10)
                    .padding(.bottom, 8)
                
                // Team HP
                teamHPSection
                    .padding(.horizontal, 14)
                    .padding(.bottom, 12)
            }
            
            // ── Active units (drag layer) ─────────────────────────────────
            activeUnitsLayer
            
            // ── Attack slot indicators ────────────────────────────────────
            AttackSlotIndicatorRow(
                screenWidth: screenWidth,
                bottomY: unitBottomY
            )
            .environmentObject(vm)
            .allowsHitTesting(false)
            
            // ── Start Turn button ─────────────────────────────────────────
            if case .idle = vm.phase {
                startTurnButton
            }
            
            // ── Last event label (small, below units) ─────────────────────
            if !vm.lastEventText.isEmpty, case .resolving = vm.phase {
                VStack { Spacer()
                    Text(vm.lastEventText)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.6))
                        .padding(.bottom, unitBottomOffset - 20)
                }
                .allowsHitTesting(false)
            }
            
            // ── Game Over overlay ─────────────────────────────────────────
            if case .gameOver(let won) = vm.phase {
                gameOverOverlay(won: won)
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Background
    var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.04, green: 0.05, blue: 0.15),
                Color(red: 0.07, green: 0.09, blue: 0.22),
                Color(red: 0.04, green: 0.05, blue: 0.15)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Enemy section
    var enemySection: some View {
        VStack(spacing: 8) {
            // Turn counter
            HStack {
                Text("TURN \(vm.turnNumber)")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.5))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(6)
                Spacer()
            }
            
            // Enemy HP bars
            EnemyHPBarsView(
                enemy: vm.enemy,
                shake: vm.enemyShake,
                flashHit: vm.showEnemyHit
            )
            
            // Enemy sprite placeholder
            ZStack {
                Ellipse()
                    .fill(vm.enemy.color.opacity(0.18))
                    .frame(width: 110, height: 40)
                    .offset(y: 28)
                
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [vm.enemy.color.opacity(0.9), vm.enemy.color.opacity(0.6)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 90, height: 90)
                    .overlay(
                        Text(vm.enemy.name.prefix(1))
                            .font(.system(size: 44, weight: .black, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.9))
                    )
                    .shadow(color: vm.enemy.color.opacity(0.6), radius: vm.showEnemyHit ? 20 : 8)
                    .scaleEffect(vm.enemyShake ? 0.93 : 1.0)
                    .animation(.spring(response: 0.15, dampingFraction: 0.4), value: vm.enemyShake)
                
                // Hit flash
                if vm.showEnemyHit {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.7))
                        .frame(width: 90, height: 90)
                        .transition(.opacity)
                }
            }
            .frame(height: 110)
        }
    }
    
    // MARK: - Active units drag layer
    var activeUnitsLayer: some View {
        ZStack {
            ForEach(Array(vm.activeUnits.enumerated()), id: \.element.id) { (slotIdx, unit) in
                let isAnimating = animatingSlotIndex == slotIdx
                let isHit = vm.hitUnitId == unit.id
                
                TeamUnitView(
                    unit: unit,
                    slotIndex: slotIdx,
                    isAnimatingEvent: isAnimating,
                    isHit: isHit
                )
                .environmentObject(vm)
                .position(x: vm.getVisualX(for: unit), y: unitBottomY)
                .gesture(
                    DragGesture()
                        .onChanged { val in
                            if vm.draggedUnitId == nil {
                                vm.startDragging(unitId: unit.id)
                            }
                            vm.updateDraggedUnit(translation: val.translation)
                        }
                        .onEnded { _ in vm.endDragging() }
                )
                // Animación simple para TODAS las unidades
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: vm.getVisualX(for: unit))
                .zIndex(vm.draggedUnitId == unit.id ? 10 : Double(slotIdx))
            }
        }
    }
    
    // MARK: - Queue row
    var queueRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                // Show queue in roster order
                let queue = vm.queueUnits
                ForEach(queue, id: \.unit.id) { item in
                    VStack(spacing: 2) {
                        Text("#\(item.index + 1)")
                            .font(.system(size: 7, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.white.opacity(0.3))
                        QueueUnitView(unit: item.unit, queuePosition: item.index)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .background(Color.white.opacity(0.04))
        .cornerRadius(10)
    }
    
    // MARK: - Team HP section
    var teamHPSection: some View {
        TeamHPBarView(
            current: vm.teamHP,
            max: vm.teamMaxHP,
            shake: vm.teamShake
        )
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(Color.white.opacity(0.06))
        .cornerRadius(12)
    }
    
    // MARK: - Start Turn button
    var startTurnButton: some View {
        VStack {
            Spacer()
            Spacer()
            
            Button(action: { vm.startTurn() }) {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 14, weight: .black))
                    Text("START TURN")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .kerning(1.2)
                }
                .foregroundColor(Color.black)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.yellow, Color(red: 1.0, green: 0.7, blue: 0.1)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(color: Color.yellow.opacity(0.5), radius: 12, x: 0, y: 4)
            }
            .padding(.bottom, unitBottomOffset + 100)
        }
        .allowsHitTesting(true)
    }
    
    // MARK: - Game Over overlay
    func gameOverOverlay(won: Bool) -> some View {
        ZStack {
            Color.black.opacity(0.75).ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text(won ? "🏆 VICTORY!" : "💀 GAME OVER")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundColor(won ? Color.yellow : Color.red)
                
                Text(won ? "Enemy defeated!" : "Your team was wiped out!")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.8))
                
                Button(action: { vm.restart() }) {
                    Text("PLAY AGAIN")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(Color.black)
                        .padding(.horizontal, 36)
                        .padding(.vertical, 16)
                        .background(Capsule().fill(won ? Color.yellow : Color.red))
                        .shadow(color: (won ? Color.yellow : Color.red).opacity(0.5), radius: 12)
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(red: 0.06, green: 0.07, blue: 0.18))
            )
            .padding(30)
        }
    }
}
