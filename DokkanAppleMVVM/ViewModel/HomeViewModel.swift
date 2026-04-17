// HomeViewModel.swift
import Foundation
import SwiftUI

class HomeViewModel: ObservableObject {
    @Published var highestWave: Int = 1
    
    init() {
        loadHighestWave()
    }
    
    func loadHighestWave() {  // ← Cambiado a public
        highestWave = UserDefaults.standard.integer(forKey: "highestWave")
        if highestWave == 0 {
            highestWave = 1
        }
    }
    
    func startGame() {
        // No needed, usamos showGame en la vista
    }
    
    func resetHighestWave() {
        highestWave = 1
        UserDefaults.standard.set(1, forKey: "highestWave")
    }
}
