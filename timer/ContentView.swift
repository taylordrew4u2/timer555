import SwiftUI

struct ContentView: View {
    @State private var baseSeconds = 300 // default 5 minutes
    @State private var isRunning = false
    @State private var deadline: Date? = nil // when countdown hits 0
    @State private var pausedRemaining = 300
    @State private var solidUntil: Date? = nil // timestamp until which solid red is shown
    @State private var timerTick: Int = 0 // Counter to force UI updates
    
    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    private let SOLID_MS: TimeInterval = 5.0 // 5 seconds
    
    // Environment values for device detection
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Main background
                Color.black
                    .ignoresSafeArea(.all)
                
                // Flash overlay when under 1 minute
                if shouldFlash {
                    Color.red.opacity(0.3)
                        .ignoresSafeArea(.all)
                        .opacity(flashOpacity)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: flashOpacity)
                        .zIndex(5)
                }
                
                // Solid red overlay when timer reaches 0
                if isSolidRed {
                    Color(red: 1.0, green: 0.16862745, blue: 0.16862745) // #ff2b2b
                        .ignoresSafeArea(.all)
                        .zIndex(10)
                }
                
                VStack(spacing: 0) {
                    // Controls at the top with safe area
                    HStack(spacing: adaptiveButtonSpacing(for: geometry)) {
                        // Down 10s button
                        Button(action: {
                            adjustTime(-10)
                        }) {
                            Text("▼ −10s")
                                .font(.system(size: adaptiveButtonFontSize(for: geometry), weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, adaptiveButtonPadding(for: geometry).horizontal)
                                .padding(.vertical, adaptiveButtonPadding(for: geometry).vertical)
                                .frame(minWidth: adaptiveMinButtonSize(for: geometry).width,
                                       minHeight: adaptiveMinButtonSize(for: geometry).height)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.white, lineWidth: 2)
                                )
                        }
                        .disabled(isRunning && !isSolidRed)
                        .opacity(isRunning && !isSolidRed ? 0.6 : 1.0)
                        
                        // Start/Pause button
                        Button(action: {
                            toggleStart()
                        }) {
                            Text(isRunning ? "Pause" : "Start")
                                .font(.system(size: adaptiveButtonFontSize(for: geometry), weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, adaptiveButtonPadding(for: geometry).horizontal)
                                .padding(.vertical, adaptiveButtonPadding(for: geometry).vertical)
                                .frame(minWidth: adaptiveMinButtonSize(for: geometry).width,
                                       minHeight: adaptiveMinButtonSize(for: geometry).height)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.white, lineWidth: 2)
                                )
                        }
                        
                        // Reset button
                        Button(action: {
                            resetTimer()
                        }) {
                            Text("Reset")
                                .font(.system(size: adaptiveButtonFontSize(for: geometry), weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, adaptiveButtonPadding(for: geometry).horizontal)
                                .padding(.vertical, adaptiveButtonPadding(for: geometry).vertical)
                                .frame(minWidth: adaptiveMinButtonSize(for: geometry).width,
                                       minHeight: adaptiveMinButtonSize(for: geometry).height)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.white, lineWidth: 2)
                                )
                        }
                        
                        // Up 10s button
                        Button(action: {
                            adjustTime(10)
                        }) {
                            Text("▲ +10s")
                                .font(.system(size: adaptiveButtonFontSize(for: geometry), weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, adaptiveButtonPadding(for: geometry).horizontal)
                                .padding(.vertical, adaptiveButtonPadding(for: geometry).vertical)
                                .frame(minWidth: adaptiveMinButtonSize(for: geometry).width,
                                       minHeight: adaptiveMinButtonSize(for: geometry).height)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.white, lineWidth: 2)
                                )
                        }
                        .disabled(isRunning && !isSolidRed)
                        .opacity(isRunning && !isSolidRed ? 0.6 : 1.0)
                    }
                    .padding(.horizontal, geometry.safeAreaInsets.leading + geometry.safeAreaInsets.trailing + 16)
                    .padding(.top, max(geometry.safeAreaInsets.top, 10))
                    .zIndex(1001)
                    
                    Spacer()
                    
                    // Timer display - centered with responsive sizing
                    Text(formatTime(remainingSeconds))
                        .font(.system(
                            size: adaptiveTimerFontSize(for: geometry),
                            weight: .black,
                            design: .monospaced
                        ))
                        .foregroundColor(timerColor)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.3)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20)
                        .accessibilityLabel("Timer showing \(formatTime(remainingSeconds))")
                    
                    Spacer()
                }
            }
        }
        .onReceive(timer) { _ in
            tick()
        }
        .preferredColorScheme(.dark)
        .onAppear {
            updateImmediate()
        }
        // Support for Mac keyboard shortcuts and accessibility
        .onKeyPress(.space) {
            toggleStart()
            return .handled
        }
        .onKeyPress("r") {
            resetTimer()
            return .handled
        }
        .onKeyPress(.upArrow) {
            adjustTime(10)
            return .handled
        }
        .onKeyPress(.downArrow) {
            adjustTime(-10)
            return .handled
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Timer App")
    }
    
    // MARK: - Adaptive Sizing Functions
    
    private func adaptiveTimerFontSize(for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let screenHeight = geometry.size.height
        let isLandscape = screenWidth > screenHeight
        
        // Different sizing for different device classes
        if horizontalSizeClass == .regular && verticalSizeClass == .regular {
            // iPad in any orientation
            if isLandscape {
                return min(screenWidth * 0.18, screenHeight * 0.25, 200)
            } else {
                return min(screenWidth * 0.22, screenHeight * 0.18, 180)
            }
        } else if horizontalSizeClass == .regular && verticalSizeClass == .compact {
            // iPhone landscape or iPad landscape (compact height)
            return min(screenWidth * 0.12, screenHeight * 0.35, 120)
        } else {
            // iPhone portrait or compact width
            if isLandscape {
                return min(screenWidth * 0.15, screenHeight * 0.4, 100)
            } else {
                return min(screenWidth * 0.24, screenHeight * 0.25, 160)
            }
        }
    }
    
    private func adaptiveButtonFontSize(for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        
        if horizontalSizeClass == .regular && verticalSizeClass == .regular {
            // iPad
            return max(16, min(20, screenWidth * 0.025))
        } else {
            // iPhone or Mac
            return max(12, min(16, screenWidth * 0.035))
        }
    }
    
    private func adaptiveButtonSpacing(for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        
        if horizontalSizeClass == .regular && verticalSizeClass == .regular {
            // iPad
            return max(20, min(40, screenWidth * 0.04))
        } else {
            // iPhone
            return max(12, min(20, screenWidth * 0.03))
        }
    }
    
    private func adaptiveButtonPadding(for geometry: GeometryProxy) -> (horizontal: CGFloat, vertical: CGFloat) {
        if horizontalSizeClass == .regular && verticalSizeClass == .regular {
            // iPad
            return (horizontal: 16, vertical: 10)
        } else {
            // iPhone
            return (horizontal: 12, vertical: 6)
        }
    }
    
    private func adaptiveMinButtonSize(for geometry: GeometryProxy) -> (width: CGFloat, height: CGFloat) {
        if horizontalSizeClass == .regular && verticalSizeClass == .regular {
            // iPad - larger touch targets
            return (width: 80, height: 44)
        } else {
            // iPhone - standard touch targets
            return (width: 60, height: 36)
        }
    }
    
    // MARK: - Computed Properties
    
    private var remainingSeconds: Int {
        // Force dependency on currentTime to trigger UI updates
        _ = timerTick
        
        if isSolidRed { return 0 }
        if isRunning, let deadline = deadline {
            return max(0, Int(ceil(deadline.timeIntervalSinceNow)))
        } else {
            return pausedRemaining
        }
    }
    
    private var isSolidRed: Bool {
        guard let solidUntil = solidUntil else { return false }
        return Date() < solidUntil
    }
    
    private var shouldFlash: Bool {
        let remaining = remainingSeconds
        return remaining <= 60 && remaining > 0 && !isSolidRed
    }
    
    private var flashOpacity: Double {
        shouldFlash ? 1.0 : 0.0
    }
    
    private var timerColor: Color {
        if remainingSeconds <= 60 && !isSolidRed {
            return Color(red: 1.0, green: 0.16862745, blue: 0.16862745) // #ff2b2b
        } else {
            return .white
        }
    }
    
    // MARK: - Functions
    
    private func formatTime(_ seconds: Int) -> String {
        let totalSeconds = max(0, seconds)
        let minutes = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
    
    private func start() {
        if isSolidRed { return } // ignore during solid screen
        if !isRunning {
            let startFrom = remainingSeconds
            deadline = Date().addingTimeInterval(TimeInterval(startFrom))
            isRunning = true
        }
    }
    
    private func pause() {
        if isRunning {
            pausedRemaining = remainingSeconds
            isRunning = false
            deadline = nil
        }
    }
    
    private func toggleStart() {
        if isRunning {
            pause()
        } else {
            start()
        }
    }
    
    private func adjustTime(_ seconds: Int) {
        let newSeconds = max(0, min(36000, remainingSeconds + seconds)) // clamp 0..10h
        setRemaining(newSeconds)
    }
    
    private func setRemaining(_ newSeconds: Int) {
        let clampedSeconds = max(0, min(36000, newSeconds))
        if isRunning, deadline != nil {
            deadline = Date().addingTimeInterval(TimeInterval(clampedSeconds))
        } else {
            pausedRemaining = clampedSeconds
        }
        updateImmediate()
    }
    
    private func resetTimer() {
        isRunning = false
        deadline = nil
        pausedRemaining = baseSeconds
        solidUntil = nil
        updateImmediate()
    }
    
    private func enterSolid() {
        isRunning = false
        deadline = nil
        solidUntil = Date().addingTimeInterval(SOLID_MS)
    }
    
    private func maybeLeaveSolid() {
        if let solidUntil = solidUntil, Date() >= solidUntil {
            self.solidUntil = nil
            pausedRemaining = baseSeconds
            isRunning = true
            deadline = Date().addingTimeInterval(TimeInterval(pausedRemaining))
        }
    }
    
    private func updateImmediate() {
        // This function is called to force UI updates
        // SwiftUI handles most of this automatically via @State
    }
    
    private func tick() {
        // Update timer tick counter to force UI refresh
        timerTick += 1
        
        if isSolidRed {
            maybeLeaveSolid()
            return
        }
        
        if isRunning {
            let remaining = remainingSeconds
            if remaining <= 0 {
                enterSolid()
                return
            }
        }
    }
}

#Preview("iPhone") {
    ContentView()
}

#Preview("iPad") {
    ContentView()
}

#Preview("Mac") {
    ContentView()
        .frame(width: 800, height: 600)
}
