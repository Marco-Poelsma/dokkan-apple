// UnitPosition.swift
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
