local ADDON, ns = ...
ns.stdBuilds = ns.stdBuilds or {}
ns.stdBuilds.SHAMAN = {
    { name = "Elemental", variant = "ele",
      title = { ru = "Стихии (рейд)", en = "Elemental (raid)", es = "Elemental (banda)" },
      glyphs = { major = { 41536, 45776, 41524 }, minor = { 44923, 43386, 43385 } },
      note = {
          ru = "Основная ветка 57/14/0 для хорошей экипировки: весь урон Молнии и Выброса лавы, Тотем гнева и «Клятва стихий» рейду. Символ тотема гнева работает, только когда стоит один Тотем гнева.",
          en = "Main 57/14/0 for good gear: full Lightning Bolt and Lava Burst damage, Totem of Wrath and Elemental Oath for the raid. The Totem of Wrath glyph works only with a single Totem of Wrath down.",
          es = "Rama principal 57/14/0 para buen equipo: todo el daño de Descarga de relámpagos y Ráfaga de lava, Tótem de cólera y Juramento elemental para la banda. El glifo del tótem solo funciona con un único Tótem de cólera.",
      } },
    { name = "Elemental (starter)", variant = "ele",
      title = { ru = "Стихии (старт, экономия маны)", en = "Elemental (starter, mana)", es = "Elemental (inicio, maná)" },
      ranks = {
          { 5, 5, 3, 3, 0, 0, 1, 5, 0, 0, 2, 1, 3, 3, 5, 1, 3, 2, 2, 3, 0, 1, 3, 5, 1 },
          { 0, 0, 5, 0, 5, 0, 0, 3, 1 },
          {},
      },
      glyphs = { major = { 41536, 45776, 41524 }, minor = { 44923, 43386, 43385 } },
      note = {
          ru = "Пока экипировка слабая и в долгих боях кончается мана: «Конвекция» 5/5 удешевляет заклинания вместо «Улучшенного кольца огня» и «Ока шторма».",
          en = "For weak gear when mana runs out in long fights: Convection 5/5 makes spells cheaper, replacing Improved Fire Nova and Eye of the Storm.",
          es = "Para equipo flojo, cuando el maná se acaba en combates largos: Convección 5/5 abarata los hechizos en lugar de Nova de Fuego mejorada y Ojo de la tormenta.",
      } },
    { name = "Enhancement", variant = "enh_phys",
      title = { ru = "Совершенствование (рейд)", en = "Enhancement (raid)", es = "Mejora (banda)" },
      glyphs = { major = { 41539, 45771, 41542 }, minor = { 43385, 43388, 43344 } },
      note = {
          ru = "Основная ветка 19/52/0: два оружия, Удар бури, Вскипание лавы, волки и «Оружие Водоворота». Рейду — «Высвобожденная ярость» и усиленные тотемы.",
          en = "Main 19/52/0: dual wield, Stormstrike, Lava Lash, wolves and Maelstrom Weapon. The raid gets Unleashed Rage and improved totems.",
          es = "Rama principal 19/52/0: doble empuñadura, Golpe de tormenta, Latigazo de lava, lobos y Arma vorágine. La banda recibe Ira desatada y tótems mejorados.",
      } },
    { name = "Enhancement (spellhance)", variant = "enh_spell",
      title = { ru = "Совершенствование (урон заклинаниями)", en = "Enhancement (spellhance)", es = "Mejora (daño con hechizos)" },
      ranks = {
          { 0, 5, 3, 0, 3, 0, 1, 5, 2 },
          { 3, 0, 5, 0, 5, 0, 0, 3, 1, 0, 5, 0, 0, 1, 3, 3, 3, 0, 3, 1, 1, 3, 1, 1, 3, 1, 0, 5, 1 },
          {},
      },
      glyphs = { major = { 41532, 41539, 41530 }, minor = { 43385, 43386, 43388 } },
      note = {
          ru = "Та же основа 19/52/0 под экипировку с силой заклинаний: урон идёт от Молнии с «Оружия Водоворота», шоков и Языка пламени. «Знания предков» 5/5 вместо улучшенного тотема неистовства ветра.",
          en = "The same 19/52/0 core for spell power gear: damage comes from Maelstrom Lightning Bolts, shocks and Flametongue. Ancestral Knowledge 5/5 replaces Improved Windfury Totem.",
          es = "La misma base 19/52/0 para equipo con poder con hechizos: el daño viene de Descarga de relámpagos con Arma vorágine, choques y Lengua de Fuego. Conocimiento ancestral 5/5 sustituye a Tótem Viento Furioso mejorado.",
      } },
    { name = "Restoration", variant = "resto",
      title = { ru = "Исцеление (рейд)", en = "Restoration (raid)", es = "Restauración (banda)" },
      glyphs = { major = { 41517, 45775, 41527 }, minor = { 43386, 43385, 43388 } },
      note = {
          ru = "Основная ветка 0/13/58 и новичку, и опытному: Цепное исцеление по рейду, Быстрина и Щит земли на танка, «Грохочущие удары» ради крита — он возвращает ману через Водный щит.",
          en = "Main 0/13/58 for both new and seasoned healers: Chain Heal on the raid, Riptide and Earth Shield on the tank, Thundering Strikes for crit, which returns mana through Water Shield.",
          es = "Rama principal 0/13/58 para novatos y veteranos: Sanación en cadena en la banda, Mareas Vivas y Escudo de tierra en el tanque, Golpes de trueno por el crítico, que devuelve maná con Escudo de agua.",
      } },
}
