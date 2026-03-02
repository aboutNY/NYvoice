import Foundation
import SwiftUI

struct RecordingModalView: View {
    @ObservedObject var controller: SessionController
    private let barCount = 18

    var body: some View {
        Group {
            if controller.state == .recording {
                recordingBody
            } else if controller.state == .cancelling {
                cancellingBody
            } else {
                processingBody
            }
        }
        .padding(16)
        .frame(width: 300)
    }

    private var recordingBody: some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                Circle()
                    .fill(.red)
                    .frame(width: 8, height: 8)
                Text("Recording")
                    .font(.headline)
            }

            WaveformView(level: controller.recordingAudioLevel, barCount: barCount)
                .frame(height: 42)

            Text("Elapsed: \(formattedElapsed)")
                .font(.system(.body, design: .monospaced))
            Text("Press Esc to cancel")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text(controller.statusMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Stop") {
                Task {
                    await controller.stopAndProcessRecording()
                }
            }
            .keyboardShortcut(.defaultAction)
        }
    }

    private var processingBody: some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "hourglass")
                Text("Processing")
                    .font(.headline)
            }

            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(0.9)

            Text("処理中です。しばらくお待ちください。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text(controller.statusMessage)
                .font(.system(.body, design: .monospaced))
        }
    }

    private var cancellingBody: some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "xmark.circle")
                Text("Canceled")
                    .font(.headline)
            }
            Text("キャンセルしました。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(controller.statusMessage)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }

    private var formattedElapsed: String {
        let total = controller.recordingElapsedSeconds
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

private struct WaveformView: View {
    let level: Double
    let barCount: Int

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.08)) { timeline in
            GeometryReader { proxy in
                let width = proxy.size.width
                let height = proxy.size.height
                let normalizedLevel = max(0.005, min(1.0, level))
                let phase = timeline.date.timeIntervalSinceReferenceDate
                let spacing: CGFloat = 4
                let barWidth = max(2, (width - (CGFloat(barCount - 1) * spacing)) / CGFloat(barCount))

                HStack(alignment: .center, spacing: spacing) {
                    ForEach(0..<barCount, id: \.self) { index in
                        Capsule()
                            .fill(.red.opacity(0.85))
                            .frame(width: barWidth,
                                   height: barHeight(for: index, level: normalizedLevel, phase: phase, maxHeight: height))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
        .animation(.easeOut(duration: 0.08), value: level)
        .accessibilityLabel("Input waveform")
    }

    private func barHeight(for index: Int, level: Double, phase: TimeInterval, maxHeight: CGFloat) -> CGFloat {
        let center = Double(barCount - 1) / 2.0
        let distance = abs(Double(index) - center) / max(center, 1)
        let envelope = 1.0 - (distance * 0.65)
        let minimum = maxHeight * 0.12
        let pulse = (sin((phase * 8) + Double(index)) + 1) / 2
        let activity = max(level, 0.02 + (pulse * 0.02))
        let amplitude = maxHeight * CGFloat(activity * max(0.15, envelope))
        return max(minimum, amplitude)
    }
}
