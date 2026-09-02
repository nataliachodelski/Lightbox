# Lightbox

A native macOS app for hand-writing SVG. It has a live preview and lets you overlay a reference image so you can trace artwork by eye.

Lightbox is basically a code editor with syntax highlighting on one side and a WebKit preview on the other, which updates as you type. You can also drop in a reference image (above or below the canvas) and trace over it.

<img width="1012" height="564" alt="Screenshot 2026-09-02 at 19 57 43" src="https://github.com/user-attachments/assets/fcd8ecf8-bdd8-4294-9f82-6e2d13b14c58" />

## Features

- **Live SVG preview**: the canvas redraws shortly after you stop typing, so you catch mistakes right away.
- **Code editor**: XML syntax highlighting, line numbers, comment toggling (`⌘/`), and autocomplete for tags and attributes based on a built-in SVG schema.
- **Reference images**: drag one in (or use `⇧⌘I`), then position, scale, rotate, and adjust its opacity and stacking order from the inspector. These settings are saved per document.
- **Canvas controls**: zoom in, out, to-fit, or to actual size, plus checkerboard, white, black, or custom backgrounds.
- **Safety**: `<script>` tags get stripped before rendering, and you'll see a one-time warning banner when that happens.
- **Native document handling**: `.svg` files are just plain text, handled through `FileDocument`/`DocumentGroup`, so Lightbox works like any other document-based Mac app: open, save, versions, all of it.

## Installing

Grab `Lightbox-<version>-macOS.zip` from the [Releases page](https://github.com/StephentheGD/Lightbox/releases), unzip it, and drag `Lightbox.app` into `/Applications`.

The app is signed ad-hoc, not notarized, so macOS will block it the first time you try to open it. You'll get a message saying it "cannot be opened because Apple cannot check it for malicious software." To get past that:

1. Try opening Lightbox and dismiss the warning.
2. Go to **System Settings → Privacy & Security**, scroll down to the Security section, and click **Open Anyway** next to the Lightbox message.
3. Click **Open** to confirm.

You only have to do this once per version you install. If you'd rather skip it entirely, build from source instead. Local builds don't trigger this prompt.

## Requirements

- macOS 14.0+
- Xcode 16.2+ (needed for the Icon Composer `.icon` asset format)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen), to generate the `.xcodeproj`

## Building

Generate the .xcodeproj from [`project.yml`](project.yml) by running:

```bash
./regenerate.sh
```

Use this instead of running `xcodegen generate` directly. XcodeGen doesn't understand the `.icon` format yet, so the script patches the generated project afterward to make Xcode recognize the app icon.

From there, open `Lightbox.xcodeproj` and run the `Lightbox` scheme.

For a distributable build, run [`release.sh`](release.sh). It regenerates the project, builds Release for both architectures, and zips up `dist/Lightbox-<version>-macOS.zip`.

## Project structure

```
Lightbox/
  Document/   SVGDocument (FileDocument) and the default new-document template
  Editor/     Code editor, XML syntax highlighter, autocomplete engine, SVG schema
  Preview/    WKWebView bridge that renders SVG source and reports zoom/errors
  Reference/  Reference image import, storage, and overlay controller
  UI/         Top-level SwiftUI views (split view, toolbar, inspector)
LightboxTests/
```
