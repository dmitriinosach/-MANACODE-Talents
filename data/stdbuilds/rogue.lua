local ADDON, ns = ...
ns.stdBuilds = ns.stdBuilds or {}
ns.stdBuilds.ROGUE = {
    { name = "Assassination (БиС: максимум урона)",
      title = { ru = "Убийство (рейд, энергия)", en = "Assassination (raid, energy)", es = "Asesinato (banda, energía)" },
      glyphs = { major = { 45768, 45761, 45767 }, minor = { 43380, 43376, 43378 } },
      note = {
          ru = "Основная ветка на одну цель, 51/13/7: Расправа и Отравление, большую часть урона дают яды. «Неослабевающие удары» возвращают энергию за завершающие приёмы.",
          en = "Main single-target build, 51/13/7: Mutilate and Envenom, poisons do most of the damage. Relentless Strikes returns energy on finishers.",
          es = "Rama principal a un objetivo, 51/13/7: Mutilar y Envenenar, los venenos hacen casi todo el daño. Golpes implacables devuelve energía con los remates.",
      } },
    { name = "Assassination (Хасте: пассивный крит)",
      title = { ru = "Убийство (скорость и крит)", en = "Assassination (haste and crit)", es = "Asesinato (celeridad y crítico)" },
      glyphs = { major = { 45768, 45761, 45767 }, minor = { 43380, 43376, 43378 } },
      note = {
          ru = "Вариант 51/18/2 под кинжалы 1.8 и 1.4: «Близкий бой» и «Молниеносные рефлексы» вместо возврата энергии. По урону почти равна основной, выбирайте по вкусу.",
          en = "The 51/18/2 variant for 1.8 and 1.4 daggers: Close Quarters Combat and Lightning Reflexes instead of the energy return. Damage is nearly equal to the main build, pick what you like.",
          es = "Variante 51/18/2 para dagas de 1.8 y 1.4: Combate cuerpo a cuerpo y Reflejos relámpago en lugar de la energía devuelta. El daño es casi igual al de la rama principal.",
      } },
    { name = "Assassination (АоЕ: Шквал клинков)", drop = true },
    { name = "Assassination (Fan of Knives)", variant = "assassination",
      title = { ru = "Убийство (АоЕ, Веер клинков)", en = "Assassination (AoE, Fan of Knives)", es = "Asesinato (área, Abanico de cuchillos)" },
      ranks = {
          [1] = {0,0,5,3,2,0,1,0,5,3,5,2,1,0,0,5,2,0,1,0,3},
          [2] = {0,2,5,2,0,5,2,0,5,0,0,3,1,0,1,0,2,2,2,1},
          [3] = {},
      },
      glyphs = { major = { 45766, 45767, 42971 }, minor = { 43380, 43376, 43378 } },
      note = {
          ru = "Вторая ветка для больших пачек, 38/33/0: всё ради Веера клинков, в обеих руках медленное оружие с быстродействующим ядом. По боссу заметно слабее основных.",
          en = "A second spec for big packs, 38/33/0: everything goes into Fan of Knives, two slow weapons with Instant Poison. Clearly weaker on bosses than the main builds.",
          es = "Segunda rama para grupos grandes, 38/33/0: todo para Abanico de cuchillos, dos armas lentas con veneno instantáneo. En jefes rinde bastante menos que las principales.",
      } },
    { name = "Combat (БиС)",
      title = { ru = "Бой (мечи и топоры)", en = "Combat (swords and axes)", es = "Combate (espadas y hachas)" },
      glyphs = { major = { 42972, 45762, 42969 }, minor = { 43380, 43376, 43378 } },
      note = {
          ru = "Основная рейдовая ветка под мечи и топоры: медленное оружие в правой руке, быстрое в левой. Комбо-очки уходят в Мясорубку и Рваную рану; с капом пробивания брони берите ветку через Потрошение.",
          en = "Main raid build for swords and axes: slow main hand, fast off hand. Combo points go into Slice and Dice and Rupture; with capped armor penetration take the Eviscerate build.",
          es = "Rama principal de banda para espadas y hachas: arma lenta en la mano derecha y rápida en la izquierda. Los puntos de combo van a Hacer picadillo y Ruptura; con el tope de penetración de armadura usa la rama de Eviscerar.",
      } },
    { name = "Combat (Кулак/Кинжал)",
      title = { ru = "Бой (кистевое и кинжалы)", en = "Combat (fist weapons and daggers)", es = "Combate (armas de puño y dagas)" },
      glyphs = { major = { 42972, 45762, 42969 }, minor = { 43380, 43376, 43378 } },
      note = {
          ru = "Та же ветка с «Близким боем» вместо «Руби, кромсай!»: берите, если лучшее оружие у вас кистевое или кинжалы.",
          en = "The same build with Close Quarters Combat instead of Hack and Slash: take it when your best weapons are fist weapons or daggers.",
          es = "La misma rama con Combate cuerpo a cuerpo en lugar de Tajar y cortar: úsala si tus mejores armas son de puño o dagas.",
      } },
    { name = "Combat (Eviscerate)", variant = "combat",
      title = { ru = "Бой (Потрошение, кап пробивания)", en = "Combat (Eviscerate, armor penetration cap)", es = "Combate (Eviscerar, tope de penetración)" },
      ranks = {
          [1] = {3,0,5,2,0,0,0,0,5,0,5},
          [2] = {0,2,5,2,0,5,1,0,0,0,0,3,5,0,1,5,2,2,3,1,0,0,5,0,1,2,5,1},
          [3] = {},
      },
      glyphs = { major = { 42972, 45762, 42961 }, minor = { 43380, 43376, 43378 } },
      note = {
          ru = "Для вещей 264 уровня и выше с капом пробивания брони: «Жестокое потрошение» вместо «Кровавого фонтана», комбо-очки уходят в Потрошение, Рваная рана не нужна. Без пробивания брони слабее ветки через Рваную рану.",
          en = "For item level 264 and higher gear with capped armor penetration: Improved Eviscerate instead of Blood Spatter, combo points go into Eviscerate and Rupture is dropped. Without armor penetration it is weaker than the Rupture build.",
          es = "Para equipo de nivel 264 o más con el tope de penetración de armadura: Eviscerar mejorado en lugar de Salpicadura de sangre, los puntos de combo van a Eviscerar y Ruptura sobra. Sin penetración rinde menos que la rama de Ruptura.",
      } },
}
