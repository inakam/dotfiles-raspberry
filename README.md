# Raspberry Pi Dotfiles

Raspberry Pi用のdotfiles設定です。現在の環境を完全に再現できるように設計されています。

## インストール

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply inakam
# もしくは
chezmoi init --apply inakam
```

## 含まれる設定

### システム設定
- **bash**: メインシェル
- **byobu**: ターミナルマルチプレクサ（.profileで自動起動）
- **chezmoi**: ドットファイル管理

### インストールされるパッケージ（apt）

#### 開発ツール
- build-essential, git, gh, curl, wget
- vim, geany

#### ユーティリティ
- htop, tmux, byobu, tree, ncdu, lsof, strace, nano
- snapd

#### ファイル操作
- zip, unzip, xz-utils, p7zip-full, 7zip

#### ネットワーク
- openssh-server, openssh-client
- net-tools, netcat-openbsd, ethtool, wireless-tools, network-manager
- tailscale

#### Bluetooth/Sound
- bluez, bluez-firmware
- pulseaudio, pulseaudio-module-bluetooth
- pipewire, pipewire-pulse, alsa-utils, wireplumber

#### 画像・動画
- ffmpeg, imagemagick, v4l-utils

#### Python開発
- python3, python3-dev, python3-pip, python3-venv
- python3-pygame, python3-picamera2
- thonny

#### Raspberry Piハードウェア
- python3-gpiozero, python3-serial, python3-spidev, python3-smbus
- python3-libcamera, python3-sense-hat, sense-hat
- libcamera-tools

### インストールされるツール（snap/npm）

#### 経由: snap
- **neovim**: エディタ

#### 経由: nvm + npm
- **Node.js**: LTSバージョン
- **claude-code**: Anthropic AIのCLIツール
- **codex**: Claude Code Explorer
- **task-master**: タスク管理ツール

### エイリアス

#### エディタ
- `vi`, `vim` → nvim
- `view` → nvim -R

#### chezmoi
- `crsync`: chezmoi git pull
- `capply`: chezmoi apply
- `cdiff`: chezmoi diff
- `cra`: chezmoi git pull && chezmoi apply

#### その他
- `bs`: source ~/.bashrc
- `cy`: codex --yolo
- `cur`: cursor-agent
- `tm`, `taskmaster`: task-master
- `cl`: claude --dangerously-skip-permissions
- `clp`: claude --permission-mode plan

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
├── dot_profile             # ログインシェル設定（byobu自動起動）
├── dot_bashrc.d/           # bash設定の各パーツ
│   ├── aliases.bash        # エイリアス
│   ├── claude.bash         # Claude Code関連
│   ├── completion.bash     # 補完設定
│   ├── history.bash        # 履歴設定
│   ├── nvm.bash            # nvm設定
│   └── path.bash           # PATH設定
├── dot_claude/             # Claude Code設定
├── dot_config/
│   ├── apt/
│   │   └── packages.list   # apt-getパッケージリスト
│   └── mise/
│       └── config.toml     # mise設定（オプション）
└── startup/raspberry/      # 初回起動スクリプト
    ├── run_once_01_install_packages.sh
    ├── run_once_02_mise_install.sh
    └── run_once_03_scripts.sh
```

## オプション設定

以下のツールはインストールされている場合のみ有効になります：

- **starship**: プロンプトのカスタマイズ（インストール方法: `curl -sS https://starship.rs/install.sh | sh`）
- **mise**: ツールバージョン管理（インストール方法: `curl https://mise.run | sh`）
