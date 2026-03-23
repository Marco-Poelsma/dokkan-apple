import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: ViewModel
    
    var body: some View {
        ZStack {
            // Color de fondo del juego
            Color.blue.opacity(0.3)
                .ignoresSafeArea()
            
                
            // Player
            if let player = viewModel.player {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.orange)
                    .frame(width: player.width, height: player.height)
                    .position(player.center)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                viewModel.movePlayerTo(x: value.location.x)
                            }
                    )
            }
        }
        .alert(isPresented: $viewModel.showGameOverAlert) {
            Alert(
                title: Text("GAME OVER"),
                message: Text("¿Quieres volver a jugar?"),
                primaryButton: .default(Text("Jugar otra vez")) {
                    viewModel.restartGame()
                },
                secondaryButton: .cancel(Text("No"))
            )
        }
    }
}
