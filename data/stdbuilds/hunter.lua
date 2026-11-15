local ADDON, ns = ...
ns.stdBuilds = ns.stdBuilds or {}
ns.stdBuilds.HUNTER = {
    { name = "Beast Mastery",
      title = { ru = "Повелитель зверей (рейд)", en = "Beast Mastery (raid)", es = "Bestias (banda)" },
      glyphs = { major = { 42902, 42914, 42912 }, minor = { 43351, 43350, 43338 } },
      note = {
          ru = "Рейдовая ветка спека, 53/13/5: урон питомца и Звериный гнев по откату. Не хватает меткости, переложите очки из «Верной цели» в «Точное наведение».",
          en = "The raid build of the spec, 53/13/5: pet damage and Bestial Wrath on cooldown. If you are short on hit, move points from Careful Aim to Focused Aim.",
          es = "La rama de banda, 53/13/5: daño de la mascota y Cólera de bestias siempre que esté lista. Si te falta golpe, pasa puntos de Puntería cuidadosa a Puntería centrada.",
      } },
    { name = "Траппер",
      title = { ru = "Стрельба (траппер)", en = "Marksmanship (trap weaving)", es = "Puntería (con trampas)" },
      glyphs = { major = { 42912, 42914, 45733 }, minor = { 43351, 43350, 43338 } },
      note = {
          ru = "Стрельба со Взрывной ловушкой в ротации: ловушку ставят под босса вместо одного Верного выстрела. Ауры меткого выстрела в ветке нет, прибавку к силе атаки должен давать кто-то в рейде.",
          en = "Marksmanship with Explosive Trap in the rotation: the trap goes under the boss in place of one Steady Shot. There is no Trueshot Aura here, so someone in the raid has to bring the attack power buff.",
          es = "Puntería con Trampa explosiva en la rotación: la trampa se pone bajo el jefe en lugar de un Disparo firme. No lleva Aura de disparo certero, así que el poder de ataque debe darlo otro en la banda.",
      } },
    { name = "Marksmanship (raid)", variant = "mm",
      title = { ru = "Стрельба (рейд)", en = "Marksmanship (raid)", es = "Puntería (banda)" },
      ranks = {
          [1] = {5,0,2},
          [2] = {0,3,5,3,0,5,2,0,1,1,3,0,0,1,3,2,3,3,1,3,5,0,3,1,3,5,1},
          [3] = {5,0,0,0,0,0,2},
      },
      glyphs = { major = { 42912, 42914, 45732 }, minor = { 43351, 43350, 43338 } },
      note = {
          ru = "Обычная рейдовая стрельба без ловушек, 7/57/7, с Аурой меткого выстрела. «Точное наведение» добирает меткость: если кап набран вещами, эти очки можно отдать «Улучшенной метке охотника».",
          en = "Standard raid Marksmanship without traps, 7/57/7, with Trueshot Aura. Focused Aim covers hit: once gear caps it, those points can go to Improved Hunter's Mark.",
          es = "Puntería de banda sin trampas, 7/57/7, con Aura de disparo certero. Puntería centrada completa el golpe: si el equipo ya llega al tope, esos puntos pueden ir a Marca del cazador mejorada.",
      } },
    { name = "Survival (Раздача маны)",
      title = { ru = "Выживание (рейд, Восполнение)", en = "Survival (raid, Replenishment)", es = "Supervivencia (banda, Reposición)" },
      glyphs = { major = { 45731, 45732, 45733 }, minor = { 43351, 43350, 43338 } },
      note = {
          ru = "Основная ветка, 0/15/56: «Групповая охота» даёт рейду Восполнение. Разрывной выстрел по откату, Взрывная ловушка под босса, когда можно подойти.",
          en = "Main build, 0/15/56: Hunting Party gives the raid Replenishment. Explosive Shot on cooldown, Explosive Trap under the boss when you can step in.",
          es = "Rama principal, 0/15/56: Partida de caza da Reposición a la banda. Disparo explosivo siempre que esté listo y Trampa explosiva bajo el jefe cuando puedas acercarte.",
      } },
    { name = "Survival (Личный дпс: без Hunting Party)",
      title = { ru = "Выживание (личный урон)", en = "Survival (personal damage)", es = "Supervivencia (daño personal)" },
      glyphs = { major = { 45731, 45732, 45733 }, minor = { 43351, 43350, 43338 } },
      note = {
          ru = "Ветка 6/14/51 без «Групповой охоты»: очки ушли в «Сильный дух ястреба». Берите, если Восполнение рейду даёт кто-то другой, а меткость набрана вещами.",
          en = "The 6/14/51 build without Hunting Party: the points go into Improved Aspect of the Hawk. Take it when someone else brings Replenishment and your hit comes from gear.",
          es = "Rama 6/14/51 sin Partida de caza: los puntos van a Aspecto del halcón mejorado. Úsala si otro da Reposición a la banda y el golpe te lo da el equipo.",
      } },
    { name = "Survival (Мульти-дот: без Hunting Party)", drop = true },
}
