import SwiftUI

struct HabitsView: View {
    @EnvironmentObject var store: AppStore
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            Group {
                if store.habits.isEmpty {
                    ContentUnavailableView {
                        Label("Sin hábitos aún", systemImage: "repeat")
                    } description: {
                        Text("Un hábito pequeño repetido cada día vale más que un gran esfuerzo ocasional.")
                    } actions: {
                        Button("Crear hábito") { showAdd = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        Section {
                            ForEach(store.habits) { habit in
                                HabitRow(habit: habit)
                            }
                            .onDelete { offsets in
                                store.deleteHabits(at: offsets)
                            }
                        } footer: {
                            Text("Toca el círculo para marcar el día de hoy. Mantén tu racha 🔥")
                        }
                    }
                }
            }
            .navigationTitle("Hábitos")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                AddHabitSheet()
            }
        }
    }
}

struct HabitRow: View {
    @EnvironmentObject var store: AppStore
    let habit: Habit

    private var lastSevenDays: [Date] {
        (0..<7).reversed().compactMap { Calendar.current.date(byAdding: .day, value: -$0, to: Date()) }
    }

    var body: some View {
        let doneToday = habit.isDone(on: Date())
        HStack(spacing: 14) {
            Button {
                withAnimation { store.toggleHabit(habit.id) }
                if !doneToday { Haptics.success() }
            } label: {
                CheckCircle(isOn: doneToday, color: Theme.success)
                    .font(.largeTitle)
            }
            .buttonStyle(.plain)
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: habit.icon)
                        .foregroundStyle(Theme.accent)
                    Text(habit.title)
                        .font(.headline)
                }
                HStack(spacing: 6) {
                    ForEach(lastSevenDays, id: \.self) { day in
                        Circle()
                            .fill(habit.isDone(on: day) ? Theme.success : Color.secondary.opacity(0.2))
                            .frame(width: 10, height: 10)
                    }
                    Spacer()
                    Label("\(habit.currentStreak)", systemImage: "flame.fill")
                        .font(.caption.bold())
                        .foregroundStyle(habit.currentStreak > 0 ? Theme.warning : Color.secondary)
                    if habit.bestStreak > habit.currentStreak {
                        Text("máx \(habit.bestStreak)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                if let g = store.goal(habit.goalID) {
                    Label(g.title, systemImage: g.area.icon)
                        .font(.caption)
                        .foregroundStyle(g.area.color)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddHabitSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var icon = "checkmark.circle.fill"
    @State private var goalID: UUID? = nil

    private let columns = [GridItem(.adaptive(minimum: 48), spacing: 10)]

    var body: some View {
        NavigationStack {
            Form {
                Section("Hábito") {
                    TextField("Ej. Leer 10 páginas", text: $title)
                }
                Section("Ideas") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Habit.suggestions) { s in
                                Button {
                                    title = s.title
                                    icon = s.icon
                                } label: {
                                    Label(s.title, systemImage: s.icon)
                                        .font(.caption.weight(.semibold))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Theme.accent.opacity(0.12))
                                        .foregroundStyle(Theme.accent)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                Section("Ícono") {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(Habit.iconOptions, id: \.self) { name in
                            Button {
                                icon = name
                            } label: {
                                Image(systemName: name)
                                    .font(.title3)
                                    .frame(width: 48, height: 48)
                                    .background(icon == name ? Theme.accent.opacity(0.2) : Theme.card)
                                    .foregroundStyle(icon == name ? Theme.accent : Color.primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
                if !store.goals.filter({ !$0.isCompleted }).isEmpty {
                    Section("Apoya a un objetivo (opcional)") {
                        Picker("Objetivo", selection: $goalID) {
                            Text("Ninguno").tag(UUID?.none)
                            ForEach(store.goals.filter { !$0.isCompleted }) { g in
                                Text(g.title).tag(Optional(g.id))
                            }
                        }
                    }
                }
            }
            .navigationTitle("Nuevo hábito")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Crear") {
                        store.addHabit(Habit(title: title.trimmed, icon: icon, goalID: goalID))
                        Haptics.tap()
                        dismiss()
                    }
                    .disabled(title.trimmed.isEmpty)
                }
            }
        }
    }
}
