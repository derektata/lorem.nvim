# Changelog

## Unreleased

### Added

- **Nix flake package output** — `packages.default` exposes the plugin as a
  `vimUtils.buildVimPlugin` derivation. Users managing Neovim with Nix
  (home-manager, nixvim) can now consume it directly as a flake input.

### Breaking Changes

- **`debounce_ms` config field removed** — if you had `debounce_ms` in your
  `require("lorem").opts { ... }` call, remove it. The inline trigger no longer
  uses a debounce timer; expansion fires on the trailing space instead.

- **Inline trigger requires a trailing space** — the old trigger fired after a
  short delay without a space. The new trigger is `lorem5<space>` /
  `lorem5p<space>`. Muscle memory for the old timing-based behavior will need
  to adjust.

### Changed

- **Space-triggered expansion** — inline trigger now requires a trailing space
  (`lorem5<space>`) instead of relying on a debounce timer. Typing at any speed
  will no longer cause accidental expansions.

- **Cursor repositioning after expansion** — cursor moves to the end of the
  generated text after an inline trigger fires. Works correctly for both
  single-line (words) and multi-line (paragraphs) output.

- **Removed LibUV dependency** — `vim.loop` / LibUV timer is no longer used.
  The debounce timer, `clear_timer`, `debounce_ms` config field, and
  `current_fmt` helper have all been removed.

- **Inlined comma logic** — `create_comma_ctx` and `should_comma` removed;
  the probability check is now a single conditional inside `build_sentence`,
  eliminating a table allocation per word.

- **Removed `build_sentences` wrapper** — the one-liner helper that wrapped
  `build_sentence` in a loop is inlined directly into `build_paragraph`.

- **Merged `sentence_conf` into `get_config`** — config resolution is now a
  single function instead of two chained calls.

- **Fixed `generate_text` global leak** — was missing `local`, causing it to
  pollute the global Lua namespace.

- **Fixed pattern injection in tab completion** — `filter_opts` was
  concatenating raw user input into a Lua pattern via `string.find`; replaced
  with `vim.startswith` to avoid errors on metacharacter input (e.g. `(`).

- **`:LoremIpsum` now repositions cursor** — `insert_text` moves the cursor to
  the end of the generated text, consistent with the inline trigger.

- **Inline trigger namespaced to `LoremIpsum` augroup** — the `TextChangedI`
  autocmd now belongs to a named augroup, preventing duplicate registration on
  re-source and allowing users to disable it with `autocmd! LoremIpsum`.
