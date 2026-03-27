// BattleEvent.swift
// Modelos para los eventos de combate de un turno

import Foundation

// MARK: - Attack Slot (cuando llega el ataque enemigo)
// 0 = antes del slot1, 1 = tras slot1, 2 = tras slot2, 3 = tras slot3
typealias EnemyAttackSlot = Int

// MARK: - Attack Type
enum AttackType {
    case normal
    case superAttack   // the one big hit per turn
    case additionalAttack
}

// MARK: - Single combat event
struct BattleEvent: Identifiable {
    let id = UUID()
    let kind: EventKind
    
    enum EventKind {
        case unitAttacks(unit: TeamUnit, damage: Int, type: AttackType, isCrit: Bool, dodged: Bool)
        case enemyAttacks(slot: EnemyAttackSlot, targetUnit: TeamUnit, damage: Int, dodged: Bool)
    }
    
    var description: String {
        switch kind {
        case .unitAttacks(let u, let dmg, let t, let crit, let dodged):
            if dodged { return "\(u.name): Miss!" }
            let prefix = t == .superAttack ? "⚡SA" : t == .additionalAttack ? "➕AA" : "⚔"
            let critStr = crit ? " CRIT!" : ""
            return "\(prefix) \(u.name): \(dmg)\(critStr)"
        case .enemyAttacks(_, let target, let dmg, let dodged):
            if dodged { return "💨 \(target.name) dodged!" }
            return "💥 Enemy → \(target.name): \(dmg)"
        }
    }
}

// MARK: - Full turn result
struct TurnResult {
    var events: [BattleEvent] = []
    var totalDamageToEnemy: Int = 0
    var totalDamageToTeam: Int = 0
}
