// Unit.swift
import Foundation
import SwiftUI

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
