# Raspberry Pi Dotfiles

Raspberry Pi用のdotfiles設定です。

## インストール

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply inakam
# もしくは
chezmoi init --apply inakam
```

## 含まれる設定

### システム設定
- **bash**: メインシェル（zshから移行）
- **starship**: プロンプトのカスタマイズ
- **mise**: ツールバージョン管理
- **chezmoi**: ドットファイル管理

### インストールされるパッケージ（apt）
- build-essential, git, curl, wget
- vim, neovim
- htop, tmux, tree, ncdu
- ripgrep, fzf, bat
- openssh-server, tailscale
- ffmpeg, imagemagick
- python3, python3-dev, python3-pip

### ツール
- **ghq**: リポジトリ管理
- **fzf**: ファジーファインダー
- **bat**: catの代替
- **ripgrep**: grepの代替

## Claude Code Plugin

claude codeの中でpluginsをインストールします：

```bash
/plugin marketplace add thedotmack/claude-mem
/plugin marketplace add fumiya-kume/claude-code
/plugin marketplace add OthmanAdi/planning-with-files
/plugin marketplace add anthropics/skills
```

## 設定の変更

```bash
chezmoi edit ~/.bashrc
chezmoi diff
chezmoi apply
```

## Gitからの反映

```bash
chezmoi git pull
chezmoi apply
```

## ディレクトリ構成

```
.
├── dot_bashrc              # メインのbash設定
├── dot_bashrc.d/           # bash設定の各パーツ
│   ├── aliases.bash        # エイリアス
│   ├── claude.bash         # Claude Code関連
│   ├── completion.bash     # 補完設定
│   ├── ghq.bash            # ghq + fzf
│   ├── history.bash        # 履歴設定
│   └── path.bash           # PATH設定
├── dot_claude/             # Claude Code設定
├── dot_config/
│   ├── apt/
│   │   └── packages.list   # apt-getパッケージリスト
│   └── mise/
│       └── config.toml     # mise設定
└── startup/raspberry/      # 初回起動スクリプト
```
