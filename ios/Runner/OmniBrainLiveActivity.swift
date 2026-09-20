import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Activity Attributes Model
public struct OmniBrainPomodoroAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var remainingSeconds: Int
        public var totalSeconds: Int
        public var isPaused: Bool
        public var taskName: String
        
        public init(remainingSeconds: Int, totalSeconds: Int, isPaused: Bool, taskName: String) {
            self.remainingSeconds = remainingSeconds
            self.totalSeconds = totalSeconds
            self.isPaused = isPaused
            self.taskName = taskName
        }
    }
    
    public var sessionId: String
    
    public init(sessionId: String) {
        self.sessionId = sessionId
    }
}

// MARK: - SwiftUI Live Activity & Dynamic Island Widget
@available(iOS 16.1, *)
public struct OmniBrainLiveActivityWidget: Widget {
    public init() {}
    
    public var body: some WidgetConfiguration {
        ActivityConfiguration(for: OmniBrainPomodoroAttributes.self) { context in
            // Lock screen / Banner presentation
            LockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded Dynamic Island
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        Image(systemName: "timer")
                            .foregroundColor(Color(red: 138/255, green: 43/255, blue: 226/255))
                            .font(.system(size: 20, weight: .bold))
                        Text(context.state.taskName.isEmpty ? "Odak Seansı" : context.state.taskName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    .padding(.leading, 8)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(formatTime(context.state.remainingSeconds))
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(red: 125/255, green: 249/255, blue: 255/255))
                        .padding(.trailing, 8)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 6) {
                        ProgressView(value: Double(context.state.totalSeconds - context.state.remainingSeconds),
                                     total: Double(max(1, context.state.totalSeconds)))
                            .tint(Color(red: 138/255, green: 43/255, blue: 226/255))
                            .scaleEffect(x: 1, y: 1.5, anchor: .center)
                        
                        HStack {
                            Text(context.state.isPaused ? "⏸ Duraklatıldı" : "⚡ Odaklanılıyor")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.gray)
                            Spacer()
                            Text("OmniBrain AI")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color(red: 125/255, green: 249/255, blue: 255/255))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 6)
                }
            } compactLeading: {
                Image(systemName: "timer")
                    .foregroundColor(Color(red: 138/255, green: 43/255, blue: 226/255))
                    .font(.system(size: 13, weight: .bold))
            } compactTrailing: {
                Text(formatTime(context.state.remainingSeconds))
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(red: 125/255, green: 249/255, blue: 255/255))
            } minimal: {
                Image(systemName: "timer")
                    .foregroundColor(Color(red: 138/255, green: 43/255, blue: 226/255))
            }
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - Lock Screen Banner View
@available(iOS 16.1, *)
struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<OmniBrainPomodoroAttributes>
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 4)
                    .frame(width: 46, height: 46)
                Circle()
                    .trim(from: 0, to: CGFloat(Double(context.state.totalSeconds - context.state.remainingSeconds) / Double(max(1, context.state.totalSeconds))))
                    .stroke(Color(red: 138/255, green: 43/255, blue: 226/255), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 46, height: 46)
                Image(systemName: context.state.isPaused ? "pause.fill" : "timer")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(red: 125/255, green: 249/255, blue: 255/255))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(context.state.taskName.isEmpty ? "Odaklanma Seansı" : context.state.taskName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                Text(context.state.isPaused ? "Zamanlayıcı Duraklatıldı" : "Derin Odaklanma Modu")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            Text(String(format: "%02d:%02d", context.state.remainingSeconds / 60, context.state.remainingSeconds % 60))
                .font(.system(size: 26, weight: .bold, design: .monospaced))
                .foregroundColor(Color(red: 125/255, green: 249/255, blue: 255/255))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            LinearGradient(colors: [
                Color(red: 17/255, green: 24/255, blue: 39/255),
                Color(red: 10/255, green: 14/255, blue: 23/255)
            ], startPoint: .top, endPoint: .bottom)
        )
    }
}
