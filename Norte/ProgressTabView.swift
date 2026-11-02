import SwiftUI
import Charts

struct ProgressTabView: View {
    @EnvironmentObject var store: AppStore
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    levelCard
                    statsGrid
                    weekChart
                    goalsOverview
                    reflectionsCard
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .background(Theme.background)
            .navigationTitle("Progreso")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .navigationDestination(for: String.self) { route in
                if route == "reflections" {
                    ReflectionsHistoryView()
                }
            }
        }
    }

    private var levelCard: some View {
        let points = store.totalPoints
        let level = LevelInfo.level(for: points)
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Nivel \(level) · \(LevelInfo.title(for: level))")
                        .font(.title3.bold())
                    Text("\(points) puntos acumulados")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Theme.warning)
            }
            ProgressView(value: LevelInfo.progressInLevel(for: points))
                .tint(Theme.accent)
            Text("\(LevelInfo.pointsPerLevel - points % LevelInfo.pointsPerLevel) puntos para el siguiente nivel")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatTile(title: "Días de racha", value: "\(store.activityStreak)", icon: "flame.fill", color: Theme.warning)
            StatTile(title: "Tareas completadas", value: "\(store.tasksDoneTotal)", icon: "checkmark.circle.fill", color: Theme.accent)
            StatTile(title: "Min. de enfoque (7 días)", value: "\(store.focusMinutesThisWeek)", icon: "timer", color: Theme.reflect)
            StatTile(title: "Hábitos cumplidos (7 días)", value: "\(Int(store.habitConsistencyWeek * 100))%", icon: "repeat", color: Theme.success)
        }
    }

    private var weekChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Últimos 7 días", icon: "chart.bar.fill")
            Chart(store.lastSevenDays) { day in
                BarMark(
                    x: .value("Día", day.label),
                    y: .value("Puntos", day.points)
                )
                .foregroundStyle(day.points > 0 ? Theme.accent : Color.secondary.opacity(0.3))
                .cornerRadius(6)
            }
            .frame(height: 170)
            Text("Puntos por tareas, hábitos, minutos de enfoque y reflexiones.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }

    private var goalsOverview: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Objetivos", icon: "flag.fill")
            let active = store.goals.filter { !$0.isCompleted }
            if active.isEmpty {
                Text(store.goals.isEmpty ? "Aún no tienes objetivos." : "¡Todos tus objetivos están completados!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            ForEach(active) { goal in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Label(goal.title, systemImage: goal.area.icon)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                        Spacer()
                        Text("\(Int(goal.progress * 100))%")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    ProgressView(value: goal.progress)
                        .tint(goal.area.color)
                }
            }
            let completedCount = store.goals.filter { $0.isCompleted }.count
            if completedCount > 0 {
                Text("\(completedCount) objetivo(s) completado(s) 🏆")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .card()
    }

    private var reflectionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(title: "Reflexiones", icon: "moon.stars.fill", color: Theme.reflect)
                Spacer()
                if !store.reflections.isEmpty {
                    NavigationLink(value: "reflections") {
                        Text("Ver todas")
                            .font(.subheadline)
                    }
                }
            }
            let recent = Array(store.reflections.sorted { $0.dateKey > $1.dateKey }.prefix(3))
            if recent.isEmpty {
                Text("Tus reflexiones nocturnas aparecerán aquí.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            ForEach(recent) { r in
                ReflectionSummaryRow(reflection: r)
            }
        }
        .card()
    }
}

struct ReflectionSummaryRow: View {
    let reflection: Reflection

    private var dateText: String {
        guard let d = DateKey.date(from: reflection.dateKey) else { return reflection.dateKey }
        return d.spanishShort
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(reflection.moodEmoji)
                .font(.title2)
            VStack(alignment: .leading, spacing: 3) {
                Text(dateText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                if !reflection.wins.isEmpty {
                    Text(reflection.wins)
                        .font(.subheadline)
                        .lineLimit(2)
                }
                if !reflection.blockers.isEmpty {
                    Text("Me frenó: \(reflection.blockers)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
    }
}

struct ReflectionsHistoryView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        List {
            ForEach(store.reflections.sorted { $0.dateKey > $1.dateKey }) { r in
                VStack(alignment: .leading, spacing: 6) {
                    ReflectionSummaryRow(reflection: r)
                    if !r.tomorrowFocus.isEmpty {
                        Text("Siguiente: \(r.tomorrowFocus)")
                            .font(.caption)
                            .foregroundStyle(Theme.accent)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Reflexiones")
    }
}

struct SettingsView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Perfil") {
                    TextField("Tu nombre", text: $store.profile.name)
                }
                Section {
                    Toggle("Recordatorios diarios", isOn: $store.profile.remindersEnabled)
                    if store.profile.remindersEnabled {
                        DatePicker("Mañana (planear el día)", selection: $store.profile.morningTime, displayedComponents: .hourAndMinute)
                        DatePicker("Noche (reflexionar)", selection: $store.profile.eveningTime, displayedComponents: .hourAndMinute)
                    }
                } header: {
                    Text("Recordatorios")
                } footer: {
                    Text("Si no ves notificaciones, revisa Ajustes de iOS › Notificaciones › Norte.")
                }
                Section("Enfoque") {
                    Stepper("Sesión: \(store.profile.focusMinutes) min", value: $store.profile.focusMinutes, in: 5...90, step: 5)
                    Stepper("Descanso: \(store.profile.breakMinutes) min", value: $store.profile.breakMinutes, in: 1...30)
                }
                Section {
                    Button("Borrar todos los datos", role: .destructive) {
                        confirmReset = true
                    }
                }
                Section("Acerca de") {
                    Text("Norte 1.0. Tu brújula para crecer, cumplir objetivos y dejar de procrastinar. Tus datos se guardan solo en este dispositivo.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Ajustes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") { dismiss() }
                }
            }
            .confirmationDialog("¿Borrar objetivos, hábitos, tareas y reflexiones?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Borrar todo", role: .destructive) {
                    store.resetAll()
                }
                Button("Cancelar", role: .cancel) {}
            }
            .onChange(of: store.profile.remindersEnabled) { _, _ in syncReminders() }
            .onChange(of: store.profile.morningTime) { _, _ in syncReminders() }
            .onChange(of: store.profile.eveningTime) { _, _ in syncReminders() }
            .onChange(of: store.profile.name) { _, _ in syncReminders() }
        }
    }

    private func syncReminders() {
        let profile = store.profile
        Task {
            if profile.remindersEnabled {
                _ = await NotificationManager.requestAuthorization()
            }
            NotificationManager.scheduleDailyReminders(for: profile)
        }
    }
}
