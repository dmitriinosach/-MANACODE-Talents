local ADDON, ns = ...
ns.stdBuilds = ns.stdBuilds or {}
ns.stdBuilds.MAGE = {
    { name = "Arcane (ЦЛК прогресс: живучесть)", variant = "arcane",
      title = { ru = "Тайная магия (ЦЛК, живучесть)", en = "Arcane (ICC, survivability)", es = "Arcano (CCH, aguante)" },
      glyphs = { major = { 44955, 42735, 42751 }, minor = { 43364, 43360, 43357 } },
      note = {
          ru = "Для ЦЛК, где урон по рейду идёт постоянно: Чародейское равновесие не даёт сбивать Чародейские стрелы, Магическое поглощение добавляет сопротивления. Защита от льда и Колдовское поглощение превращают поглощённый урон в силу заклинаний.",
          en = "For ICC with its constant raid damage: Arcane Stability protects Arcane Missiles from pushback, Magic Absorption adds resistances. Frost Warding and Incanter's Absorption turn absorbed damage into spell power.",
          es = "Para CCH, con daño constante a la banda: Estabilidad Arcana evita los retrasos de Misiles Arcanos y Absorción de magia da resistencias. Custodia de Escarcha y Absorción del encantador convierten el daño absorbido en poder con hechizos.",
      } },
    { name = "Arcane (Ульдуар/ИК: бёрст)", variant = "arcane",
      title = { ru = "Тайная магия (максимум урона)", en = "Arcane (max damage)", es = "Arcano (daño máximo)" },
      glyphs = { major = { 44955, 42735, 42751 }, minor = { 43364, 43360, 43357 } },
      note = {
          ru = "Больше урона и меньше расход маны: Чародейская сосредоточенность целиком и Искусные чары вместо защиты от сбивания каста. Берите, когда в группе есть Аура сосредоточенности.",
          en = "More damage and cheaper casts: full Arcane Concentration and Arcane Subtlety instead of pushback protection. Take it when your group has Concentration Aura.",
          es = "Más daño y menos gasto de maná: Concentración Arcana completa y Sutileza Arcana en lugar de la protección contra retrasos. Úsala si tu grupo tiene Aura de concentración.",
      } },
    { name = "Arcane (максимум урона: АоЕ)", drop = true },
    { name = "Fire (ЦЛК прогресс: живучесть)", drop = true },
    { name = "Fire (сингл-таргет: дальность, не дух)", variant = "fire",
      title = { ru = "Огонь (Огненный шар, одна цель)", en = "Fire (Fireball, single target)", es = "Fuego (Bola de Fuego, un objetivo)" },
      glyphs = { major = { 42739, 42751, 45737 }, minor = { 43364, 43339, 43361 } },
      note = {
          ru = "Основная ветка огня: Огненный шар с Пыткой слабых, Живая бомба на цели, Огненная глыба по Пути огня. Улучшенный ожог нужен, если в рейде никто другой не даёт 5% крита по цели.",
          en = "The main fire build: Fireball with Torment the Weak, Living Bomb on the target, Pyroblast on Hot Streak. Improved Scorch is needed only if nobody else brings the 5% crit debuff.",
          es = "La rama principal de fuego: Bola de Fuego con Atormentar a los débiles, Bomba viva en el objetivo y Piroexplosión con Buena racha. Agostar mejorado solo hace falta si nadie más aporta el 5% de crítico.",
      } },
    { name = "Fire (общий урон: АоЕ трэш)", variant = "fire",
      title = { ru = "Огонь (Огненный шар, пачки)", en = "Fire (Fireball, trash and AoE)", es = "Fuego (Bola de Fuego, grupos)" },
      glyphs = { major = { 42739, 42751, 45737 }, minor = { 44920, 43339, 43364 } },
      note = {
          ru = "Тот же Огненный шар, но с Взрывной волной и Дыханием дракона: после них Огненный столб мгновенный. Для боёв с пачками и трэша; символ взрывной волны убирает отбрасывание.",
          en = "The same Fireball build with Blast Wave and Dragon's Breath: they make the next Flamestrike instant. For add fights and trash; Glyph of Blast Wave removes the knockback.",
          es = "La misma rama de Bola de Fuego con Ola explosiva y Aliento de dragón: después de ellos Fogonazo es instantáneo. Para grupos de enemigos; el glifo de Ola explosiva quita el empujón.",
      } },
    { name = "Frost", variant = "frost",
      title = { ru = "Лёд (рейд)", en = "Frost (raid)", es = "Escarcha (banda)" },
      glyphs = { major = { 42742, 42751, 50045 }, minor = { 43364, 43339, 43361 } },
      note = {
          ru = "Ледяная стрела без остановки, мгновенная Стрела ледяного огня по Заморозке мозгов, Глубокая заморозка по Ледяным пальцам. Урона меньше, чем у огня и тайной магии, зато рейду идёт Восполнение.",
          en = "Nonstop Frostbolt, instant Frostfire Bolt on Brain Freeze, Deep Freeze on Fingers of Frost. Less damage than Fire or Arcane, but it gives the raid Replenishment.",
          es = "Descarga de Escarcha sin parar, Descarga de Pirofrío instantánea con Congelación cerebral y Congelación profunda con Dedos de Escarcha. Hace menos daño que Fuego o Arcano, pero da Reposición a la banda.",
      } },
}
