# Pixel Importer 91 README 改善議論の引き継ぎメモ（Claude向け）

作成日：2026-11-05

## 1. このメモの目的

原神UGC（Miliastra Wonderland）向けツール **Pixel Importer 91** の README 改善について、ChatGPTとの議論で確定した方針、採用済みの修正、未確定の提案を整理する。

Claudeには、**元の `README.md`、改訂英語版、改訂日本語版と本メモを合わせて確認し、提案内容を批判的にレビューしてほしい**。現在の改訂版を無条件に正解とみなす必要はない。ユーザーの決定事項を優先しながら、事実関係・読みやすさ・英日間の整合性を確認することが目的。

## 2. 対象ファイルと位置づけ

| ファイル | 位置づけ |
| --- | --- |
| `README.md`（元のファイル） | 改訂前の英語README。215行。導入の詳細なQuick startが含まれている。 |
| `README.revised.md` | ChatGPTが作成し、ユーザーとの議論を反映して更新した英語の改訂案（最新版）。 |
| `Pixel_Importer_91_README.md` | `README.revised.md` と同じ内容を別名で渡したもの。読み込みに問題があったため作成。 |
| `README.ja.md` | 改訂英語版に対応する日本語訳。 |
| `README.proposed.md` | 初期の改訂案。Quick startを詳しくする方向だったが、その後方針を変更したため、**現在の推奨案ではない**。 |

最終的にGitHubで使う場合は、英語版を `README.md`、日本語版を `README.ja.md` として相互リンクさせる想定。

## 3. ツールの概要（READMEで伝えたい内容）

Pixel Importer 91 は、Miliastra WonderlandのClient Scripts（Lua）で、画像をImageControlとして表示するための非公式ツール。主な開発目的は、**既存のUI画像表示手法では生成データが大きくなり、多数の画像を1ステージに入れにくい**という問題の解決。

本ツールは**明確に異なる2つのコンポーネント**から構成される。

1. **ブラウザ版コンバーター (`index.html`)**：PNGをリサイズ・必要に応じて91色に量子化し、Lua画像データと `Index.lua` を生成する。変換はブラウザ内で完結し、インストールや画像アップロードは不要。
2. **Luaレンダラー (`lua/PixelView.lua`)**：Client Scriptsから変換済みデータを読み込み、ImageControlで表示する。デコード、隣接する同色ドットの結合、ImageControlの再利用などを担当。

**「コンバーターがデータを作り、Luaレンダラーがゲーム内で表示する」**という役割分担を、冒頭で分かりやすく説明したい。この点はユーザーの要望によって改訂版に追加済み。

関連リンク（改訂版に記載されているもの）：

- コンバーター：https://hiro400.github.io/pixel-importer-91/
- 解説動画：https://youtu.be/Akh2coZszas

## 4. ユーザーが確定した編集方針（重要）

### A. READMEに詳細なQuick startを載せない

当初、ChatGPTはQuick startを増補し、Script Mapping、ImageControlテンプレート、エディタの操作を段階的に説明することを提案した。しかしユーザーは、**これらは動画ですでに詳しく説明しているため、READMEで繰り返すのはむしろ不要**と判断した。

その結果、次の方針に変更・合意した。

- **詳細なQuick startセクションは削除する**。
- README冒頭の動画リンクから操作チュートリアルへ案内する。
- READMEの主目的は **ツールの紹介、機能・設定・API・性能・データ形式・技術的仕組みのリファレンス** とする。
- **最小限のLuaコード例は残す**。ただし `PixelView API` の中に置き、動画で説明したエディタ側の準備が済んでいることを前提とする。
- `examples/Main.lua` のような完全な例への参照は有用。

**注意：Claudeから改良案を出す場合も、詳細なQuick startを再導入しないでほしい。**

### B. フォルダ例は `external_lua_file/images` に統一する

元のREADMEには `mygame/images` という例があり、Luaの `require` も `mygame/images/Index` となっていた。この点についてユーザーが確認し、**`mygame` を除く方が分かりやすい**と決定した。

採用する例：

