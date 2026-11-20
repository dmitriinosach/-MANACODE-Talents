local ADDON, ns = ...
ns.stdBuilds = ns.stdBuilds or {}
ns.stdBuilds.WARLOCK = {
    { name = "Affliction", variant = "affli",
      title = { ru = "Колдовство (рейд)", en = "Affliction (raid)", es = "Aflicción (banda)" },
      glyphs = { major = { 50077, 45779, 45785 }, minor = { 43390, 43389, 43394 } },
      note = {
          ru = "Основная ветка: доты, Блуждающий дух и Стрела Тьмы, ниже 25% здоровья цели Похищение души. Охотник Скверны с Матерым охотником Скверны не остаётся без маны.",
          en = "The main build: DoTs, Haunt and Shadow Bolt, Drain Soul below 25% target health. Improved Felhunter keeps the Felhunter from running out of mana.",
          es = "La rama principal: efectos de daño en el tiempo, Poseer y Descarga de las Sombras, y Drenar alma por debajo del 25% de salud. Manáfago mejorado evita que el manáfago se quede sin maná.",
      } },
    { name = "Affliction (Intensity)", variant = "affli",
      title = { ru = "Колдовство (урон по рейду, АоЕ)", en = "Affliction (raid damage, AoE)", es = "Aflicción (daño a la banda, área)" },
      ranks = {
          [1] = {2,3,5,0,0,0,2,0,3,1,0,2,3,5,1,0,0,5,3,5,0,0,3,3,1,1,5,1},
          [2] = {},
          [3] = {5,5,0,0,0,0,0,5,2},
      },
      glyphs = { major = { 50077, 45779, 45785 }, minor = { 43390, 43389, 43394 } },
      note = {
          ru = "Для боёв, где по вам постоянно идёт урон: Напряжение 2/2 не даёт сбивать Стрелу Тьмы, Усиление проклятия ускоряет проклятия на нескольких целях. Питомец без Матерого охотника Скверны бьёт слабее.",
          en = "For fights with constant damage on you: Intensity 2/2 stops Shadow Bolt pushback, Amplify Curse speeds up curses on several targets. Without Improved Felhunter the pet deals less damage.",
          es = "Para combates con daño constante sobre ti: Intensidad 2/2 evita los retrasos de Descarga de las Sombras y Amplificar maldición acelera las maldiciones en varios objetivos. Sin Manáfago mejorado la mascota hace menos daño.",
      } },
    { name = "Demonology", variant = "demo",
      title = { ru = "Демонология (рейд)", en = "Demonology (raid)", es = "Demonología (banda)" },
      glyphs = { major = { 50077, 45785, 42459 }, minor = { 43389, 43390, 43394 } },
      note = {
          ru = "Страж Скверны и Демонический союз: рейд получает силу заклинаний от вашей. Ниже 35% здоровья цели Истребление делает Ожог души быстрым, Метаморфоза по готовности.",
          en = "Felguard and Demonic Pact: the raid gains spell power from yours. Below 35% target health Decimation makes Soul Fire fast; use Metamorphosis on cooldown.",
          es = "Guardia vil y Pacto demoníaco: la banda gana poder con hechizos a partir del tuyo. Por debajo del 35% de salud, Diezmar acelera Fuego de alma; usa Metamorfosis en cuanto esté lista.",
      } },
    { name = "Destruction (Стандарт: +5 своих очков)", variant = "destro",
      title = { ru = "Разрушение (с Поглощением души)", en = "Destruction (with Soul Leech)", es = "Destrucción (con Parasitar alma)" },
      ranks = {
          [1] = {},
          [2] = {0,3,3,1,0,0,3,0,0,0,3},
          [3] = {0,5,2,0,3,2,0,5,2,2,0,1,3,1,0,5,1,3,3,5,2,3,1,3,5,1},
      },
      glyphs = { major = { 42454, 42453, 42464 }, minor = { 43390, 43394, 43389 } },
      note = {
          ru = "Универсальная ветка с бесом: Поглощение души возвращает ману и даёт рейду Восполнение, Жизнеотвод почти не нужен. Жертвенный огонь, Поджигание, Стрела Хаоса, Испепеление.",
          en = "The all-round imp build: Soul Leech returns mana and gives the raid Replenishment, so Life Tap is rarely needed. Immolate, Conflagrate, Chaos Bolt, Incinerate.",
          es = "La rama versátil con diablillo: Parasitar alma devuelve maná y da Reposición a la banda, así que Transfusión de vida casi no hace falta. Inmolar, Conflagrar, Descarga de caos, Incinerar.",
      } },
    { name = "Destruction (Имп: под 2сет Т9)", variant = "destro",
      title = { ru = "Разрушение (сильный бес)", en = "Destruction (strong imp)", es = "Destrucción (diablillo fuerte)" },
      glyphs = { major = { 42454, 42453, 45785 }, minor = { 43390, 43394, 43389 } },
      note = {
          ru = "Больше урона беса за счёт Нечистой силы, без Поглощения души. Для рейда, где Восполнение дают другие; ману берёте Жизнеотводом, его символ добавляет силу заклинаний от духа.",
          en = "More imp damage from Unholy Power, no Soul Leech. For raids where others bring Replenishment; mana comes from Life Tap, and its glyph adds spell power from Spirit.",
          es = "Más daño del diablillo gracias a Poder profano, sin Parasitar alma. Para bandas donde otros dan Reposición; el maná sale de Transfusión de vida y su glifo da poder con hechizos según el espíritu.",
      } },
}
