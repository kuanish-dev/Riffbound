# Riffbound — заметки для Claude

Симулятор гитары на клавиатуре (бывший ритм-экшен: врагов и цветов больше нет), Godot 4.7.2, GDScript
типизированный, всё строится кодом (редактор не используется). Управление, табы и устройство — в README.md.
Комментарии по-русски, идентификаторы по-английски.

## Правила архитектуры
- `core/` не знает о `view/` и `audio/`; связывает всё `app/main.gd`. Службы для показа — через `Game`.
- Игра на гитаре — события `{kind, string, fret, pos, midis, amount}`, kind = метод `StringVoice`
  (pluck, slur, mute, dead, bend). Их одинаково играет живой голос и слои лупера, пишет `Looper`,
  выгружает `MidiFile`, превращает в песню `Songs.from_layer`.
- Песню оценивает `SongJudge` (чистая модель): наружу только факты `fact(kind, data)`, показ проигрывает
  их методами `_on_<факт>`. Время приходит параметрами, часы он сам не читает. Так же устроен `StyleMeter`:
  ест факты оценки, время — в `update()`, наружу — `ranked(rank, up)` (его слушают StyleView, Shaker,
  FxLayer, звук в Main). Баланс рангов — `StyleMeter.RANKS`/`GAIN`/`DROP`; `--sim` печатает стиль каждой песни.
- Код управляется таблицами: `Songs.BUILT_IN` (табы), `Songs.EVENT_NOTES`, `Tuning.SCALES`, `Backing.STYLES`/
  `PARTS`/`PROGRESSIONS`, `Tracks.BUILT_IN`/`LOADERS`, `SampleBank.NOTES`, `FxLayer.TEX`, `Shop.SKINS` (облик гитары —
  данные), `UiSounds.SOUNDS` (рецепты звуков отклика), `Main.COMMAND_SOUNDS`/`FACT_SOUNDS`, `StyleMeter.RANKS`, `Shaker.KICKS`/`SWAY`, `Sfx.UP`/`DOWN`, `Layout.GUITAR_POSES`, `StageView.PALETTE`/
  `STRIPES`/`SHADOWS`, `Glyph.NEON_LAYERS` (вид в духе Hotline Miami — неоновые надписи через `Glyph.neon`), `GuitarArt.SHAPES`/`HEADS`/`PICKUPS`, `TouchPad.lists()` (списки строками: меню, магазин), `Timing.JUDGEMENTS`, `SongJudge.STARS`/`TECH_NAMES`, `InputConfig.KEYS`, `Main.COMMANDS`
  (режим → клавиша → метод), `TouchPad.GUITAR`/`EXTRA` (сенсорные кнопки → те же действия ввода), `Hud.FOOTER`, `Hud._draw_top_<режим>`/`_draw_highway_<режим>`, `GuitarVoices.LEAD_FX`,
  `Autoplay._do_<действие>`, `Main._load_<kind>`/`_tap_<kind>` (подложка: style / track). Ветки `if id == "..."` не добавлять.
- Темп переменный: `Timing.bpm` (песня — `bpm`, трек — свой), длины — `Timing.slot_len()`/`beat_len()`/`bar_len()`.
  Ставит его Main до `performance.start()` и `conductor.start()`; лупер — `Looper.BARS` тактов текущего темпа.
- Музыка — круг в целых тактах: `Conductor.set_music(stream, секунды, loop_start, offset)`. Встроенные треки
  `tools/build_assets.py` режет ровно в `bars` тактов от сильной доли; свои — часы заворачивают сами.
  Метроном (N, `Game.metronome`) — второй плеер Conductor (`set_click`, луп `Backing.metronome` в такт):
  стартует и перескакивает вместе с музыкой, выключенный играет беззвучно — так он не уходит с доли.
- Ассеты: только CC0 / OFL / CC-BY с упоминанием, всё в `CREDITS.md`; `assets/` пересобирается `tools/build_assets.py`
  (исходники не в репозитории — ссылки в CREDITS). Чужие песни с авторским правом не добавлять.
- Лады A S D F (1–4), удары J K L, бенд — пробел. Звучит верхний из зажатых ладов (как на гитаре);
  аккорд — один лад и удар по нескольким струнам. 4-й лад = 1-й лад следующей струны (струны перекрываются).
