import AVFoundation
import Combine
import Foundation

@MainActor
final class TonePlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published private(set) var activeInstrumentID: String?
    @Published private(set) var statusMessage: String?

    private var audioPlayer: AVAudioPlayer?

    func play(instrument: Instrument) {
        stop()

        guard AudioSourceCatalog.approvedSource(for: instrument) != nil else {
            statusMessage = "\(instrument.nameZh) 尚未通過實器錄音來源審核，暫不播放舊版合成音檔。"
            return
        }

        guard playBundledSample(for: instrument) else {
            activeInstrumentID = nil
            statusMessage = "找不到 \(instrument.nameZh) 的已核准離線音檔。"
            return
        }
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        activeInstrumentID = nil
        statusMessage = nil
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
            statusMessage = nil
            return true
        } catch {
            activeInstrumentID = nil
            audioPlayer = nil
            statusMessage = "\(instrument.nameZh) 音檔無法播放，請重新檢查來源與格式。"
            return false
        }
    }
}
