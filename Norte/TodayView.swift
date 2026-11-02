import SwiftUI

struct TodayView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var router: AppRouter
    @State private var showAddTask = false
    @State private var addAsFrog = false
    @State private var showReflection = false
    @State private var quickTask = ""

    private var todayKey: String { DateKey.today }
    private var todayTasks: [DailyTask] { store.tasks(for: todayKey) }
    private var frog: DailyTask? { todayTasks.first { $0.isFrog } }
    private var otherTasks: [DailyTask] { todayTasks.filter { !$0.isFrog } }
    private var doneCount: Int { todayTasks.filter { $0.isDone }.count }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    header
                    if !store.overdueTasks.isEmpty {
                        overdueCard
                    }
                    frogCard
                    tasksCard
                    habitsCard
                    focusCard
                    reflectionCard
                    tipCard
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .background(Theme.background)
            .navigationTitle("Hoy")
            .sheet(isPresented: $showAddTask) {
                AddTaskSheet(isFrog: addAsFrog)
            }
            .sheet(isPresented: $showReflection) {
                ReflectionSheet(dateKey: todayKey)
            }
        }
    }

    // MARK: - Secciones

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let base: String
        if hour < 12 {
            base = "Buenos días"
        } else if hour < 19 {
            base = "Buenas tardes"
        } else {
            base = "Buenas noches"
        }
        return store.profile.name.isEmpty ? base : "\(base), \(store.profile.name)"
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(greeting)
                .font(.title2.bold())
            Text(Date().spanishLong)
                .foregroundStyle(.secondary)
            HStack {
                Label("\(store.activityStreak) días de racha", systemImage: "flame.fill")
                    .foregroundStyle(Theme.warning)
                Spacer()
                Label("Nivel \(LevelInfo.level(for: store.totalPoints))", systemImage: "star.fill")
                    .foregroundStyle(Theme.accent)
            }
            .font(.subheadline.weight(.semibold))
            .padding(.top, 4)
        }
        .card()
    }

    private var overdueCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Pendientes de días anteriores", icon: "clock.arrow.circlepath", color: Theme.warning)
            Text("Tienes \(store.overdueTasks.count) tarea(s) sin terminar. ¿Las mueves a hoy o las dejas ir?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(spacing: 12) {
                Button("Mover a hoy") { withAnimation { store.moveOverdueToToday() } }
                    .buttonStyle(PrimaryButtonStyle(color: Theme.warning))
                Button("Descartar") { withAnimation { store.discardOverdue() } }
                    .buttonStyle(PrimaryButtonStyle(color: .gray))
            }
        }
        .card()
    }

    private var frogCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("🐸")
                Text("Tu rana de hoy")
                    .font(.headline)
            }
            if let frog = frog {
                TaskRow(task: frog, accent: Theme.frog)
            } else {
                Text("La tarea más importante del día (y probablemente la que más pereza te da). Hazla primero y el resto del día será cuesta abajo.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button {
                    addAsFrog = true
                    showAddTask = true
                } label: {
                    Label("Elegir mi rana", systemImage: "plus")
                }
                .buttonStyle(PrimaryButtonStyle(color: Theme.frog))
                suggestionsView
            }
        }
        .card()
    }

    private var suggestions: [MilestoneSuggestion] {
        let linked = Set(todayTasks.compactMap { $0.milestoneID })
        var items: [MilestoneSuggestion] = []
        for g in store.goals where !g.isCompleted {
            if let m = g.nextMilestone, !linked.contains(m.id) {
                items.append(MilestoneSuggestion(goal: g, milestone: m))
            }
        }
        return Array(items.prefix(3))
    }

    @ViewBuilder
    private var suggestionsView: some View {
        let items = suggestions
        if !items.isEmpty {
            Text("Siguientes pasos de tus objetivos")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.top, 4)
            ForEach(items) { item in
                Button {
                    withAnimation {
                        store.addTask(title: item.milestone.title, goalID: item.goal.id,
                                      milestoneID: item.milestone.id, isFrog: frog == nil)
                    }
                    Haptics.tap()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(item.goal.area.color)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.milestone.title)
                                .foregroundStyle(.primary)
                            Text(item.goal.title)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var tasksCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(title: "Plan de hoy", icon: "checklist")
                Spacer()
                Text("\(doneCount)/\(todayTasks.count)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            if todayTasks.isEmpty {
                Text("Máximo 3 tareas importantes. Menos es más.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            ForEach(otherTasks) { task in
                TaskRow(task: task)
            }
            HStack(spacing: 10) {
                Image(systemName: "plus.circle")
                    .foregroundStyle(Theme.accent)
                TextField("Agregar tarea para hoy", text: $quickTask)
                    .submitLabel(.done)
                    .onSubmit {
                        withAnimation { store.addTask(title: quickTask) }
                        quickTask = ""
                    }
            }
            Button {
                addAsFrog = false
                showAddTask = true
            } label: {
                Label("Agregar desde un objetivo", systemImage: "flag")
                    .font(.subheadline.weight(.semibold))
            }
        }
        .card()
    }

    private var habitsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(title: "Hábitos de hoy", icon: "repeat", color: Theme.success)
                Spacer()
                Text("\(store.habitsDone(on: todayKey))/\(store.habits.count)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            if store.habits.isEmpty {
                Text("Los hábitos pequeños y diarios construyen tus objetivos grandes.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button("Crear mi primer hábito") { router.tab = .habits }
                    .font(.subheadline.weight(.semibold))
            }
            ForEach(store.habits) { habit in
                HabitTodayRow(habit: habit)
            }
        }
        .card()
    }

    private var focusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "¿Procrastinando?", icon: "timer", color: Theme.warning)
            Text("Empezar es lo más difícil. Comprométete con solo 2 minutos, o haz una sesión completa de enfoque.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(spacing: 12) {
                Button {
                    router.goToFocus(minutes: 2)
                } label: {
                    Label("Solo 2 min", systemImage: "bolt.fill")
                }
                .buttonStyle(PrimaryButtonStyle(color: Theme.warning))
                Button {
                    router.goToFocus(minutes: store.profile.focusMinutes)
                } label: {
                    Label("\(store.profile.focusMinutes) min", systemImage: "timer")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            if store.focusMinutesToday > 0 {
                Text("Hoy llevas \(store.focusMinutesToday) min de enfoque en \(store.sessionsToday) sesión(es).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .card()
    }

    private var reflectionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Cierre del día", icon: "moon.stars.fill", color: Theme.reflect)
            if let r = store.reflection(for: todayKey) {
                HStack(spacing: 12) {
                    Text(r.moodEmoji)
                        .font(.title)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Reflexión guardada")
                            .font(.subheadline.weight(.semibold))
                        if !r.wins.isEmpty {
                            Text(r.wins)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                    Spacer()
                    Button("Editar") { showReflection = true }
                        .font(.subheadline)
                }
            } else {
                Text("2 minutos para revisar qué funcionó, qué te frenó y qué harás mañana.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button {
                    showReflection = true
                } label: {
                    Label("Reflexionar", systemImage: "pencil.line")
                }
                .buttonStyle(PrimaryButtonStyle(color: Theme.reflect))
            }
        }
        .card()
    }

    private var tipCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(Theme.warning)
            VStack(alignment: .leading, spacing: 4) {
                Text("Consejo de hoy")
                    .font(.subheadline.weight(.semibold))
                Text(Tips.today)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .card()
    }
}

// MARK: - Filas

struct TaskRow: View {
    @EnvironmentObject var store: AppStore
    let task: DailyTask
    var accent: Color = Theme.accent

    var body: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation { store.toggleTask(task.id) }
                if !task.isDone { Haptics.success() }
            } label: {
                CheckCircle(isOn: task.isDone, color: accent)
            }
            .buttonStyle(.plain)
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .strikethrough(task.isDone)
                    .foregroundStyle(task.isDone ? Color.secondary : Color.primary)
                if let g = store.goal(task.goalID) {
                    Label(g.title, systemImage: g.area.icon)
                        .font(.caption)
                        .foregroundStyle(g.area.color)
                }
            }
            Spacer()
        }
        .contentShape(Rectangle())
        .contextMenu {
            if !task.isFrog {
                Button {
                    withAnimation { store.setFrog(task.id) }
                } label: {
                    Label("Hacerla mi rana", systemImage: "star")
                }
            }
            Button(role: .destructive) {
                withAnimation { store.deleteTask(task.id) }
            } label: {
                Label("Eliminar", systemImage: "trash")
            }
        }
    }
}

