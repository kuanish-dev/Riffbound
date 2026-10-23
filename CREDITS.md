# Авторы и лицензии материалов

Код Riffbound — свой. Звуки, треки, текстуры и шрифты — чужие, под свободными лицензиями. Всё ниже собрано
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
Коробейники (народная), «В пещере горного короля» (Григ), «Ода к радости» (Бетховен), Токката ре минор (Бах) —
общественное достояние; табы упрощены и записаны для игры.
