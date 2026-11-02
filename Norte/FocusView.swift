import SwiftUI

struct FocusView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var timer: FocusTimer
    @EnvironmentObject var router: AppRouter
    @State private var minutes: Int = 0

    private let durationOptions = [2, 10, 25, 50]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    switch timer.phase {
                    case .idle:
                        setupView
                    case .focus, .paused, .rest:
                        runningView
                    case .finished:
                        finishedView
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .background(Theme.background)
            .navigationTitle("Enfoque")
            .onAppear {
                if minutes == 0 { minutes = store.profile.focusMinutes }
                consumePendingRequest()
            }
            .onChange(of: router.pendingFocusMinutes) { _, _ in
                consumePendingRequest()
            }
        }
    }

    private func consumePendingRequest() {
        guard let m = router.pendingFocusMinutes else { return }
        router.pendingFocusMinutes = nil
        if !timer.isActive {
            minutes = m
            timer.start(minutes: m)
        }
    }

    private var durationHint: String {
        switch minutes {
        case 2: return "La regla de los 2 minutos: solo empieza. Si después quieres seguir, sigue."
        case 10: return "Un sprint corto para tareas pequeñas o para calentar."
        case 25: return "El Pomodoro clásico. Suficiente para avanzar sin agotarte."
        default: return "Para trabajo profundo. Asegúrate de no tener interrupciones."
        }
    }

    // MARK: - Configuración

    private var setupView: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "¿En qué vas a enfocarte?", icon: "scope")
                TextField("Ej. Escribir la introducción del ensayo", text: $timer.intention, axis: .vertical)
                    .lineLimit(1...3)
                    .textFieldStyle(.roundedBorder)
                let pending = store.tasks(for: DateKey.today).filter { !$0.isDone }
                if !pending.isEmpty {
                    Menu {
                        ForEach(pending) { task in
                            Button(task.title) {
                                timer.intention = task.title
                                timer.linkedTaskID = task.id
                                timer.linkedGoalID = task.goalID
                            }
                        }
                    } label: {
                        Label("Elegir de mi plan de hoy", systemImage: "checklist")
                            .font(.subheadline.weight(.semibold))
                    }
                }
            }
            .card()

            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Duración", icon: "clock")
                HStack(spacing: 8) {
                    ForEach(durationOptions, id: \.self) { m in
                        Button {
                            minutes = m
                        } label: {
                            Text("\(m) min")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(minutes == m ? Theme.accent : Theme.accent.opacity(0.12))
                                .foregroundStyle(minutes == m ? Color.white : Theme.accent)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                Text(durationHint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .card()

            Button {
                timer.start(minutes: minutes)
                Haptics.tap()
            } label: {
                Label("Empezar", systemImage: "play.fill")
            }
            .buttonStyle(PrimaryButtonStyle())

            HStack(spacing: 12) {
                StatTile(title: "Sesiones hoy", value: "\(store.sessionsToday)", icon: "timer", color: Theme.accent)
                StatTile(title: "Min. hoy", value: "\(store.focusMinutesToday)", icon: "bolt.fill", color: Theme.warning)
                StatTile(title: "Min. semana", value: "\(store.focusMinutesThisWeek)", icon: "calendar", color: Theme.success)
            }

            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "Antes de empezar", icon: "checklist.checked", color: Theme.success)
                Text("• Celular en modo No molestar y fuera de la vista.\n• Define exactamente qué vas a hacer.\n• Si te distraes, vuelve sin juzgarte. Eso también es entrenar.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .card()
        }
    }

    // MARK: - En curso

    private var runningView: some View {
        VStack(spacing: 24) {
            Text(timer.phase == .rest ? "Descanso" : (timer.phase == .paused ? "En pausa" : "Enfoque"))
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.top, 12)
            ZStack {
                ProgressRing(progress: timer.progress,
                             color: timer.phase == .rest ? Theme.success : Theme.accent,
                             lineWidth: 14)
                    .frame(width: 250, height: 250)
                VStack(spacing: 8) {
                    Text(timer.timeText)
                        .font(.system(size: 58, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    if !timer.intention.isEmpty && timer.phase != .rest {
                        Text(timer.intention)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .padding(.horizontal, 36)
                    }
                }
            }
            Text(timer.phase == .rest
                 ? "Levántate, estírate, toma agua. Nada de redes sociales."
                 : "Una sola cosa. Si tu mente se va, tráela de vuelta.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            HStack(spacing: 12) {
                if timer.phase == .focus {
                    Button {
                        timer.pause()
                    } label: {
                        Label("Pausar", systemImage: "pause.fill")
                    }
                    .buttonStyle(PrimaryButtonStyle(color: Theme.warning))
                }
                if timer.phase == .paused {
                    Button {
                        timer.resume()
                    } label: {
                        Label("Continuar", systemImage: "play.fill")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                Button {
                    timer.stop()
                } label: {
                    Label(timer.phase == .rest ? "Saltar" : "Terminar", systemImage: "xmark")
                }
                .buttonStyle(PrimaryButtonStyle(color: .gray))
            }
        }
        .card()
    }

    // MARK: - Completado

    private var finishedView: some View {
        VStack(spacing: 16) {
            Text("🎉")
                .font(.system(size: 64))
            Text("¡Sesión completada!")
                .font(.title.bold())
            Text("\(timer.completedMinutes) minuto(s) de enfoque real. Eso es progreso.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let id = timer.linkedTaskID, let task = store.tasks.first(where: { $0.id == id }), !task.isDone {
                Button {
                    store.toggleTask(id)
                    timer.linkedTaskID = nil
                    Haptics.success()
                } label: {
                    Label("Marcar \"\(task.title)\" como hecha", systemImage: "checkmark.circle")
                }
                .buttonStyle(PrimaryButtonStyle(color: Theme.success))
            }
            if timer.completedMinutes <= 5 {
                Button {
                    minutes = store.profile.focusMinutes
                    timer.start(minutes: store.profile.focusMinutes)
                } label: {
                    Label("¿Agarraste ritmo? Sigue \(store.profile.focusMinutes) min", systemImage: "bolt.fill")
                }
                .buttonStyle(PrimaryButtonStyle(color: Theme.warning))
            } else {
                Button {
                    timer.startRest(minutes: store.profile.breakMinutes)
                } label: {
                    Label("Descanso de \(store.profile.breakMinutes) min", systemImage: "cup.and.saucer.fill")
                }
                .buttonStyle(PrimaryButtonStyle(color: Theme.success))
            }
            Button {
                timer.start(minutes: minutes == 0 ? store.profile.focusMinutes : minutes)
            } label: {
                Label("Otra sesión de \(minutes == 0 ? store.profile.focusMinutes : minutes) min", systemImage: "arrow.clockwise")
            }
            .buttonStyle(PrimaryButtonStyle())
            Button("Terminar por ahora") {
                timer.reset()
            }
            .foregroundStyle(.secondary)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .card()
    }
}
