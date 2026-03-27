// DokkanBattleApp.swift
// Entry point - reemplaza FrameByFrameMVVMApp

import SwiftUI

@main
struct DokkanApple: App {
    @StateObject var battleVM = BattleViewModel()
    
    var body: some Scene {
        WindowGroup {
            BattleView()
                .environmentObject(battleVM)
        }
    }
}
