# 12 音频资产清单（美术 demo 版）

> 生成：2026-10-31 ｜ 脚本：`tools/gen_audio_demo.py`（`python tools/gen_audio_demo.py all`）
> 共 46 条，全部为**程序合成的临时素材**；触发点对应 `scripts/prologue/prologue_demo.gd` 的 State 与回调。
> 已有的船夫配音（`assets/audio/npc/*.mp3`）保持不动，本包不重复生成人声。

---

## 一、怎么用

1. 文件已在 `assets/audio/{music,ambience,sfx,ui,sting}/`，Godot 打开工程会自动导入。
2. 先接 P0（29 条），就能让整个 demo 有声音；P1（17 条）是打磨。
3. 场景切换建议：音乐淡出 0.3 s、底噪交叉 0.8 s；`SceneTransition` 的 0.28 s 黑场正好盖住。
4. 船夫说话时把 `amb_*` 压低 4 dB、音乐压低 6 dB，别盖过 mp3 对白。
5. 替换成正式素材时保持文件名与时长接近，触发代码不用改。

---

## 二、音乐（6）

| 文件 | 时长 | 场景 | 用途 | 触发（代码） | 优先级 | 备注 |
|---|---|---|---|---|---|---|
| `mus_title_theme_v01.wav` | 34s | 标题画面 | 主主题：3/4 拍摇篮曲，钢琴 + 音乐盒，全篇唯一的旋律来源 | `main.tscn 进入时` | P0 | 16 小节 34 s loop；后 8 小节加音乐盒 |
| `mus_cabin_warm_v01.wav` | 40s | 船舱 | 船舱日常：同一主题转 F 大调，暖、慢、留白 | `State.CABIN_CLOSED / CABIN_OPEN` | P0 | 12 小节 40 s loop |
| `mus_boat_drift_v01.wav` | 32s | 船上 | 行驶：低频 drone + 每小节四个音的琶音，像船身在水上晃 | `State.BOAT` | P0 | 8 小节 32 s loop；引擎声交给 amb_boat_moving |
| `mus_dock_dusk_v01.wav` | 30s | 码头 / 船夫 | 极简：只有低频和每 7 秒一枚钢琴单音，把空间让给对白 | `State.DOCK / FERRYMAN` | P1 | 30 s loop；船夫说话时压低 -6 dB |
| `mus_end_card_v01.wav` | 13s | 序章结束页 | 收束：主题最后一次完整陈述，然后留白 | `prologue_end.tscn` | P1 | 13 s 单次，不循环 |
| `mus_hotel_night_v01.wav` | 38s | 旅馆正门 / 信箱 | 夜：D 小调 drone + 高音音乐盒，冷但不吓人 | `State.HOTEL_EXTERIOR → HOTEL_DOOR_OPEN` | P0 | 8 小节 38 s loop |

## 三、Sting（1）

| 文件 | 时长 | 场景 | 用途 | 触发（代码） | 优先级 | 备注 |
|---|---|---|---|---|---|---|
| `sting_logo_v01.wav` | 8.5s | 序章标题卡 | 钟 + 上行钢琴，标题卡出现时的唯一一次大动作 | `State.PROLOGUE_LOGO` | P0 | 8.5 s 单次；配合 5 秒停留 |

## 四、环境底噪（7）

| 文件 | 时长 | 场景 | 用途 | 触发（代码） | 优先级 | 备注 |
|---|---|---|---|---|---|---|
| `amb_boat_moving_v01.wav` | 40s | 船上 | 水声 + 2.3 Hz 引擎闷响 + 船体吱呀 + 远处海鸥 | `State.BOAT` | P0 | 40 s 循环；引擎是这版的特色，画面有烟囱 |
| `amb_dock_dusk_v01.wav` | 45s | 码头 | 拍岸水声 + 缆绳吱呀 + 海鸥 + 远处房子 | `State.DOCK / FERRYMAN` | P0 | 45 s 循环；船夫对白时压低 -4 dB |
| `amb_interior_v01.wav` | 40s | 近景（床头柜 / 箱子） | 室内近景：更干、更近的房间底噪 + 钟 | `State.SUITCASE_VIEW / NIGHTSTAND_VIEW` | P1 | 40 s 循环；比主船舱低 2 dB |
| `amb_cabin_closed_v01.wav` | 45s | 船舱（关窗） | 室内底噪 + 挂钟滴答 + 隔着百叶窗的海 | `State.CABIN_CLOSED` | P0 | 45 s 循环；滴答 1 Hz，左右脚交替 |
| `amb_cabin_open_v01.wav` | 45s | 船舱（开窗） | 同一房间，开窗后海和风进来、海鸥变清楚 | `State.CABIN_OPEN 起` | P0 | 45 s 循环；与 closed 版交叉淡化 0.8 s |
| `amb_hotel_night_v01.wav` | 45s | 旅馆正门 | 夜海 + 风 + 门灯电流 100 Hz | `State.HOTEL_EXTERIOR / HOTEL_NO_MAILBOX / HOTEL_DOOR_OPEN` | P0 | 45 s 循环；门灯 hum 是“有人在等你”的暗示 |
| `amb_mailbox_v01.wav` | 40s | 信箱近景 | 风 + 远处海 + 铁皮共振，比门外更近、更空 | `State.MAILBOX_CLOSED / MAILBOX_OPEN` | P1 | 40 s 循环 |

