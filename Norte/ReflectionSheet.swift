import SwiftUI

struct ReflectionSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    let dateKey: String

    @State private var mood = 3
    @State private var wins = ""
    @State private var blockers = ""
    @State private var tomorrow = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("¿Cómo te sentiste hoy?") {
                    HStack {
                        ForEach(1...5, id: \.self) { m in
                            Button {
                                mood = m
                                Haptics.tap()
                            } label: {
                                Text(Reflection.emoji(for: m))
                                    .font(.largeTitle)
                                    .padding(6)
                                    .background(mood == m ? Theme.accent.opacity(0.2) : Color.clear)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            if m < 5 { Spacer() }
                        }
                    }
                }
                Section("¿Qué logré hoy?") {
                    TextField("Hasta lo pequeño cuenta", text: $wins, axis: .vertical)
                        .lineLimit(3...6)
                }
                Section("¿Qué me frenó o me distrajo?") {
                    TextField("Sé honesto, sin juzgarte", text: $blockers, axis: .vertical)
                        .lineLimit(3...6)
                }
                Section {
                    TextField("Una sola cosa", text: $tomorrow, axis: .vertical)
                        .lineLimit(2...4)
                } header: {
                    Text("Mañana, lo más importante es…")
                } footer: {
                    Text("Se agregará como tu rana de mañana.")
                }
            }
            .navigationTitle("Reflexión")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { save() }
                }
            }
            .onAppear {
                if let r = store.reflection(for: dateKey) {
                    mood = r.mood
                    wins = r.wins
                    blockers = r.blockers
                    tomorrow = r.tomorrowFocus
                }
            }
        }
    }

    private func save() {
        let reflection = Reflection(dateKey: dateKey, mood: mood, wins: wins.trimmed,
                                    blockers: blockers.trimmed, tomorrowFocus: tomorrow.trimmed)
        store.saveReflection(reflection)
        let focus = tomorrow.trimmed
        if !focus.isEmpty, dateKey == DateKey.today {
            let tomorrowKey = DateKey.tomorrow
            let exists = store.tasks.contains { $0.dateKey == tomorrowKey && $0.title == focus }
            if !exists {
                store.addTask(title: focus, dateKey: tomorrowKey, isFrog: true)
            }
        }
        Haptics.success()
        dismiss()
    }
}