struct HabitTodayRow: View {
    @EnvironmentObject var store: AppStore
    let habit: Habit

    var body: some View {
        let done = habit.isDone(on: Date())
        HStack(spacing: 12) {
            Button {
                withAnimation { store.toggleHabit(habit.id) }
                if !done { Haptics.success() }
            } label: {
                CheckCircle(isOn: done, color: Theme.success)
            }
            .buttonStyle(.plain)
            Image(systemName: habit.icon)
                .foregroundStyle(Theme.success)
                .frame(width: 22)
            Text(habit.title)
                .strikethrough(done)
                .foregroundStyle(done ? Color.secondary : Color.primary)
            Spacer()
            if habit.currentStreak > 0 {
                Label("\(habit.currentStreak)", systemImage: "flame.fill")
                    .font(.caption.bold())
                    .foregroundStyle(Theme.warning)
            }
        }
    }
}

// MARK: - Agregar tarea

struct AddTaskSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var isFrog: Bool
    @State private var title = ""
    @State private var goalID: UUID? = nil
    @State private var milestoneID: UUID? = nil

    init(isFrog: Bool) {
        _isFrog = State(initialValue: isFrog)
    }

    private var selectedGoal: Goal? { store.goal(goalID) }
    private var pendingMilestones: [Milestone] {
        selectedGoal?.milestones.filter { !$0.isDone } ?? []
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("¿Qué vas a hacer?", text: $title)
                    Toggle(isOn: $isFrog) {
                        Label("Es mi rana (la más importante)", systemImage: "star.fill")
                    }
                }
                Section("Vincular a un objetivo (opcional)") {
                    Picker("Objetivo", selection: $goalID) {
                        Text("Ninguno").tag(UUID?.none)
                        ForEach(store.goals.filter { !$0.isCompleted }) { g in
                            Text(g.title).tag(Optional(g.id))
                        }
                    }
                    if !pendingMilestones.isEmpty {
                        Picker("Paso", selection: $milestoneID) {
                            Text("Ninguno").tag(UUID?.none)
                            ForEach(pendingMilestones) { m in
                                Text(m.title).tag(Optional(m.id))
                            }
                        }
                    }
                }
            }
            .navigationTitle(isFrog ? "Elegir mi rana" : "Nueva tarea")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Agregar") { save() }
                        .disabled(title.trimmed.isEmpty)
                }
            }
            .onChange(of: goalID) { _, _ in
                milestoneID = nil
            }
            .onChange(of: milestoneID) { _, newValue in
                if title.trimmed.isEmpty, let m = pendingMilestones.first(where: { $0.id == newValue }) {
                    title = m.title
                }
            }
        }
    }

    private func save() {
        store.addTask(title: title, goalID: goalID, milestoneID: milestoneID, isFrog: isFrog)
        Haptics.tap()
        dismiss()
    }
}
