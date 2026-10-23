# Авторы и лицензии материалов

Код Riffbound — свой, под лицензией GNU GPL v3.0 (`LICENSE`). Звуки, треки, текстуры и шрифты — чужие,
под свободными лицензиями (GPL на них не распространяется). Всё ниже собрано
из исходных файлов скриптом `tools/build_assets.py` (что именно с ними сделано — в последней колонке).

## Треки для джема — `assets/tracks/` (CC0)
| Трек | Автор | Источник | Обработка |
|---|---|---|---|
| Rock Theme 3 | Umplix | [opengameart.org/content/rock-theme-3](https://opengameart.org/content/rock-theme-3) | 32 такта от сильной доли, громкость |
| Rocky Musicloop | johndekale | [opengameart.org/content/rocky-musicloop](https://opengameart.org/content/rocky-musicloop) | 19 тактов, громкость |
| Unchained Destiny (Rock) | nene | [opengameart.org/content/unchained-destiny-rock](https://opengameart.org/content/unchained-destiny-rock) | 32 такта, громкость |
| JRPG Epic Rock Battle Theme | HydroGene | [opengameart.org/content/jrpg-epic-rock-battle-theme-1](https://opengameart.org/content/jrpg-epic-rock-battle-theme-1) | 72 такта, громкость |
| Background Music Loop | Pro Sensory (Alex McCulloch) | [opengameart.org/content/background-music-loop](https://opengameart.org/content/background-music-loop) | 56 тактов, громкость |
| Funked Up | Joth | [opengameart.org/content/funked-up](https://opengameart.org/content/funked-up) | 24 такта, громкость |

Темп, сильная доля и тональность определены автоматически (librosa; для Rock Theme 3 и Rocky Musicloop темп —
из MIDI авторов).

## Подложки уроков и песен — `assets/tracks/` (lesson_1…lesson_10 и треки всех песен)
Аранжировки свои (`tools/classics_data.py`), сведены скриптом `tools/band.py` из сэмплов ниже: удары барабанов сведены
из многомикрофонной записи в стерео, гитара — чистый сигнал через перегруз и имитацию кабинета, всё — с компрессией,
эквализацией и ревербом (pedalboard от Spotify, GPL-3.0; в игру не входит).

| Инструмент | Авторы | Источник | Лицензия |
|---|---|---|---|
| MuldjordKit — барабаны (Tama Superstar) | Lars Muldjord, DrumGizmo ([drumgizmo.org](https://drumgizmo.org)); SFZ-версия — kinwie | [github.com/sfzinstruments/DrumGizmo.MuldjordKit](https://github.com/sfzinstruments/DrumGizmo.MuldjordKit) | [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) |
| Emily Guitar — ритм-гитара и подголосок | Karoryfer Samples | [github.com/sfzinstruments/karoryfer.emilyguitar](https://github.com/sfzinstruments/karoryfer.emilyguitar) | CC0 |
| Swagbass — бас | Karoryfer Samples | [github.com/sfzinstruments/karoryfer.swagbass](https://github.com/sfzinstruments/karoryfer.swagbass) | CC0 |
| VSCO 2 Community Edition — альты и виолончели | Versilian Studios | [github.com/sgossner/VSCO-2-CE](https://github.com/sgossner/VSCO-2-CE) | CC0 |

## Сэмплы — `assets/guitar/`, `assets/bass/`, `assets/drums/` (CC0, Karoryfer Samples)
| Инструмент | Источник | Обработка |
|---|---|---|
| Emily Guitar — электрогитара, прямой сигнал | [github.com/sfzinstruments/karoryfer.emilyguitar](https://github.com/sfzinstruments/karoryfer.emilyguitar) | перегруз, фильтр кабинета, 3.2 с на ноту, OGG |
| Swagbass — бас | [github.com/sfzinstruments/karoryfer.swagbass](https://github.com/sfzinstruments/karoryfer.swagbass) | обрезка, 16 бит |
| Big Rusty Drums — барабаны | [github.com/sfzinstruments/karoryfer.big-rusty-drums](https://github.com/sfzinstruments/karoryfer.big-rusty-drums) | обрезка, 16 бит |

## Текстуры — `assets/fx/` (CC0)
Kenney — [Particle Pack](https://kenney.nl/assets/particle-pack): light_01, light_03, flare_01, spark_04,
star_05, smoke_03, circle_05, уменьшены до 256×256.

## Шрифты — `assets/fonts/` (SIL Open Font License 1.1)
| Шрифт | Авторы | Лицензия |
|---|---|---|
| Rubik | The Rubik Project Authors ([github.com/googlefonts/rubik](https://github.com/googlefonts/rubik)) | `assets/fonts/Rubik-OFL.txt` |
| Russo One | Jovanny Lemonad | `assets/fonts/RussoOne-OFL.txt` |

## Мелодии песен
Коробейники (народная), «В пещере горного короля» (Григ), «Ода к радости» (Бетховен), Токката ре минор (Бах),
«Лебединое озеро» (Чайковский), Симфония №5 и «К Элизе» (Бетховен), Канон ре мажор (Пахельбель), «Турецкий марш»
(Моцарт), «Полёт шмеля» (Римский-Корсаков) — общественное достояние; табы упрощены и записаны для игры.
Уроки 1–10 сочинены для игры (GPL-3.0, как код).
