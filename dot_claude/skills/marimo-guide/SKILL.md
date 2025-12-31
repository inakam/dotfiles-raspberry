---
name: marimo-guide
description: marimo（リアクティブPythonノートブック）の開発支援スキル。marimoノートブックの作成、UI要素の実装、SQLクエリ、Webアプリ化を支援する。「marimoでノートブックを作成」「marimoでダッシュボードを作る」「marimoでインタラクティブなUIを作成」「Jupyterからmarimoに移行」「marimoをWebアプリとして公開」などのリクエスト時に使用する。
---

# marimo Guide

marimoを使ったリアクティブPythonノートブック開発を支援するスキル。

## Quick Reference

```python
import marimo as mo

# セルは自動的に依存関係を追跡、参照変数が変更されると自動実行
x = 10
y = x * 2  # xが変更されるとyも自動更新

# UI要素
slider = mo.ui.slider(1, 100, value=50)
mo.md(f"値: {slider.value}")

# インタラクティブ表示
mo.hstack([slider, mo.md(f"選択: **{slider.value}**")])
```

## Workflow Decision Tree

1. **新規ノートブック作成** → 下記Quick Startを参照
2. **UI要素実装** → [ui-elements.md](references/ui-elements.md) を参照
3. **SQLクエリ** → [sql-guide.md](references/sql-guide.md) を参照
4. **ベストプラクティス** → [best-practices.md](references/best-practices.md) を参照
5. **Webアプリ化** → [deployment.md](references/deployment.md) を参照

## Quick Start

### インストール

```bash
pip install marimo                # 最小インストール
pip install "marimo[recommended]" # フル機能
pip install "marimo[sql]"         # SQL機能付き
```

### 基本コマンド

```bash
marimo edit notebook.py   # ノートブック作成/編集
marimo run notebook.py    # Webアプリとして実行
marimo tutorial intro     # チュートリアル
```

### ノートブック構造

marimoは純粋な.pyファイルとして保存される：

```python
import marimo

app = marimo.App()

@app.cell
def _():
    import marimo as mo
    return (mo,)

@app.cell
def _(mo):
    # セル内容
    slider = mo.ui.slider(1, 100)
    return (slider,)

@app.cell
def _(mo, slider):
    mo.md(f"値: {slider.value}")
    return ()
```

## Core Concepts

### リアクティブ実行

- セルは変数の依存関係でDAG（有向非巡回グラフ）を構成
- 参照される変数が変更されると依存セルが自動実行
- セルの順序ではなく変数の参照関係で実行順が決定
- **重要**: オブジェクトのmutationは追跡されない

### UI要素

```python
# 基本入力
slider = mo.ui.slider(0, 100, step=1, value=50)
number = mo.ui.number(start=0, stop=100)
text = mo.ui.text(placeholder="入力...")
checkbox = mo.ui.checkbox(label="有効化")
dropdown = mo.ui.dropdown(options=["A", "B", "C"])

# 値の取得
slider.value  # 現在の値

# 複合要素
form = mo.ui.form({
    "name": mo.ui.text(),
    "age": mo.ui.number(start=0, stop=120)
})
```

### レイアウト

```python
# 水平・垂直配置
mo.hstack([elem1, elem2, elem3])
mo.vstack([elem1, elem2, elem3])

# タブ
mo.ui.tabs({
    "Tab 1": content1,
    "Tab 2": content2
})

# アコーディオン
mo.accordion({
    "Section 1": content1,
    "Section 2": content2
})

# サイドバー
mo.sidebar(navigation_content)
```

### Markdown

```python
# 基本
mo.md("# タイトル")

# 変数埋め込み
mo.md(f"値: **{slider.value}**")

# LaTeX
mo.md(r"$E = mc^2$")
```

## Common Patterns

### データ可視化ダッシュボード

```python
import marimo as mo
import plotly.express as px
import pandas as pd

# データ読み込み
df = pd.read_csv("data.csv")

# フィルターUI
column = mo.ui.dropdown(options=df.columns.tolist(), label="カラム")
threshold = mo.ui.slider(df[column.value].min(), df[column.value].max())

# フィルタリング
filtered_df = df[df[column.value] > threshold.value]

# グラフ表示
fig = px.scatter(filtered_df, x="x", y="y")
mo.ui.plotly(fig)
```

### フォーム入力

```python
form = mo.ui.form(
    mo.md('''
    **設定入力**

    名前: {name}
    年齢: {age}
    同意: {agree}
    ''').batch(
        name=mo.ui.text(),
        age=mo.ui.number(start=0, stop=120),
        agree=mo.ui.checkbox()
    )
)

# 送信後のみ処理
mo.stop(not form.value)
result = process(form.value)
```

### 条件付き実行

```python
# 条件を満たさない場合セルを停止
mo.stop(
    slider.value < 10,
    mo.md("10以上の値を選択してください")
)

# 以降のコードは条件を満たした場合のみ実行
expensive_computation()
```

## Debugging

### キャッシュクリア

```bash
marimo edit notebook.py --no-cache
```

### セル依存関係の確認

エディタ上部の「Variables」パネルで変数の依存関係を確認

### 一般的な問題

- **セルが実行されない**: 変数名の重複、循環参照がないか確認
- **UIが反応しない**: グローバル変数に代入されているか確認
- **mutationが反映されない**: 新しいオブジェクトを作成する

## Resources

詳細なリファレンスは以下を参照：

- [ui-elements.md](references/ui-elements.md) - UI要素の詳細、全コンポーネント一覧
- [sql-guide.md](references/sql-guide.md) - SQLクエリ、データベース接続
- [best-practices.md](references/best-practices.md) - ベストプラクティス、よくあるミス
- [deployment.md](references/deployment.md) - Webアプリ化、デプロイ方法
