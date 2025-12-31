# marimo SQLガイド

## 目次

1. [セットアップ](#セットアップ)
2. [SQLセルの作成](#sqlセルの作成)
3. [データソース接続](#データソース接続)
4. [クエリパターン](#クエリパターン)
5. [Python連携](#python連携)

## セットアップ

### インストール

```bash
pip install "marimo[sql]"
```

### 出力タイプ設定

`pyproject.toml`:

```toml
[tool.marimo.sql]
output = "native"  # 推奨（大規模データセット向け）
# その他: pandas, polars, lazy-polars, auto
```

## SQLセルの作成

### 方法

1. セル追加ボタンを右クリック → SQL選択
2. セルのコンテキストメニュー → SQLに変換
3. ノートブック下部の「SQL」ボタン

### 基本構文

```sql
-- SQLセル内
SELECT * FROM users WHERE age > 20
```

結果は自動的にDataFrameとして返される。

## データソース接続

### SQLite

```python
import sqlite3

# 接続作成
conn = sqlite3.connect("database.db")
```

SQLセルで自動認識される。

### PostgreSQL

```python
from sqlalchemy import create_engine

engine = create_engine("postgresql://user:pass@localhost/dbname")
```

### MySQL

```python
from sqlalchemy import create_engine

engine = create_engine("mysql+pymysql://user:pass@localhost/dbname")
```

### DuckDB

```python
import duckdb

conn = duckdb.connect("database.duckdb")
```

### UI経由の接続

エディタ右下の「+」ボタンからデータベース接続ウィザードを使用可能。

## クエリパターン

### 基本クエリ

```sql
-- テーブル全体
SELECT * FROM users

-- フィルタリング
SELECT name, email FROM users WHERE active = true

-- 集計
SELECT department, COUNT(*) as count
FROM employees
GROUP BY department
ORDER BY count DESC
```

### ローカルDataFrame参照

```python
# Pythonセル
import pandas as pd
df = pd.DataFrame({"id": [1, 2, 3], "name": ["A", "B", "C"]})
```

```sql
-- SQLセルでdf変数を直接参照
SELECT * FROM df WHERE id > 1
```

### SQLセル出力の参照

```sql
-- result_dfという名前で出力される（セル設定で変更可能）
SELECT * FROM users
```

```python
# 別セルで参照
filtered = result_df[result_df["age"] > 30]
```

### ファイルからの読み込み

```sql
-- CSVファイル（DuckDB使用時）
SELECT * FROM 'data.csv'

-- Parquetファイル
SELECT * FROM 'data.parquet'
```

### CTEとサブクエリ

```sql
WITH active_users AS (
    SELECT * FROM users WHERE last_login > '2024-01-01'
),
orders AS (
    SELECT user_id, COUNT(*) as order_count
    FROM purchases
    GROUP BY user_id
)
SELECT u.name, o.order_count
FROM active_users u
JOIN orders o ON u.id = o.user_id
```

## Python連携

### 動的パラメータ

```python
# Pythonセル
min_age = mo.ui.slider(0, 100, value=20, label="最小年齢")
```

```sql
-- SQLセルでPython変数を参照
SELECT * FROM users WHERE age >= {min_age.value}
```

### 結果の処理

```python
# SQLセルの出力（sql_resultと仮定）
import plotly.express as px

fig = px.bar(sql_result, x="category", y="count")
mo.ui.plotly(fig)
```

### プログラマティッククエリ

```python
import duckdb

# DuckDBで直接クエリ
result = duckdb.sql(f"""
    SELECT * FROM df
    WHERE column = '{filter_value}'
""").df()
```

## Tips

### パフォーマンス

- 大規模データには`output = "native"`を使用
- 必要なカラムのみSELECT
- 適切なWHERE句でフィルタリング

### デバッグ

```sql
-- 結果の確認
SELECT * FROM table LIMIT 10

-- テーブル構造
DESCRIBE table

-- 利用可能なテーブル一覧（DuckDB）
SHOW TABLES
```

### チュートリアル

```bash
marimo tutorial sql
```
