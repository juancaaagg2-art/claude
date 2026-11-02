import SwiftUI

// MARK: - Fechas

enum DateKey {
    static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func key(for date: Date) -> String { formatter.string(from: date) }
    static var today: String { key(for: Date()) }
    static var tomorrow: String { key(daysAgo: -1) }
    static func date(from key: String) -> Date? { formatter.date(from: key) }

    static func key(daysAgo n: Int) -> String {
        let d = Calendar.current.date(byAdding: .day, value: -n, to: Date()) ?? Date()
        return key(for: d)
    }
}

extension Date {
    private static let esLong: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_MX")
        f.dateFormat = "EEEE d 'de' MMMM"
        return f
    }()
    private static let esShort: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_MX")
        f.dateFormat = "d 'de' MMM yyyy"
        return f
    }()
    private static let esWeekday: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_MX")
        f.dateFormat = "EEE"
        return f
    }()

    var spanishLong: String { Self.esLong.string(from: self).capitalizingFirst }
    var spanishShort: String { Self.esShort.string(from: self).replacingOccurrences(of: ".", with: "") }
    var spanishWeekdayShort: String {
        Self.esWeekday.string(from: self).replacingOccurrences(of: ".", with: "").capitalizingFirst
    }
}

// MARK: - Áreas de vida

enum GoalArea: String, Codable, CaseIterable, Identifiable {
    case salud, carrera, aprendizaje, finanzas, relaciones, mente, creatividad, otro

    var id: String { rawValue }

    var title: String {
        switch self {
        case .salud: return "Salud"
        case .carrera: return "Carrera"
        case .aprendizaje: return "Aprendizaje"
        case .finanzas: return "Finanzas"
        case .relaciones: return "Relaciones"
        case .mente: return "Mente"
        case .creatividad: return "Creatividad"
        case .otro: return "Otro"
        }
    }

    var icon: String {
        switch self {
        case .salud: return "heart.fill"
        case .carrera: return "briefcase.fill"
        case .aprendizaje: return "book.fill"
        case .finanzas: return "dollarsign.circle.fill"
        case .relaciones: return "person.2.fill"
        case .mente: return "brain.head.profile"
        case .creatividad: return "paintpalette.fill"
        case .otro: return "star.fill"
        }
    }

    var color: Color {
        switch self {
        case .salud: return .pink
        case .carrera: return .blue
        case .aprendizaje: return .orange
        case .finanzas: return .green
        case .relaciones: return .purple
        case .mente: return .teal
        case .creatividad: return .indigo
        case .otro: return .gray
        }
    }
}

// MARK: - Objetivos

struct Milestone: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var isDone: Bool = false
    var doneAt: Date? = nil
}

struct Goal: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var why: String = ""
    var area: GoalArea = .otro
    var deadline: Date? = nil
    var milestones: [Milestone] = []
    var createdAt: Date = Date()
    var completedAt: Date? = nil

    var isCompleted: Bool { completedAt != nil }
    var doneCount: Int { milestones.filter { $0.isDone }.count }

    var progress: Double {
        if isCompleted { return 1 }
        guard !milestones.isEmpty else { return 0 }
        return Double(doneCount) / Double(milestones.count)
    }

    var nextMilestone: Milestone? { milestones.first { !$0.isDone } }

    var daysLeft: Int? {
        guard let deadline = deadline else { return nil }
        let cal = Calendar.current
        return cal.dateComponents([.day], from: cal.startOfDay(for: Date()), to: cal.startOfDay(for: deadline)).day
    }
}

// MARK: - Hábitos

