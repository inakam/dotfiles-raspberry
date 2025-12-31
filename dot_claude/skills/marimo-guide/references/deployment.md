# marimo デプロイメントガイド

## 目次

1. [アプリとして実行](#アプリとして実行)
2. [レイアウト設定](#レイアウト設定)
3. [デプロイ方法](#デプロイ方法)
4. [認証設定](#認証設定)
5. [スクリプト実行](#スクリプト実行)

## アプリとして実行

### 基本コマンド

```bash
# Webアプリとして起動
marimo run notebook.py

# ポート指定
marimo run notebook.py --port 8080

# ホスト指定（外部アクセス許可）
marimo run notebook.py --host 0.0.0.0
```

### オプション

```bash
marimo run notebook.py \
    --port 8080 \
    --host 0.0.0.0 \
    --headless \              # ブラウザを開かない
    --include-code            # コードを表示
```

## レイアウト設定

### 垂直レイアウト（デフォルト）

セル出力を縦に並べる標準レイアウト。コードは非表示。

### グリッドレイアウト

エディタでドラッグ＆ドロップでレイアウト調整：

1. 右上メニュー → 「Grid layout」選択
2. セル出力をドラッグして配置
3. リサイズハンドルでサイズ調整

レイアウトは`layouts/`フォルダに保存される。

### スライドレイアウト

プレゼンテーション形式：

```python
# スライド区切り
mo.md("---")  # 水平線でスライド分割
```

## デプロイ方法

### Docker

`Dockerfile`:

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY notebook.py .

EXPOSE 8080

CMD ["marimo", "run", "notebook.py", "--host", "0.0.0.0", "--port", "8080", "--headless"]
```

`requirements.txt`:

```
marimo
pandas
plotly
# その他の依存関係
```

ビルド・実行：

```bash
docker build -t marimo-app .
docker run -p 8080:8080 marimo-app
```

### Docker Compose

`docker-compose.yml`:

```yaml
version: "3.8"
services:
  marimo:
    build: .
    ports:
      - "8080:8080"
    volumes:
      - ./data:/app/data
    environment:
      - API_KEY=${API_KEY}
```

### HuggingFace Spaces

1. 新しいSpaceを作成（Docker SDK）
2. 以下のファイルをアップロード：
   - `Dockerfile`
   - `notebook.py`
   - `requirements.txt`

`Dockerfile`（HuggingFace用）:

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

EXPOSE 7860

CMD ["marimo", "run", "notebook.py", "--host", "0.0.0.0", "--port", "7860", "--headless"]
```

### Railway

1. GitHubリポジトリを接続
2. Dockerfileを自動検出
3. 環境変数を設定
4. デプロイ

### nginx（リバースプロキシ）

```nginx
server {
    listen 80;
    server_name marimo.example.com;

    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## 認証設定

### 基本認証

```bash
marimo run notebook.py --token-auth
# トークンがコンソールに表示される
```

### カスタム認証

環境変数で設定：

```bash
export MARIMO_AUTH_TOKEN="your-secret-token"
marimo run notebook.py --token-auth
```

### OAuth（上級）

FastAPI等でラップして認証を追加：

```python
from fastapi import FastAPI, Depends
from fastapi.security import OAuth2PasswordBearer
import marimo

app = FastAPI()

# 認証ミドルウェア
@app.middleware("http")
async def auth_middleware(request, call_next):
    # 認証ロジック
    ...
```

## スクリプト実行

marimoノートブックは通常のPythonスクリプトとしても実行可能：

```bash
python notebook.py
```

### CLIからの実行

```python
# notebook.py内
if __name__ == "__main__":
    import marimo
    marimo.App().run()
```

### 定期実行

cronやスケジューラで：

```bash
# crontab
0 * * * * python /path/to/notebook.py
```

### CI/CD統合

```yaml
# GitHub Actions
name: Run Notebook
on:
  schedule:
    - cron: "0 0 * * *"
jobs:
  run:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.11"
      - run: pip install marimo pandas
      - run: python notebook.py
```

## Tips

### 環境変数

```python
import os

api_key = os.environ.get("API_KEY")
```

### データ永続化

```python
# ボリュームマウントしたパスを使用
DATA_DIR = "/app/data"
df.to_csv(f"{DATA_DIR}/output.csv")
```

### ログ出力

```python
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

logger.info("処理開始")
```
