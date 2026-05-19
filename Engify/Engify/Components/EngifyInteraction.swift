import AVFoundation
import SwiftUI
import UIKit

enum EngifySpring {
    static let tapDown = Animation.spring(response: 0.20, dampingFraction: 0.88, blendDuration: 0)
    static let jellyRelease = Animation.spring(response: 0.35, dampingFraction: 0.50, blendDuration: 0)
    static let settle = Animation.spring(response: 0.28, dampingFraction: 0.74, blendDuration: 0)
    static let cascade = Animation.spring(response: 0.46, dampingFraction: 0.62, blendDuration: 0)
    static let tabSlide = Animation.spring(response: 0.40, dampingFraction: 0.68, blendDuration: 0)
}

private enum EngifyPressPhase {
    case idle
    case pressed
    case overshoot

    var scale: CGFloat {
        switch self {
        case .idle:
            return 1
        case .pressed:
            return 0.95
        case .overshoot:
            return 1.02
        }
    }
}

struct EngifyJellyPressModifier: ViewModifier {
    let isDisabled: Bool

    @State private var phase: EngifyPressPhase = .idle

    func body(content: Content) -> some View {
        content
            .scaleEffect(phase.scale)
            .contentShape(Rectangle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard !isDisabled, phase != .pressed else { return }
                        withAnimation(EngifySpring.tapDown) {
                            phase = .pressed
                        }
                    }
                    .onEnded { _ in
                        guard !isDisabled else { return }

                        withAnimation(EngifySpring.jellyRelease) {
                            phase = .overshoot
                        }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                            withAnimation(EngifySpring.settle) {
                                phase = .idle
                            }
                        }
                    }
            )
            .onDisappear {
                phase = .idle
            }
    }
}

extension View {
    func engifyJellyPress(isDisabled: Bool = false) -> some View {
        modifier(EngifyJellyPressModifier(isDisabled: isDisabled))
    }
}

enum EngifyFeedbackEvent {
    case successPop
    case tabSwitch
    case errorBuzz
}

@MainActor
final class EngifyFeedback {
    static let shared = EngifyFeedback()

    private enum Keys {
        static let prefix = "engify.settings."
        static let soundEffectsEnabled = prefix + "sound_effects_enabled"
        static let hapticFeedbackEnabled = prefix + "haptic_feedback_enabled"
    }

    private let synthesizer = EngifySoundSynthesizer()

    private init() { }

    func play(_ event: EngifyFeedbackEvent, settings: LearningSettingsManager? = nil) {
        let hapticsEnabled = settings?.hapticFeedbackEnabled ?? storedBool(for: Keys.hapticFeedbackEnabled, default: true)
        let soundEnabled = settings?.soundEffectsEnabled ?? storedBool(for: Keys.soundEffectsEnabled, default: true)

        if hapticsEnabled {
            switch event {
            case .successPop:
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.prepare()
                impact.impactOccurred()
            case .tabSwitch:
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.prepare()
                impact.impactOccurred(intensity: 0.72)
            case .errorBuzz:
                let notification = UINotificationFeedbackGenerator()
                notification.prepare()
                notification.notificationOccurred(.error)
            }
        }

        guard soundEnabled else { return }

        switch event {
        case .successPop:
            synthesizer.playBubblePop()
        case .tabSwitch:
            synthesizer.playMutedTick()
        case .errorBuzz:
            synthesizer.playSoftBuzz()
        }
    }

    private func storedBool(for key: String, default defaultValue: Bool) -> Bool {
        if UserDefaults.standard.object(forKey: key) == nil {
            return defaultValue
        }

        return UserDefaults.standard.bool(forKey: key)
    }
}

private final class EngifySoundSynthesizer {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)
    private var isStarted = false

    init() {
        guard let format else { return }
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 0.58
    }

    func playBubblePop() {
        play(segments: [
            .init(frequency: 920, duration: 0.045, amplitude: 0.18),
            .init(frequency: 1360, duration: 0.08, amplitude: 0.12)
        ])
    }

    func playMutedTick() {
        play(segments: [
            .init(frequency: 620, duration: 0.022, amplitude: 0.08),
            .init(frequency: 410, duration: 0.03, amplitude: 0.04)
        ])
    }

    func playSoftBuzz() {
        play(segments: [
            .init(frequency: 180, duration: 0.04, amplitude: 0.07),
            .init(frequency: 160, duration: 0.045, amplitude: 0.06, silenceAfter: 0.03),
            .init(frequency: 150, duration: 0.06, amplitude: 0.05)
        ])
    }

    private func play(segments: [ToneSegment]) {
        guard let format else { return }

        startIfNeeded()

        let frameCount = segments.reduce(into: AVAudioFrameCount(0)) { count, segment in
            count += AVAudioFrameCount((segment.duration + segment.silenceAfter) * format.sampleRate)
        }

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount

        let sampleRate = format.sampleRate
        let channel = buffer.floatChannelData?[0]
        var frameIndex: AVAudioFrameCount = 0

        for segment in segments {
            let toneFrames = Int(segment.duration * sampleRate)
            let silenceFrames = Int(segment.silenceAfter * sampleRate)

            for i in 0..<toneFrames {
                let progress = Double(i) / Double(max(1, toneFrames - 1))
                let envelope = envelopeValue(progress: progress)
                let t = Double(frameIndex) / sampleRate
                channel?[Int(frameIndex)] = Float(sin(2 * .pi * segment.frequency * t) * segment.amplitude * envelope)
                frameIndex += 1
            }

            if silenceFrames > 0 {
                for _ in 0..<silenceFrames {
                    channel?[Int(frameIndex)] = 0
                    frameIndex += 1
                }
            }
        }

        player.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
        if !player.isPlaying {
            player.play()
        }
    }

    private func startIfNeeded() {
        guard !isStarted else { return }
        do {
            try engine.start()
            isStarted = true
        } catch {
            isStarted = false
        }
    }

    private func envelopeValue(progress: Double) -> Double {
        let attack = min(1, progress / 0.18)
        let release = max(0, 1 - pow(progress, 1.8))
        return attack * release
    }

    private struct ToneSegment {
        let frequency: Double
        let duration: Double
        let amplitude: Double
        var silenceAfter: Double = 0
    }
}
