import AVFoundation

/// Centralized Text-to-Speech service using AVSpeechSynthesizer.
/// Coordinates playback rate (speed) and pronunciation model (US, UK, AU accents).
final class TTSService {
    static let shared = TTSService()
    private let synthesizer = AVSpeechSynthesizer()

    private init() {}

    /// Speaks the given text utilizing user settings for speed and accent model.
    func speak(text: String, speed: String, model: String) {
        // Stop any active speech before starting a new one
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)

        // Map speed settings: standard rate is 0.5
        switch speed {
        case "slow":
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.75
        case "fast":
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 1.25
        default:
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        }

        // Map pronunciation model to matching BCP-47 language codes
        let languageCode: String
        switch model {
        case "uk_english":
            languageCode = "en-GB"
        case "australian":
            languageCode = "en-AU"
        default:
            languageCode = "en-US"
        }

        if let voice = AVSpeechSynthesisVoice(language: languageCode) {
            utterance.voice = voice
        }

        synthesizer.speak(utterance)
    }

    /// Stops any ongoing speech immediately.
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
}
