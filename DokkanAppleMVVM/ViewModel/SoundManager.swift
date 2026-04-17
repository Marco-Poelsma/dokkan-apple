// SoundManager.swift - Con soporte para BGM
import AVFoundation
import SwiftUI

class SoundManager: ObservableObject {
    static let shared = SoundManager()
    
    // Efectos de sonido
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    @Published var isSoundEnabled: Bool = true
    
    // Música de fondo (BGM)
    private var bgmPlayer: AVAudioPlayer?
    @Published var isBGMEnabled: Bool = true
    private var bgmVolume: Float = 0.3
    
    // Ruta base de la carpeta Sounds
    private let soundFolder = "Sounds"
    
    private init() {
        setupAudioSession()
        setupBGM()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Error setting up audio session: \(error)")
        }
    }
    
    // MARK: - BGM Setup
    private func setupBGM() {
        guard let url = getSoundURL(named: "bgm", withExtension: "mp3") else {
            print("❌ No se encontró bgm.mp3 en la carpeta Sounds")
            return
        }
        
        do {
            bgmPlayer = try AVAudioPlayer(contentsOf: url)
            bgmPlayer?.numberOfLoops = -1 // Loop infinito
            bgmPlayer?.volume = bgmVolume
            bgmPlayer?.prepareToPlay()
            print("✅ BGM cargado correctamente: bgm.mp3")
        } catch {
            print("❌ Error cargando BGM: \(error)")
        }
    }
    
    // Reproducir BGM
    func playBGM() {
        guard isBGMEnabled else { return }
        
        if let player = bgmPlayer, !player.isPlaying {
            player.play()
            print("🎵 BGM reproducido")
        }
    }
    
    // Pausar BGM
    func pauseBGM() {
        bgmPlayer?.pause()
        print("⏸️ BGM pausado")
    }
    
    // Detener BGM
    func stopBGM() {
        bgmPlayer?.stop()
        bgmPlayer?.currentTime = 0
        print("⏹️ BGM detenido")
    }
    
    // Cambiar volumen del BGM
    func setBGMVolume(_ volume: Float) {
        bgmVolume = max(0, min(1, volume))
        bgmPlayer?.volume = bgmVolume
    }
    
    // Activar/Desactivar BGM
    func toggleBGM() {
        isBGMEnabled.toggle()
        if isBGMEnabled {
            playBGM()
        } else {
            pauseBGM()
        }
    }
    
    // MARK: - Efectos de sonido
    private func getSoundURL(named soundName: String, withExtension ext: String = "mp3") -> URL? {
        // Buscar en la carpeta Sounds
        if let soundURL = Bundle.main.url(forResource: soundName,
                                         withExtension: ext,
                                         subdirectory: soundFolder) {
            return soundURL
        }
        
        // Si no lo encuentra, intentar buscar en la raíz (fallback)
        if let fallbackURL = Bundle.main.url(forResource: soundName, withExtension: ext) {
            print("⚠️ Sonido \(soundName) encontrado en raíz, debería estar en carpeta Sounds")
            return fallbackURL
        }
        
        print("❌ No se encontró el sonido: \(soundName).\(ext) en carpeta \(soundFolder)")
        return nil
    }
    
    // Método para reproducir sonido con completion handler
    func playSound(named soundName: String,
                   withExtension ext: String = "mp3",
                   volume: Float = 1.0,
                   completion: (() -> Void)? = nil) {
        guard isSoundEnabled else {
            completion?()
            return
        }
        
        let key = "\(soundName).\(ext)"
        
        // Si el sonido ya está cargado, usarlo
        if let player = audioPlayers[key] {
            player.volume = volume
            player.currentTime = 0
            player.play()
            
            // Esperar a que termine
            DispatchQueue.main.asyncAfter(deadline: .now() + player.duration) {
                completion?()
            }
            return
        }
        
        // Cargar el sonido desde la carpeta Sounds
        guard let url = getSoundURL(named: soundName, withExtension: ext) else {
            completion?()
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = volume
            player.prepareToPlay()
            player.play()
            audioPlayers[key] = player
            
            // Esperar a que termine
            DispatchQueue.main.asyncAfter(deadline: .now() + player.duration) {
                completion?()
            }
        } catch {
            print("Error playing sound \(soundName): \(error)")
            completion?()
        }
    }
    
    // Método para reproducir sonido sin esperar (modo async)
    func playSoundAsync(named soundName: String,
                        withExtension ext: String = "mp3",
                        volume: Float = 1.0) {
        guard isSoundEnabled else { return }
        
        let key = "\(soundName).\(ext)"
        
        if let player = audioPlayers[key] {
            if player.isPlaying {
                player.currentTime = 0
            }
            player.volume = volume
            player.play()
            return
        }
        
        guard let url = getSoundURL(named: soundName, withExtension: ext) else { return }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = volume
            player.prepareToPlay()
            player.play()
            audioPlayers[key] = player
        } catch {
            print("Error playing sound \(soundName): \(error)")
        }
    }
    
    // Pre-cargar todos los sonidos
    func preloadSounds() {
        let soundsToPreload = [
            "uhit", "sa", "ehit", "dodge", "lvlup", "death"
        ]
        
        for soundName in soundsToPreload {
            preloadSound(named: soundName)
        }
    }
    
    // Pre-cargar un sonido específico
    func preloadSound(named soundName: String, withExtension ext: String = "mp3") {
        guard let url = getSoundURL(named: soundName, withExtension: ext) else { return }
        
        let key = "\(soundName).\(ext)"
        guard audioPlayers[key] == nil else { return }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            audioPlayers[key] = player
            print("✅ Sonido pre-cargado: \(soundName)")
        } catch {
            print("❌ Error pre-cargando sonido \(soundName): \(error)")
        }
    }
    
    // Alternar efectos de sonido
    func toggleSound() {
        isSoundEnabled.toggle()
    }
    
    func setSoundEnabled(_ enabled: Bool) {
        isSoundEnabled = enabled
    }
    
    // Limpiar recursos
    func cleanup() {
        for (_, player) in audioPlayers {
            player.stop()
        }
        audioPlayers.removeAll()
        stopBGM()
    }
}
