# Riffbound — заметки для Claude

Симулятор гитары на клавиатуре (бывший ритм-экшен: врагов и цветов больше нет), Godot 4.7.2, GDScript
типизированный, всё строится кодом (редактор не используется). Управление, табы и устройство — в README.md.
Комментариев в коде нет (просьба пользователя): код объясняет себя именами, короткими функциями и файлами
с одной обязанностью — кусок кода должен читаться без чтения соседних. Неочевидное «почему» и форматы данных —
здесь, в CLAUDE.md, а правила игры — в README.md. Идентификаторы по-английски, тексты для игрока — по-русски.

## Правила архитектуры
- `core/` не знает о `view/` и `audio/`; связывает всё `app/`: `Main` — режимы и маршрут команд, `SceneBuilder` —
  сборка сцены, `MusicLoader` — подложка и метроном, `JamSession`/`ShopScreen`/`CommonCommands` — команды режимов,
  `GuitarRouter` — события гитары в голос, лупер и оценку, `Feedback` — звуки отклика. Службы для показа — через `Game`.
- Показ: `Hud` — фасад над слоями `view/hud/` (экран на режим: `MenuView`, `SongView`, `ResultsView`, `JamView`,
  `ShopView`; `KeyControls`/`TouchControls`; `Toast`); общее — `Lanes` (дорожка), `Cue` (что жать), `Strikes`, `Ink`.
  Сенсор — `view/touch/` (`TouchPad` — пальцы, `TouchButtons`/`TouchLists` — раскладка, `BendGesture`, рисование —
  `PadArt`/`StringArt`/`NeckArt`). Гитара на сцене — `view/guitar/` (`GuitarArt`, формы — `GuitarShapes`).
- Игра на гитаре — события `{kind, string, fret, pos, midis, amount}`, kind = метод `StringVoice`
  (pluck, slur, mute, dead, bend). Их одинаково играет живой голос и слои лупера, пишет `Looper`,
  выгружает `MidiFile`, превращает в песню `Songs.from_layer`.
- Песню оценивает `SongJudge` (чистая модель): наружу только факты `fact(kind, data)`, показ проигрывает
  их методами `_on_<факт>`. Время приходит параметрами, часы он сам не читает. Так же устроен `StyleMeter`:
  ест факты оценки, время — в `update()`, наружу — `ranked(rank, up)` (его слушают StyleView, Shaker,
  FxLayer, звук в Main). Баланс рангов — `StyleMeter.RANKS`/`GAIN`/`DROP`; `--sim` печатает стиль каждой песни.
- Код управляется таблицами: `Difficulty.LEVELS` (пять уровней: какие доли остаются, аккорды, глушняки, техника, рука сама — `auto_hand`, окно, монеты, ключ рекорда; чем выше, тем больше механик — `test_harder_levels_add_mechanics`),
  `SongBook.SONGS` (табы), `LayerSong.EVENT_NOTES`, `Tuning.SCALES`, `Backing.STYLES`/
  `PARTS`/`KEYS`, `Harmony.QUALITIES`/`PROGRESSIONS`, `Tracks.BUILT_IN`/`LOADERS`, `SongTracks.TRACKS`, `SampleBank.NOTES`, `FxLayer.TEX`, `Shop.SKINS` (облик гитары —
  данные), `UiSounds.SOUNDS` (рецепты звуков отклика), `Main.COMMAND_SOUNDS`, `Feedback.FACT_SOUNDS`, `StyleMeter.RANKS`, `Shaker.KICKS`/`SWAY`, `Sfx.UP`/`DOWN`, `Layout.GUITAR_POSES`, `StageView.PALETTE`/
  `STRIPES`/`SHADOWS`, `Glyph.NEON_LAYERS` (вид в духе Hotline Miami — неоновые надписи через `Glyph.neon`), `GuitarShapes.SHAPES`/`HEADS`/`PICKUPS`, `TouchLists.lists()` (списки строками: меню, магазин), `Timing.JUDGEMENTS`, `SongJudge.STARS`/`TECH_NAMES`, `InputConfig.KEYS`, `Main.COMMANDS`
  (режим → клавиша → «метод» или «объект.метод»), `TouchButtons.GUITAR`/`EXTRA` (сенсорные кнопки → те же действия ввода;
  вид — `art` → `TouchControls._draw_<art>`, лады — гриф `NeckArt`), `GuitarVoices.LEAD_FX`,
  `Autoplay._do_<действие>`, `MusicLoader._load_<kind>`, `JamSession._tap_<kind>` (подложка: style / track). Ветки `if id == "..."` не добавлять.
