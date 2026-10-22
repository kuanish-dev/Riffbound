class_name Layout
## Разметка экрана 1280×720 — все координаты показа в одном месте.

const SCREEN := Vector2(1280, 720)
const TOP_H := 54.0
const STAGE := Rect2(0, 54, 1280, 198)        ## сцена с музыкантом
const FLOOR_Y := 246.0
const MUSICIAN := Vector2(150, 244)           ## точка между ступнями
const NECK_TIP := Vector2(262, 132)           ## гриф гитары: отсюда разлетаются вспышки нот
const AMP := Rect2(24, 140, 80, 106)
const HIGHWAY := Rect2(20, 262, 1240, 236)    ## дорожка-таб: ноты едут справа к линии удара
const LANE_GAP := 70.0                        ## расстояние между струнами на дорожке
const HIT_X := 230.0                          ## линия удара на дорожке
const SLOT_PX := 46.0
const CONTROLS_Y := 512.0                     ## лады, струны, бенд
const FOOTER_Y := 640.0
const MAP := Rect2(700, 62, 560, 182)         ## карта грифа в джеме
const LOOP_BAR := Rect2(840, 512, 420, 40)    ## лупер в джеме
const LOOP_BAR_TOUCH := Rect2(712, 8, 436, 38) ## на сенсоре низ занят кнопками — лупер в верхней полосе
