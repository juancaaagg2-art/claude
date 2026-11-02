# Norte 🧭

App nativa para iPhone (SwiftUI, iOS 17+) para crecer como persona: definir objetivos, dividirlos en pasos, planear el día, vencer la procrastinación con sesiones de enfoque, sostener hábitos y reflexionar cada noche.

Todos tus datos se guardan únicamente en tu teléfono.

## Qué hace

| Pestaña | Para qué sirve |
|---|---|
| **Hoy** | Saludo, racha y nivel. Tu **rana del día** (la tarea más importante), plan de máximo 3 tareas, hábitos de hoy, botón "Solo 2 min" contra la procrastinación, cierre del día y consejo diario. |
| **Objetivos** | Objetivos con área de vida, *tu porqué*, fecha límite y pasos pequeños. Progreso en anillo. Un toque manda el siguiente paso al plan de hoy. |
| **Enfoque** | Temporizador Pomodoro (2, 10, 25 o 50 min) con intención, pausa, descanso y notificación al terminar. Al completar puedes marcar la tarea como hecha. |
| **Hábitos** | Hábitos diarios con racha 🔥, últimos 7 días y vínculo a un objetivo. |
| **Progreso** | Nivel y puntos, racha, tareas completadas, minutos de enfoque, consistencia de hábitos, gráfica de 7 días, historial de reflexiones y ajustes. |

Recordatorios: uno por la mañana ("¿Cuál es tu rana de hoy?") y uno por la noche ("Cierre del día"). La hora se cambia en Ajustes.

## Cómo instalarla en tu iPhone

### Opción A: tienes una Mac (gratis)

1. Instala **Xcode** desde la Mac App Store (versión 16 o superior).
2. Clona este repositorio y abre `Norte.xcodeproj`.
3. En Xcode ve a **Settings › Accounts** y agrega tu Apple ID (sirve una cuenta gratuita).
4. Selecciona el target **Norte › Signing & Capabilities**, marca *Automatically manage signing* y elige tu *Team*. Si Xcode se queja del Bundle Identifier, cámbialo a algo único como `com.tunombre.norte`.
5. Conecta tu iPhone por cable. En el iPhone activa **Ajustes › Privacidad y seguridad › Modo desarrollador**.
6. Elige tu iPhone como destino en la barra superior y pulsa **Run** (▶).
7. La primera vez el iPhone pedirá confiar en el desarrollador: **Ajustes › General › VPN y gestión de dispositivos › tu Apple ID › Confiar**.

Con una cuenta gratuita la app caduca a los 7 días; vuelve a pulsar Run para renovarla. Con el programa de desarrolladores de pago (99 USD/año) dura un año y además puedes usar TestFlight.

### Opción B: no tienes Mac (Windows o Linux)

Cada `push` a este repositorio ejecuta un workflow de GitHub Actions que compila la app y publica un archivo **`Norte-unsigned.ipa`** como artefacto.

1. Entra a la pestaña **Actions** del repositorio, abre la última ejecución y descarga el artefacto `Norte-unsigned-ipa`.
2. Instala en tu computadora **Sideloadly** (Windows/Mac) o **AltStore**.
3. Conecta el iPhone, arrastra el `.ipa`, escribe tu Apple ID y pulsa *Start*. La herramienta firma la app con tu cuenta y la instala.
4. En el iPhone confía en el desarrollador como en el paso 7 de la Opción A.

Igual que con Xcode, con una cuenta gratuita la app caduca a los 7 días y hay que volver a instalarla (AltStore puede renovarla automáticamente).

### Opción C: App Store / TestFlight

Requiere el programa de desarrolladores de pago. Archiva desde Xcode (**Product › Archive**) y sube a App Store Connect.

## Estructura del proyecto

```
Norte.xcodeproj/          Proyecto de Xcode (grupo sincronizado con la carpeta Norte/)
Norte/
  NorteApp.swift          Punto de entrada
  ContentView.swift       Pestañas y enrutador
  Models.swift            Objetivos, pasos, hábitos, tareas, reflexiones, perfil
  AppStore.swift          Estado global y persistencia en JSON
  FocusTimer.swift        Temporizador de enfoque
  NotificationManager.swift
  TodayView.swift, GoalsView.swift, HabitsView.swift, FocusView.swift,
  ProgressTabView.swift, ReflectionSheet.swift, OnboardingView.swift
  Components.swift, Theme.swift
  Assets.xcassets/        Ícono y color de acento
.github/workflows/build-ios.yml   Compilación y empaquetado automático
```

## Ideas para seguir creciendo

- Widget de pantalla de inicio con la rana del día.
- Sincronización con iCloud.
- Estadísticas mensuales y exportación de datos.
