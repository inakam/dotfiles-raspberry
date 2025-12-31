---
name: gokart-guide
description: gokart（luigi上に構築されたMLパイプラインフレームワーク）の開発支援スキル。gokartを使ったタスク・パイプラインの実装、デバッグ、テスト作成を支援する。「gokartでタスクを作成」「gokartパイプラインを実装」「gokartのエラーを解決」「gokartタスクのテストを書く」「gokart mypyエラー」などのリクエスト時に使用する。
---

# gokart Guide

gokartを使ったMLパイプライン開発を支援するスキル。

## Quick Reference

**重要**: 必ず `gokart.TaskOnKart[T]` と型パラメータを指定すること（mypyで型チェックを行うため）

```python
import gokart
import luigi
import pandas as pd
from pandera.typing import DataFrame

# 基本タスク（型パラメータ必須）
class MyTask(gokart.TaskOnKart[str]):
    def run(self):
        self.dump('result')

# 依存関係付きタスク
class ProcessTask(gokart.TaskOnKart[pd.DataFrame]):
    input_task: gokart.TaskOnKart[pd.DataFrame] = gokart.TaskInstanceParameter()

    def run(self):
        data = self.load(self.input_task)
        self.dump(data.dropna())

# 実行
result = gokart.build(ProcessTask(input_task=LoadTask()))
```

### ⚠️ 非推奨パターン

| パターン                    | 理由                  | 代替案                          |
| --------------------------- | --------------------- | ------------------------------- |
| `rerun=True`                | pylint_gokartで警告   | `_cache_key_datetime`パラメータ |
| `yield`による動的タスク生成 | run()が毎回リスタート | `requires()`で静的に構築        |

## Reference Guide

| 用途                       | 参照先                                            |
| -------------------------- | ------------------------------------------------- |
| **パターン・テンプレート** | [patterns.md](references/patterns.md)             |
| **API詳細**                | [api-reference.md](references/api-reference.md)   |
| **ベストプラクティス**     | [best-practices.md](references/best-practices.md) |
| **テスト作成**             | [testing.md](references/testing.md)               |

## Core Concepts

### TaskOnKart

- `gokart.TaskOnKart[T]` - 型付きタスク（`T`は出力型、**必須**）
- `run()` - タスクロジック実装、`self.dump()`で保存
- `load()` - 依存タスクの出力を読み込み
- `dump()` - 結果を保存

### Parameters

| パラメータ                           | 用途               |
| ------------------------------------ | ------------------ |
| `luigi.Parameter()`                  | 文字列             |
| `luigi.IntParameter()`               | 整数               |
| `luigi.DateParameter()`              | 日付               |
| `gokart.TaskInstanceParameter()`     | タスク依存関係     |
| `gokart.ListTaskInstanceParameter()` | 複数タスク依存関係 |
| `gokart.SerializableParameter()`     | Pydanticモデル等   |

### Execution

- `gokart.build(task)` - Jupyter/インラインコード用
- `gokart.run()` - CLI用（`python main.py TaskName --local-scheduler`）

## Key Patterns（概要）

詳細は [patterns.md](references/patterns.md) を参照。

### Pipelineパターン（推奨）

`requires()`内でタスクインスタンスを渡し、`run()`内で`load()`して結果を取得。

```
Pipeline.requires()内での構築:
  DownloadA() ─┐
               ├─→ JoinAB(a=downloadA, b=downloadB) ─→ ProcessC(input=joinAB)
  DownloadB() ─┘

実行時:
  1. DownloadA.run() → 結果をキャッシュ
  2. DownloadB.run() → 結果をキャッシュ
  3. JoinAB.run() → self.load(self.a), self.load(self.b) でA,Bの結果を取得
```

### 2段階gokart.build()パターン

依存タスクの結果に基づいてタスク数を動的に決めたい場合は、**2回のgokart.build()**を使う。

```python
# 1回目: データ取得（件数確定）
data = gokart.build(DownloadData(...))

# Pythonで動的にタスク生成
tasks = [ProcessItem(item=item) for item in data]

# 2回目: 動的タスクを実行
result = gokart.build(ConcatResults(tasks=tasks), workers=50)
```

### API呼び出し分解パターン

外部APIコールを1リクエスト1タスクに分解し、途中再開を可能にする。

```python
class TagText(gokart.TaskOnKart[dict]):
    text: str = luigi.Parameter()
    model: str = luigi.Parameter(significant=False)  # キャッシュキーから除外

class TagTexts(gokart.TaskOnKart[dict[str, dict]]):
    texts: Tuple[str, ...] = luigi.TupleParameter()

    def requires(self):
        return {text: TagText(text=text, model='gpt-4o') for text in self.texts}
```

## Debugging

```python
# ログ出力
gokart.build(task, log_level=logging.DEBUG)

# タスクツリー確認
print(gokart.make_tree_info(task))

# キャッシュ無効化（rerun=Trueの代替）
class MyTask(gokart.TaskOnKart[pd.DataFrame]):
    _cache_key_datetime: datetime = luigi.DateSecondParameter(default=datetime.now())
```

## pyproject.toml設定

```toml
[tool.mypy]
plugins = ["pandera.mypy", "gokart.mypy"]

[tool.pylint.MASTER]
load-plugins = ["pylint_gokart"]
enable = ["list-parameter-use", "rerun-use"]
```
