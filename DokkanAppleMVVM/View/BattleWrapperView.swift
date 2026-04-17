// BattleWrapperView.swift
import SwiftUI

struct BattleWrapperView: View {
    @StateObject private var viewModel = BattleViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        BattleView()
            .environmentObject(viewModel)
            .onReceive(viewModel.$phase) { phase in
                if case .gameOver = phase {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        NotificationCenter.default.post(name: NSNotification.Name("UpdateHighestWave"), object: nil)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
    }
}