## 五、场景音效（24）

| 文件 | 时长 | 场景 | 用途 | 触发（代码） | 优先级 | 备注 |
|---|---|---|---|---|---|---|
| `sfx_window_latch_v01.wav` | 0.2s | 船舱 | 点窗框插销 | `_on_window_input()` | P0 | 金属插销 + 木框，短 |
| `sfx_window_open_v01.wav` | 2.2s | 船舱 | 把窗推开：插销、窗框、海一下涌进来 | `_on_window_input() 后接转场` | P0 | 2.2 s；第三段是空气变宽 |
| `sfx_door_cabin_v01.wav` | 1.3s | 船舱 | 推开船舱门离开 | `_on_door_input() → State.BOAT` | P0 | 门把 + 门轴 + 合上 |
| `sfx_suitcase_open_v01.wav` | 1.4s | 船舱 | 进入床前箱子近景 | `_on_suitcase_input() → SUITCASE_VIEW` | P1 | 两个搭扣 + 箱盖吱呀 |
| `sfx_knife_take_v01.wav` | 0.9s | 船舱 | 从箱子里拿起小刀 | `_on_suitcase_knife_input()` | P0 | 金属滑出 + 短鸣 |
| `sfx_fish_take_v01.wav` | 1.1s | 船舱 | 从水桶里拿起死鱼 | `_on_fish_input()` | P0 | 湿手 + 两滴水 |
| `sfx_heron_sewn_v01.wav` | 0.9s | 船舱 | 点击缝着嘴的白鹭 | `_on_heron_input()（heron_cut 之前）` | P1 | 瓷 + 绷紧的红线 |
| `sfx_thread_cut_v01.wav` | 1.2s | 船舱 | 用小刀割开喙上的红线 | `_use_on_heron('knife')` | P0 | 线绷断“铮”，一声 |
| `sfx_beak_open_v01.wav` | 1.0s | 船舱 | 白鹭张嘴，切到 cabin_open_beak | `_use_on_heron('knife') → CABIN_BEAK` | P1 | 木/瓷的开口声 |
| `sfx_heron_swallow_v01.wav` | 0.9s | 船舱 | 把鱼喂进白鹭嘴里 | `_use_on_heron('fish')` | P0 | 干咽，不要拟人化 |
| `sfx_coin_drop_v01.wav` | 2.4s | 船舱 | 硬币从鸟嘴掉到木地板 | `_drop_coin_from_beak()（0.85 s 补间）` | P0 | 配 0.85 s 动画：第 1 下最重，转两圈才停 |
| `sfx_coin_pickup_v01.wav` | 0.8s | 船舱 | 点击地板上的硬币 | `_on_coin_pickup()` | P0 | 金属 + 指甲刮 |
| `sfx_nightstand_touch_v01.wav` | 1.0s | 船舱 | 进入床头柜近景 | `_on_nightstand_input() → NIGHTSTAND_VIEW` | P1 | 木头轻响 + 黄铜灯罩 + 纸角 |
| `sfx_letter_take_v01.wav` | 0.8s | 船舱 | 收下母亲的信 | `_on_note_hotspot_input()（第二次）` | P0 | 纸滑进手里；纸条浮层本身用 ui_note_open |
| `sfx_dock_step_v01.wav` | 1.6s | 码头 | 踏上码头 / 走到船夫面前 | `State.BOAT → FERRYMAN` | P1 | 湿木板三步 + 缆绳 |
| `sfx_coin_palm_v01.wav` | 0.4s | 码头 | 把硬币放到船夫掌心 | `_pay_ferryman()（拖拽 coin）` | P0 | 金属落皮手套，闷 |
| `sfx_cloth_shift_v01.wav` | 0.8s | 码头 | 船夫侧身让开 | `_pay_ferryman() 之后` | P1 | 雨披/外套的布料 |
| `sfx_hotel_arrive_v01.wav` | 2.4s | 旅馆 | 从码头转向旅馆正门 | `_on_hotel_hotspot_input()` | P1 | 一阵风 + 低频，遮住淡入淡出 |
| `sfx_key_appear_v01.wav` | 0.9s | 旅馆 | 信箱消失后拿到钥匙 | `State.HOTEL_NO_MAILBOX 进入` | P0 | 金属一闪；对应 mailbox_key 入栏 |
| `sfx_key_insert_v01.wav` | 1.0s | 旅馆 | 把钥匙拖到门上 | `_on_item_dropped('mailbox_key')` | P0 | 入孔 + 两下转动 |
| `sfx_hotel_door_v01.wav` | 2.4s | 旅馆 | 旅馆大门打开 | `State.HOTEL_DOOR_OPEN` | P0 | 2.4 s 门轴 + 空气 + 落锁 |
| `sfx_mailbox_open_v01.wav` | 1.2s | 旅馆 · 信箱 | 打开锈死的信箱门 | `_on_mailbox_closeup_input()` | P0 | 锈铁铰链，略长 |
| `sfx_mailbox_close_v01.wav` | 0.6s | 旅馆 · 信箱 | 信箱合上 / 切换状态 | `State.MAILBOX_OPEN → HOTEL_EXTERIOR` | P1 | 金属碰铁皮 |
| `sfx_letter_insert_v01.wav` | 1.1s | 旅馆 · 信箱 | 把信投进信箱 | `_post_letter()（拖 letter）` | P0 | 纸 + 铁皮箱空腔 |

