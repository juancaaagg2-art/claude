import Foundation
import UIKit

@MainActor
final class FocusTimer: ObservableObject {
    enum Phase: Equatable {
        case idle, focus, paused, rest, finished
    }

    @Published var phase: Phase = .idle
    @Published var remaining: TimeInterval = 0
    @Published var total: TimeInterval = 0
    @Published var intention: String = ""
    @Published var linkedTaskID: UUID? = nil
    @Published var linkedGoalID: UUID? = nil
    @Published var completedMinutes: Int = 0

    var onFinish: ((FocusSession) -> Void)?

    private var endDate: Date?
    private var startDate: Date?
    private var timer: Timer?
    private var pausedRemaining: TimeInterval = 0
    private var currentMinutes: Int = 0

    var progress: Double { total > 0 ? min(1, max(0, 1 - remaining / total)) : 0 }
    var isActive: Bool { phase == .focus || phase == .paused || phase == .rest }

    var timeText: String {
        let s = Int(remaining.rounded(.up))
        return String(format: "%02d:%02d", s / 60, s % 60)
    }

    func start(minutes: Int) {
        currentMinutes = minutes
        total = TimeInterval(minutes * 60)
        remaining = total
        startDate = Date()
        endDate = Date().addingTimeInterval(total)
        phase = .focus
        UIApplication.shared.isIdleTimerDisabled = true
        let body = intention.isEmpty ? "Buen trabajo. Tómate un descanso." : "Terminaste: \(intention). Tómate un descanso."
        NotificationManager.scheduleFocusEnd(after: total, title: "¡Sesión de enfoque completada!", body: body)
        schedule()
    }

    func startRest(minutes: Int) {
        total = TimeInterval(minutes * 60)
        remaining = total
        endDate = Date().addingTimeInterval(total)
        phase = .rest
        NotificationManager.scheduleFocusEnd(after: total, title: "Fin del descanso", body: "¿Listo para otra sesión de enfoque?")
        schedule()
    }

    func pause() {
        guard phase == .focus else { return }
        pausedRemaining = remaining
        timer?.invalidate()
        phase = .paused
        NotificationManager.cancelFocusEnd()
    }

    func resume() {
        guard phase == .paused else { return }
        endDate = Date().addingTimeInterval(pausedRemaining)
        phase = .focus
        NotificationManager.scheduleFocusEnd(after: pausedRemaining, title: "¡Sesión de enfoque completada!", body: "Buen trabajo. Tómate un descanso.")
        schedule()
    }

    func stop() {
        timer?.invalidate()
        NotificationManager.cancelFocusEnd()
        UIApplication.shared.isIdleTimerDisabled = false
        phase = .idle
        remaining = 0
        total = 0
    }

    func reset() {
        stop()
        intention = ""
        linkedTaskID = nil
        linkedGoalID = nil
        completedMinutes = 0
    }

    private func schedule() {
        timer?.invalidate()
        let t = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
        tick()
    }

    private func tick() {
        guard let endDate = endDate, phase == .focus || phase == .rest else { return }
        remaining = max(0, endDate.timeIntervalSinceNow)
        if remaining <= 0 {
            complete()
        }
    }

    private func complete() {
        timer?.invalidate()
        UIApplication.shared.isIdleTimerDisabled = false
        Haptics.success()
        if phase == .focus {
            completedMinutes = currentMinutes
            let session = FocusSession(startedAt: startDate ?? Date(), minutes: currentMinutes,
                                       intention: intention, goalID: linkedGoalID)
            onFinish?(session)
            phase = .finished
        } else {
            phase = .idle
        }
    }
}
