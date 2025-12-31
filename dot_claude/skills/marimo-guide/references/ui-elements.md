# marimo UI要素リファレンス

## 目次

1. [入力要素](#入力要素)
2. [選択要素](#選択要素)
3. [日付・時刻](#日付時刻)
4. [ファイル操作](#ファイル操作)
5. [複合要素](#複合要素)
6. [データ表示](#データ表示)
7. [レイアウト](#レイアウト)

## 入力要素

### テキスト入力

```python
# 単行テキスト
text = mo.ui.text(
    value="",              # 初期値
    placeholder="入力...", # プレースホルダー
    label="名前",          # ラベル
    kind="text",           # text/password/email/url
    max_length=100,        # 最大文字数
    disabled=False,        # 無効化
    full_width=False       # 幅いっぱい
)

# 複数行テキスト
textarea = mo.ui.text_area(
    value="",
    placeholder="説明を入力...",
    rows=4,                # 行数
    max_length=1000
)
```

### 数値入力

```python
# 数値
number = mo.ui.number(
    start=0,               # 最小値
    stop=100,              # 最大値
    step=1,                # ステップ
    value=50,              # 初期値
    label="数量"
)

# スライダー
slider = mo.ui.slider(
    start=0,
    stop=100,
    step=1,
    value=50,
    label="値",
    show_value=True,       # 値を表示
    full_width=False
)

# 範囲スライダー
range_slider = mo.ui.range_slider(
    start=0,
    stop=100,
    step=1,
    value=[20, 80],        # [min, max]
    label="範囲"
)
```

### ボタン・スイッチ

```python
# ボタン
button = mo.ui.button(
    label="実行",
    kind="neutral",        # neutral/success/warn/danger
    disabled=False
)
# button.value は押された回数

# 実行ボタン（計算を手動トリガー）
run_button = mo.ui.run_button(label="計算実行")

# スイッチ
switch = mo.ui.switch(
    value=False,
    label="有効化"
)
```

## 選択要素

### ドロップダウン

```python
# 単一選択
dropdown = mo.ui.dropdown(
    options=["A", "B", "C"],           # リスト
    # または辞書形式
    # options={"表示A": "value_a", "表示B": "value_b"},
    value="A",                          # 初期値
    label="選択",
    allow_select_none=False,            # 未選択を許可
    searchable=True                     # 検索可能
)

# 複数選択
multiselect = mo.ui.multiselect(
    options=["A", "B", "C", "D"],
    value=["A", "B"],                   # 初期選択
    label="複数選択",
    max_selections=3                    # 最大選択数
)
```

### ラジオ・チェックボックス

```python
# ラジオボタン
radio = mo.ui.radio(
    options=["オプション1", "オプション2", "オプション3"],
    value="オプション1",
    label="選択",
    inline=False                        # 横並び表示
)

# チェックボックス
checkbox = mo.ui.checkbox(
    value=False,
    label="同意する"
)
```

## 日付時刻

```python
# 日付
date = mo.ui.date(
    value=None,                         # 初期値（datetime.date）
    start=None,                         # 選択可能開始日
    stop=None,                          # 選択可能終了日
    label="日付選択"
)

# 日時
datetime = mo.ui.datetime(
    value=None,
    start=None,
    stop=None,
    label="日時選択"
)

# 日付範囲
date_range = mo.ui.date_range(
    value=None,                         # (start, stop)タプル
    label="期間選択"
)
```

## ファイル操作

```python
# ファイルアップロード
file = mo.ui.file(
    filetypes=[".csv", ".xlsx"],        # 許可する拡張子
    multiple=False,                      # 複数ファイル
    label="ファイル選択"
)
# file.value でファイル内容にアクセス
# file.name() でファイル名
# file.contents() でバイト内容

# ファイルブラウザ
browser = mo.ui.file_browser(
    initial_path="./",
    filetypes=[".py"],
    multiple=True,
    restrict_navigation=True             # ディレクトリ移動制限
)
```

## 複合要素

### フォーム

```python
# 辞書形式
form = mo.ui.form({
    "name": mo.ui.text(label="名前"),
    "age": mo.ui.number(start=0, stop=120, label="年齢"),
    "agree": mo.ui.checkbox(label="同意")
})
# form.value = {"name": "...", "age": 25, "agree": True}

# batch形式（Markdown内埋め込み）
form = mo.ui.form(
    mo.md('''
    **入力フォーム**

    名前: {name}
    年齢: {age}
    ''').batch(
        name=mo.ui.text(),
        age=mo.ui.number(start=0, stop=120)
    ),
    submit_button_label="送信"
)
```

### 配列・辞書

```python
# 動的配列
array = mo.ui.array([
    mo.ui.text() for _ in range(3)
])
# array.value = ["text1", "text2", "text3"]

# 辞書
dictionary = mo.ui.dictionary({
    "field1": mo.ui.text(),
    "field2": mo.ui.number(start=0, stop=100)
})
```

## データ表示

### テーブル

```python
import pandas as pd

df = pd.DataFrame({"A": [1, 2, 3], "B": ["x", "y", "z"]})

# インタラクティブテーブル
table = mo.ui.table(
    df,
    selection="multi",                   # single/multi/None
    pagination=True,
    page_size=10,
    label="データ"
)
# table.value で選択された行（DataFrame）

# データエクスプローラー
explorer = mo.ui.dataframe(df)
# フィルタ、ソート、グラフ作成が可能
```

### グラフ

```python
import plotly.express as px
import altair as alt

# Plotly
fig = px.scatter(df, x="A", y="B")
mo.ui.plotly(fig)

# Altair（インタラクティブ選択）
chart = alt.Chart(df).mark_point().encode(x="A", y="B")
selection = mo.ui.altair_chart(chart)
# selection.value で選択されたデータ

# Matplotlib
import matplotlib.pyplot as plt
fig, ax = plt.subplots()
ax.plot([1, 2, 3])
mo.mpl.interactive(fig)
```

## レイアウト

### スタック配置

```python
# 水平配置
mo.hstack(
    [elem1, elem2, elem3],
    justify="start",                     # start/center/end/space-between
    align="center",                      # start/center/end/stretch
    gap=1                                # 間隔（rem単位）
)

# 垂直配置
mo.vstack([elem1, elem2, elem3])

# 配置指定
mo.left(content)                         # 左寄せ
mo.center(content)                       # 中央
mo.right(content)                        # 右寄せ
```

### コンテナ

```python
# タブ（状態付き）
tabs = mo.ui.tabs({
    "タブ1": content1,
    "タブ2": content2
})
# tabs.value で選択中のタブ名

# アコーディオン
mo.accordion({
    "セクション1": content1,
    "セクション2": content2
})

# コールアウト
mo.callout(
    content,
    kind="info"                          # info/warn/danger/success/neutral
)

# サイドバー
mo.sidebar(navigation)

# カルーセル
mo.carousel([slide1, slide2, slide3])
```

### ルーティング

```python
mo.routes({
    "/": home_page,
    "/about": about_page,
    "/user/:id": user_page               # パラメータ付き
})
```
