# インストール

```
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply inakam
# もしくは
chezmoi init --apply inakam
```

## Raycastの手動設定（初回のみ）:

1. Raycastを起動（Brewでインストールされている）
2. Script Commandsの設定で ~/.config/raycast/scripts を読み込む
3. 「Import Settings & Data」でバックアップされた .rayconfig を読み込む
  - もしExportするときは「Settings」「Extensions」「ScriptDirectories」「Snippets」だけをExport（aaaaaaaa）

# Obsidianの設定

コミュニティプラグインを追加する
- Thino
- Advanced URI

# Claude Code Plugin

- claude codeの中でpluginsをインストールする
```
/plugin marketplace add thedotmack/claude-mem
/plugin install claude-mem
```

# 設定の変更

```
chezmoi edit ~/.zshrc
chezmoi diff
chezmoi apply
```

# Gitからの反映

```
chezmoi git pull
chezmoi apply
```

