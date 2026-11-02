import SwiftUI

struct GoalsView: View {
    @EnvironmentObject var store: AppStore
    @State private var showEditor = false

    private var active: [Goal] { store.goals.filter { !$0.isCompleted } }
    private var completed: [Goal] { store.goals.filter { $0.isCompleted } }

    var body: some View {
        NavigationStack {
            Group {
                if store.goals.isEmpty {
                    ContentUnavailableView {
                        Label("Sin objetivos aún", systemImage: "flag")
                    } description: {
                        Text("Define qué quieres lograr y por qué. Luego divídelo en pasos pequeños.")
                    } actions: {
                        Button("Crear mi primer objetivo") { showEditor = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        if !active.isEmpty {
                            Section("En progreso") {
                                ForEach(active) { goal in
                                    NavigationLink(value: goal.id) {
                                        GoalRow(goal: goal)
                                    }
                                }
                            }
                        }
                        if !completed.isEmpty {
                            Section("Completados") {
                                ForEach(completed) { goal in
                                    NavigationLink(value: goal.id) {
                                        GoalRow(goal: goal)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Objetivos")
            .navigationDestination(for: UUID.self) { id in
                GoalDetailView(goalID: id)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showEditor) {
                GoalEditorView(goal: nil)
            }
        }
    }
}

struct GoalRow: View {
    let goal: Goal

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(goal.area.color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: goal.area.icon)
                    .foregroundStyle(goal.area.color)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(goal.title)
                    .font(.headline)
                if goal.isCompleted {
                    Text("¡Completado!")
                        .font(.caption)
                        .foregroundStyle(Theme.success)
                } else if let next = goal.nextMilestone {
                    Text("Siguiente: \(next.title)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    Text("Agrega pasos para avanzar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let d = goal.daysLeft, !goal.isCompleted {
                    Text(deadlineText(d))
                        .font(.caption2)
                        .foregroundStyle(d < 0 ? Color.red : Color.secondary)
                }
            }
            Spacer()
            ZStack {
                ProgressRing(progress: goal.progress, color: goal.area.color, lineWidth: 5)
                    .frame(width: 42, height: 42)
                Text("\(Int(goal.progress * 100))%")
                    .font(.caption2.bold())
            }
        }
        .padding(.vertical, 4)
    }

    private func deadlineText(_ d: Int) -> String {
        if d == 0 { return "Vence hoy" }
        if d < 0 { return "Venció hace \(-d) día(s)" }
        return "Faltan \(d) día(s)"
    }
}

struct GoalDetailView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    let goalID: UUID

    @State private var newStep = ""
    @State private var showEditor = false
    @State private var confirmDelete = false

    private var goal: Goal? { store.goal(goalID) }

    var body: some View {
        if let goal = goal {
            List {
                Section {
                    VStack(spacing: 12) {
                        ZStack {
                            ProgressRing(progress: goal.progress, color: goal.area.color, lineWidth: 10)
                                .frame(width: 120, height: 120)
                            VStack(spacing: 2) {
                                Text("\(Int(goal.progress * 100))%")
                                    .font(.title.bold())
                                Text("\(goal.doneCount)/\(goal.milestones.count) pasos")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Label(goal.area.title, systemImage: goal.area.icon)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(goal.area.color)
                        if let deadline = goal.deadline, let d = goal.daysLeft {
                            Text("Fecha límite: \(deadline.spanishShort) · \(d >= 0 ? "faltan \(d) día(s)" : "venció hace \(-d) día(s)")")
                                .font(.caption)
                                .foregroundStyle(d < 0 ? Color.red : Color.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }

                if !goal.why.isEmpty {
                    Section("Tu porqué") {
                        Text(goal.why)
                            .italic()
                    }
                }

                Section {
                    ForEach(goal.milestones) { m in
                        Button {
                            withAnimation { store.toggleMilestone(goalID: goal.id, milestoneID: m.id) }
                            if !m.isDone { Haptics.success() }
                        } label: {
                            HStack(spacing: 12) {
                                CheckCircle(isOn: m.isDone, color: goal.area.color)
                                Text(m.title)
                                    .strikethrough(m.isDone)
                                    .foregroundStyle(m.isDone ? Color.secondary : Color.primary)
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete { offsets in
                        store.deleteMilestones(goalID: goal.id, at: offsets)
                    }
                    HStack(spacing: 10) {
                        Image(systemName: "plus.circle")
                            .foregroundStyle(goal.area.color)
                        TextField("Nuevo paso pequeño", text: $newStep)
                            .submitLabel(.done)
                            .onSubmit {
                                store.addMilestone(goalID: goal.id, title: newStep)
                                newStep = ""
                            }
                    }
                } header: {
                    Text("Pasos")
                } footer: {
                    Text("Pasos concretos que puedas terminar en una sesión. Desliza para eliminar.")
                }

                Section {
                    if let next = goal.nextMilestone, !goal.isCompleted {
                        let alreadyToday = store.tasks(for: DateKey.today).contains { $0.milestoneID == next.id }
                        Button {
                            store.addTask(title: next.title, goalID: goal.id, milestoneID: next.id)
                            Haptics.tap()
                        } label: {
                            Label(alreadyToday ? "\"\(next.title)\" ya está en tu plan de hoy" : "Agregar \"\(next.title)\" al plan de hoy",
                                  systemImage: "sun.max")
                        }
                        .disabled(alreadyToday)
                    }
                    Button {
                        withAnimation { store.setGoalCompleted(goal.id, !goal.isCompleted) }
                        if !goal.isCompleted { Haptics.success() }
                    } label: {
                        Label(goal.isCompleted ? "Reabrir objetivo" : "Marcar como completado",
                              systemImage: goal.isCompleted ? "arrow.uturn.backward" : "checkmark.seal.fill")
                    }
                    Button(role: .destructive) {
                        confirmDelete = true
                    } label: {
                        Label("Eliminar objetivo", systemImage: "trash")
                    }
                }
            }
            .navigationTitle(goal.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Editar") { showEditor = true }
                }
            }
            .sheet(isPresented: $showEditor) {
                GoalEditorView(goal: goal)
            }
            .confirmationDialog("¿Eliminar este objetivo?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Eliminar", role: .destructive) {
                    store.deleteGoal(goal.id)
                    dismiss()
                }
                Button("Cancelar", role: .cancel) {}
            }
        } else {
            ContentUnavailableView("Objetivo no encontrado", systemImage: "flag.slash")
        }
    }
}

struct GoalEditorView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    private let existing: Goal?
    @State private var title: String
    @State private var why: String
    @State private var area: GoalArea
    @State private var hasDeadline: Bool
    @State private var deadline: Date
    @State private var milestones: [Milestone]
    @State private var newStep = ""

    init(goal: Goal?) {
        existing = goal
        _title = State(initialValue: goal?.title ?? "")
        _why = State(initialValue: goal?.why ?? "")
        _area = State(initialValue: goal?.area ?? .otro)
        _hasDeadline = State(initialValue: goal?.deadline != nil)
        let defaultDeadline = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
        _deadline = State(initialValue: goal?.deadline ?? defaultDeadline)
        _milestones = State(initialValue: goal?.milestones ?? [])
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Objetivo") {
                    TextField("¿Qué quieres lograr?", text: $title)
                    Picker("Área", selection: $area) {
                        ForEach(GoalArea.allCases) { a in
                            Label(a.title, systemImage: a.icon).tag(a)
                        }
                    }
                }
                Section {
                    TextField("Esto te sostendrá cuando no tengas ganas", text: $why, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("¿Por qué te importa?")
                }
                Section("Fecha límite") {
                    Toggle("Tiene fecha límite", isOn: $hasDeadline)
                    if hasDeadline {
                        DatePicker("Fecha", selection: $deadline, displayedComponents: .date)
                    }
                }
                Section {
                    ForEach(milestones) { m in
                        Text(m.title)
                    }
                    .onDelete { offsets in
                        milestones.remove(atOffsets: offsets)
                    }
                    HStack {
                        TextField("Agregar paso", text: $newStep)
                            .submitLabel(.done)
                            .onSubmit { addStep() }
                        Button {
                            addStep()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                        .disabled(newStep.trimmed.isEmpty)
                    }
                } header: {
                    Text("Pasos pequeños")
                } footer: {
                    Text("Divide el objetivo en pasos concretos. Ej: \"Leer el capítulo 1\", \"Correr 10 minutos\".")
                }
            }
            .navigationTitle(existing == nil ? "Nuevo objetivo" : "Editar objetivo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { save() }
                        .disabled(title.trimmed.isEmpty)
                }
            }
        }
    }

    private func addStep() {
        let clean = newStep.trimmed
        guard !clean.isEmpty else { return }
        milestones.append(Milestone(title: clean))
        newStep = ""
    }

    private func save() {
        var goal = existing ?? Goal(title: "")
        goal.title = title.trimmed
        goal.why = why.trimmed
        goal.area = area
        goal.deadline = hasDeadline ? deadline : nil
        goal.milestones = milestones
        if existing == nil {
            store.addGoal(goal)
        } else {
            store.updateGoal(goal)
        }
        Haptics.tap()
        dismiss()
    }
}
