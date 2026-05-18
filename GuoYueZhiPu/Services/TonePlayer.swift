import AVFoundation
import Combine
import Foundation

@MainActor
final class TonePlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published private(set) var activeInstrumentID: String?

    private let sampleRate = 44_100.0
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format: AVAudioFormat
    private var audioPlayer: AVAudioPlayer?

    override init() {
        format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        super.init()
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
    }

    func play(instrument: Instrument) {
        stop()

        if playBundledSample(for: instrument) {
            return
        }

        activeInstrumentID = instrument.id

        let duration = 1.4
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let channels = buffer.floatChannelData else {
            activeInstrumentID = nil
            return
        }

        buffer.frameLength = frameCount
        let output = channels[0]

        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let phase = 2.0 * Double.pi * instrument.pitchFrequencyHz * t
            let rawSample = sample(for: instrument.audioWaveformType, phase: phase)
            let envelope = envelope(at: t, duration: duration)
            output[frame] = Float(rawSample * envelope * 0.28)
        }

        do {
            if !engine.isRunning {
                try engine.start()
            }

            player.scheduleBuffer(buffer, at: nil, options: .interrupts) { [weak self] in
                Task { @MainActor in
                    self?.activeInstrumentID = nil
                }
            }
            player.play()
        } catch {
            activeInstrumentID = nil
        }
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        player.stop()
        activeInstrumentID = nil
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            activeInstrumentID = nil
            audioPlayer = nil
        }
    }

    private func playBundledSample(for instrument: Instrument) -> Bool {
        guard let url = Bundle.main.url(
            forResource: instrument.audioFileName,
            withExtension: "wav",
            subdirectory: "Audio/Instruments"
        ) else {
            return false
        }

        do {
            activeInstrumentID = instrument.id
            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.prepareToPlay()
            player.play()
            audioPlayer = player
            return true
        } catch {
            activeInstrumentID = nil
            audioPlayer = nil
            return false
        }
    }

    private func sample(for waveform: String, phase: Double) -> Double {
        switch waveform {
        case "sawtooth":
            let normalized = phase / (2.0 * Double.pi)
            return 2.0 * (normalized - floor(normalized + 0.5))
        case "triangle":
            return 2.0 * abs(2.0 * (phase / (2.0 * Double.pi) - floor(phase / (2.0 * Double.pi) + 0.5))) - 1.0
        case "square":
            return sin(phase) >= 0 ? 1.0 : -1.0
        case "metallic":
            return 0.58 * sin(phase) + 0.28 * sin(phase * 2.7) + 0.14 * sin(phase * 5.2)
        case "noise":
            return Double.random(in: -1.0...1.0)
        default:
            return sin(phase)
        }
    }

    private func envelope(at time: Double, duration: Double) -> Double {
        let attack = min(time / 0.04, 1.0)
        let release = min((duration - time) / 0.35, 1.0)
        return max(0.0, min(attack, release))
    }
}
