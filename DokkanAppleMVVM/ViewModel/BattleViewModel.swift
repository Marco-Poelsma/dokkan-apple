// BattleViewModel.swift
// ViewModel principal - lógica completa del juego con efectos de sonido y BGM

import Foundation
import SwiftUI
import AVFoundation

// MARK: - Game Phase
enum GamePhase {
    case idle           // esperando que el jugador ordene unidades
    case resolving      // animando los eventos del turno
    case gameOver(won: Bool)
}

class BattleViewModel: ObservableObject {
    
    // MARK: Unidades
    @Published var roster: [TeamUnit] = []   // orden completo (7 units)
    @Published var draggedUnitId: UUID? = nil
    
    // MARK: Enemigo & HP del equipo
    @Published var enemy: Enemy = Enemy.defaultEnemy()
    @Published var teamHP: Int = 200_000
    let teamMaxHP: Int = 200_000
    
    // MARK: Fase del enemigo (wave)
    @Published var currentWave: Int = 1
    @Published var highestWave: Int {
        didSet {
            UserDefaults.standard.set(highestWave, forKey: "highestWave")
        }
    }
    
    // MARK: Turno
    @Published var turnNumber: Int = 1
    @Published var activeStartIndex: Int = 0
    
    // MARK: Ataques enemigos por turno: slot 0-3
    @Published var enemyAttackSlots: [EnemyAttackSlot] = []
    
    // MARK: Resolución de turno
    @Published var phase: GamePhase = .idle
    @Published var currentEvents: [BattleEvent] = []
    @Published var currentEventIndex: Int = 0
    @Published var animatingEvent: BattleEvent? = nil
    
    // MARK: UI feedback
    @Published var showEnemyHit: Bool = false
    @Published var showTeamHit: Bool = false
    @Published var hitUnitId: UUID? = nil
    @Published var lastEventText: String = ""
    @Published var teamShake: Bool = false
    @Published var enemyShake: Bool = false
    @Published var showWaveTransition: Bool = false
    @Published var waveTransitionText: String = ""
    
    // MARK: Drag
    private let screenWidth = UIScreen.main.bounds.width
    
    // MARK: Sound Manager
    private let soundManager = SoundManager.shared
    
    // MARK: Init
    init() {
        let savedWave = UserDefaults.standard.integer(forKey: "highestWave")
        highestWave = savedWave > 0 ? savedWave : 1
        roster = UnitFactory.makeTeam().shuffled()
        generateEnemyAttacks()
        
        // Pre-cargar sonidos para evitar delay
        soundManager.preloadSounds()
        
        // Iniciar música de fondo (BGM)
        soundManager.playBGM()
    }
    
    // MARK: Active units
    var activeUnits: [TeamUnit] {
        let indices = activeSlotIndices
        return indices.map { roster[$0] }
    }
    
    var activeSlotIndices: [Int] {
        (0..<3).map { (activeStartIndex + $0) % roster.count }
    }
    
    var queueUnits: [(unit: TeamUnit, index: Int)] {
        let active = Set(activeSlotIndices)
        return roster.enumerated()
            .filter { !active.contains($0.offset) }
            .map { (unit: $0.element, index: $0.offset) }
    }
    
    // MARK: Generate enemy attacks
    private func generateEnemyAttacks() {
        enemyAttackSlots = []
        let attackCount = Int.random(in: 1...3)
        var slots = (0...3).map { $0 }
        slots.shuffle()
        enemyAttackSlots = Array(slots.prefix(attackCount)).sorted()
    }
    
    // MARK: Advance turn
    private func advanceTurn() {
        activeStartIndex = (activeStartIndex + 3) % roster.count
        turnNumber += 1
        for unit in roster { unit.newTurn() }
        generateEnemyAttacks()
    }
    
    // MARK: Start Turn
    func startTurn() {
        guard case .idle = phase else { return }
        phase = .resolving
        
        let events = buildTurnEvents()
        currentEvents = events
        currentEventIndex = 0
        
        playNextEvent()
    }
    
