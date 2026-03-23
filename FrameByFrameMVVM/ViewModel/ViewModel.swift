import SwiftUI

class ViewModel: ObservableObject {
    @Published var player: Player?
    @Published var showGameOverAlert = false
    @Published var isGameActive = true
    
    private var displayLink: CADisplayLink?
    private var lastUpdateTime: CFTimeInterval = 0
    private var accumulatedTime: CFTimeInterval = 0
    
    init() {
        setupInitialPosition()
        setupGameLoop()
    }
    
    func setupInitialPosition() {
        let screenHeight = UIScreen.main.bounds.height
        let screenWidth = UIScreen.main.bounds.width
        
        let initialY = screenHeight - 100
        let initialX = screenWidth / 2
        
        player = Player(
            center: CGPoint(x: initialX, y: initialY),
            width: 60,
            height: 60
        )
    }
    
    func setupGameLoop() {
        displayLink = CADisplayLink(target: self, selector: #selector(gameLoop))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc func gameLoop() {
        guard isGameActive else { return }
        
        let currentTime = CACurrentMediaTime()
        
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
            return
        }
        
        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
    }
    
    func movePlayerTo(x: CGFloat) {
        guard let player = player, isGameActive else { return }
        
        let newX = min(max(x, player.width/2), UIScreen.main.bounds.width - player.width/2)
        
        DispatchQueue.main.async {
            self.player?.center = CGPoint(x: newX, y: player.center.y)
            self.objectWillChange.send()
        }
    }
    
    func restartGame() {
        // Reiniciar posición del player
        setupInitialPosition()
        
        // Reactivar el juego
        isGameActive = true
        showGameOverAlert = false
        
        objectWillChange.send()
    }
    
    deinit {
        displayLink?.invalidate()
    }
}
