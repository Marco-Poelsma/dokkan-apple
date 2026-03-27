// DokkanBattleApp.swift
// Entry point - reemplaza FrameByFrameMVVMApp

import SwiftUI

@main
struct Dokkan: App {
    @StateObject var battleVM = BattleViewModel()
    
    var body: some Scene {
        WindowGroup {
            BattleView()
                .environmentObject(battleVM)
        }
    }
}
