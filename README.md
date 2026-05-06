# 🎡 Ruleta Cómic

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
![Flask](https://img.shields.io/badge/Flask-000000?style=for-the-badge&logo=flask&logoColor=white)
![MySQL](https://img.shields.io/badge/MySQL-4479A1?style=for-the-badge&logo=mysql&logoColor=white)

Aplicación móvil interactiva inspirada en el estilo visual de los cómics, desarrollada con Flutter y Flask.

La aplicación genera personajes aleatorios a través de múltiples ruletas dinámicas conectadas entre sí mediante filtros inteligentes y preguntas aleatorias almacenadas en MySQL.

---

# 🧩 Flujo de la Ruleta

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

Cada nivel se filtra dinámicamente según las selecciones anteriores.

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
## 🛠️ Tecnologías

- **Frontend:** Flutter + Dart
- **Backend:** Python + Flask
- **Base de datos:** MySQL

---

# 📂 Arquitectura del Proyecto

```text
Seed_races/
│
├── backend/
│   ├── app.py
│   ├── requirements.txt
│   └── .env
│
├── ruleta_app/
│   └── lib/
│       └── main.dart
│
├── Documentacion/
│   └── ERDSE.pdf
│
└── README.md
```

---

## 🚀 Cómo correr el proyecto

### Backend

```bash
pip install -r requirements.txt
python app.py
```

### Frontend

Abre el proyecto en Android Studio y corre el emulador.

---

## 👩‍💻 Autores

- **Mariana Gutiérrez Restrepo**
- **Julián David López**