## 六、界面音（8）

| 文件 | 时长 | 场景 | 用途 | 触发（代码） | 优先级 | 备注 |
|---|---|---|---|---|---|---|
| `ui_click_v01.wav` | 0.1s | 全局 | 标题开始/退出、返回箭头 | `main.tscn / back_arrow / hotel_return_arrow` | P0 | 干燥、短、无混响 |
| `ui_drag_pick_v01.wav` | 0.1s | 全局 | 从道具栏拖起一件东西 | `game_hud._start_drag()` | P1 | 布料 + 极轻金属 |
| `ui_drop_ok_v01.wav` | 0.9s | 全局 | 拖到有效目标 | `prologue_demo._on_item_dropped() 命中` | P0 | 一声小钟，别太亮 |
| `ui_drop_fail_v01.wav` | 0.2s | 全局 | 拖到无效位置 | `prologue_demo._on_item_dropped() 未命中` | P1 | 闷响，不刺耳 |
| `ui_item_gain_v01.wav` | 1.0s | 全局 | 道具进入右侧格子 | `GameState.add_item() → inventory_changed` | P0 | 纸 + 小钟；5 格固定列 |
| `ui_note_open_v01.wav` | 0.9s | 全局 | 纸条/信件浮层打开 | `hud.show_note()` | P1 | 纸展开 |
| `ui_note_close_v01.wav` | 0.3s | 全局 | 点击关闭纸条浮层 | `hud._on_note_input()` | P1 | 纸合上 |
| `ui_speech_pop_v01.wav` | 0.2s | 全局 | NPC 气泡出现（船夫说话时） | `hud.show_speech()` | P1 | 极轻的一声，别盖住 mp3 对白 |

---

## 七、优先级

| 优先级 | 数量 | 含义 |
|---|---|---|
| P0 | 29 | demo 必须有 |
| P1 | 17 | 打磨层 |

## 八、这版没有的东西

- **服务生 / 白鹭夫人的人声**：`WAITER`、`EGRET` 两个状态目前只有文字气泡，没有配音。
  合成人声会很出戏，建议真人录或用与船夫同一套 TTS 音色补。
- **旅馆门前解谜**：当前 demo 已删除该逻辑，所以没有外套/扣子/钥匙那一套音效。
- **第一章 113**：还没进 demo，本包不预生成。

## 九、已知局限

- 全部为加性合成 + 噪声整形：钢琴/弦乐偏电子，海鸥和引擎只是“像”，不是真录音。
- 混响是合成 IR，空间感弱于真实卷积。
- 作用是把 demo 的节奏跑通；正式版需要真人演奏、拟音与配音替换。
