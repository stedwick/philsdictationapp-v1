# Tauri + React + Typescript

This template should help get you started developing with Tauri, React and Typescript in Vite.

## Recommended IDE Setup

- [VS Code](https://code.visualstudio.com/) + [Tauri](https://marketplace.visualstudio.com/items?itemName=tauri-apps.tauri-vscode) + [rust-analyzer](https://marketplace.visualstudio.com/items?itemName=rust-lang.rust-analyzer)

<!--TODO: [PWA] install-->
<!--TODO: [Test] in more browsers-->
<!--https://developer.mozilla.org/en-US/docs/Web/API/Web_Speech_API#browser_compatibility-->
<!--https://kagi.com/search?q=Google+analytics+free+alternative-->
<!--MAYBE: [App Stores] https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps/Guides/Making_PWAs_installable-->
## Deploy

```
npm config set prefix="~/.npm-global"
npm install netlify-cli -g
netlify login
netlify link
npm run build
npm run preview
netlify deploy --dir dist --alias syncta-speech
```

## Microsoft Store release (Windows)

Store listing: https://apps.microsoft.com/detail/9ntphh45ffrn (Partner Center: Apps and games → Phil's Dictation App).

Requires Rust, Node, and the Windows SDK (for `makeappx.exe` / `makepri.exe`).

1. Bump the version in `src-tauri/tauri.conf.json` (`package.version`) and `src-tauri/Cargo.toml`. The Store only accepts a version higher than the published one.
2. Build the app, then the MSIX:
   ```
   npx tauri build
   npm run msix
   ```
   Output: `src-tauri/target/release/bundle/msix/PhilsDictationApp_<version>.0_x64.msix`
3. Test the release build: install `src-tauri/target/release/bundle/msi/*.msi` (uninstall the Store version first) and confirm dictation types text.
4. In Partner Center: **Start update** → **Packages**: upload the `.msix`, remove the old one → add "What's new" → **Submit**. Certification takes a few hours to ~3 business days; installs auto-update.

`npm run msix` ([scripts/build-msix.ps1](scripts/build-msix.ps1)) packs only the release exe and the logos in `src-tauri/msix/`, using `src-tauri/msix/AppxManifest.xml` with the version from `tauri.conf.json`. The package is unsigned; the Store signs it.

- Don't use the MSIX Packaging Tool. It records everything that changes during install, which pulled the WebView2 profile and Microsoft sign-in caches from the build machine into the package.
- Keep the manifest identity and display name as is (`18087PhilPDX.PhilsDictationApp`, `CN=185BEB8C-D0D8-46C6-B4D6-0062E3C7275E`, `Phil's Dictation App`). Partner Center rejects packages that don't match the reserved app.

### Speech recognition in WebView2

Dictation uses the browser's `webkitSpeechRecognition`. Since WebView2 Runtime 153, Microsoft's new speech service rejects WebView2 apps with HTTP 403, which shows up in JS as a `network` error. `additionalBrowserArgs` in `tauri.conf.json` disables `msSpeechRecognitionServiceUseCetoService` to fall back to the old service. See https://github.com/MicrosoftEdge/WebView2Feedback/issues/5724. If dictation breaks again, check that issue first.
