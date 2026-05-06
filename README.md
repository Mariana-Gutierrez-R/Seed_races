# 🎡 Ruleta Cómic

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
![Flask](https://img.shields.io/badge/Flask-000000?style=for-the-badge&logo=flask&logoColor=white)
![MySQL](https://img.shields.io/badge/MySQL-4479A1?style=for-the-badge&logo=mysql&logoColor=white)

Aplicación móvil interactiva inspirada en el estilo visual de los cómics, desarrollada con Flutter y Flask.

La aplicación genera personajes aleatorios a través de múltiples ruletas dinámicas conectadas entre sí mediante filtros inteligentes y preguntas aleatorias almacenadas en MySQL.

---

# ✨ Características

- 🎯 Sistema de ruletas encadenadas
- 🎲 Eventos aleatorios entre preguntas y ruletas
- 🧠 Preguntas dinámicas sin repetición inmediata
- 💾 Persistencia de resultados en MySQL
- 🎨 Interfaz estilo cómic animada
- ⚡ Backend REST API con Flask
- 🔄 Reinicio automático de preguntas
- 🛡️ Control de flujo para evitar bloqueos
- 🎮 Sistema de selección progresiva de personaje

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
