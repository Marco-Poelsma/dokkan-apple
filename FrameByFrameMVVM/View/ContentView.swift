import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: ViewModel
    
    var body: some View {
        ZStack {
            Color.blue.opacity(0.3)
                .ignoresSafeArea()
            
            // Flechas indicadoras entre casillas
            ArrowsIndicator()
            
            // Unidades
            ForEach(viewModel.units) { unit in
                UnitView(unit: unit)
                    .position(viewModel.getVisualPosition(for: unit))
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if viewModel.draggedUnitId == nil {
                                    viewModel.startDragging(unitId: unit.id)
                                }
                                viewModel.updateDraggedUnit(translation: value.translation)
                            }
                            .onEnded { _ in
                                viewModel.endDragging()
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

struct ArrowsIndicator: View {
    let screenWidth = UIScreen.main.bounds.width
    let screenHeight = UIScreen.main.bounds.height
    let bottomOffset: CGFloat = 100
    let arrowSize: CGFloat = 30
    
    var body: some View {
        ZStack {
            // Flecha izquierda -> centro
            ArrowView(direction: .right)
                .position(
                    x: (screenWidth / 4 + screenWidth / 2) / 2,
                    y: screenHeight - bottomOffset
                )
            
            // Flecha centro -> derecha
            ArrowView(direction: .right)
                .position(
                    x: (screenWidth / 2 + screenWidth * 3 / 4) / 2,
                    y: screenHeight - bottomOffset
                )
            
            // Flecha derecha -> centro (izquierda)
            ArrowView(direction: .left)
                .position(
                    x: (screenWidth / 2 + screenWidth * 3 / 4) / 2,
                    y: screenHeight - bottomOffset
                )
            
            // Flecha centro -> izquierda
            ArrowView(direction: .left)
                .position(
                    x: (screenWidth / 4 + screenWidth / 2) / 2,
                    y: screenHeight - bottomOffset
                )
        }
    }
}

struct ArrowView: View {
    enum Direction {
        case left, right
    }
    
    let direction: Direction
    @State private var isAnimating = false
    
    var body: some View {
        Image(systemName: direction == .right ? "arrow.right" : "arrow.left")
            .font(.system(size: 20, weight: .medium))
            .foregroundColor(Color.white.opacity(0.6))
            .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
            .overlay(
                Image(systemName: direction == .right ? "arrow.right" : "arrow.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.3))
                    .offset(x: direction == .right ? 4 : -4)
                    .opacity(isAnimating ? 0.8 : 0.2)
            )
            .onAppear {
                withAnimation(
                    Animation.easeInOut(duration: 0.8)
                        .repeatForever(autoreverses: true)
                ) {
                    isAnimating = true
                }
            }
    }
}

