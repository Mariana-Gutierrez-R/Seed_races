part of comic_ruleta_app;

// ================== MODELS ==================

class PreguntaModel {
  final int id;
  final String texto;
  final List<RespuestaModel> respuestas;

  const PreguntaModel({
    required this.id,
    required this.texto,
    required this.respuestas,
  });
}

class RespuestaModel {
  final int id;
  final String texto;

  const RespuestaModel({required this.id, required this.texto});
}

class PersonajeModel {
  final int? idCharacter;
  final String characterName;
  final String originName;
  final String categoryName;
  final String raceName;
  final String subraceName;
  final String roleName;
  final String weaponName;
  final String damageTypeName;
  final String moralityName;
  final String threatLevelName;

  const PersonajeModel({
    required this.idCharacter,
    required this.characterName,
    required this.originName,
    required this.categoryName,
    required this.raceName,
    required this.subraceName,
    required this.roleName,
    required this.weaponName,
    required this.damageTypeName,
    required this.moralityName,
    required this.threatLevelName,
  });

  factory PersonajeModel.fromJson(Map<String, dynamic> json) {
    return PersonajeModel(
      idCharacter: json['id_character'] as int?,
      characterName: json['character_name']?.toString() ?? 'Sin nombre',
      originName: json['origin_name']?.toString() ?? '-',
      categoryName: json['category_name']?.toString() ?? '-',
      raceName: json['race_name']?.toString() ?? '-',
      subraceName: json['subrace_name']?.toString() ?? '-',
      roleName: json['role_name']?.toString() ?? '-',
      weaponName: json['weapon_name']?.toString() ?? '-',
      damageTypeName: json['damage_type_name']?.toString() ?? '-',
      moralityName: json['morality_name']?.toString() ?? '-',
      threatLevelName: json['threat_level_name']?.toString() ?? '-',
    );
  }
}

class EstadoJuego {
  final String? origin;
  final String? category;
  final String? race;
  final String? subrace;
  final String? role;
  final String? weapon;
  final String? damageType;
  final String? morality;
  final String? threatLevel;

  const EstadoJuego({
    this.origin,
    this.category,
    this.race,
    this.subrace,
    this.role,
    this.weapon,
    this.damageType,
    this.morality,
    this.threatLevel,
  });

  EstadoJuego copyWith({
    String? origin,
    String? category,
    String? race,
    String? subrace,
    String? role,
    String? weapon,
    String? damageType,
    String? morality,
    String? threatLevel,
  }) {
    return EstadoJuego(
      origin: origin ?? this.origin,
      category: category ?? this.category,
      race: race ?? this.race,
      subrace: subrace ?? this.subrace,
      role: role ?? this.role,
      weapon: weapon ?? this.weapon,
      damageType: damageType ?? this.damageType,
      morality: morality ?? this.morality,
      threatLevel: threatLevel ?? this.threatLevel,
    );
  }

  bool get completo {
    return origin != null &&
        category != null &&
        race != null &&
        subrace != null &&
        role != null &&
        weapon != null &&
        damageType != null &&
        morality != null &&
        threatLevel != null;
  }
}

enum NivelRuleta {
  origen,
  categoria,
  raza,
  subraza,
  rol,
  arma,
  tipoDano,
  moralidad,
  nivelAmenaza,
}

extension NivelRuletaExt on NivelRuleta {
  String get titulo {
    switch (this) {
      case NivelRuleta.origen:
        return 'GIRAR ORIGEN';
      case NivelRuleta.categoria:
        return 'GIRAR CATEGORÍA';
      case NivelRuleta.raza:
        return 'GIRAR RAZA';
      case NivelRuleta.subraza:
        return 'GIRAR SUBRAZA';
      case NivelRuleta.rol:
        return 'GIRAR ROL';
      case NivelRuleta.arma:
        return 'GIRAR ARMA';
      case NivelRuleta.tipoDano:
        return 'GIRAR TIPO DE DAÑO';
      case NivelRuleta.moralidad:
        return 'GIRAR MORALIDAD';
      case NivelRuleta.nivelAmenaza:
        return 'GIRAR NIVEL DE AMENAZA';
    }
  }
}
