# gokart Best Practices

## Table of Contents

1. [Type Safety (必須)](#type-safety-必須)
2. [Task Design](#task-design)
3. [Parameter Design](#parameter-design)
4. [Testable Task Pattern](#testable-task-pattern)
5. [Pipeline Design](#pipeline-design)
6. [API Call Design](#api-call-design)
7. [Reproducibility](#reproducibility)
8. [Performance](#performance)
9. [Debugging](#debugging)
10. [Common Mistakes](#common-mistakes)

---

## Type Safety (必須)

**重要**: mypyによる型チェックを有効にするため、必ず`gokart.TaskOnKart[T]`と型パラメータを指定すること。

### pyproject.toml設定

```toml
[tool.mypy]
plugins = ["pandera.mypy", "gokart.mypy"]
strict = true

[tool.pylint.MASTER]
load-plugins = ["pylint_gokart"]
enable = ["list-parameter-use", "rerun-use"]
```

### 型パラメータ必須

```python
# Good: 型パラメータを指定
class MyTask(gokart.TaskOnKart[pd.DataFrame]):
    def run(self):
        self.dump(pd.DataFrame())

# Bad: mypyでエラー
class MyTask(gokart.TaskOnKart):
    def run(self):
        self.dump(pd.DataFrame())
```

### pandera.typing.DataFrameによる型安全

```python
from pandera.typing import DataFrame
import pandera as pa

class UserSchema(pa.DataFrameModel):
    user_id: pa.typing.Series[int] = pa.Field(gt=0)
    name: pa.typing.Series[str]

# Good: スキーマ付きDataFrame
class LoadUsers(gokart.TaskOnKart[DataFrame[UserSchema]]):
    def run(self):
        df = pd.read_csv('users.csv')
        self.dump(df.pipe(DataFrame[UserSchema]))

# TaskInstanceParameterにも型を指定
class ProcessUsers(gokart.TaskOnKart[DataFrame[UserSchema]]):
    users_task: gokart.TaskOnKart[DataFrame[UserSchema]] = gokart.TaskInstanceParameter()
```

### ジェネリクス構文（Python 3.12+）

```python
# 推奨: 新しいジェネリクス構文
class MyProjectTask[T](gokart.TaskOnKart[T]):
    task_namespace = 'my_project'

class LoadData(MyProjectTask[pd.DataFrame]):
    def run(self):
        self.dump(pd.read_csv('data.csv'))
```

---

## Task Design

### 単一責任の原則

```python
# Good: 1タスク1責任
class LoadData(gokart.TaskOnKart[pd.DataFrame]):
    def run(self):
        self.dump(pd.read_csv('data.csv'))

class CleanData(gokart.TaskOnKart[pd.DataFrame]):
    data_task: gokart.TaskOnKart[pd.DataFrame] = gokart.TaskInstanceParameter()
    def run(self):
        self.dump(self.load(self.data_task).dropna())

# Bad: 複数の責任を混在
class LoadAndCleanData(gokart.TaskOnKart[pd.DataFrame]):
    def run(self):
        df = pd.read_csv('data.csv')
        self.dump(df.dropna())
```

### requires()の戻り値型

```python
from typing import Any

class MyTask(gokart.TaskOnKart[pd.DataFrame]):
    input_task: gokart.TaskOnKart[pd.DataFrame] = gokart.TaskInstanceParameter()

    # Good: 正確な型アノテーション
    def requires(self) -> dict[str, gokart.TaskOnKart[Any] | list[gokart.TaskOnKart[Any]]]:
        return {'input': self.input_task}
```

### output()のオーバーライドは慎重に

```python
# 通常はoutput()を省略（自動生成される）
class MyTask(gokart.TaskOnKart[str]):
    def run(self):
        self.dump('result')

# 必要な場合のみオーバーライド
class CustomOutputTask(gokart.TaskOnKart[str]):
    def output(self):
        return self.make_target('custom/path.pkl')
```

---

## Parameter Design

### TaskInstanceParameterの型指定

```python
from pandera.typing import DataFrame

class ProcessData(gokart.TaskOnKart[DataFrame[OutputSchema]]):
    # Good: 入力タスクの型を明示
    input_task: gokart.TaskOnKart[DataFrame[InputSchema]] = gokart.TaskInstanceParameter()

    def run(self):
        df = self.load(self.input_task)  # 型推論が効く
        self.dump(df.pipe(DataFrame[OutputSchema]))
```

### Pydantic + SerializableParameter

```python
from pydantic import BaseModel, Field, SecretStr
from typing import Annotated, Literal
import json

class SlackConfig(BaseModel):
    token: Annotated[SecretStr, Field(description='Slack token')]
    channel: Annotated[str, Field(description='通知先チャンネル')]

    def gokart_serialize(self) -> str:
        # シークレットはキャッシュキーに含めない
        return 'noop'

    @classmethod
    def gokart_deserialize(cls, s: str) -> 'SlackConfig':
        return cls.model_validate(json.loads(s))

class NotifyTask(gokart.TaskOnKart[None]):
    slack_config: SlackConfig = gokart.SerializableParameter(object_type=SlackConfig)
```

### パラメータにはデフォルト値を

```python
class TrainModel(gokart.TaskOnKart[Any]):
    learning_rate: float = luigi.FloatParameter(default=0.01)
    epochs: int = luigi.IntParameter(default=100)
```

### 非significantパラメータ

```python
class MyTask(gokart.TaskOnKart[Any]):
    # ハッシュに影響しないパラメータ
    verbose: bool = luigi.BoolParameter(default=False, significant=False)
    dry_run: bool = luigi.BoolParameter(default=False, significant=False)
```

### キャッシュ無効化パラメータ

実行時刻をパラメータに含めることで実質的にキャッシュを無効化する。

```python
from datetime import datetime

class AlwaysRunTask(gokart.TaskOnKart[pd.DataFrame]):
    """毎回必ず実行するタスク（外部データ取得など）"""
    # 実行時刻をキャッシュキーに含めることで毎回異なるハッシュになる
    _cache_key_datetime: datetime = luigi.DateSecondParameter(default=datetime.now())

    def run(self):
        # 外部APIやDBから最新データを取得
        df = fetch_latest_data()
        self.dump(df)
```

**ユースケース**:

- 外部API/DBから最新データを取得するタスク
- 時刻に依存する処理（現在時刻でフィルタリング等）
- 開発中のデバッグ（rerun=Trueの代替）

**注意**: `rerun=True`との違い

- `rerun=True`: 既存キャッシュを無視するが、キャッシュキーは同じ
- `_cache_key_datetime`: 毎回異なるキャッシュキーが生成される

---

## Testable Task Pattern

ビジネスロジックを`_run`クラスメソッドに分離してテストしやすくする。

### 実装パターン

```python
from pandera.typing import DataFrame

class TransformTask(gokart.TaskOnKart[DataFrame[OutputSchema]]):
    input_task: gokart.TaskOnKart[DataFrame[InputSchema]] = gokart.TaskInstanceParameter()

    def run(self):
        df = self.load(self.input_task)
        result = self._run(df)
        self.dump(result)

    @classmethod
    def _run(cls, df: DataFrame[InputSchema]) -> DataFrame[OutputSchema]:
        """ビジネスロジック（gokartに依存しない純粋関数）"""
        return df.assign(
            new_column=df['value'] * 2,
        ).pipe(DataFrame[OutputSchema])
```

### テストコード

```python
import pytest
import pandas as pd
from pandera.typing import DataFrame

class TestTransformTask:
    def test_run(self):
        # gokartに依存しない単体テスト
        input_df = pd.DataFrame({'value': [1, 2, 3]}).pipe(DataFrame[InputSchema])
        result = TransformTask._run(input_df)

        expected = pd.DataFrame({
            'value': [1, 2, 3],
            'new_column': [2, 4, 6]
        })
        pd.testing.assert_frame_equal(result.reset_index(drop=True), expected)
```

---

## Pipeline Design

### 宣言的パイプライン（jasmineパターン）

requires()内でパイプライン全体を構築し、見通しを良くする。

```python
class RunModel(gokart.TaskOnKart[None]):
    """パイプラインのエントリーポイント"""
    from_date: date = luigi.DateParameter()
    to_date: date = luigi.DateParameter()

    def requires(self):
        # ========== データ取得 ==========
        action_data = PreprocessActionLog(from_date=self.from_date, to_date=self.to_date)
        target_user = DownloadUserMetaData()

        # ========== 前処理 ==========
        user_segment = SplitSegment(target_user=target_user)

        # ========== test/ctrl群の並列処理 ==========
        test_score = PredictModel(action_data=action_data, user_segment=user_segment, prefix='test')
        ctrl_score = PredictModel(action_data=action_data, user_segment=user_segment, prefix='ctrl')

        # ========== 結果統合 ==========
        scores = FlattenTask(target=[test_score, ctrl_score])
        return UploadScore(score=scores)
```

**ポイント**:

- コメントでセクションを区切る
- 変数名で処理内容を明示
- requires()を読むだけでパイプラインの流れがわかる

### FlattenTaskヘルパー

```python
class FlattenTask(gokart.TaskOnKart[pd.DataFrame]):
    """複数タスクの結果を結合"""
    target: list[gokart.TaskOnKart[pd.DataFrame]] = gokart.ListTaskInstanceParameter()

    def requires(self):
        return self.target

    def run(self):
        self.dump(pd.concat([self.load(t) for t in self.target], ignore_index=True))
```

---

## API Call Design

### 1リクエスト = 1タスク（mekongパターン）

外部APIコールを個別タスクに分解し、キャッシュによる途中再開を可能にする。

```python
# Bad: 1タスクで全リクエスト（途中失敗で全やり直し）
class TagAllTexts(gokart.TaskOnKart[list[dict]]):
    texts: list[str] = luigi.ListParameter()

    def run(self):
        results = []
        for text in self.texts:
            result = call_api(text)  # 50件目で失敗 → 全やり直し
            results.append(result)
        self.dump(results)

# Good: 1リクエスト = 1タスク（途中再開可能）
class TagText(gokart.TaskOnKart[dict]):
    text: str = luigi.Parameter()

    def run(self):
        result = call_api(self.text)
        self.dump(result)

class TagAllTexts(gokart.TaskOnKart[dict[str, dict]]):
    texts: Tuple[str, ...] = luigi.TupleParameter()

    def requires(self):
        return {text: TagText(text=text) for text in self.texts}

    def run(self):
        self.dump(self.load())
```

### significant=Falseでモデル変更を許容

```python
class TagWithGPT(gokart.TaskOnKart[dict]):
    text: str = luigi.Parameter()
    # モデル変更でキャッシュを無効化しない
    gpt_model: str = luigi.Parameter(significant=False)
```

### バッチ分割で大量リクエストを並列化

```python
def create_pipeline(texts: list[str], batch_size: int = 10) -> ConcatResults:
    batches = [tuple(texts[i:i+batch_size]) for i in range(0, len(texts), batch_size)]
    return ConcatResults(
        tasks=[TagTexts(texts=batch) for batch in batches]
    )
```

---

## Reproducibility

### ランダムシード固定

```python
class MLTask(gokart.TaskOnKart[Any]):
    fix_random_seed_methods = [
        'random.seed',
        'numpy.random.seed',
        'torch.random.manual_seed'
    ]
    fix_random_seed_value: int = luigi.IntParameter(default=42)
```

### コード変更検知

```python
class MyTask(gokart.TaskOnKart[Any]):
    serialized_task_definition_check: bool = True  # コード変更で再実行
```

### モジュールバージョン記録

gokartは自動的に`log/module_versions/`にモジュールバージョンを記録

---

## Performance

### メモリ効率的なロード

```python
class ProcessLargeData(gokart.TaskOnKart[None]):
    def run(self):
        # load_generatorでメモリ効率的に処理
        for chunk in self.load_generator():
            process(chunk)
        self.dump(None)
```

### 大規模DataFrame

```python
class SaveLargeDF(gokart.TaskOnKart[pd.DataFrame]):
    def output(self):
        return self.make_large_data_frame_target('large.zip')
```

### 並列実行時のロック

```python
class ConcurrentTask(gokart.TaskOnKart[Any]):
    redis_host: str = luigi.Parameter()
    redis_port: int = luigi.IntParameter()
    should_lock_run: bool = True  # 実行時ロック
```

---

## Debugging

### ログレベル設定

```python
import logging
gokart.build(task, log_level=logging.DEBUG)
```

### タスク情報の確認

```python
# ツリー表示
print(gokart.make_tree_info(task))

# テーブル表示
from gokart.tree.task_info import make_task_info_as_table
print(make_task_info_as_table(task))
```

### 強制再実行

```python
# 単一タスク
gokart.build(MyTask(rerun=True))

# パイプライン全体
gokart.build(EndTask(
    middle=MiddleTask(rerun=True, start=StartTask(rerun=True))
))
```

---

## Common Mistakes

### 1. 型パラメータの省略

```python
# Bad: mypyでエラー
class MyTask(gokart.TaskOnKart):
    pass

# Good: 型パラメータを指定
class MyTask(gokart.TaskOnKart[str]):
    pass
```

### 2. Jupyter/IPythonでのタスク重複

```python
# Bad: 同じセルを再実行するとTaskClassAmbigiousException
class MyTask(gokart.TaskOnKart[str]):
    pass

# Good: reset_register=Trueで解決（デフォルト）
gokart.build(task, reset_register=True)
```

### 3. run()とbuild()の混在

```python
# Bad: 同じスクリプトで混在
gokart.run()
gokart.build(task)  # luigi.registerがクリアされる

# Good: どちらか一方を使用
```

### 4. 空DataFrameの見逃し

```python
# Good: 空DataFrame検知を有効化
class MyTask(gokart.TaskOnKart[pd.DataFrame]):
    fail_on_empty_dump: bool = True
```

### 5. pylint-gokart警告の無視

```python
# Bad: ListTaskInstanceParameterをタプルで渡す
tasks = (Task1(), Task2())  # pylint: list-parameter-use

# Good: リストで渡す
tasks = [Task1(), Task2()]

# Bad: rerunを使用（非推奨）
gokart.build(MyTask(rerun=True))  # pylint: rerun-use

# Good: キャッシュ無効化パラメータを使用
class MyTask(gokart.TaskOnKart[pd.DataFrame]):
    _cache_key_datetime: datetime = luigi.DateSecondParameter(default=datetime.now())
```

### 6. yieldによる動的タスク生成

```python
# Bad: run()内でyieldを使う（非推奨）
class DynamicTask(gokart.TaskOnKart[dict]):
    def run(self):
        other_target = yield OtherTask()  # run()が毎回リスタートされる
        self.dump(process(other_target))

# Good: requires()で静的に依存関係を定義
class StaticTask(gokart.TaskOnKart[dict]):
    other_task: gokart.TaskOnKart[Any] = gokart.TaskInstanceParameter()

    def requires(self):
        return {'other': self.other_task}

    def run(self):
        other_result = self.load(self.other_task)
        self.dump(process(other_result))
```

**yieldの問題点**:

- `run()`がyieldのたびに最初から再実行される
- `run()`は冪等でなければならない
- デバッグが困難

### 7. シークレットのキャッシュキー混入

```python
# Bad: シークレットがキャッシュキーに含まれる
class Config(BaseModel):
    api_key: str
    def gokart_serialize(self) -> str:
        return json.dumps({'api_key': self.api_key})  # シークレット漏洩

# Good: シークレットをキャッシュキーから除外
class Config(BaseModel):
    api_key: SecretStr
    def gokart_serialize(self) -> str:
        return 'noop'  # シークレットを含めない
```