    // MARK: Build events
    private func buildTurnEvents() -> [BattleEvent] {
        var events: [BattleEvent] = []
        let units = activeUnits
        let saSlot = Int.random(in: 0..<3)
        
        func isCrit(_ unit: TeamUnit) -> Bool { Double.random(in: 0...1) < unit.critChance }
        func isAA(_ unit: TeamUnit) -> Bool { Double.random(in: 0...1) < unit.aaChance }
        func isDodge(_ unit: TeamUnit) -> Bool { Double.random(in: 0...1) < unit.dodgeChance }
        
        appendEnemyEvents(at: 0, targets: units, isDodge: isDodge, into: &events)
        
        for (slotIndex, unit) in units.enumerated() {
            let attackType: AttackType = (slotIndex == saSlot) ? .superAttack : .normal
            let crit = isCrit(unit)
            let dmg = calcUnitDamage(unit, type: attackType, isCrit: crit)
            events.append(BattleEvent(kind: .unitAttacks(unit: unit, damage: dmg, type: attackType, isCrit: crit, dodged: false)))
            
            if attackType == .superAttack { unit.applySAEffect() }
            
            if isAA(unit) {
                let aaCrit = isCrit(unit)
                let aaDmg = calcUnitDamage(unit, type: .additionalAttack, isCrit: aaCrit)
                events.append(BattleEvent(kind: .unitAttacks(unit: unit, damage: aaDmg, type: .additionalAttack, isCrit: aaCrit, dodged: false)))
            }
            
            unit.registerHit()
            appendEnemyEvents(at: slotIndex + 1, targets: units, isDodge: isDodge, into: &events)
        }
        
        return events
    }
    
    private func appendEnemyEvents(at slot: Int, targets: [TeamUnit], isDodge: (TeamUnit) -> Bool, into events: inout [BattleEvent]) {
        let attacksHere = enemyAttackSlots.filter { $0 == slot }
        guard !attacksHere.isEmpty else { return }
        
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
        base = max(1000, base - enemy.atk / 8)
        return base
    }
    
