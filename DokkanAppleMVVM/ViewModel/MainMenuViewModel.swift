// MainMenuViewModel.swift
import Foundation
import SwiftUI
import AVFoundation

class MainMenuViewModel: ObservableObject {
    @Published var showingGame = false
    @Published var animateLogo = false
    @Published var animateButtons = false
    @Published var highScore: Int = 1
    
    private let soundManager = SoundManager.shared
    
    init() {
        loadHighScore()
        setupAudio()
    }
    
    private func loadHighScore() {
        highScore = UserDefaults.standard.integer(forKey: "highestWave")
        if highScore == 0 {
            highScore = 1
        }
    }
    
    private func setupAudio() {
        // Iniciar música de fondo
        soundManager.playBGM()
    }
    
    var highScoreText: String {
        return "🏆 BEST WAVE: \(highScore)"
    }
    
    func startGame() {
        // Efecto de sonido al iniciar
        soundManager.playSound(named: "lvlup", volume: 0.7)
        
        // Pequeño delay para el efecto de sonido
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.showingGame = true
        }
    }
    
    func onAppear() {
        // Animaciones al aparecer
        withAnimation(.easeOut(duration: 0.8)) {
            animateLogo = true
        }
        
        withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
            animateButtons = true
        }
        
        // Actualizar high score desde UserDefaults
        let currentHighScore = UserDefaults.standard.integer(forKey: "highestWave")
        if currentHighScore > highScore {
            highScore = currentHighScore
            objectWillChange.send()
        }
    }
}