```text
external_lua_file/
├── pixel_importer/
│   └── PixelView.lua
└── images/
    ├── Index.lua
    └── sample.lua
```

```lua
local PixelView = require("pixel_importer/PixelView")
local Images = require("images/Index")
```

コンバーターの **Folder in your stage** の設定例は `images`。これはREADME内での**説明用の推奨例**であり、実装がこの配置を強制する、あるいはコンバーターのデフォルト値が必ず `images` である、と断定しないこと。別のフォルダを使う場合は読み込みパスを合わせる。

### C. 「Why Pixel Importer 91?」の説明文はユーザー指定の文章を採用

ユーザーは、**ツールの開発時のチャットに基づく**として、以下の英語本文と箇条書きを具体的に指定し、改訂版への反映を依頼した。これは開発目的・機能の伝え方について最も優先度の高い参照文である。文言を大幅に変える必要がある場合は理由を説明してほしい。

> Existing UI image rendering tools tend to produce large files, making it difficult to include many images in a single Miliastra Wonderland stage. Pixel Importer 91 solves this problem by storing image data in a highly compact format, at the cost of limiting each image to 91 colors.
>
> Key features include:
>
> - **Compact Lua data.** PNG image data is converted into Lua files, using approximately one byte per pixel to store color information. Taking advantage of the 91-color limitation, the tool further compresses the data using an encoding scheme similar to Run-Length Encoding (RLE).
> - **Fewer ImageControls.** Adjacent pixels of the same color can be combined into a single wider ImageControl (**Merge**, enabled by default).
> - **Efficient rendering.** Previously created ImageControls are reused whenever possible. The `Grow` function also allows ImageControls to be created gradually across multiple frames, reducing freezes during initial rendering.
> - **Batch conversion.** Convert multiple PNG images at once and manage them through the automatically generated `Index.lua` file.
> - **Local conversion.** The converter runs entirely in your browser, requiring no installation or image uploads.
> - **Flexible settings.** Adjust image resolution, resizing method, transparency threshold, merging, and display-time resolution.

この文章では、**ファイルサイズ削減を主眼とし、ImageControl数の削減・描画効率・バッチ変換・ローカル動作を別の特長として説明**している。

### D. 重複する「Its main trade-off...」は削除

ユーザーは、91色制限についてすでに「Why Pixel Importer 91?」と「Limitations」で説明しているので、箇条書きの後にあった **`Its main trade-off...`** という重複文を削除することを了承した。再び追加する必要はない。

### E. 英語版と日本語版を併用する

改訂英語版の後、日本語版を作ることも依頼された。`README.ja.md` では**章構成・情報量・コード・API名・ファイルパス・設定名を基本的に英語版と揃える**。自然な日本語にしつつ、技術的な意味を変えないこと。

## 5. 現在の改訂版READMEの構成

`README.revised.md` の大まかな構成：

1. 冒頭の紹介：ツールの目的、2コンポーネントの説明、コンバーター・動画・日本語版へのリンク
2. `Demo and video tutorial`：スクリーンショットと動画への誘導。READMEの役割の説明
3. `Why Pixel Importer 91?`：ユーザー指定の導入文・特徴6項目
4. `PixelView API`：最小コード例、メソッド表、`Grow` の使い方、オプション表、読み込み失敗時の挙動
5. `Choosing the settings`：コンバーター側の設定とLua表示側の設定の使い分け
6. `Performance`：Compress（RLE）とMergeの効果を分離して説明し、実測データを記載
7. `Data format`：非圧縮データ形式、RLE符号化の概要
8. `How it works`：リサイズ、91色への量子化、Lua符号化、レンダリング
9. `Limitations`
10. `Privacy and safety`、`Disclaimer`、`License`

章立ては確定的な仕様ではないが、**チュートリアルではなくリファレンス中心**の構成はユーザーと合意済み。

## 6. 技術的な説明で維持したい区別・注意

### CompressとMergeは別の機能