- Темп переменный: `Timing.bpm` (песня — `bpm`, трек — свой), длины — `Timing.slot_len()`/`beat_len()`/`bar_len()`.
  Ставит его Main до `performance.start()` и `conductor.start()`; лупер — `Looper.BARS` тактов текущего темпа.
- Музыка — круг в целых тактах: `Conductor.set_music(stream, секунды, loop_start, offset)`. Встроенные треки
  `tools/build_assets.py` режет ровно в `bars` тактов от сильной доли; свои — часы заворачивают сами.
  Метроном (N, `Game.metronome`) — второй плеер Conductor (`set_click`, луп `Backing.metronome` в такт):
  стартует и перескакивает вместе с музыкой, выключенный играет беззвучно — так он не уходит с доли.
- Уроки и песни: каждая играет под свой трек (backing = id трека, тот же id), трек — живая группа, сведённая
  заранее (`tools/band.py`: STYLES, MIX). Один источник — `tools/classics_data.py` (урок — таб `tab`, песня — мелодия
  нотами `melody` → таб с позициями руки, где меньше сдвигов); `tools/classics.py book` пишет `core/song_book.gd`
  и `core/song_tracks.gd` целиком — руками их не править. Порядок — от лёгкого к трудному: сначала уроки
  (`lesson: true`, по механике на урок; `keeps` — правила уровня, которые урок не отдаёт: `Difficulty.rules_for`,
  `SongJudge.rules`), потом песни по росту трудности; держит `ProgressionTests` (трудность —
  плотность нот + техники; техника песни сначала есть в уроке). Треки уроков (`jam: false`) не в джеме
  (`MusicLoader.jam_choices`). Согласованность трека и песни — `test_song_tracks_match_songs`.
  Сэмплы (~750 МБ) — вне репозитория, в `~/Desktop/projects/riffbound-sources` (что откуда — CREDITS.md).
- Гармония — `Harmony` (имя аккорда → ноты). Музыка знает свои аккорды по тактам: `Game.chords` (по кругу от начала часов).
  Стиль играет их (`Backing.render(id, аккорды)`: бас — ступени `BASS_NOTES`, клавиши — аккорд), у песни — её `chords`
  (`Songs.chords_of`, весь таймлайн с отсчётом), в джеме — `Harmony.progression` строя, у трека — найденные по звуку
  (`build_assets.py --chords`, проверять на слух). Hud в джеме подсвечивает ноты аккорда (`_draw_chords`, карта «Ещё»).
  Новая песня — с аккордом на каждый такт (`test_song_chords`).
- Код — GPL-3.0 (`LICENSE`, кладётся и в APK). Ассеты: только CC0 / OFL / CC-BY с упоминанием, всё в `CREDITS.md`; `assets/` пересобирается `tools/build_assets.py`
  (исходники не в репозитории — ссылки в CREDITS). Чужие песни с авторским правом не добавлять.
- Лады A S D F (1–4), удары J K L, бенд — пробел (на тон); на сенсоре бенд любой высоты до `Tuning.BEND_MAX` —
  тяга пальцем (`bend_pull` с силой), вибрато — покачивание, слайд — палец по ладам (`slide`, высота съезжает в `StringVoice`). Звучит верхний из зажатых ладов (как на гитаре);
  аккорд — один лад и удар по нескольким струнам. 4-й лад = 1-й лад следующей струны (струны перекрываются).
- Время игры — только из `Conductor` (позиция звука), не из кадров. Удары оцениваются по `player_time()`.
- Разработка (бот, тесты, снимки) — только в `dev/`; она не сохраняет рекорды, песни и магазин (`Songs.persist = false`;
  тесты, которые меняют сохраняемое, ставят его сами).
- Звук гитары — «tone» скина: эффекты шины Lead (`GuitarVoices.set_tone`, Main следит в `_sync_tone`: надетая,
  в магазине — выбранная). Новый звук: свойства проверяет `test_tones_are_valid`, громкость — `--tones`
  (держать около −18 дБ, как «кранч»; подгонять post_gain перегруза или AudioEffectAmplify в конце).
