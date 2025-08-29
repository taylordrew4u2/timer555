//
//  ContentView.swift
//  timer
//
//  Created by taylor drew on 8/29/25.
//

import SwiftUI
import Foundation

struct ContentView: View {
    @State private var remainingSeconds: Int = 300 // 5 minutes default
    @State private var isRunning: Bool = false
    @State private var timer: Timer?
    @State private var showFlash: Bool = false
    @State private var showSolid: Bool = false
    @State private var solidStartTime: Date?
    
    private let baseSeconds = 300 // 5 minutes
    private let solidDuration: TimeInterval = 5.0 // 5 seconds
    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea(.all)
            
            // Flash overlay
            if showFlash {
                Color.red.opacity(0.3)
                    .ignoresSafeArea(.all)
                    .opacity(showFlash ? 1 : 0)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: showFlash)
            }
            
            // Solid red overlay
            if showSolid {
                Color(red: 1.0, green: 43/255, blue: 43/255) // #ff2b2b
                    .ignoresSafeArea(.all)
                    .onAppear {
                        solidStartTime = Date()
                        startSolidTimer()
                    }
            }
            
            VStack {
                Spacer()
                
                // Timer display
                Text(formatTime(remainingSeconds))
                    .font(.system(size: min(UIScreen.main.bounds.width * 0.24, 200), weight: .black, design: .default))
                    .foregroundColor(remainingSeconds <= 60 && !showSolid ? Color(red: 1.0, green: 43/255, blue: 43/255) : .white)
                    .monospacedDigit()
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                Spacer()
            }
            
            // Controls at top
            VStack {
                HStack(spacing: 16) {
                    // Down button
                    Button(action: { adjustTime(-10) }) {
                        Text("▼ −10s")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                    }
                    .disabled(showSolid)
                    
                    // Start/Pause button
                    Button(action: toggleTimer) {
                        Text(isRunning ? "Pause" : "Start")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                    }
                    .disabled(showSolid)
                    
                    // Reset button
                    Button(action: resetTimer) {
                        Text("Reset")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                    }
                    .disabled(showSolid)
                    
                    // Up button
                    Button(action: { adjustTime(10) }) {
                        Text("▲ +10s")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                    }
                    .disabled(showSolid)
                }
                .padding(.top, 8)
                
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            updateDisplay()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    // MARK: - Timer Functions
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    private func toggleTimer() {
        if showSolid { return }
        
        if isRunning {
            pauseTimer()
        } else {
            startTimer()
        }
    }
    
    private func startTimer() {
        if showSolid { return }
        
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if remainingSeconds > 0 {
                remainingSeconds -= 1
                updateDisplay()
                
                if remainingSeconds == 0 {
                    timerReachedZero()
                }
            }
        }
    }
    
    private func pauseTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    private func resetTimer() {
        pauseTimer()
        remainingSeconds = baseSeconds
        updateDisplay()
    }
    
    private func adjustTime(_ adjustment: Int) {
        if showSolid { return }
        
        remainingSeconds = max(0, min(36000, remainingSeconds + adjustment)) // clamp 0..10h
        updateDisplay()
    }
    
    private func updateDisplay() {
        // Update flash state based on remaining time
        if remainingSeconds <= 60 && !showSolid && remainingSeconds > 0 {
            if !showFlash {
                showFlash = true
            }
        } else {
            showFlash = false
        }
    }
    
    private func timerReachedZero() {
        pauseTimer()
        showFlash = false
        showSolid = true
    }
    
    private func startSolidTimer() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { solidTimer in
            if let startTime = solidStartTime {
                if Date().timeIntervalSince(startTime) >= solidDuration {
                    solidTimer.invalidate()
                    exitSolid()
                }
            }
        }
    }
    
    private func exitSolid() {
        showSolid = false
        solidStartTime = nil
        remainingSeconds = baseSeconds
        startTimer() // Auto-restart after solid screen
    }
}

#Preview {
    ContentView()
}