    // MARK: Animate events
    private func playNextEvent() {
        if case .gameOver = phase { return }
        
        guard currentEventIndex < currentEvents.count else {
            finalizeTurn()
            return
        }
        
        let event = currentEvents[currentEventIndex]
        animatingEvent = event
        lastEventText = event.description
        
        applyEvent(event)
        
        if case .gameOver = phase {
            animatingEvent = nil
            return
        }
        
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
            if case .gameOver = self.phase {
                self.animatingEvent = nil
                return
            }
            self.currentEventIndex += 1
            self.animatingEvent = nil
            self.playNextEvent()
        }
    }
    
    // MARK: Apply Event with Sounds
    private func applyEvent(_ event: BattleEvent) {
        switch event.kind {
        case .unitAttacks(let unit, let dmg, let type, let isCrit, let dodged):
            if !dodged {
                enemy.receiveDamage(dmg)
                triggerEnemyHit()
                
                // Reproducir sonido según tipo de ataque
                switch type {
                case .normal:
                    soundManager.playSound(named: "uhit", volume: 0.7)
                case .superAttack:
                    soundManager.playSound(named: "sa", volume: 1.0)
                case .additionalAttack:
                    soundManager.playSound(named: "uhit", volume: 0.5)
                }
                
                // Sonido de crítico
                if isCrit {
                    soundManager.playSound(named: "uhit", volume: 0.8)
                }
            } else {
                // Sonido de esquivar
                soundManager.playSound(named: "dodge", volume: 80.0)
            }
            
        case .enemyAttacks(_, let target, let dmg, let dodged):
            if !dodged {
                teamHP = max(0, teamHP - dmg)
                triggerTeamHit(unitId: target.id)
                soundManager.playSound(named: "ehit", volume: 0.8)
            } else {
                soundManager.playSound(named: "dodge", volume: 80.0)
            }
        }
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
            spawnNextEnemy()
        } else if teamHP <= 0 {
            phase = .gameOver(won: false)
            soundManager.playSound(named: "death", volume: 1.0)
            
            // Opcional: Bajar volumen del BGM o pausarlo en Game Over
            soundManager.setBGMVolume(0.2)
        }
    }
    
    // MARK: Spawn next enemy
    private func spawnNextEnemy() {
        currentWave += 1
        
        // Sonido de nueva wave
        soundManager.playSound(named: "lvlup", volume: 0.9)
        
        if currentWave > highestWave {
            highestWave = currentWave
        }
        
        waveTransitionText = "WAVE \(currentWave)"
        showWaveTransition = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.showWaveTransition = false
        }
        
        let multiplier = pow(1.5, Double(currentWave - 1))
        let baseEnemy = Enemy.defaultEnemy()
        
        // Crear nuevo enemigo con estadísticas aumentadas
        let newEnemy = Enemy(
            name: "Wave \(currentWave) Boss",
            atk: Int(Double(baseEnemy.atk) * multiplier),
            color: getWaveColor(wave: currentWave)
        )
        
        // Ajustar HP manualmente porque el init no tiene maxHp
        newEnemy.remainingHP = Int(Double(baseEnemy.totalHP) * multiplier)
        
        teamHP = teamMaxHP
        turnNumber = 1
        activeStartIndex = 0
        
        // Resetear unidades (resetear buffs)
        for unit in roster {
            unit.permAtkBoost = 0
            unit.tempAtkBoost = 0
            unit.permDefBoost = 0
            unit.tempDefBoost = 0
            unit.hitCount = 0
        }
        
        enemy = newEnemy
        generateEnemyAttacks()
        
        // Restaurar volumen del BGM si estaba bajo
        soundManager.setBGMVolume(0.5)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            if case .resolving = self.phase {
                self.finalizeTurn()
            }
        }
    }
    
    private func getWaveColor(wave: Int) -> Color {
        let colors: [Color] = [
            Color(red: 0.6, green: 0.0, blue: 0.6),  // Fase 1 - Púrpura
            Color.red,                                 // Fase 2 - Rojo
            Color.orange,                              // Fase 3 - Naranja
            Color.yellow,                              // Fase 4 - Amarillo
            Color.green,                               // Fase 5 - Verde
            Color.blue,                                // Fase 6 - Azul
            Color(red: 0.29, green: 0.0, blue: 0.51),  // Fase 7 - Índigo
            Color.pink,                                // Fase 8 - Rosa
            Color.black,                               // Fase 9 - Marrón
            Color(red: 0.1, green: 0.1, blue: 0.1)     // Fase 10+ - Negro
        ]
        let index = min(wave - 1, colors.count - 1)
        return colors[index]
    }
    
    private func finalizeTurn() {
        if case .resolving = phase, teamHP > 0 {
            phase = .idle
            advanceTurn()
        }
    }
    
    // MARK: Restart
    func restart() {
        // Asegurar que BGM continúa sonando al reiniciar
        soundManager.setBGMVolume(0.5)
        soundManager.playBGM()
        
        roster = UnitFactory.makeTeam().shuffled()
        enemy = Enemy.defaultEnemy()
        teamHP = teamMaxHP
        currentWave = 1
        turnNumber = 1
        activeStartIndex = 0
        phase = .idle
        currentEvents = []
        currentEventIndex = 0
        animatingEvent = nil
        lastEventText = ""
        showWaveTransition = false
        generateEnemyAttacks()
    }
    
    // MARK: Skip Wave (Developer/Testing)
    func skipCurrentWave() {
        // Solo permitir skip cuando no se está resolviendo un turno
        guard case .idle = phase else { return }
        
        // Sonido de skip (opcional)
        soundManager.playSound(named: "lvlup", volume: 0.7)
        
        // Matar al enemigo instantáneamente
        enemy.remainingHP = 0
        
        // Forzar el spawn del siguiente enemigo
        spawnNextEnemy()
    }
    
    // MARK: Drag logic
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
        
        if unit.isBeingDragged {
            return base + unit.dragOffset
        }
        return base
    }
    
    private func getUnit(by id: UUID) -> TeamUnit? {
        roster.first { $0.id == id }
    }
    
    func enemyAttackCount(atSlot slot: Int) -> Int {
        enemyAttackSlots.filter { $0 == slot }.count
    }
    
    // MARK: BGM Control Methods (Opcional - para control externo)
    func pauseBGM() {
        soundManager.pauseBGM()
    }
    
    func resumeBGM() {
        soundManager.playBGM()
    }
    
    func setBGMVolume(_ volume: Float) {
        soundManager.setBGMVolume(volume)
    }
    
    // MARK: Cleanup (llamar cuando se destruye el ViewModel)
    deinit {
        // No detenemos el BGM para que pueda continuar entre vistas
        // Solo limpiamos si es necesario
        print("BattleViewModel deinit - BGM continúa reproduciéndose")
    }
}
