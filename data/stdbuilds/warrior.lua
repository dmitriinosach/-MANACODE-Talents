local ADDON, ns = ...
ns.stdBuilds = ns.stdBuilds or {}
ns.stdBuilds.WARRIOR = {
    { name = "Arms (Улучшенный смертельный удар)", variant = "arms",
      title = { ru = "Оружие (рейд)", en = "Arms (raid)", es = "Armas (banda)" },
      ranks = {
          { 3, 0, 2, 2, 3, 0, 2, 1, 2, 3, 3, 3, 5, 1, 0, 0, 0, 0, 2, 0, 1, 2, 2, 0, 3, 2, 3, 1, 2, 5, 1 },
          { 3, 2, 5, 0, 0, 0, 0, 0, 5, 0, 2 },
          {},
      },
      glyphs = { major = { 43423, 43421, 43416 }, minor = { 43395, 49084, 43397 } },
      note = {
          ru = "Классическая ветка 54/17/0: вся ветка Оружия с «Травмой» и «Кровавым бешенством» для рейда, из Неистовства «Безжалостность» и «Улучшенная казнь». Специализация стоит на топорах, под другое оружие переставьте пять очков.",
          en = "The classic 54/17/0 build: the whole Arms tree with Trauma and Blood Frenzy for the raid, Cruelty and Improved Execute from Fury. Weapon specialization is set to axes; move the five points for another weapon.",
          es = "La rama clásica 54/17/0: todo el árbol de Armas con Trauma y Frenesí de sangre para la banda, Crueldad y Ejecutar mejorado de Furia. La especialización está en hachas; mueve los cinco puntos para otra arma.",
      } },
    { name = "Arms (Улучшенная казнь: не рекомендуется гайдом)", drop = true },
    { name = "Fury (Стандарт)", variant = "fury",
      title = { ru = "Неистовство (рейд)", en = "Fury (raid)", es = "Furia (banda)" },
      glyphs = { major = { 43432, 43418, 43414 }, minor = { 43396, 43395, 49084 } },
      note = {
          ru = "Основная ветка 18/53/0 с «Хваткой титана»: «Улучшенный рассекающий удар» для боёв с несколькими целями и «Командирский голос» для крика. Если в рейде есть паладин Воздаяния с улучшенным благословением, берите ветку на одну цель.",
          en = "Main 18/53/0 Titan's Grip build: Improved Cleave for fights with several targets and Commanding Presence for the shout. If the raid has a Retribution paladin with the improved blessing, take the single-target build.",
          es = "Rama principal 18/53/0 con Agarre de titán: Rajar mejorado para combates con varios objetivos y Presencia imponente para el grito. Si la banda tiene un paladín de Reprensión con la bendición mejorada, usa la rama de un objetivo.",
      } },
    { name = "Fury (Overpower Weaving: доп. кнопка)", drop = true },
    { name = "Fury (single target)", variant = "fury",
      title = { ru = "Неистовство (одна цель)", en = "Fury (single target)", es = "Furia (un objetivo)" },
      ranks = {
          { 3, 0, 2, 0, 2, 3, 0, 0, 2, 3, 3 },
          { 3, 0, 5, 0, 3, 0, 0, 0, 5, 5, 2, 0, 3, 1, 0, 0, 5, 3, 1, 2, 0, 5, 0, 1, 3, 5, 1 },
          {},
      },
      glyphs = { major = { 43432, 43418, 43416 }, minor = { 43396, 43395, 49084 } },
      note = {
          ru = "Ветка 18/53/0 под боссов: «Улучшенная казнь» и «Необузданный гнев» вместо «Улучшенного рассекающего удара» и «Луженой глотки». Больше ярости и урона в фазе добивания, меньше по пачкам.",
          en = "The 18/53/0 build for bosses: Improved Execute and Unbridled Wrath instead of Improved Cleave and Booming Voice. More rage and execute-phase damage, less on packs.",
          es = "Rama 18/53/0 para jefes: Ejecutar mejorado e Ira desenfrenada en lugar de Rajar mejorado y Voz resonante. Más ira y daño en la fase de ejecución, menos en grupos.",
      } },
    { name = "Protection (Deep Prot)", variant = "prot",
      title = { ru = "Защита (рейд)", en = "Protection (raid)", es = "Protección (banda)" },
      glyphs = { major = { 43425, 43415, 45793 }, minor = { 43399, 43397, 49084 } },
      note = {
          ru = "Универсальная ветка танка: вся Защита, «Глубокие раны» и «Безжалостность» ради угрозы по одной цели и по пачке. Подходит для рейдов и подземелий.",
          en = "The all-round tank build: all of Protection plus Deep Wounds and Cruelty for threat on one target and on packs. Fits raids and dungeons.",
          es = "La rama de tanque universal: toda Protección más Heridas profundas y Crueldad para amenaza a un objetivo y en grupos. Sirve para bandas y mazmorras.",
      } },
    { name = "Protection (Unrelenting Assault)", drop = true },
    { name = "Protection (cooldowns)", variant = "prot",
      title = { ru = "Защита (защитные кнопки)", en = "Protection (cooldowns)", es = "Protección (defensivos)" },
      ranks = {
          { 3, 5, 0, 0, 2, 0, 0, 0, 2, 3 },
          { 3 },
          { 0, 5, 3, 3, 5, 1, 2, 2, 5, 0, 0, 0, 2, 1, 2, 5, 2, 1, 0, 3, 0, 1, 1, 3, 3, 2, 1 },
      },
      glyphs = { major = { 43425, 43426, 43429 }, minor = { 43399, 43397, 49084 } },
      note = {
          ru = "Вариант основной ветки с «Отработанными навыками»: «Глухая оборона» и «Возмездие» восстанавливаются на минуту быстрее. Чуть меньше крита, чаще защитные кнопки; удобна в среднем снаряжении.",
          en = "A variant of the main build with Improved Disciplines: Shield Wall and Retaliation come back a minute sooner. Slightly less crit, defensive cooldowns more often; handy in medium gear.",
          es = "Variante de la rama principal con Disciplinas mejoradas: Muro de escudo y Represalias se recuperan un minuto antes. Algo menos de crítico, defensivos más a menudo; cómoda con equipo medio.",
      } },
}
