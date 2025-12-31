# gokart API Reference

## Table of Contents

1. [TaskOnKart](#taskonkart)
2. [Parameters](#parameters)
3. [Build and Run](#build-and-run)
4. [Target Methods](#target-methods)
5. [Testing Utilities](#testing-utilities)

---

## TaskOnKart

`gokart.TaskOnKart[T]` - メインタスククラス（`luigi.Task`継承）

**重要**: 必ず型パラメータ`[T]`を指定すること（mypyで型チェックを行うため）

### Core Methods

```python
def run(self) -> None:
    """タスクロジック実行。self.dump()で結果を保存"""

def requires(self) -> dict[str, gokart.TaskOnKart[Any] | list[gokart.TaskOnKart[Any]]]:
    """依存タスクを返す。TaskInstanceParameterから自動生成される場合は省略可"""

def output(self) -> FlattenableItems[TargetOnKart]:
    """出力ターゲットを返す。デフォルトはself.make_target()"""

def load(self, target: None | str | TaskOnKart[T] = None) -> T:
    """入力データをロード
    - 引数なし: requires()の全入力をロード（dictならdict、単一ならその値）
    - strキー: 特定キーの入力をロード
    - TaskOnKart: 特定タスクの出力をロード"""

def load_generator(self, target=None) -> Generator:
    """大規模データのメモリ効率的なロード"""

def dump(self, obj: T, target: None | str = None) -> None:
    """出力を保存。複数出力時はtargetキーを指定"""
```

### Class Parameters

| Parameter                             | Type | Default                                | Description                          |
| ------------------------------------- | ---- | -------------------------------------- | ------------------------------------ |
| `workspace_directory`                 | str  | `./resources/`                         | 出力ディレクトリ (s3://, gs:// 対応) |
| `local_temporary_directory`           | str  | `./resources/tmp/`                     | 一時ファイルディレクトリ             |
| `rerun`                               | bool | False                                  | タスク強制再実行                     |
| `strict_check`                        | bool | False                                  | 全入力の存在を必須とする             |
| `modification_time_check`             | bool | False                                  | 入出力のタイムスタンプをチェック     |
| `serialized_task_definition_check`    | bool | False                                  | コード変更時に再実行                 |
| `significant`                         | bool | True                                   | unique_id計算に含める                |
| `fix_random_seed_methods`             | list | `['random.seed', 'numpy.random.seed']` | シード固定メソッド                   |
| `fix_random_seed_value`               | int  | (auto)                                 | 固定シード値                         |
| `redis_host`                          | str  | None                                   | タスクロック用Redisホスト            |
| `redis_port`                          | int  | None                                   | Redisポート                          |
| `fail_on_empty_dump`                  | bool | False                                  | 空DataFrameダンプでエラー            |
| `should_dump_supplementary_log_files` | bool | True                                   | メタデータファイルを保存             |

---

## Parameters

### TaskInstanceParameter

```python
# 依存タスクをパラメータとして受け取る
task: gokart.TaskOnKart[pd.DataFrame] = gokart.TaskInstanceParameter()

# pandera型付きDataFrameの場合
from pandera.typing import DataFrame
task: gokart.TaskOnKart[DataFrame[UserSchema]] = gokart.TaskInstanceParameter()
```

### ListTaskInstanceParameter

```python
# 複数タスクのリスト
tasks: list[gokart.TaskOnKart[pd.DataFrame]] = gokart.ListTaskInstanceParameter()

# 間接依存（完了を待つが結果は使わない）
indirect_depends_tasks: list[gokart.TaskOnKart[Any]] = gokart.ListTaskInstanceParameter(
    description='完了を待つが結果は使わないタスク'
)
```

### ExplicitBoolParameter

```python
# CLIで明示的に--flag=true/falseを指定する必要がある
flag: bool = gokart.ExplicitBoolParameter(default=False)
```

### SerializableParameter

Pydanticモデル等のカスタムオブジェクトをパラメータとして使用。

```python
from pydantic import BaseModel, Field, SecretStr
from typing import Annotated
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

class S3Config(BaseModel):
    bucket_name: str
    prefix: str

    def gokart_serialize(self) -> str:
        return json.dumps({'bucket_name': self.bucket_name, 'prefix': self.prefix})

    @classmethod
    def gokart_deserialize(cls, s: str) -> 'S3Config':
        return cls.model_validate(json.loads(s))

# 使用例
class UploadTask(gokart.TaskOnKart[None]):
    s3_config: S3Config = gokart.SerializableParameter(object_type=S3Config)
    slack_config: SlackConfig = gokart.SerializableParameter(object_type=SlackConfig)
```

---

## Build and Run

### gokart.build()

```python
gokart.build(
    task: TaskOnKart[T],
    return_value: bool = True,      # タスク出力を返す
    reset_register: bool = True,    # luigiレジストリをリセット
    log_level: int = logging.ERROR,
    **env_params
) -> T | None
```

### gokart.run()

```python
# main.py
if __name__ == '__main__':
    gokart.add_config('./conf/config.ini')
    gokart.run()

# CLI: python main.py TaskName --local-scheduler --param=value
```

---

## Target Methods

### make_target()

```python
def output(self):
    return self.make_target('output.pkl')  # unique_idが自動付加
    # 対応形式: .pkl, .csv, .tsv, .json, .parquet, .feather, .txt, .gz, .xml, .npz, .png, .jpg, .ini
```

### make_model_target()

```python
def output(self):
    return self.make_model_target(
        'model.zip',
        save_function=model.save,
        load_function=Model.load
    )
```

### make_large_data_frame_target()

```python
def output(self):
    return self.make_large_data_frame_target('large_df.zip', max_byte=2**26)
```

---

## Testing Utilities

### test_run

```python
import gokart
gokart.test_run  # 空DataFrameでのテスト用タスク
```

### assert_frame_contents_equal

```python
from gokart.testing import assert_frame_contents_equal
assert_frame_contents_equal(df1, df2)
```

---

## Configuration File (ini)

```ini
[TaskOnKart]
workspace_directory=${TASK_WORKSPACE_DIRECTORY}
local_temporary_directory=./tmp/

[ProjectConfig]
workspace=${TASK_WORKSPACE_DIRECTORY}
environment=${ENV}

[BigQueryConfig]
project_id=${BQ_PROJECT_ID}
dataset_id=my_dataset
```

Load with `gokart.add_config('config.ini')` before `gokart.run()`.

---

## mypy / pylint 設定

### pyproject.toml

```toml
[tool.mypy]
plugins = ["pandera.mypy", "gokart.mypy"]
strict = true

[tool.pylint.MASTER]
load-plugins = ["pylint_gokart"]
disable = "all"
enable = ["list-parameter-use", "rerun-use"]
```