- Интерфейс минимальный (игрок не должен путаться): на экране только нужное сейчас. Подсказка клавиш — одна строка
  `KeyControls.HINTS` на режим; что жать перед нотой — `Cue.next()` (мигают клавиши и кнопки); сенсорные кнопки прячутся
  по `needs` (`Game.needs` — умения песни) и `more` (панель «Ещё» джема, `Game.more`). На сенсоре бенд — жест
  (удар по струне и тяга вбок, `BendGesture`), списки листаются пальцем (`Game.scroll`), строки — по отпусканию. Новую кнопку или надпись —
  только если без неё не сыграть; второстепенное — в «Ещё».
- Каждое действие игрока звучит: команда без исхода — строка в `Main.COMMAND_SOUNDS`, с исходом — `feedback.say(звук, текст)`
  в методе (не `hud.toast` напрямую). Имена звуков проверяет `SoundTests` (и в таблицах, и в вызовах в коде).
- Новая форма корпуса обязана проходить `ShopTests` (контур триангулируется, ручки и звукосниматели на корпусе);
  смотреть все гитары разом — снимок `--shop --skin=N` или лист скинов.
- Новая встроенная песня обязана проходить `test_built_in_songs_are_playable`, `ProgressionTests` и `--sim` на 100%
  на всех пяти уровнях.

## Подводные камни
- Подложки песен собираются в фоновом потоке, пока игрок в меню (`MusicLoader.prerender_tick`; на эмуляторе с SwiftShader
  песня собирается ~2 с, в основном потоке это была пауза после касания). Поэтому `Backing.render` не читает
  глобальное: темп — параметром, кэш сэмплов — свой у потока (`pcm`).
- Петля `AudioStreamWAV`: микшер читает за `loop_end` — на Android это SIGSEGV через ~1 круг (на Mac молча).
  Поэтому `Backing.to_wav` дописывает за концом `LOOP_PAD` сэмплов начала петли.
- Android 11+: Godot читает файлы напрямую только в «Документах» и «Загрузках»; «Музыка» идёт через MediaStore,
  где чужих файлов не видно («File not found», хотя `DirAccess` их листает). Свои треки — `Документы/Riffbound`,
  разрешение `READ_MEDIA_AUDIO` (custom_permissions) + `OS.request_permissions()`.
- `input_devices/pointing/emulate_touch_from_mouse` делает `is_touchscreen_available()` = true и на компьютере —
  в проект не ставить; `--touch` включает эмуляцию из кода.
- WAV барабанов и баса — `compress/mode=0` в `.import` (по умолчанию QOA, тогда `AudioStreamWAV.data` не PCM).
- Swagbass подписывает ноты на октаву выше, чем они звучат («a1» — это A0): файлы `assets/bass/<midi>.wav` названы
  по настоящей высоте (`build_assets.BASS_OCTAVE`). Раньше бас подложки звучал на октаву ниже (~30–60 Гц, телефон
  его не воспроизводит). Emily — по-научному, VSCO — на две октавы ниже (`band.scan`).
