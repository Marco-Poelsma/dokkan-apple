// BattleViewModel.swift
// ViewModel principal - lógica completa del juego

import Foundation
import SwiftUI

// MARK: - Game Phase
enum GamePhase {
    case idle           // esperando que el jugador ordene unidades
    case resolving      // animando los eventos del turno
    case gameOver(won: Bool)
}

class BattleViewModel: ObservableObject {
    
    // ── Unidades ──────────────────────────────────────────────────────────
    @Published var roster: [TeamUnit] = []   // orden completo (7 units)
    @Published var draggedUnitId: UUID? = nil
    
    // ── Enemigo & HP del equipo ───────────────────────────────────────────
    @Published var enemy: Enemy = Enemy.defaultEnemy()
    @Published var teamHP: Int = 200_000
    let teamMaxHP: Int = 200_000
    
    // ── Turno ─────────────────────────────────────────────────────────────
    @Published var turnNumber: Int = 1
    /// Índice en `roster` de la primera unidad activa (0, 3, 6, 3, 0 ...)
    @Published var activeStartIndex: Int = 0
    
    // ── Ataques enemigos por turno: slot 0-3 ─────────────────────────────
    /// Cuántos ataques llegan antes de la unidad en slot0 del turno actual
    @Published var enemyAttackSlots: [EnemyAttackSlot] = []
    
    // ── Resolución de turno ───────────────────────────────────────────────
    @Published var phase: GamePhase = .idle
    @Published var currentEvents: [BattleEvent] = []
    @Published var currentEventIndex: Int = 0
    @Published var animatingEvent: BattleEvent? = nil
    
    // ── UI feedback ───────────────────────────────────────────────────────
    @Published var showEnemyHit: Bool = false
    @Published var showTeamHit: Bool = false
    @Published var hitUnitId: UUID? = nil
    @Published var lastEventText: String = ""
    @Published var teamShake: Bool = false
    @Published var enemyShake: Bool = false
    
    // ── Drag ──────────────────────────────────────────────────────────────
    private let screenWidth = UIScreen.main.bounds.width
    
    // MARK: - Init
    init() {
        roster = UnitFactory.makeTeam().shuffled()
        generateEnemyAttacks()
    }
    
    // MARK: - Active units (3 visible dragueable)
    var activeUnits: [TeamUnit] {
        let indices = activeSlotIndices
        return indices.map { roster[$0] }
    }
    
    var activeSlotIndices: [Int] {
        (0..<3).map { (activeStartIndex + $0) % roster.count }
    }
    
    // Unidades que no están activas (visibles en cola, poco saturadas)
    var queueUnits: [(unit: TeamUnit, index: Int)] {
        let active = Set(activeSlotIndices)
        return roster.enumerated()
            .filter { !active.contains($0.offset) }
            .map { (unit: $0.element, index: $0.offset) }
    }
    
    // MARK: - Generate enemy attacks for this turn
    private func generateEnemyAttacks() {
        enemyAttackSlots = []
        // Between 1 and 3 attacks, spread randomly across slots 0-3
        let attackCount = Int.random(in: 1...3)
        var slots = (0...3).map { $0 }
        slots.shuffle()
        enemyAttackSlots = Array(slots.prefix(attackCount)).sorted()
    }
    
    // MARK: - Advance turn rotation
    private func advanceTurn() {
        // Pattern: 0 → 3 → 6(→0) → 3 → 0 → ...
        // Since team = 7: slots are [0,1,2], [3,4,5], [6,0,1], [3,4,5] ...
        activeStartIndex = (activeStartIndex + 3) % roster.count
        turnNumber += 1
        for unit in roster { unit.newTurn() }
        generateEnemyAttacks()
    }
    
    // MARK: - Start Turn (resolve battle events)
    func startTurn() {
        guard case .idle = phase else { return }
        phase = .resolving
        
        let events = buildTurnEvents()
        currentEvents = events
        currentEventIndex = 0
        
        playNextEvent()
    }
    
