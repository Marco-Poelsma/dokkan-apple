// MainMenuView.swift
import SwiftUI

struct MainMenuView: View {
    @StateObject private var viewModel = MainMenuViewModel()
    
    var body: some View {
        ZStack {
            // Fondo animado
            BackgroundView()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Logo / Título
                VStack(spacing: 15) {
                    Text("⚔️ BATTLE ARENA ⚔️")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .purple, radius: 10)
                        .scaleEffect(viewModel.animateLogo ? 1 : 0.8)
                        .opacity(viewModel.animateLogo ? 1 : 0)
                    
                    Text("Idle RPG Battle")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                        .shadow(color: .black, radius: 2)
                        .opacity(viewModel.animateLogo ? 1 : 0)
                        .offset(y: viewModel.animateLogo ? 0 : -20)
                }
                
                Spacer()
                
                // High Score
                HStack {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.yellow)
                        .font(.title2)
                    Text(viewModel.highScoreText)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .padding()
                .background(Color.black.opacity(0.5))
                .cornerRadius(20)
                .opacity(viewModel.animateButtons ? 1 : 0)
                .offset(y: viewModel.animateButtons ? 0 : 30)
                
                // Botón Jugar
                Button(action: {
                    viewModel.startGame()
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                            .font(.title2)
                        Text("COMENZAR BATALLA")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .frame(width: 280, height: 65)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.purple, Color.blue]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(35)
                    .shadow(color: .purple, radius: 10)
                }
                .opacity(viewModel.animateButtons ? 1 : 0)
                .offset(y: viewModel.animateButtons ? 0 : 30)
                
                Spacer()
                
                // Versión
                Text("v1.0.0")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.bottom, 20)
                    .opacity(viewModel.animateButtons ? 1 : 0)
            }
            .padding()
            
            // Navigation Link al juego
            NavigationLink(
                destination: GameView()
                    .navigationBarHidden(true)
                    .onDisappear {
                        // Actualizar high score al volver
                        viewModel.onAppear()
                    },
                isActive: $viewModel.showingGame
            ) {
                EmptyView()
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
    }
}

// MARK: - Background View Animado
struct BackgroundView: View {
    @State private var animateGradient = false
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.4, green: 0.0, blue: 0.6),
                Color(red: 0.1, green: 0.0, blue: 0.3),
                Color.black
            ]),
            startPoint: animateGradient ? .topLeading : .bottomTrailing,
            endPoint: animateGradient ? .bottomTrailing : .topLeading
        )
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
}
