// HomeView.swift
import SwiftUI

struct HomeView: View {
    @State private var showGame = false
    @State private var highestWave: Int = 1
    
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
            
            VStack(spacing: 40) {
                Spacer()
                
                // Logo
                VStack(spacing: 10) {
                    Text("⚔️")
                        .font(.system(size: 70))
                    
                    Text("DOKKAN APPLE")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundColor(Color.yellow)
                    
                    Text("BATTLE ARENA")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.6))
                        .kerning(2)
                }
                
                Spacer()
                
                // Max Score Card
                VStack(spacing: 12) {
                    Text("🏆 HIGHEST WAVE 🏆")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Color.yellow.opacity(0.8))
                    
                    Text("\(highestWave)")
                        .font(.system(size: 60, weight: .black, design: .rounded))
                        .foregroundColor(Color.white)
                    
                    Text("waves cleared")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.5))
                }
                .padding(30)
                .frame(width: 280)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                        )
                )
                
                Spacer()
                
                // Play Button
                Button(action: {
                    showGame = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 20, weight: .black))
                        Text("START BATTLE")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                    }
                    .foregroundColor(Color.black)
                    .padding(.horizontal, 50)
                    .padding(.vertical, 18)
                    .background(
                        Capsule()
                            .fill(Color.yellow)
                            .shadow(color: Color.yellow.opacity(0.5), radius: 10)
                    )
                }
                
                // Reset button (opcional)
                Button(action: {
                    UserDefaults.standard.set(1, forKey: "highestWave")
                    highestWave = 1
                }) {
                    Text("Reset Score")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.4))
                        .underline()
                }
                .padding(.top, 10)
                
                Spacer()
            }
            .padding()
        }
        .fullScreenCover(isPresented: $showGame) {
            BattleWrapperView()
        }
        .onAppear {
            let saved = UserDefaults.standard.integer(forKey: "highestWave")
            highestWave = saved > 0 ? saved : 1
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UpdateHighestWave"))) { _ in
            let saved = UserDefaults.standard.integer(forKey: "highestWave")
            highestWave = saved > 0 ? saved : 1
        }
    }
}
