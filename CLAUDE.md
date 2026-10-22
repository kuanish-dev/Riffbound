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
  их методами `_on_<факт>`. Время приходит параметрами, часы он сам не читает.
- Код управляется таблицами: `Songs.BUILT_IN` (табы), `Songs.EVENT_NOTES`, `Tuning.SCALES`, `Synth.BACKINGS`/
  `PROGRESSIONS`, `Timing.JUDGEMENTS`, `SongJudge.STARS`/`TECH_NAMES`, `InputConfig.KEYS`, `Main.COMMANDS`
  (режим → клавиша → метод), `TouchPad.GUITAR`/`EXTRA` (сенсорные кнопки → те же действия ввода), `Hud.FOOTER`, `Hud._draw_top_<режим>`/`_draw_highway_<режим>`, `GuitarVoices.LEAD_FX`,
  `Autoplay._do_<действие>`. Ветки `if id == "..."` не добавлять.
- Лады A S D F (1–4), удары J K L, бенд — пробел. Звучит верхний из зажатых ладов (как на гитаре);
  аккорд — один лад и удар по нескольким струнам. 4-й лад = 1-й лад следующей струны (струны перекрываются).
- Время игры — только из `Conductor` (позиция звука), не из кадров. Удары оцениваются по `player_time()`.
- Разработка (бот, тесты, снимки) — только в `dev/`; она не сохраняет рекорды и песни (`Songs.persist = false`).
- Новая встроенная песня обязана проходить `test_built_in_songs_are_playable` и `--sim` на 100%.

## Подводные камни
- `Performance` — имя встроенного синглтона Godot, классу так называться нельзя (поэтому `SongJudge`).
- `when` — ключевое слово (охрана в match), именем переменной не годится.
- Android-экспорт требует `rendering/textures/vram_compression/import_etc2_astc=true`; иконки проекта пока нет (стандартная Godot).
- Godot 4.7 GLES3: `msaa_2d` не поддерживается — сглаживание через `antialiased` в draw-вызовах.
- В headless у заглушки аудиодрайвера проигрывания не убираются → голоса нот там не создаются
  (`StringVoice.silent`), часы идут по кадрам. Выход — через `Main.quit()` (сначала глушит звук).
- Окно в фоне macOS почти не рисует: снимки отключают vsync, но всё равно могут снять кадр позже `--at`.
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
# APK (пресет export_presets.cfg «Android», шаблоны 4.7.2, SDK/Java прописаны в editor_settings-4.7.tres):
JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home \
GODOT_ANDROID_KEYSTORE_RELEASE_PATH=$HOME/.android/debug.keystore \
GODOT_ANDROID_KEYSTORE_RELEASE_USER=androiddebugkey GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD=android \
godot --headless --path . --export-release "Android" build/Riffbound.apk
# проверка на эмуляторе: emulator -avd droptuner -no-window -no-audio -gpu swiftshader_indirect; adb install -r …;
# adb shell am start -n com.riffbound.game/com.godot.game.GodotAppLauncher; adb exec-out screencap -p > shot.png
```
