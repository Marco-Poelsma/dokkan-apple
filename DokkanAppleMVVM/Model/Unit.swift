// Unit.swift (actualizado con mejor feedback visual)
import Foundation
import SwiftUI

enum UnitPosition: Int, CaseIterable {
    case left = 0
    case center = 1
    case right = 2
    
    var index: Int {
        return self.rawValue
    }
    
    func xPosition(in screenWidth: CGFloat) -> CGFloat {
        switch self {
        case .left:
            return screenWidth / 4
        case .center:
            return screenWidth / 2
        case .right:
            return screenWidth * 3 / 4
        }
    }
}

class Unit: Sprite, Identifiable {
    let id = UUID()
    var positionType: UnitPosition
    var isBeingDragged: Bool = false
    var dragOffset: CGFloat = 0
    
    init(positionType: UnitPosition, center: CGPoint, width: CGFloat, height: CGFloat) {
        self.positionType = positionType
        super.init(center: center, width: width, height: height)
    }
    
    func startDrag() {
        isBeingDragged = true
        dragOffset = 0
    }
    
    func updateDrag(offset: CGFloat) {
        dragOffset = offset
    }
    
    func endDrag() {
        isBeingDragged = false
        dragOffset = 0
    }
}
