# Pixel Importer 91

Display your own images in **Miliastra Wonderland** using Client Scripts (Lua).

Pixel Importer 91 consists of **two components** that work together:

1. **Browser-based converter (`index.html`).** Resize and convert one or more PNG images into compact Lua data files, along with an automatically generated `Index.lua` for loading them. The converter runs entirely in your browser.
2. **Lua renderer (`lua/PixelView.lua`).** Use this library in your stage's Client Scripts to display the converted images through ImageControls. It handles image decoding, merging adjacent pixels, and reusing controls.

In short, **the converter prepares the image data, and the Lua renderer displays it in the game**. The tool supports pixel art, icons, illustrations, and photos.

**[Open the converter](https://hiro400.github.io/pixel-importer-91/)** · **[Watch the video tutorial](https://youtu.be/Akh2coZszas)** · **[日本語版 README](README.ja.md)**

## Demo and video tutorial

![The converter](examples/screenshot.png)

![The sample picture shown in the game](examples/in-game.png)

*In-game example: 16 × 16 dots, rendered with 69 ImageControls.*

**New to the tool? Start with the [video tutorial](https://youtu.be/Akh2coZszas).** It covers converting images, preparing the ImageControl template, registering Lua files in Script Mapping, and displaying the result in the editor.

This README is primarily a **reference** for the converter's features, the Lua API, performance considerations, and the data format. It does not repeat the editor setup walkthrough from the video.

## Why Pixel Importer 91?

Existing UI image rendering tools tend to produce large files, making it difficult to include many images in a single Miliastra Wonderland stage. Pixel Importer 91 solves this problem by storing image data in a highly compact format, at the cost of limiting each image to 91 colors.

Key features include:

- **Compact Lua data.** PNG image data is converted into Lua files, using approximately one byte per pixel to store color information. Taking advantage of the 91-color limitation, the tool further compresses the data using an encoding scheme similar to Run-Length Encoding (RLE).
- **Fewer ImageControls.** Adjacent pixels of the same color can be combined into a single wider ImageControl (**Merge**, enabled by default).
- **Efficient rendering.** Previously created ImageControls are reused whenever possible. The `Grow` function also allows ImageControls to be created gradually across multiple frames, reducing freezes during initial rendering.
- **Batch conversion.** Convert multiple PNG images at once and manage them through the automatically generated `Index.lua` file.
- **Local conversion.** The converter runs entirely in your browser, requiring no installation or image uploads.
- **Flexible settings.** Adjust image resolution, resizing method, transparency threshold, merging, and display-time resolution.

## PixelView API

### Minimal example

The following snippet illustrates the API after the editor setup shown in the video:

```lua
local PixelView = require("pixel_importer/PixelView")
local Images = require("images/Index")

local view = PixelView.New({
    parent = script.object,
    templateIndex = 1, -- replace with your ImageControl template index
    x = 200,
    y = 200,
    dotSize = 4,
})

view:Show(Images["sample"])
```

In this example, set **Folder in your stage** to `images` and place the generated files in `external_lua_file/images`, and `PixelView.lua` in `external_lua_file/pixel_importer`. The import paths are then `images/Index` and `pixel_importer/PixelView`. Adjust the `require` paths if you use a different folder. This snippet assumes `script.object` is an appropriate UI parent and that the ImageControl template already exists. For **large images**, pre-create controls with `Grow` before calling `Show`, as described below. See [`examples/Main.lua`](examples/Main.lua) for a more complete example.

### Methods

| Method | Description |
| --- | --- |
| `PixelView.New(options)` | Create a view. See the options below. |
| `view:Show(art)` | Display an image. Does nothing when that same image is already displayed. Passing `nil` hides it. |
| `view:Clear()` | Hide the displayed image without discarding the ImageControls; they can be reused later. |
| `view:Count(art)` | Return the number of ImageControls required with the current view settings. Also prepare the image layout for later display. Returns `0` for `nil`. |
| `view:Prepare(art)` | Prepare the layout without displaying the image. Usually unnecessary if `Count` is used. |
| `view:Grow(count, total)` | Create up to `count` additional ImageControls during the call, until the view has `total`. Return `true` when the target has been reached. |

`Show` normally calculates the positions and colors of the necessary controls the first time an image is displayed. `Count` or `Prepare` performs that calculation in advance, so the first `Show` has less work to do.

For large images, call `Grow` **once per frame** (for example, from `OnUpdate`) until it returns `true`:

```lua
local art = Images["sample"]
local total = view:Count(art)

-- In OnUpdate, repeat until this returns true:
if view:Grow(300, total) then
    view:Show(art)
end
```

A smaller first argument creates fewer ImageControls per frame and may reduce stuttering during preparation. The example above is an API usage pattern, not a complete event-handler script.

### `PixelView.New` options

| Option | Default | Description |
| --- | --- | --- |
| `parent` | Required | UI parent under which ImageControls will be created. |
| `templateIndex` | Required | Index of the ImageControl template. |
| `x`, `y` | `0`, `0` | Position of the top-left dot (`anchoredPositionX` / `Y`). |
| `dotSize` | `4` | Size of each dot and the distance between neighboring dot positions. |
| `step` | `1` | Display every `step`-th source dot in each direction. For example, `2` displays roughly half the width and height. |
| `merge` | `true` | Combine adjacent same-colored dots in each row into wider ImageControls. |
| `gap` | `0` | Gap between neighboring dots; must be smaller than `dotSize`. |
| `pivotX` | `0.5` | Horizontal pivot of the ImageControl template (`0` = left, `0.5` = center, `1` = right). Used when `merge` is enabled. |

### Missing images

If a generated image file cannot be loaded—for instance, because it is absent from Script Mapping—`Index.lua` prints a message like:

```text
[Pixel Importer 91] Cannot load: sample
```

That image is treated as `nil`; `view:Show(nil)` hides the current picture and `view:Count(nil)` returns `0`.

## Choosing the settings

### In the converter

- **Max width / Max height:** Limit the number of output dots while preserving the image's aspect ratio. Images that already fit are not enlarged.
- **Smooth / Sharp:** Use Smooth (bicubic) for illustrations or photos. Use Sharp (nearest-neighbor) for pixel art whose original pixels should remain distinct.
- **Alpha threshold:** Determine whether a resulting dot is opaque or transparent; partial transparency is not retained.
- **Compress (default: on):** Apply RLE to the exported Lua data. This affects file size, not the number of ImageControls used to display the image.
- **Merge (default: on):** Combine horizontal runs of identical colors when rendered, reducing the number of ImageControls. This affects rendering, not the underlying 91-color palette.

The converter also shows an output preview and the ImageControl count for each image, as well as the largest count in the batch.
The **step** and **merge** settings in the converter's preview section only change this preview and these counts, not the generated files.
Set them to the same values as in `PixelView.New` so that the counts match the game.

### When rendering in Lua

**`Grow`** pre-creates ImageControls over several frames. Creating thousands of controls all at once can cause a noticeable pause. Use `view:Count(art)` to determine how many are needed, then call `Grow` repeatedly before `Show`. If the game stutters while growing, decrease the per-frame `count`.

**`step`** lets you display a smaller version of the same image data without converting it again. With `step = 2`, roughly one quarter of the source dots are sampled (before any merging), so the number of ImageControls may fall substantially.

**`merge` and `gap`** interact. One wide ImageControl spans an entire merged run, including what would otherwise be gaps between its dots. If preserving visible gaps between individual dots matters, use `merge = false`.

**Reuse views when possible.** Each view manages its own ImageControls. Pictures shown in the same location at different times can share a view, and `Clear` hides an image without removing controls that may be used later.

## Performance

Two different optimizations matter:

| Optimization | What it reduces | What it does not necessarily reduce |
| --- | --- | --- |
| **Compress (RLE)** | Size of generated Lua image data | Number of ImageControls |
| **Merge** | Number of ImageControls and work needed to display an image | Size of the Lua image data (the generated files are the same) |

### ImageControl count and display time

An opaque 128 × 144 picture contains **18,432 dots**. Without merging, it requires 18,432 ImageControls. In one test with a 128 × 144 portrait, the following results were observed:

| Measurement | Merge off | Merge on |
| --- | ---: | ---: |
| ImageControls | 18,432 | 8,607 |
| `Show` time | About 0.32 s | About 0.16 s |

This is **one image-specific measurement**, not a benchmark guarantee. Merge is typically more effective on images with long horizontal runs of the same color. Highly detailed images may benefit less.

### Lua data size

With compression enabled, repeated dots and repeated patterns from the row above are represented by shorter codes. The resulting size reduction depends on the image; pictures with large uniform or repeated areas generally compress better than highly varied pictures.

For a meaningful comparison, check the **generated `.lua` file sizes** for your own images with Compress on and off. No universal compression ratio is implied by the measurements above, which concern ImageControls and display time.

## Data format

An uncompressed generated image has the following structure:

```lua
return {
    width = 16,
    height = 16,
    palette = {
        A = "#FAD250",
        B = "#281E32",
        ["7"] = "#46A06E",
    },
    rows = {
        "......BBBB......",
        "....BBAAAABB....",
        -- ...
    },
}
```

Each character in `rows` represents one dot. `.` means transparent; other characters refer to colors in `palette`. Every image has its own palette.

With **Compress** enabled, the file also contains `encoding = "rle"`. Each row then uses the following codes:

| Code | Meaning |
| --- | --- |
| A color key or `.` | One dot, written directly |
| Space + length + key | Repeat `key` for `length` dots |
| Two spaces + length | Copy `length` dots from the same positions in the row immediately above |

The run length is encoded as one character: `A` = 4, `B` = 5, and so on, up to `.` = 95, following the order of the encoding keys. For example, `" CA"` means six `A` dots. A compressed run starts at length four, because a three-character code would not save space for shorter runs.

Spaces do not occur in uncompressed rows, so they can identify RLE commands without conflicting with ordinary color keys.

## How it works

1. **Resize.** The converter shrinks images to fit the chosen maximum width and height without changing their aspect ratio. Smooth mode uses bicubic filtering, combining information from the source image; color channels are multiplied by alpha during resizing to reduce dark fringes at transparent edges. Sharp mode uses nearest-neighbor sampling, preserving individual pixel colors.
2. **Reduce colors.** Images with more than 91 colors are quantized using k-means in **CIE Lab** color space. The algorithm weights each color by its frequency and chooses initial clusters using **k-means++**, helping retain colors that are visually distinct even if they are less common. A fixed random seed makes the result reproducible.
3. **Encode Lua.** The most frequent color is assigned `A`, then the next most frequent color `B`, and so on. If compression is enabled, the encoder looks for runs of at least four identical dots or dots matching the row above, selecting the representation that covers more dots.
4. **Render.** `PixelView` decodes the image and positions ImageControls. When merging is enabled, consecutive same-colored dots in a row are drawn as a single wider control.

### Why 91 colors?

Each color is stored as a **single character in a Lua string**. The format uses 91 printable ASCII characters as palette keys; space, `.`, `"`, and `\` are reserved or excluded. In particular, `.` represents transparency and spaces mark RLE commands. This design keeps the image data compact without requiring a separate multi-character identifier for each dot.

The limit applies to **each image independently**: different images can use different 91-color palettes.

## Limitations

- **Maximum 91 colors per image.** Images with more colors are reduced automatically, so gradients and fine color differences may change.
- **Binary transparency only.** Each output dot is opaque or transparent, with the threshold set in the converter.
- **Large images still require many UI controls.** Merge, Grow, and `step` help, but they do not remove the game's practical performance constraints.
- **Merging changes the appearance of dotted gaps.** When `gap > 0`, horizontal merged runs fill the intervening spaces.

## Privacy and safety

The converter is a single HTML file with no external libraries. Its Content Security Policy restricts network access, so images are processed locally rather than uploaded. You can save `index.html` and use it offline.

## Disclaimer

This is an unofficial, fan-made tool. It is not affiliated with or endorsed by HoYoverse. Miliastra Wonderland is a trademark of its respective owner.

## License

[MIT](LICENSE)
