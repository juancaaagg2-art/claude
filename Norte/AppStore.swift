import Foundation
import Combine

final class AppStore: ObservableObject {
    @Published var profile = UserProfile()
    @Published var goals: [Goal] = []
    @Published var habits: [Habit] = []
    @Published var tasks: [DailyTask] = []
    @Published var reflections: [Reflection] = []
    @Published var sessions: [FocusSession] = []

    private struct Snapshot: Codable {
        var profile: UserProfile
        var goals: [Goal]
        var habits: [Habit]
        var tasks: [DailyTask]
        var reflections: [Reflection]
        var sessions: [FocusSession]
    }

    private let fileURL: URL
    private var cancellables = Set<AnyCancellable>()

    init() {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        fileURL = dir.appendingPathComponent("norte-data.json")
        load()
        objectWillChange
            .debounce(for: .milliseconds(400), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.save() }
            .store(in: &cancellables)
    }

    // MARK: - Persistencia

    func save() {
        let snapshot = Snapshot(profile: profile, goals: goals, habits: habits,
                                tasks: tasks, reflections: reflections, sessions: sessions)
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(snapshot)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            print("Norte: error al guardar: \(error)")
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let snapshot = try? decoder.decode(Snapshot.self, from: data) else { return }
        profile = snapshot.profile
        goals = snapshot.goals
        habits = snapshot.habits
        tasks = snapshot.tasks
        reflections = snapshot.reflections
        sessions = snapshot.sessions
    }

    func resetAll() {
        let name = profile.name
        profile = UserProfile()
        profile.name = name
        profile.hasOnboarded = true
        goals = []
        habits = []
        tasks = []
        reflections = []
        sessions = []
        save()
    }

    // MARK: - Objetivos

    func goal(_ id: UUID?) -> Goal? {
        guard let id = id else { return nil }
        return goals.first { $0.id == id }
    }

    func addGoal(_ goal: Goal) {
        goals.insert(goal, at: 0)
    }

    func updateGoal(_ goal: Goal) {
        guard let i = goals.firstIndex(where: { $0.id == goal.id }) else { return }
        goals[i] = goal
    }

    func deleteGoal(_ id: UUID) {
        goals.removeAll { $0.id == id }
        for i in habits.indices where habits[i].goalID == id {
            habits[i].goalID = nil
        }
        for i in tasks.indices where tasks[i].goalID == id {
            tasks[i].goalID = nil
            tasks[i].milestoneID = nil
        }
    }

    func setGoalCompleted(_ id: UUID, _ completed: Bool) {
        guard let i = goals.firstIndex(where: { $0.id == id }) else { return }
        goals[i].completedAt = completed ? Date() : nil
    }

    func addMilestone(goalID: UUID, title: String) {
        let clean = title.trimmed
        guard !clean.isEmpty, let i = goals.firstIndex(where: { $0.id == goalID }) else { return }
        goals[i].milestones.append(Milestone(title: clean))
    }

    func deleteMilestones(goalID: UUID, at offsets: IndexSet) {
        guard let i = goals.firstIndex(where: { $0.id == goalID }) else { return }
        let removed = offsets.map { goals[i].milestones[$0].id }
        goals[i].milestones.remove(atOffsets: offsets)
        for t in tasks.indices {
            if let m = tasks[t].milestoneID, removed.contains(m) {
                tasks[t].milestoneID = nil
            }
        }
    }

    func toggleMilestone(goalID: UUID, milestoneID: UUID) {
        guard let g = goals.firstIndex(where: { $0.id == goalID }),
              let m = goals[g].milestones.firstIndex(where: { $0.id == milestoneID }) else { return }
        let done = !goals[g].milestones[m].isDone
        goals[g].milestones[m].isDone = done
        goals[g].milestones[m].doneAt = done ? Date() : nil
        for i in tasks.indices where tasks[i].milestoneID == milestoneID {
            tasks[i].isDone = done
            tasks[i].doneAt = done ? Date() : nil
        }
    }

    // MARK: - Hábitos

    func addHabit(_ habit: Habit) {
        habits.append(habit)
    }

    func deleteHabit(_ id: UUID) {
        habits.removeAll { $0.id == id }
    }

    func deleteHabits(at offsets: IndexSet) {
        habits.remove(atOffsets: offsets)
    }

    func toggleHabit(_ id: UUID, on date: Date = Date()) {
        guard let i = habits.firstIndex(where: { $0.id == id }) else { return }
        let key = DateKey.key(for: date)
        if habits[i].completions.contains(key) {
            habits[i].completions.remove(key)
        } else {
            habits[i].completions.insert(key)
        }
    }

    func habitsDone(on key: String) -> Int {
        habits.filter { $0.completions.contains(key) }.count
    }

    // MARK: - Plan diario

    func tasks(for key: String) -> [DailyTask] {
        let dayTasks = tasks.filter { $0.dateKey == key }
        return dayTasks.filter { $0.isFrog } + dayTasks.filter { !$0.isFrog }
    }

    var overdueTasks: [DailyTask] {
        let today = DateKey.today
        return tasks.filter { !$0.isDone && $0.dateKey < today }
    }