    // MARK: - Build all events for this turn
    private func buildTurnEvents() -> [BattleEvent] {
        var events: [BattleEvent] = []
        let units = activeUnits
        
        // Pick which of our attacks is the SA (super attack) – one per turn
        let saSlot = Int.random(in: 0..<3)
        
        // Determine crits per unit
        func isCrit(_ unit: TeamUnit) -> Bool { Double.random(in: 0...1) < unit.critChance }
        func isAA(_ unit: TeamUnit) -> Bool { Double.random(in: 0...1) < unit.aaChance }
        func isDodge(_ unit: TeamUnit) -> Bool { Double.random(in: 0...1) < unit.dodgeChance }
        
        // -- Before slot-0 attack: enemy attacks at slot 0
        appendEnemyEvents(at: 0, targets: units, isDodge: isDodge, into: &events)
        
        for (slotIndex, unit) in units.enumerated() {
            let attackType: AttackType = (slotIndex == saSlot) ? .superAttack : .normal
            let crit = isCrit(unit)
            let dmg = calcUnitDamage(unit, type: attackType, isCrit: crit)
            events.append(BattleEvent(kind: .unitAttacks(unit: unit, damage: dmg, type: attackType, isCrit: crit, dodged: false)))
            
            // SA effect
            if attackType == .superAttack { unit.applySAEffect() }
            
            // AA check
            if isAA(unit) {
                let aaCrit = isCrit(unit)
                let aaDmg = calcUnitDamage(unit, type: .additionalAttack, isCrit: aaCrit)
                events.append(BattleEvent(kind: .unitAttacks(unit: unit, damage: aaDmg, type: .additionalAttack, isCrit: aaCrit, dodged: false)))
            }
            
            // Build by hit: register any hit from this unit
            unit.registerHit()
            
            // Enemy attacks after this slot (slot index+1)
            appendEnemyEvents(at: slotIndex + 1, targets: units, isDodge: isDodge, into: &events)
        }
        
        return events
    }
    
    private func appendEnemyEvents(at slot: Int, targets: [TeamUnit], isDodge: (TeamUnit) -> Bool, into events: inout [BattleEvent]) {
        let attacksHere = enemyAttackSlots.filter { $0 == slot }
        guard !attacksHere.isEmpty else { return }
        
        // Target: first unit in current active rotation (slot 0 = takes most hits)
        let targetIndex = min(slot, targets.count - 1)
        let target = targets[targetIndex]
        
        for _ in attacksHere {
            let dodged = isDodge(target)
            let dmg = dodged ? 0 : enemy.damageToTeam(defender: target)
            events.append(BattleEvent(kind: .enemyAttacks(slot: slot, targetUnit: target, damage: dmg, dodged: dodged)))
        }
    }
    
    private func calcUnitDamage(_ unit: TeamUnit, type: AttackType, isCrit: Bool) -> Int {
        var base = unit.effectiveAtk
        switch type {
        case .superAttack:    base = Int(Double(base) * 3.5)
        case .additionalAttack: base = Int(Double(base) * 0.7)
        case .normal:         base = Int(Double(base) * 1.5)
        }
        if isCrit { base = Int(Double(base) * 1.5) }
        // Subtract part of enemy defense
        base = max(1000, base - enemy.atk / 8)
        return base
    }
    
