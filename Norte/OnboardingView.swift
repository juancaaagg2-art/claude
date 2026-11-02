import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var store: AppStore
    @State private var page = 0
    @State private var name = ""
    @State private var firstGoal = ""
    @State private var firstWhy = ""

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                welcomePage.tag(0)
                namePage.tag(1)
                goalPage.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button {
                if page < 2 {
                    withAnimation { page += 1 }
                } else {
                    finish()
                }
            } label: {
                Text(page < 2 ? "Continuar" : "Empezar")
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(Theme.background)
    }

    private var welcomePage: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "location.north.circle.fill")
                .font(.system(size: 90))
                .foregroundStyle(Theme.accent)
            Text("Norte")
                .font(.largeTitle.bold())
            Text("Tu brújula para crecer, cumplir tus objetivos y dejar de procrastinar.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
            VStack(alignment: .leading, spacing: 14) {
                feature("flag.fill", "Objetivos claros divididos en pasos pequeños")
                feature("sun.max.fill", "Un plan diario con tu tarea más importante")
                feature("timer", "Sesiones de enfoque para vencer la pereza")
                feature("repeat", "Hábitos con rachas que te mantienen en línea")
            }
            .padding(.top, 12)
            Spacer()
            Spacer()
        }
        .padding()
    }

    private var namePage: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("¿Cómo te llamas?")
                .font(.title.bold())
            Text("Para saludarte cada mañana.")
                .foregroundStyle(.secondary)
            TextField("Tu nombre", text: $name)
                .textFieldStyle(.roundedBorder)
                .font(.title3)
                .padding(.horizontal, 32)
                .submitLabel(.next)
                .onSubmit { withAnimation { page = 2 } }
            Spacer()
            Spacer()
        }
        .padding()
    }

    private var goalPage: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("¿Qué quieres lograr?")
                .font(.title.bold())
            Text("Empieza con un objetivo. Puedes cambiarlo o agregar más después.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
            TextField("Ej. Correr mi primer 10K", text: $firstGoal)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 32)
            TextField("¿Por qué te importa?", text: $firstWhy, axis: .vertical)
                .lineLimit(2...4)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 32)
            Text("Al continuar te pediremos permiso para enviarte un recordatorio por la mañana y otro por la noche.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
            Spacer()
            Spacer()
        }
        .padding()
    }

    private func feature(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 28)
                .foregroundStyle(Theme.accent)
            Text(text)
                .font(.subheadline)
        }
    }

    private func finish() {
        store.profile.name = name.trimmed
        let goalTitle = firstGoal.trimmed
        if !goalTitle.isEmpty {
            store.addGoal(Goal(title: goalTitle, why: firstWhy.trimmed, area: .otro))
        }
        store.profile.hasOnboarded = true
        let profile = store.profile
        Task {
            let granted = await NotificationManager.requestAuthorization()
            if granted {
                NotificationManager.scheduleDailyReminders(for: profile)
            }
        }
    }
}
