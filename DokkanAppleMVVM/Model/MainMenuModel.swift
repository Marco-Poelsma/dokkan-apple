// MainMenuModel.swift
import Foundation
import SwiftUI

struct MainMenuModel {
    var highScore: Int
    var isSoundEnabled: Bool
    var isBGMEnabled: Bool
    
    static let defaults = UserDefaults.standard
    
    static func load() -> MainMenuModel {
        return MainMenuModel(
            highScore: defaults.integer(forKey: "highestWave"),
            isSoundEnabled: defaults.object(forKey: "isSoundEnabled") as? Bool ?? true,
            isBGMEnabled: defaults.object(forKey: "isBGMEnabled") as? Bool ?? true
        )
    }
    
    func save() {
        MainMenuModel.defaults.set(highScore, forKey: "highestWave")
        MainMenuModel.defaults.set(isSoundEnabled, forKey: "isSoundEnabled")
        MainMenuModel.defaults.set(isBGMEnabled, forKey: "isBGMEnabled")
    }
}
