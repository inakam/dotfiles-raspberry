# marimo ベストプラクティス

## 目次

1. [変数管理](#変数管理)
2. [コード構成](#コード構成)
3. [リアクティビティ](#リアクティビティ)
4. [UI設計](#ui設計)
5. [パフォーマンス](#パフォーマンス)
6. [よくあるミス](#よくあるミス)

## 変数管理

### グローバル変数を控えめに

```python
# 悪い例：多数のグローバル変数
data = load_data()
cleaned = clean(data)
transformed = transform(cleaned)
result = analyze(transformed)

# 良い例：関数にカプセル化
def process_data():
    data = load_data()
    cleaned = clean(data)
    transformed = transform(cleaned)
    return analyze(transformed)

result = process_data()
```

### アンダースコアプレフィックス

一時変数にはアンダースコアを使用（ローカル変数として扱われる）：

```python
# _付き変数はセル間で共有されない
_temp_df = df.dropna()
_filtered = _temp_df[_temp_df["value"] > 0]
result = _filtered.groupby("category").sum()
```

### 説明的な命名

```python
# 悪い例
x = mo.ui.slider(0, 100)
y = load_data()

# 良い例
threshold_slider = mo.ui.slider(0, 100, label="閾値")
user_data = load_data()
```

## コード構成

### 関数でロジックをカプセル化

```python
def calculate_metrics(df: pd.DataFrame) -> dict:
    """メトリクス計算（テスト可能）"""
    return {
        "mean": df["value"].mean(),
        "std": df["value"].std(),
        "count": len(df)
    }

metrics = calculate_metrics(data)
```

### モジュール分割

複雑なロジックは外部モジュールに：

```python
# utils.py
def process(data):
    ...

# ノートブック内
from utils import process

# オートリロード有効化
mo.reload_module("utils")
```

### セル設計

1セル = 1つの論理的単位：

```python
# セル1：データ読み込み
data = pd.read_csv("data.csv")

# セル2：前処理
cleaned = data.dropna().reset_index(drop=True)

# セル3：可視化
fig = px.scatter(cleaned, x="x", y="y")
mo.ui.plotly(fig)
```

## リアクティビティ

### mutationを避ける

marimoはオブジェクトのmutationを追跡しない：

```python
# 悪い例：mutationは追跡されない
df["new_col"] = df["a"] + df["b"]
my_list.append(item)

# 良い例：新しいオブジェクトを作成
df = df.assign(new_col=df["a"] + df["b"])
my_list = [*my_list, item]
```

### on_changeを避ける

```python
# 悪い例：コールバック使用
slider = mo.ui.slider(0, 100, on_change=update_chart)

# 良い例：リアクティブに依存
slider = mo.ui.slider(0, 100)

# 別セルで
mo.md(f"値: {slider.value}")  # 自動更新
```

### 冪等なセル

同じ入力で同じ出力になるセルを書く：

```python
# 悪い例：副作用あり
counter += 1

# 良い例：入力から決定的に計算
result = input_value * 2
```

## UI設計

### mo.stopで条件付き実行

```python
# フォーム送信前は処理しない
mo.stop(not form.value, mo.md("フォームを入力してください"))

# 処理実行
result = expensive_process(form.value)
```

### run_buttonで手動トリガー

```python
run = mo.ui.run_button(label="実行")

mo.stop(not run.value)

# 重い処理
result = train_model(data)
```

### フィードバック表示

```python
with mo.status.spinner("処理中..."):
    result = long_running_task()

mo.callout("処理が完了しました", kind="success")
```

## パフォーマンス

### 重い計算の制御

```python
# run_buttonで手動トリガー
run = mo.ui.run_button(label="学習開始")

mo.stop(not run.value)

# モデル学習
model = train_model(data)
```

### キャッシング

```python
import functools

@functools.lru_cache(maxsize=100)
def expensive_calculation(param):
    ...
```

### 遅延評価

```python
# Polarsの遅延評価
import polars as pl

lazy_df = pl.scan_csv("large_file.csv")
result = (
    lazy_df
    .filter(pl.col("value") > 0)
    .group_by("category")
    .agg(pl.sum("value"))
    .collect()  # ここで実行
)
```

## よくあるミス

### 変数名の重複

```python
# エラー：同じ変数を複数セルで定義
# セル1
result = process_a()

# セル2（エラー）
result = process_b()

# 解決：異なる名前を使用
result_a = process_a()
result_b = process_b()
```

### 循環参照

```python
# エラー：循環依存
# セル1
a = b + 1

# セル2
b = a + 1

# 解決：依存関係を整理
```

### UIがローカル変数

```python
# 悪い例：_付きでリアクティブにならない
_slider = mo.ui.slider(0, 100)

# 良い例：グローバル変数に
slider = mo.ui.slider(0, 100)
```

### mutationの非追跡

```python
# 問題：リストのappendは追跡されない
my_list = []
# 別セル
my_list.append(item)  # 依存セルは再実行されない

# 解決：新しいリストを作成
my_list = [*my_list, item]
```

### セル出力の欠落

```python
# 問題：最後の式が出力されない場合
x = 1
y = 2
# 何も表示されない

# 解決：明示的に出力
x = 1
y = 2
mo.md(f"x={x}, y={y}")
```