struct Habit: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var icon: String = "checkmark.circle.fill"
    var goalID: UUID? = nil
    var completions: Set<String> = []
    var createdAt: Date = Date()

    func isDone(on date: Date) -> Bool { completions.contains(DateKey.key(for: date)) }

    var currentStreak: Int {
        let cal = Calendar.current
        var day = cal.startOfDay(for: Date())
        if !completions.contains(DateKey.key(for: day)) {
            guard let yesterday = cal.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
        }
        var streak = 0
        while completions.contains(DateKey.key(for: day)) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return streak
    }

    var bestStreak: Int {
        let dates = completions.compactMap { DateKey.date(from: $0) }.sorted()
        guard !dates.isEmpty else { return 0 }
        let cal = Calendar.current
        var best = 1
        var run = 1
        for i in 1..<dates.count {
            if let next = cal.date(byAdding: .day, value: 1, to: dates[i - 1]), cal.isDate(next, inSameDayAs: dates[i]) {
                run += 1
            } else {
                run = 1
            }
            best = max(best, run)
        }
        return best
    }

    static let iconOptions: [String] = [
        "checkmark.circle.fill", "figure.run", "book.fill", "drop.fill", "bed.double.fill",
        "leaf.fill", "brain.head.profile", "pencil", "dumbbell.fill", "fork.knife",
        "sun.max.fill", "moon.fill", "music.note", "phone.down.fill", "dollarsign.circle.fill", "heart.fill",
    ]

    static let suggestions: [HabitSuggestion] = [
        HabitSuggestion(title: "Leer 10 páginas", icon: "book.fill"),
        HabitSuggestion(title: "Ejercicio 20 min", icon: "figure.run"),
        HabitSuggestion(title: "Meditar 5 min", icon: "brain.head.profile"),
        HabitSuggestion(title: "Planear mi día", icon: "pencil"),
        HabitSuggestion(title: "Dormir antes de las 11", icon: "bed.double.fill"),
        HabitSuggestion(title: "Sin redes al despertar", icon: "phone.down.fill"),
        HabitSuggestion(title: "Tomar 2 L de agua", icon: "drop.fill"),
        HabitSuggestion(title: "Escribir 3 gratitudes", icon: "heart.fill"),
    ]
}

struct HabitSuggestion: Identifiable {
    let title: String
    let icon: String
    var id: String { title }
}

struct MilestoneSuggestion: Identifiable {
    let goal: Goal
    let milestone: Milestone
    var id: UUID { milestone.id }
}

// MARK: - Plan diario

struct DailyTask: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var dateKey: String = DateKey.today
    var goalID: UUID? = nil
    var milestoneID: UUID? = nil
    var isFrog: Bool = false
    var isDone: Bool = false
    var doneAt: Date? = nil
}

// MARK: - Reflexión

struct Reflection: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var dateKey: String
    var mood: Int
    var wins: String
    var blockers: String
    var tomorrowFocus: String
    var createdAt: Date = Date()

    var moodEmoji: String { Reflection.emoji(for: mood) }

    static func emoji(for mood: Int) -> String {
        let all = ["😞", "😕", "😐", "🙂", "😄"]
        return all[max(0, min(4, mood - 1))]
    }
}

// MARK: - Sesiones de enfoque

struct FocusSession: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var startedAt: Date
    var minutes: Int
    var intention: String
    var goalID: UUID? = nil
}

// MARK: - Perfil

struct UserProfile: Codable {
    var name: String = ""
    var hasOnboarded: Bool = false
    var remindersEnabled: Bool = true
    var morningTime: Date = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    var eveningTime: Date = Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date()) ?? Date()
    var focusMinutes: Int = 25
    var breakMinutes: Int = 5
}

// MARK: - Niveles y consejos

enum LevelInfo {
    static let pointsPerLevel = 250

    static func level(for points: Int) -> Int { points / pointsPerLevel + 1 }
    static func progressInLevel(for points: Int) -> Double {
        Double(points % pointsPerLevel) / Double(pointsPerLevel)
    }

    static func title(for level: Int) -> String {
        switch level {
        case 1: return "Explorador"
        case 2: return "Constante"
        case 3...4: return "Disciplinado"
        case 5...7: return "Imparable"
        default: return "Maestro"
        }
    }
}

enum Tips {
    static let all: [String] = [
        "Regla de los 2 minutos: si te da pereza empezar, comprométete solo con 2 minutos. Empezar es la parte difícil.",
        "Come la rana: haz primero la tarea más importante del día, antes de revisar el celular.",
        "Divide en pasos pequeños. Un objetivo grande se avanza con el siguiente paso, no con todo a la vez.",
        "Elimina fricción: deja listo lo que necesitas la noche anterior.",
        "Pomodoro: 25 minutos de enfoque total, 5 de descanso. Repite.",
        "Nadie se siente motivado todo el tiempo. La disciplina es actuar aunque no tengas ganas.",
        "Tu teléfono en otra habitación mientras trabajas significa menos interrupciones.",
        "Perfecto es enemigo de hecho. Una versión imperfecta terminada vale más que una perfecta imaginada.",
        "Si fallaste ayer, hoy es un día nuevo. Nunca falles dos días seguidos.",
        "Vuelve a tu porqué. Cuando dudes, relee por qué te importa este objetivo.",
        "Celebra lo pequeño. Cada paso completado entrena a tu cerebro para seguir.",
        "Programa la tarea, no la intención: ¿cuándo y dónde lo voy a hacer?",
        "Reflexionar 2 minutos cada noche te mantiene en línea con tus objetivos.",
        "Identifica tu excusa favorita y escríbela. Nombrarla le quita poder.",
    ]

    static var today: String {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        return all[day % all.count]
    }
}
