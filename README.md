# QuickLooker

A modern macOS Quick Look extension for plain text files.

Previews files that macOS won't — dotfiles, extensionless files, scripts, Markdown, and anything else that's plain text.

## Requirements

- macOS 13+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- Xcode 15+

## Build & Install

The Xcode project is generated from `project.yml` and not committed. Run:

```bash
xcodegen generate
xcodebuild -project QuickLooker.xcodeproj \
  -scheme QuickLooker \
  -configuration Release \
  -derivedDataPath build

cp -Rf build/Build/Products/Release/QuickLooker.app /Applications/
xattr -cr /Applications/QuickLooker.app
```

Then register the extension:

```bash
pluginkit -a /Applications/QuickLooker.app/Contents/PlugIns/QuickLookerExtension.appex
pluginkit -e use -i com.quicklooker.app.preview-extension
qlmanage -r && qlmanage -r cache
```

If macOS prompts you to approve it, open **System Settings → Privacy & Security** and allow it.

## Usage

Select any file in Finder and press **Space**. QuickLooker handles:

- Extensionless files (`README`, `Makefile`, `LICENSE`, `.env`, `.gitignore`, …)
- `.md` / Markdown files
- Shell scripts, Python, Ruby, and other text-based executables
- Anything else where the content is valid UTF-8, UTF-16, or Latin-1

## Uninstall

```bash
pluginkit -e ignore -i com.quicklooker.app.preview-extension
rm -rf /Applications/QuickLooker.app
```
