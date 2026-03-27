import SwiftUI

class ViewModel: ObservableObject {
    @Published var units: [Unit] = []
    @Published var showGameOverAlert = false
    @Published var isGameActive = true
    @Published var draggedUnitId: UUID? = nil
    
    private var displayLink: CADisplayLink?
    private var lastUpdateTime: CFTimeInterval = 0
    
    // Configuración de las unidades
    private let unitWidth: CGFloat = 60
    private let unitHeight: CGFloat = 60
    private let bottomOffset: CGFloat = 100
    private let screenWidth = UIScreen.main.bounds.width
    
    // Umbral más pequeño para facilitar el intercambio
    private let swapThreshold: CGFloat = 15
    
    init() {
        setupUnits()
        setupGameLoop()
    }
    
    func setupUnits() {
        let screenHeight = UIScreen.main.bounds.height
        let bottomY = screenHeight - bottomOffset
        
        units = UnitPosition.allCases.map { positionType in
            Unit(
                positionType: positionType,
                center: CGPoint(x: positionType.xPosition(in: screenWidth), y: bottomY),
                width: unitWidth,
                height: unitHeight
            )
        }
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
        
        animateUnitsToCorrectPositions(deltaTime: deltaTime)
    }
    
    func startDragging(unitId: UUID) {
        guard isGameActive else { return }
        draggedUnitId = unitId
        
        if let unit = getUnit(by: unitId) {
            unit.startDrag()
            objectWillChange.send()
        }
    }
    
    func updateDraggedUnit(translation: CGSize) {
        guard let draggedId = draggedUnitId,
              let draggedUnit = getUnit(by: draggedId),
              isGameActive else { return }
        
        // Solo movimiento horizontal, sin animación
        let horizontalOffset = translation.width
        draggedUnit.updateDrag(offset: horizontalOffset)
        
        // Verificar si debemos intercambiar posiciones
        checkAndSwapIfNeeded(draggedUnit: draggedUnit, offset: horizontalOffset)
        
        objectWillChange.send()
    }
    
    func endDragging() {
        guard let draggedId = draggedUnitId,
              let draggedUnit = getUnit(by: draggedId),
              isGameActive else { return }
        
        // Al soltar, encontrar la posición final más cercana
        let currentVisualX = draggedUnit.positionType.xPosition(in: screenWidth) + draggedUnit.dragOffset
        let finalPosition = findClosestPositionWithPreference(for: currentVisualX)
        
        // Realizar el intercambio final si es necesario
        if finalPosition != draggedUnit.positionType {
            if let targetUnit = units.first(where: { $0.positionType == finalPosition && $0.id != draggedUnit.id }) {
                // Intercambiar posiciones
                let originalPosition = draggedUnit.positionType
                draggedUnit.positionType = finalPosition
                targetUnit.positionType = originalPosition
                
                // Feedback adicional para el centro
                if finalPosition == .center || originalPosition == .center {
                    #if os(iOS)
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    #endif
                }
            } else {
                // Moverse a posición vacía
                draggedUnit.positionType = finalPosition
            }
        }
        
        draggedUnit.endDrag()
        draggedUnitId = nil
        
        // ANIMACIÓN SUAVE: todas las unidades se mueven a sus posiciones correctas
        withAnimation(.spring(response: 0.7, dampingFraction: 0.85, blendDuration: 0.3)) {
            for unit in units {
                unit.center = CGPoint(x: unit.positionType.xPosition(in: screenWidth), y: unit.center.y)
            }
        }
        
        objectWillChange.send()
    }
    
    private func checkAndSwapIfNeeded(draggedUnit: Unit, offset: CGFloat) {
        let currentVisualX = draggedUnit.positionType.xPosition(in: screenWidth) + offset
        let targetPosition = findClosestPositionWithPreference(for: currentVisualX)
        
        // Reducir el umbral para el centro (hacerlo más fácil)
        let effectiveThreshold = targetPosition == .center ? swapThreshold * 0.7 : swapThreshold
        
        // Si estamos sobre otra posición y hemos pasado el umbral
        if targetPosition != draggedUnit.positionType && abs(offset) > effectiveThreshold {
            // Buscar la unidad en la posición destino
            if let targetUnit = units.first(where: { $0.positionType == targetPosition && $0.id != draggedUnit.id }) {
                // Intercambiar posiciones (sin animación durante el drag)
                let originalPosition = draggedUnit.positionType
                draggedUnit.positionType = targetPosition
                targetUnit.positionType = originalPosition
                
                // Resetear el offset para evitar múltiples intercambios
                draggedUnit.dragOffset = 0
                
                // Feedback háptico más fuerte para el centro
                #if os(iOS)
                let feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle = targetPosition == .center || originalPosition == .center ? .medium : .light
                let generator = UIImpactFeedbackGenerator(style: feedbackStyle)
                generator.impactOccurred()
                #endif
                
                objectWillChange.send()
            }
        }
    }
    
    private func animateUnitsToCorrectPositions(deltaTime: CFTimeInterval) {
        var needsUpdate = false
        
        for unit in units {
            // Saltar la unidad que está siendo arrastrada - NO tiene animación
            if unit.id == draggedUnitId {
                continue
            }
            
            let targetX = unit.positionType.xPosition(in: screenWidth)
            let currentX = unit.center.x
            let diff = targetX - currentX
            
            if abs(diff) > 0.5 {
                // Movimiento extremadamente suave y lento para las unidades que no se arrastran
                let newX = currentX + diff * min(CGFloat(deltaTime) * 4, 0.06)
                unit.center = CGPoint(x: newX, y: unit.center.y)
                needsUpdate = true
            } else if unit.center.x != targetX {
                unit.center = CGPoint(x: targetX, y: unit.center.y)
                needsUpdate = true
            }
        }
        
        if needsUpdate {
            objectWillChange.send()
        }
    }
    
    private func findClosestPositionWithPreference(for xPosition: CGFloat) -> UnitPosition {
        let positions = UnitPosition.allCases
        var bestPosition: UnitPosition = .center
        var bestDistance: CGFloat = .greatestFiniteMagnitude
        
        for position in positions {
            let positionX = position.xPosition(in: screenWidth)
            var distance = abs(xPosition - positionX)
            
            // Dar un bonus a la posición central (reducir su distancia efectiva)
            if position == .center {
                distance -= 15
            }
            
            if distance < bestDistance {
                bestDistance = distance
                bestPosition = position
            }
        }
        
        return bestPosition
    }
    
    private func getUnit(by id: UUID) -> Unit? {
        return units.first { $0.id == id }
    }
    
    func getVisualPosition(for unit: Unit) -> CGPoint {
        if unit.isBeingDragged {
            // La unidad arrastrada sigue exactamente al dedo SIN NINGUNA ANIMACIÓN
            let baseX = unit.positionType.xPosition(in: screenWidth)
            return CGPoint(x: baseX + unit.dragOffset, y: unit.center.y)
        } else {
            // Las demás unidades muestran su posición actual
            return unit.center
        }
    }
    
    func restartGame() {
        setupUnits()
        draggedUnitId = nil
        isGameActive = true
        showGameOverAlert = false
        objectWillChange.send()
    }
    
    deinit {
        displayLink?.invalidate()
    }
}