- Время игры — только из `Conductor` (позиция звука), не из кадров. Удары оцениваются по `player_time()`.
- Разработка (бот, тесты, снимки) — только в `dev/`; она не сохраняет рекорды, песни и магазин (`Songs.persist = false`;
  тесты, которые меняют сохраняемое, ставят его сами).
- Звук гитары — «tone» скина: эффекты шины Lead (`GuitarVoices.set_tone`, Main следит в `_sync_tone`: надетая,
  в магазине — выбранная). Новый звук: свойства проверяет `test_tones_are_valid`, громкость — `--tones`
  (держать около −18 дБ, как «кранч»; подгонять post_gain перегруза или AudioEffectAmplify в конце).
- Интерфейс минимальный (игрок не должен путаться): на экране только нужное сейчас. Подсказка клавиш — одна строка
  `Hud.HINTS` на режим; что жать перед нотой — `Hud._cue()` (мигают клавиши и кнопки); сенсорные кнопки прячутся
  по `needs` (`Game.needs` — умения песни) и `more` (панель «Ещё» джема, `Game.more`). Новую кнопку или надпись —
  только если без неё не сыграть; второстепенное — в «Ещё».
- Каждое действие игрока звучит: команда без исхода — строка в `Main.COMMAND_SOUNDS`, с исходом — `_say(звук, текст)`
  в методе (не `hud.toast` напрямую). Имена звуков проверяет `SoundTests` (и в таблицах, и в вызовах в коде).
- Новая форма корпуса обязана проходить `ShopTests` (контур триангулируется, ручки и звукосниматели на корпусе);
  смотреть все гитары разом — снимок `--shop --skin=N` или лист скинов.
- Новая встроенная песня обязана проходить `test_built_in_songs_are_playable` и `--sim` на 100%.

## Подводные камни
- Петля `AudioStreamWAV`: микшер читает за `loop_end` — на Android это SIGSEGV через ~1 круг (на Mac молча).
  Поэтому `Backing.to_wav` дописывает за концом `LOOP_PAD` сэмплов начала петли.
- Android 11+: Godot читает файлы напрямую только в «Документах» и «Загрузках»; «Музыка» идёт через MediaStore,
  где чужих файлов не видно («File not found», хотя `DirAccess` их листает). Свои треки — `Документы/Riffbound`,
  разрешение `READ_MEDIA_AUDIO` (custom_permissions) + `OS.request_permissions()`.
- `input_devices/pointing/emulate_touch_from_mouse` делает `is_touchscreen_available()` = true и на компьютере —
  в проект не ставить; `--touch` включает эмуляцию из кода.
- WAV барабанов и баса — `compress/mode=0` в `.import` (по умолчанию QOA, тогда `AudioStreamWAV.data` не PCM).
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
- Общие лады на все струны: прижатый лад, пока звенит другая струна, даёт на ней хаммер-он. Поэтому оценка
  прощает случайное легато, а бот переставляет пальцы «сначала отпустить».

## Команды (всегда с таймаутом)
```sh
godot --headless --path . --import
perl -e 'alarm 120; exec @ARGV' godot --headless --path . -- --test                       # [test] PASS — N/N
perl -e 'alarm 150; exec @ARGV' godot --headless --fixed-fps 120 --path . -- --sim        # [sim] PASS
perl -e 'alarm 150; exec @ARGV' godot --path . -- --screenshot=<png> --song=4 --at=14 --autoplay
perl -e 'alarm 150; exec @ARGV' godot --path . -- --screenshot=<png> --jam --backing=funked_up --at=6
perl -e 'alarm 120; exec @ARGV' godot --path . -- --tones                  # громкость звуков гитар (динамики молчат)
python -I tools/build_assets.py <папка_загрузок> [tracks]     # assets/ (numpy, scipy, soundfile, librosa, ffmpeg)
# APK (пресет export_presets.cfg «Android», шаблоны 4.7.2, SDK/Java прописаны в editor_settings-4.7.tres):
JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home \
GODOT_ANDROID_KEYSTORE_RELEASE_PATH=$HOME/.android/debug.keystore \
GODOT_ANDROID_KEYSTORE_RELEASE_USER=androiddebugkey GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD=android \
godot --headless --path . --export-release "Android" build/Riffbound.apk
# проверка на эмуляторе: emulator -avd droptuner -no-window -no-audio -gpu swiftshader_indirect; adb install -r …;
# adb shell am start -n com.riffbound.game/com.godot.game.GodotAppLauncher; adb exec-out screencap -p > shot.png
```