    // MARK: - Animate events one by one
    private func playNextEvent() {
        // Verificar si el juego ya terminó antes de procesar más eventos
        if case .gameOver = phase {
            return
        }
        
        guard currentEventIndex < currentEvents.count else {
            // All events done – apply totals and end turn
            finalizeTurn()
            return
        }
        
        let event = currentEvents[currentEventIndex]
        animatingEvent = event
        lastEventText = event.description
        
        applyEvent(event)
        
        // Verificar si el juego terminó después de aplicar el evento
        if case .gameOver = phase {
            // Si el juego terminó, no procesar más eventos
            animatingEvent = nil
            return
        }
        
        // Duration depends on event type
        let delay: Double = {
            switch event.kind {
            case .unitAttacks(_, _, let t, _, _):
                return t == .superAttack ? 1.0 : 0.6
            case .enemyAttacks:
                return 0.7
            }
        }()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }
            // Verificar nuevamente si el juego terminó antes de continuar
            if case .gameOver = self.phase {
                self.animatingEvent = nil
                return
            }
            self.currentEventIndex += 1
            self.animatingEvent = nil
            self.playNextEvent()
        }
    }
    
    private func applyEvent(_ event: BattleEvent) {
        switch event.kind {
        case .unitAttacks(_, let dmg, _, _, let dodged):
            if !dodged {
                enemy.receiveDamage(dmg)
                triggerEnemyHit()
            }
        case .enemyAttacks(_, let target, let dmg, let dodged):
            if !dodged {
                teamHP = max(0, teamHP - dmg)
                triggerTeamHit(unitId: target.id)
            }
        }
        
        // Verificar game over después de cada evento
        checkGameOver()
    }
    
    private func triggerEnemyHit() {
        showEnemyHit = true
        enemyShake = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.showEnemyHit = false
            self.enemyShake = false
        }
    }
    
    private func triggerTeamHit(unitId: UUID) {
        showTeamHit = true
        hitUnitId = unitId
        teamShake = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.showTeamHit = false
            self.hitUnitId = nil
            self.teamShake = false
        }
    }
    
    private func checkGameOver() {
        if enemy.isDead {
            phase = .gameOver(won: true)
        } else if teamHP <= 0 {
            phase = .gameOver(won: false)
        }
    }
    
    private func finalizeTurn() {
        // Solo avanzar turno si el juego no ha terminado
        if case .resolving = phase, !enemy.isDead && teamHP > 0 {
            phase = .idle
            advanceTurn()
        }
    }
    
    // MARK: - Restart
    func restart() {
        roster = UnitFactory.makeTeam().shuffled()
        enemy = Enemy.defaultEnemy()
        teamHP = teamMaxHP
        turnNumber = 1
        activeStartIndex = 0
        phase = .idle
        currentEvents = []
        currentEventIndex = 0
        animatingEvent = nil
        lastEventText = ""
        generateEnemyAttacks()
    }
    
    // MARK: - Drag logic
    func startDragging(unitId: UUID) {
        guard case .idle = phase else { return }
        draggedUnitId = unitId
        if let unit = getUnit(by: unitId) { unit.startDrag() }
        objectWillChange.send()
    }
    
    func updateDraggedUnit(translation: CGSize) {
        guard let id = draggedUnitId, let unit = getUnit(by: id),
              case .idle = phase else { return }
        unit.updateDrag(offset: translation.width)
        objectWillChange.send()
    }
    
    func endDragging() {
        guard let id = draggedUnitId, let unit = getUnit(by: id) else { return }
        
        // Calcular la posición final
        let finalX = slotXFor(unit) + unit.dragOffset
        let positions = [UnitPosition.left, .center, .right]
        var bestSlotIndex = 1
        var minDistance = CGFloat.greatestFiniteMagnitude
        
        for (i, pos) in positions.enumerated() {
            let posX = pos.xPosition(in: screenWidth)
            let distance = abs(finalX - posX)
            if distance < minDistance {
                minDistance = distance
                bestSlotIndex = i
            }
        }
        
        // Si cambió de slot, reordenar con animación
        let currentSlotIndex = activeSlotIndices.firstIndex(where: { roster[$0].id == unit.id }) ?? 1
        if currentSlotIndex != bestSlotIndex {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                let targetUnit = activeUnits[bestSlotIndex]
                swapUnits(unit, targetUnit)
            }
        }
        
        unit.endDrag()
        draggedUnitId = nil
        objectWillChange.send()
    }
    
    private func swapUnits(_ a: TeamUnit, _ b: TeamUnit) {
        guard let ai = activeSlotIndices.firstIndex(where: { roster[$0].id == a.id }),
              let bi = activeSlotIndices.firstIndex(where: { roster[$0].id == b.id }) else { return }
        let ri = activeSlotIndices[ai]
        let rj = activeSlotIndices[bi]
        roster.swapAt(ri, rj)
        
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
    
    private func slotXFor(_ unit: TeamUnit) -> CGFloat {
        let positions = [UnitPosition.left, .center, .right]
        let slotIdx = activeSlotIndices.firstIndex(where: { roster[$0].id == unit.id }) ?? 1
        return positions[min(slotIdx, 2)].xPosition(in: screenWidth)
    }
    
    func getVisualX(for unit: TeamUnit) -> CGFloat {
        let positions = [UnitPosition.left, .center, .right]
        guard let slotIdx = activeSlotIndices.firstIndex(where: { roster[$0].id == unit.id }) else {
            return screenWidth / 2
        }
        let base = positions[min(slotIdx, 2)].xPosition(in: screenWidth)
        
        // Solo la unidad arrastrada tiene offset
        if unit.isBeingDragged {
            return base + unit.dragOffset
        }
        return base
    }
    
    private func getUnit(by id: UUID) -> TeamUnit? {
        roster.first { $0.id == id }
    }
    
    // MARK: - Enemy attack display helpers
    func enemyAttackCount(atSlot slot: Int) -> Int {
        enemyAttackSlots.filter { $0 == slot }.count
    }
}