- Аккорды треков — такты через «|», внутри такта — через пробел («D A|Bm F#m»).
- Rubik — вариативный шрифт, по умолчанию Light: вес задаёт `FontVariation` (`Glyph.text_font()`).
  Ресурсы в `static var` дают «resources still in use at exit» — шрифт держит ThemeDB.
- libsndfile падает, если писать длинный Vorbis одним блоком — `build_assets.write_ogg` пишет кусками.
- `Performance` — имя встроенного синглтона Godot, классу так называться нельзя (поэтому `SongJudge`).
- `when` — ключевое слово (охрана в match), именем переменной не годится.
- Android-экспорт требует `rendering/textures/vram_compression/import_etc2_astc=true`; иконки проекта пока нет (стандартная Godot).
- Godot 4.7 GLES3: `msaa_2d` не поддерживается — сглаживание через `antialiased` в draw-вызовах.
- В headless у заглушки аудиодрайвера проигрывания не убираются → голоса нот там не создаются
  (`StringVoice.silent`), часы идут по кадрам. Выход — через `Main.quit()` (сначала глушит звук).
- Окно в фоне macOS почти не рисует: снимки отключают vsync, но всё равно могут снять кадр позже `--at`
  (а изредка песня в снимке не дойдёт до `--at` за время alarm — просто повторить).
- Текстуры Kenney — чёрные с альфой по краям: рисовать их только со сложением цветов (FxLayer, ореол StyleView),
  обычное смешивание даёт тёмный квадрат.
- Лямбда в сигнале, захватившая `self`, держит объект: тест, подключивший лямбду к сигналу своей модели,
  обнуляет модель в `after_all`, иначе утечка при выходе.
  Окно игры при запуске забирает фокус: если пользователь в это время печатает, нажатия попадут в игру.
- `Input.parse_input_event` доходит до `_unhandled_input` только на следующем кадре (бот действует с запасом).
- Легато живёт `Fretboard.LEGATO_WINDOW` (0,65 с) от прошлой ноты на струне: на медленном темпе нота перед
  хаммер-оном или пулл-оффом не может тянуться долго (90 bpm — уже не две восьмые). `test_built_in_songs_are_playable`
  считает это по темпу песни.
- Общие лады на все струны: прижатый лад, пока звенит другая струна, даёт на ней хаммер-он. Поэтому оценка
  прощает случайное легато, а бот переставляет пальцы «сначала отпустить».

## Форматы данных
- Таб песни (`SongBook`): такт — строка на струну из восьми клеток: `-` пусто, `1`…`4` удар по ладу, `x` глушняк,
  `h2`/`p1` легато к ладу без удара, `…b` бенд, `=` держать ноту ещё восьмую; `pos` такта — позиция руки;
  `chords` — аккорд на такт («Am E» — два аккорда делят такт); `backing` — стиль `Backing.STYLES` или id трека.
- Партии подложки (`Backing.STYLES`, `tools/band.py` STYLES): такт — строка из восьми восьмых: `.` тишина,
  строчная — удар, заглавная — с акцентом. Бас: `x` корень аккорда, `o` октава, `f` квинта. Гитара группы: `x` —
  глушёный ладонью пауэр-аккорд, `X` — открытый (звенит до следующего удара). Клавиши/струнные: аккорд до следующего.
  `order` — какие такты стиля по кругу; у группы `count`/`intro` — два такта отсчёта, `end` — последний такт.
- Аккорды трека (`Tracks.BUILT_IN`): такты через `|`, внутри такта — через пробел («D A|Bm F#m»).
- Мелодия песни (`tools/classics_data.py`): по тактам, восемь восьмых: нота (`E5`, `D#5`, `Bb4`), `-` пауза, `=` держать;
  у урока вместо `melody` — `tab` (такты как в `SongBook`), `counter` — подголосок чистой гитарой в треке.
- Жест для снимка (`dev/gestures.gd`): `[время, палец, press|drag|lift|wiggle, кнопка, сдвиг от её середины]`;
  wiggle — палец качается вокруг сдвига, пока не придёт его следующий шаг.
- Аргументы разработки (после `--`): `--test`, `--sim`, `--screenshot=<png>` (`--at=<с>`, `--autoplay`, `--jam`,
  `--menu`, `--shop --skin=N`, `--gesture=<имя>`), `--difficulty=novice|easy|medium|hard|expert`, `--song=N` (с 1), `--play`, `--jam`, `--backing=<id>`, `--touch`
  (мышь как палец), `--metronome`, `--more` (панель «Ещё»), `--tones` (громкость гитар).

## Почему так (неочевидное)
- Время игры — позиция звука в плеере (`Conductor`), не кадры: иначе ритм плывёт. Свой трек короче файла
  часы заворачивают сами (seek), без звука (headless) часы идут по кадрам, в тестах — вручную.
- Метроном выключенный играет беззвучно, а не стоит: так при включении он не сбивается с доли.
- Окно прощения `Fretboard.LENIENCY`: лад, зажатый чуть позже удара, считается ладом этого удара (звук удара
  тогда звучит ещё раз — `corrected`). Легато открыто `LEGATO_WINDOW` с последней ноты на струне.
- Сложность упрощает ноты песни при старте (`Difficulty.simplify` в `SongJudge.start`), окно попадания —
  `Timing.leniency`. Защита от двойного удара (`Timing.REPEAT_GUARD`) не растёт с окном: иначе повтор одной ноты
  восьмыми принимался за дребезг. Бот (`--sim`) по умолчанию играет «эксперт», `--difficulty=novice|easy|medium|hard` — другие; на уровнях с
  `auto_hand` руку сдвигает Main (`_move_hand_to_next_note`), бот её не трогает.
- MIDI: каждая струна — свой канал, чтобы бенд одной струны не тянул остальные.
- Звуки отклика (`UiSounds`) играют по кругу из пула плееров — быстрые звуки не обрывают друг друга.
- Аккорд на одной струне звучит тише каждой ноты (`StringVoice`), чтобы в сумме не громче одиночной.
- Камера (`Shaker`) чуть приближена, чтобы при наклоне не открывались углы; `CrtOverlay` рисуется с запасом
  за краем — на тряску. Блики корпуса гитары обрезаны по корпусу — у вогнутых форм иначе вылезают.
- Упакованный массив (`PackedFloat32Array`) в словаре или через `as` — копия: буфер звука передаётся параметром.
- Объект с корутиной (`await`) живёт, пока на него есть ссылка: долгие dev-режимы — узлы сцены (`Simulation`).
- Бот (`Autoplay`) переставляет лады «сначала отпустить», отпускает лады прошлой песни и сдвигает руку не раньше
  прошлой ноты — иначе случайное легато и не те ноты.
- Сенсор: бенд начинается, только если тянуть вбок (иначе это бой), сила — от точки удара.

## Команды (всегда с таймаутом)
```sh
godot --headless --path . --import
perl -e 'alarm 120; exec @ARGV' godot --headless --path . -- --test                       # [test] PASS — N/N
perl -e 'alarm 150; exec @ARGV' godot --headless --fixed-fps 120 --path . -- --sim        # [sim] PASS
perl -e 'alarm 150; exec @ARGV' godot --path . -- --screenshot=<png> --song=4 --at=14 --autoplay
perl -e 'alarm 150; exec @ARGV' godot --path . -- --screenshot=<png> --jam --backing=funked_up --at=6
perl -e 'alarm 150; exec @ARGV' godot --path . -- --screenshot=<png> --jam --touch --gesture=vibrato --at=2.3   # жесты: Gestures.SCRIPTS
perl -e 'alarm 120; exec @ARGV' godot --path . -- --tones                  # громкость звуков гитар (динамики молчат)
# GIF для README (docs/media; docs/.gdignore прячет папку от Godot и APK): кадры — Movie Maker Godot, GIF — ffmpeg
godot --path . --write-movie <папка>/song.avi --fixed-fps 30 -- --screenshot=<png> --song=5 --touch --autoplay --at=18
godot --path . --write-movie <папка>/jam.avi --fixed-fps 30 -- --screenshot=<png> --jam --touch --backing=rock_theme_3 --gesture=demo --at=7.6
ffmpeg -ss 5.5 -t 9.5 -i song.avi -vf "fps=10,scale=640:-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=96:stats_mode=diff[p];[b][p]paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle" -loop 0 docs/media/gameplay.gif
python -I tools/build_assets.py <папка_загрузок> [tracks]     # assets/ (numpy, scipy, soundfile, librosa, ffmpeg)
python -I tools/build_assets.py --chords                       # аккорды тактов встроенных треков → Tracks.BUILT_IN
# уроки и песни: ноты, аккорды, аранжировки — tools/classics_data.py; группа из сэмплов — tools/band.py (pedalboard)
python -I tools/classics.py book                               # core/song_book.gd + core/song_tracks.gd
python -I tools/classics.py render ~/Desktop/projects/riffbound-sources   # assets/tracks/<id>.ogg (~20 с)
# APK (пресет export_presets.cfg «Android», шаблоны 4.7.2, SDK/Java прописаны в editor_settings-4.7.tres):
JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home \
GODOT_ANDROID_KEYSTORE_RELEASE_PATH=$HOME/.android/debug.keystore \
GODOT_ANDROID_KEYSTORE_RELEASE_USER=androiddebugkey GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD=android \
godot --headless --path . --export-release "Android" build/Riffbound.apk
# проверка на эмуляторе: emulator -avd droptuner -no-window -no-audio -gpu swiftshader_indirect; adb install -r …;
# adb shell am start -n com.riffbound.game/com.godot.game.GodotAppLauncher; adb exec-out screencap -p > shot.png
```
