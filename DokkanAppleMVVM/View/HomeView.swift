// HomeView.swift
import SwiftUI

struct HomeView: View {
    @State private var showGame = false
    @State private var highestWave: Int = 1
    @State private var appIconImage: UIImage? = nil
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.04, green: 0.05, blue: 0.15),
                    Color(red: 0.07, green: 0.09, blue: 0.22),
                    Color(red: 0.04, green: 0.05, blue: 0.15)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                
                // Logo con imagen desde img/AppIcon.jpg
                VStack(spacing: 5) {
                    if let image = appIconImage {
                        Image(uiImage: image)
                            .resizable()
                            .interpolation(.high)
                            .frame(width: 80, height: 80)
                            .cornerRadius(18)
                            .shadow(color: Color.yellow.opacity(0.3), radius: 10)
                    } else {
                        // Fallback mientras carga
                        Image(systemName: "apple.logo")
                            .font(.system(size: 60))
                            .foregroundColor(Color.yellow)
                    }
                    
                    Text("DOKKAN APPLE")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(Color.yellow)
                    
                    Text("BATTLE ARENA")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.6))
                        .kerning(2)
                }
                .padding(.top, 30)
                
                // Max Score Card
                VStack(spacing: 8) {
                    Text("🏆 HIGHEST WAVE 🏆")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(Color.yellow.opacity(0.8))
                    
                    Text("\(highestWave)")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundColor(Color.white)
                    
                    Text("waves cleared")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.5))
                }
                .padding(20)
                .frame(width: 250)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                        )
                )
                
                // Play Button
                Button(action: {
                    showGame = true
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 16, weight: .black))
                        Text("START BATTLE")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                    }
                    .foregroundColor(Color.black)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(Color.yellow)
                            .shadow(color: Color.yellow.opacity(0.5), radius: 8)
                    )
                }
                .padding(.top, 5)
                
                // Reset button
                Button(action: {
                    UserDefaults.standard.set(1, forKey: "highestWave")
                    highestWave = 1
                }) {
                    Text("Reset Score")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.4))
                        .underline()
                }
                .padding(.top, 5)
                
                Spacer(minLength: 20)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .fullScreenCover(isPresented: $showGame) {
            BattleWrapperView()
        }
        .onAppear {
            let saved = UserDefaults.standard.integer(forKey: "highestWave")
            highestWave = saved > 0 ? saved : 1
            loadAppIcon()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UpdateHighestWave"))) { _ in
            let saved = UserDefaults.standard.integer(forKey: "highestWave")
            highestWave = saved > 0 ? saved : 1
        }
    }
    
    private func loadAppIcon() {
        // Método 2: Buscar en el bundle completo
        if let path = Bundle.main.path(forResource: "AppIcon", ofType: "jpg") {
            if let image = UIImage(contentsOfFile: path) {
                appIconImage = image
                return
            }
        }
        
        // Si no encuentra ninguna, usar fallback
        print("No se encontró AppIcon.jpg en ninguna ubicación")
        appIconImage = UIImage(systemName: "apple.logo")?.withTintColor(.yellow, renderingMode: .alwaysOriginal)
    }
}
