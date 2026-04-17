// Enemy.swift
// Modelo del enemigo con HP en barras y stat de ATK

import Foundation
import SwiftUI

class Enemy: ObservableObject {
    let name: String
    let totalBars: Int = 10
    @Published var currentBars: Int = 10
    @Published var currentBarHP: Double = 1.0   // fraction 0.0–1.0 dentro de la barra actual
    let atk: Int
    let color: Color
    
    // Total HP virtual = bars * hpPerBar
    let hpPerBar: Int = 25_000
    var totalHP: Int { totalBars * hpPerBar }
    @Published var remainingHP: Int
    
    var isDead: Bool { remainingHP <= 0 }
    
    init(name: String, atk: Int, color: Color) {
        self.name = name
        self.atk = atk
        self.color = color
        self.remainingHP = totalBars * hpPerBar
    }
    
    // Returns damage dealt to team (mitigated by defender's DEF)
    func damageToTeam(defender: TeamUnit) -> Int {
        let raw = max(0, atk - defender.effectiveDef / 4)
        return max(500, raw)
    }
    
    func receiveDamage(_ dmg: Int) {
        remainingHP = max(0, remainingHP - dmg)
        currentBars = max(0, Int(ceil(Double(remainingHP) / Double(hpPerBar))))
        let hpInCurrentBar = remainingHP % hpPerBar
        currentBarHP = hpInCurrentBar == 0 ? (remainingHP > 0 ? 1.0 : 0.0) : Double(hpInCurrentBar) / Double(hpPerBar)
    }
    
    static func defaultEnemy() -> Enemy {
        Enemy(name: "Janemba", atk: 15_000, color: Color(red: 0.6, green: 0.0, blue: 0.6))
    }
}