- **Compress (RLE)**：生成される `.lua` の**画像データサイズ**を削減する。ImageControl数を直接減らすものではない。
- **Merge**：横方向に連続した同色ドットを1つのImageControlにまとめ、**表示時のImageControl数や描画コスト**を減らす。PNG自体のサイズを削減する機能ではない。
- **Grow**：ImageControlを複数フレームに分けて生成し、一度に大量生成することによるフリーズやカクつきを軽減する。
- **Count/Prepare**：画像のレイアウト計算を先に済ませる。
- **Clear/再利用**：ImageControlを破棄せず非表示にし、後の表示に再利用する。
- **step**：変換し直さず表示時に間引いて表示解像度を変更する。`step = 2` なら縦横が概ね半分、表示ドット数は概ね1/4（Merge適用前）。

### 実測値と推測を混同しない

改訂READMEに記載されている**特定の128×144画像の測定例**：

| 指標 | Merge off | Merge on |
| --- | ---: | ---: |
| ImageControls | 18,432 | 8,607 |
| `Show` 時間 | 約0.32秒 | 約0.16秒 |

これは**単一画像での測定例であり、一般的な性能保証ではない**。別の画像での圧縮率、Luaファイルサイズ削減率、レンダリング速度を根拠なく断定しない。ファイルサイズについては、可能なら別途実測値を加えることが初期提案にあったが、**その測定自体はまだ行っていない**。

### 技術的な内容を残したい

READMEの後半には、以下を説明している。

- 91色への減色とCIE Lab空間でのk-means++
- 色の出現頻度を用いた量子化
- 1ドット＝1文字のLua文字列によるデータ表現
- 水平方向の連続色や直前の行の繰り返しを利用するRLE型圧縮
- `.` を透過として扱うこと、空白による圧縮コードの区別
- 画像ごとに独立した91色パレット
- 二値化された透明度、ImageControlの実用上の制限

「91色はLua全般の制限」ではなく、**このツールの符号化形式で選択した文字集合の制約**として説明するのが適切、という指摘があった。

上記の正確性については、**実装コードと照合できる場合に照合してほしい**。現在のREADMEに記載されているからといって無検証で確定事項としない。

## 7. まだ決定していない・必要なら検討すること

これらはChatGPT側の提案や確認ポイントであり、ユーザーがすべて採用すると決めたわけではない。

- **性能セクションの改善**：実測条件を可能な範囲で明確にし、Luaデータファイルサイズの比較を追加すると説得力が上がる。ただし測定していない数値は作らない。
- **コード例とAPI仕様の照合**：`Grow(count, total)`、`Count`、`Prepare`、`Show`、`Clear`、`step`、`merge`、`gap`、`pivotX` の挙動や、エラー時の扱いがコードに一致するか確認する。
- **RLE詳細**：連続長の符号化・上限・行間参照・例示がコードと一致しているか検証する。
- **日本語版の校正**：訳語や言い回しの自然さ、英語版との齟齬を確認する。
- **文書分割案**：過去に `README.md` と `TECHNICAL.md` に分ける案も出たが、**採用は決まっていない**。無理に分割する必要はない。

## 8. Claudeへの依頼事項

1. まず、元の英語README・現行の英語改訂案・日本語版とこのメモを比較し、**ユーザーが承認した変更が維持されているか**確認してほしい。
2. 特に、**Quick startを詳しく復活させないこと**、**`mygame` をパス例に戻さないこと**、**ユーザー指定の「Why Pixel Importer 91?」を尊重すること**を優先してほしい。
3. 英語の可読性、重複の有無、説明の順序、技術的な正確性、日本語との整合性について、必要な修正だけを提案してほしい。
4. 元のREADMEまたは実装コードから確証の得られない箇所は、**「要確認」と明示**してほしい。未測定のベンチマーク結果を捏造しないでほしい。
5. 修正する場合は、**どこを・なぜ変更したか**を説明し、できれば英語版と日本語版の両方に変更を反映してほしい。

**編集の基本方針を一文でまとめると：**

> このREADMEは、動画チュートリアルを見たユーザーが、Pixel Importer 91の特徴・設定・Lua API・性能・データ形式を理解し、必要に応じて参照できる、正確で読みやすい技術資料にする。
