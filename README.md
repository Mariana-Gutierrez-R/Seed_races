# 🎡 Ruleta Cómic

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge\&logo=flutter\&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge\&logo=dart\&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge\&logo=python\&logoColor=white)
![Flask](https://img.shields.io/badge/Flask-000000?style=for-the-badge\&logo=flask\&logoColor=white)
![MySQL](https://img.shields.io/badge/MySQL-4479A1?style=for-the-badge\&logo=mysql\&logoColor=white)

Aplicación móvil interactiva inspirada en el estilo visual de los cómics, desarrollada con Flutter y Flask.

La aplicación genera personajes mediante múltiples ruletas dinámicas, preguntas aleatorias y diferentes modos de juego conectados a una base de datos MySQL.

---

# 🧩 Modos de Juego

## 🌌 Universo Afín

Permite seleccionar previamente un universo de referencia.

Flujo:

```text
Login
   ↓
Selección de modo
   ↓
Selección de universo
   ↓
Ruletas dinámicas
   ↓
Preguntas aleatorias
   ↓
Personaje final
```

Universos disponibles:

* Dragon Ball
* DC Comics
* LOTR
* Mitología Griega

Las primeras selecciones mantienen coherencia con el universo elegido.

---

## 🎲 Modo Caótico

Modo completamente aleatorio.

Flujo:

```text
Login
   ↓
Selección de modo
   ↓
Ruletas aleatorias
   ↓
Preguntas aleatorias
   ↓
Personaje aleatorio
```

Características:

* No utiliza filtros por universo.
* Utiliza todas las opciones disponibles en la base de datos.
* Permite combinaciones imposibles entre universos.
* Genera personajes completamente únicos.

---

# 🧩 Flujo General de la Ruleta

La generación del personaje sigue este orden:

1. Origen
2. Categoría
3. Raza
4. Subraza
5. Rol
6. Arma
7. Tipo de daño
8. Moralidad
9. Nivel de amenaza

Ejemplo:

```text
Dragon Ball
   ↓
Warrior
   ↓
Saiyan
   ↓
Elite Saiyan
```

---

## 🎨 Personalización

La aplicación permite:

### Fondos

* Color fijo.
* Color aleatorio.
* Persistencia de configuración.

### Punteros personalizados

Disponibles:

* Clásico
* Rayo
* Espada
* Murciélago
* Radar

Implementados mediante imágenes PNG ubicadas en:

```text
assets/images/
```

---

## 🛠️ Tecnologías

* **Frontend:** Flutter + Dart
* **Backend:** Python + Flask
* **Base de datos:** MySQL
* **Persistencia local:** SharedPreferences

---

# 📂 Arquitectura del Proyecto

```text
Seed_races/
│
├── backend/
│   ├── app.py
│   ├── auth.py
│   ├── requirements.txt
│   └── .env
│
├── ruleta_app/
│   │
│   ├── assets/
│   │   └── images/
│   │
│   └── lib/
│       ├── main.dart
│       │
│       ├── models/
│       │   └── models.dart
│       │
│       ├── services/
│       │   ├── api_service.dart
│       │   └── auth_service.dart
│       │
│       ├── pages/
│       │   ├── login_page.dart
│       │   ├── mode_select_page.dart
│       │   ├── universe_select_page.dart
│       │   ├── ruleta_page.dart
│       │   └── settings_page.dart
│       │
│       ├── widgets/
│       │   └── comic_widgets.dart
│       │
│       ├── painters/
│       │   └── comic_painters.dart
│       │
│       └── theme/
│           └── app_colors.dart
│
├── Documentacion/
│   └── ERDSE.pdf
│
└── README.md
```

La aplicación fue refactorizada desde una arquitectura basada en un único archivo principal hacia una estructura modular organizada por responsabilidades.

---

## 🚀 Cómo correr el proyecto

### Backend

Abrir una terminal dentro de:

```bash
backend
```

Instalar dependencias:

```bash
pip install -r requirements.txt
```

Ejecutar API principal:

```bash
python app.py
```

Ejecutar servicio de autenticación:

```bash
python auth.py
```

---

### Frontend

Abrir una terminal dentro de:

```bash
ruleta_app
```

Instalar dependencias:

```bash
flutter pub get
```

Ejecutar aplicación:

```bash
flutter run
```

Para emulador Android:

```bash
flutter run -d emulator-5554
```

---

## 👩💻 Autores

* **Mariana Gutiérrez Restrepo**
* **Julián David López**