    @discardableResult
    func addTask(title: String, dateKey: String = DateKey.today, goalID: UUID? = nil,
                 milestoneID: UUID? = nil, isFrog: Bool = false) -> DailyTask? {
        let clean = title.trimmed
        guard !clean.isEmpty else { return nil }
        if isFrog {
            for i in tasks.indices where tasks[i].dateKey == dateKey {
                tasks[i].isFrog = false
            }
        }
        let task = DailyTask(title: clean, dateKey: dateKey, goalID: goalID, milestoneID: milestoneID, isFrog: isFrog)
        tasks.append(task)
        return task
    }

    func toggleTask(_ id: UUID) {
        guard let i = tasks.firstIndex(where: { $0.id == id }) else { return }
        let done = !tasks[i].isDone
        tasks[i].isDone = done
        tasks[i].doneAt = done ? Date() : nil
        if let gID = tasks[i].goalID, let mID = tasks[i].milestoneID,
           let g = goals.firstIndex(where: { $0.id == gID }),
           let m = goals[g].milestones.firstIndex(where: { $0.id == mID }) {
            goals[g].milestones[m].isDone = done
            goals[g].milestones[m].doneAt = done ? Date() : nil
        }
    }

    func setFrog(_ id: UUID) {
        guard let task = tasks.first(where: { $0.id == id }) else { return }
        for i in tasks.indices where tasks[i].dateKey == task.dateKey {
            tasks[i].isFrog = tasks[i].id == id
        }
    }

    func deleteTask(_ id: UUID) {
        tasks.removeAll { $0.id == id }
    }

    func moveOverdueToToday() {
        let today = DateKey.today
        let hasFrogToday = tasks.contains { $0.dateKey == today && $0.isFrog }
        for i in tasks.indices where !tasks[i].isDone && tasks[i].dateKey < today {
            tasks[i].dateKey = today
            if hasFrogToday { tasks[i].isFrog = false }
        }
    }

    func discardOverdue() {
        let today = DateKey.today
        tasks.removeAll { !$0.isDone && $0.dateKey < today }
    }

    // MARK: - Reflexiones

    func reflection(for key: String) -> Reflection? {
        reflections.first { $0.dateKey == key }
    }

    func saveReflection(_ reflection: Reflection) {
        if let i = reflections.firstIndex(where: { $0.dateKey == reflection.dateKey }) {
            reflections[i] = reflection
        } else {
            reflections.append(reflection)
        }
    }

    // MARK: - Enfoque

    func addSession(_ session: FocusSession) {
        sessions.append(session)
    }

    var sessionsToday: Int {
        let key = DateKey.today
        return sessions.filter { DateKey.key(for: $0.startedAt) == key }.count
    }

    var focusMinutesToday: Int {
        let key = DateKey.today
        return sessions.filter { DateKey.key(for: $0.startedAt) == key }.reduce(0) { $0 + $1.minutes }
    }

    var focusMinutesThisWeek: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -6, to: Calendar.current.startOfDay(for: Date())) ?? Date()
        return sessions.filter { $0.startedAt >= weekAgo }.reduce(0) { $0 + $1.minutes }
    }

    // MARK: - Estadísticas

    func points(on key: String) -> Int {
        var p = 0
        for t in tasks where t.dateKey == key && t.isDone {
            p += t.isFrog ? 25 : 10
        }
        p += habitsDone(on: key) * 5
        for s in sessions where DateKey.key(for: s.startedAt) == key {
            p += s.minutes
        }
        if reflections.contains(where: { $0.dateKey == key }) {
            p += 15
        }
        for g in goals {
            for m in g.milestones {
                if let d = m.doneAt, DateKey.key(for: d) == key { p += 20 }
            }
            if let c = g.completedAt, DateKey.key(for: c) == key { p += 100 }
        }
        return p
    }

    var totalPoints: Int {
        var p = 0
        p += tasks.filter { $0.isDone }.reduce(0) { $0 + ($1.isFrog ? 25 : 10) }
        p += habits.reduce(0) { $0 + $1.completions.count * 5 }
        p += sessions.reduce(0) { $0 + $1.minutes }
        p += reflections.count * 15
        p += goals.reduce(0) { $0 + $1.doneCount * 20 + ($1.isCompleted ? 100 : 0) }
        return p
    }

    var tasksDoneTotal: Int { tasks.filter { $0.isDone }.count }

    func hasActivity(on key: String) -> Bool { points(on: key) > 0 }

    var activityStreak: Int {
        let cal = Calendar.current
        var day = cal.startOfDay(for: Date())
        if !hasActivity(on: DateKey.key(for: day)) {
            guard let yesterday = cal.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
        }
        var streak = 0
        while hasActivity(on: DateKey.key(for: day)) && streak < 3650 {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return streak
    }

    var habitConsistencyWeek: Double {
        guard !habits.isEmpty else { return 0 }
        var done = 0
        for n in 0..<7 {
            done += habitsDone(on: DateKey.key(daysAgo: n))
        }
        return Double(done) / Double(habits.count * 7)
    }

    struct DayStat: Identifiable {
        let id: String
        let label: String
        let points: Int
        let date: Date
    }

    var lastSevenDays: [DayStat] {
        (0..<7).reversed().map { n in
            let date = Calendar.current.date(byAdding: .day, value: -n, to: Date()) ?? Date()
            let key = DateKey.key(for: date)
            return DayStat(id: key, label: date.spanishWeekdayShort, points: points(on: key), date: date)
        }
    }
}
