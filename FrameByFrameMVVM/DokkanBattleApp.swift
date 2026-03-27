// DokkanBattleApp.swift
// Entry point - reemplaza FrameByFrameMVVMApp

import SwiftUI

@main
struct DokkanBattleApp: App {
    @StateObject var battleVM = BattleViewModel()
    
    var body: some Scene {
        WindowGroup {
            BattleView()
                .environmentObject(battleVM)
        }
    }
}
