// TeamUnit.swift
// Modelo de unidades con stats, arquetipos y colores únicos

import Foundation
import SwiftUI

// MARK: SA Effect
enum SAEffect: String {
    case stackAtkOneTurn   = "ATK +1T"
    case stackAtkInfinite  = "ATK +∞"
    case stackDefOneTurn   = "DEF +1T"
    case stackDefInfinite  = "DEF +∞"
    case none              = "—"
}

// MARK: Unit Archetype
enum UnitArchetype: String, CaseIterable {
    case stackerAA    = "Stacker AA"
    case dodger       = "Dodger"
    case aaLowCrit    = "AA Critter"
    case support      = "Support"
    case slot3Tank    = "Tank"
    case dpsNoDef     = "DPS"
    case buildByHit   = "Build"
}

// MARK: TeamUnit
class TeamUnit: Sprite, Identifiable, ObservableObject {
    let id = UUID()
    let archetype: UnitArchetype
    let name: String
    let color: Color
    let symbol: String
    
    // Base stats
    let baseAtk: Int
    let baseDef: Int
    let dodgeChance: Double      // 0.0 – 1.0
    let critChance: Double       // 0.0 – 1.0
    let aaChance: Double         // 0.0 – 1.0
    let saEffect: SAEffect
    
    // Runtime modifiers (accumulated during battle)
    @Published var tempAtkBoost: Int = 0        // one-turn atk stacks
    @Published var permAtkBoost: Int = 0        // infinite atk stacks
    @Published var tempDefBoost: Int = 0
    @Published var permDefBoost: Int = 0
    @Published var hitCount: Int = 0            // for Build-by-Hit units
    
    // Drag / slot state (inherited from Unit / Sprite logic)
    var positionType: UnitPosition = .center
    var isBeingDragged: Bool = false
    var dragOffset: CGFloat = 0
    
    // Computed effective stats
    var effectiveAtk: Int {
        let hitBonus = archetype == .buildByHit ? hitCount * 200 : 0
        return baseAtk + tempAtkBoost + permAtkBoost + hitBonus
    }
    
    var effectiveDef: Int {
        return baseDef + tempDefBoost + permDefBoost
    }
    
    // Called at start of every turn – reset one-turn buffs
    func newTurn() {
        tempAtkBoost = 0
        tempDefBoost = 0
    }
    
    // Apply SA effect after attacking
    func applySAEffect() {
        switch saEffect {
        case .stackAtkOneTurn:  tempAtkBoost += 15_000
        case .stackAtkInfinite: permAtkBoost += 10_000
        case .stackDefOneTurn:  tempDefBoost += 50_000
        case .stackDefInfinite: permDefBoost += 30_000
        case .none: break
        }
    }
    
    // Register a hit received (for Build-by-Hit)
    func registerHit() {
        hitCount += 1
    }
    
    func startDrag() { isBeingDragged = true; dragOffset = 0 }
    func updateDrag(offset: CGFloat) { dragOffset = offset }
    func endDrag() { isBeingDragged = false; dragOffset = 0 }
    
    init(
        archetype: UnitArchetype,
        name: String,
        color: Color,
        symbol: String,
        baseAtk: Int,
        baseDef: Int,
        dodgeChance: Double,
        critChance: Double,
        aaChance: Double,
        saEffect: SAEffect,
        center: CGPoint,
        width: CGFloat,
        height: CGFloat
    ) {
        self.archetype = archetype
        self.name = name
        self.color = color
        self.symbol = symbol
        self.baseAtk = baseAtk
        self.baseDef = baseDef
        self.dodgeChance = dodgeChance
        self.critChance = critChance
        self.aaChance = aaChance
        self.saEffect = saEffect
        super.init(center: center, width: width, height: height)
    }
}

// MARK: Unit Factory
struct UnitFactory {
    static func makeTeam() -> [TeamUnit] {
        let dummy = CGPoint(x: 0, y: 0)
        let w: CGFloat = 65, h: CGFloat = 65
        
        return [
            // 1 - Stacker AA% (stacks ATK ∞ every attack, high AA)
            TeamUnit(
                archetype: .stackerAA,
                name: "Goku",
                color: Color(red: 0.55, green: 0.20, blue: 0.90),   // purple
                symbol: "GK",
                baseAtk: 18_000,
                baseDef: 9_000,
                dodgeChance: 0.10,
                critChance: 0.15,
                aaChance: 0.50,
                saEffect: .stackAtkInfinite,
                center: dummy, width: w, height: h
            ),
            // 2 - Dodger (high dodge, low def)
            TeamUnit(
                archetype: .dodger,
                name: "Goten",
                color: Color(red: 0.10, green: 0.72, blue: 0.72),   // teal
                symbol: "GTN",
                baseAtk: 15_000,
                baseDef: 5_000,
                dodgeChance: 0.55,
                critChance: 0.12,
                aaChance: 0.18,
                saEffect: .none,
                center: dummy, width: w, height: h
            ),
            // 3 - AA low critter (moderate aa, decent crit, low stats)
            TeamUnit(
                archetype: .aaLowCrit,
                name: "Trunks",
                color: Color(red: 0.95, green: 0.55, blue: 0.10),   // orange
                symbol: "TKS",
                baseAtk: 13_000,
                baseDef: 10_000,
                dodgeChance: 0.08,
                critChance: 0.30,
                aaChance: 0.38,
                saEffect: .stackAtkOneTurn,
                center: dummy, width: w, height: h
            ),
            // 4 - Support (low dodge, applies DEF buff)
            TeamUnit(
                archetype: .support,
                name: "Piccolo",
                color: Color(red: 0.20, green: 0.68, blue: 0.28),   // green
                symbol: "PCL",
                baseAtk: 10_000,
                baseDef: 20_000,
                dodgeChance: 0.05,
                critChance: 0.05,
                aaChance: 0.20,
                saEffect: .stackDefOneTurn,
                center: dummy, width: w, height: h
            ),
            // 5 - Slot-3 Tank (very high def, low atk)
            TeamUnit(
                archetype: .slot3Tank,
                name: "Gohan",
                color: Color(red: 0.85, green: 0.15, blue: 0.25),   // red
                symbol: "GHN",
                baseAtk: 8_000,
                baseDef: 35_000,
                dodgeChance: 0.05,
                critChance: 0.05,
                aaChance: 0.10,
                saEffect: .stackDefInfinite,
                center: dummy, width: w, height: h
            ),
            // 6 - DPS no def (massive atk, no defense)
            TeamUnit(
                archetype: .dpsNoDef,
                name: "Vegeta",
                color: Color(red: 0.95, green: 0.85, blue: 0.10),   // yellow
                symbol: "VGT",
                baseAtk: 28_000,
                baseDef: 2_000,
                dodgeChance: 0.05,
                critChance: 0.25,
                aaChance: 0.15,
                saEffect: .stackAtkOneTurn,
                center: dummy, width: w, height: h
            ),
            // 7 - Build by hit (grows stronger each hit received)
            TeamUnit(
                archetype: .buildByHit,
                name: "Tien",
                color: Color(red: 0.20, green: 0.45, blue: 0.95),   // blue
                symbol: "TN",
                baseAtk: 16_000,
                baseDef: 14_000,
                dodgeChance: 0.15,
                critChance: 0.18,
                aaChance: 0.25,
                saEffect: .stackAtkInfinite,
                center: dummy, width: w, height: h
            )
        ]
    }
}
