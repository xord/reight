# Reight

レトロゲームエンジン。組み込み IDE によるスプライト・マップ・サウンドの編集が可能。

## CLI

```bash
r8 --edit .   # エディタを起動
```

## 組み込みエディタ

- **SpriteEditor** (`app/sprite/`) — ピクセルアートエディタ。ブラシ、塗りつぶし、選択、図形ツール
- **MapEditor** (`app/map/`) — チャンクベースのタイルマップエディタ
- **SoundEditor** (`app/sound/`) — 波形ベースのサウンドエディタ

各エディタは `App` 基底クラスを継承し、Tool パターンで描画ツールを切り替える。

## プロジェクトデータ

JSON ファイルで管理:
- `project.json` — プロジェクト設定
- `chips.json` — タイルセット
- `maps.json` — マップデータ
- `sounds.json` — サウンドデータ

## 定数

- 画面解像度: 400x224
- パレット: 32 色（`PALETTE_COLORS`）
- スプライトサイズ: 8x8 ピクセル単位
