# gokart Common Patterns & Templates

## Table of Contents

1. [Basic Task](#basic-task)
2. [Project Base Class](#project-base-class)
3. [Pipeline with Dependencies](#pipeline-with-dependencies)
4. [Type-Safe Pipeline](#type-safe-pipeline)
5. [Pandera Schema Validation](#pandera-schema-validation)
6. [Pydantic with SerializableParameter](#pydantic-with-serializableparameter)
7. [Multiple Inputs](#multiple-inputs)
8. [Multiple Outputs](#multiple-outputs)
9. [ML Model Training](#ml-model-training)
10. [Pipeline Class Pattern](#pipeline-class-pattern)
11. [Declarative Pipeline Pattern](#declarative-pipeline-pattern)
12. [API Call Decomposition Pattern](#api-call-decomposition-pattern)
13. [2段階gokart.build()パターン](#2段階gokartbuildパターン)
14. [Testable Task Pattern](#testable-task-pattern)
15. [Config Injection](#config-injection)

---

## Basic Task

**重要**: 必ず `gokart.TaskOnKart[T]` と型パラメータを指定すること（mypyで型チェックを行うため）

```python
import gokart

class HelloWorld(gokart.TaskOnKart[str]):
    def run(self):
        self.dump('Hello, World!')

output = gokart.build(HelloWorld())
```

---

## Project Base Class

プロジェクト共通の設定を持つベースクラスを定義する（mojitoパターン）

```python
from logging import getLogger
import gokart

class MyProjectTask[T](gokart.TaskOnKart[T]):
    """プロジェクト共通のベースクラス"""
    task_namespace = 'my_project'

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.logger = getLogger(self.__module__)

# 使用例
class LoadData(MyProjectTask[pd.DataFrame]):
    def run(self):
        self.logger.info('Loading data...')
        self.dump(pd.read_csv('data.csv'))
```

---

## Pipeline with Dependencies

```python
import gokart
import luigi
import pandas as pd

class LoadData(gokart.TaskOnKart[pd.DataFrame]):
    def run(self):
        self.dump(pd.read_csv('data.csv'))

class ProcessData(gokart.TaskOnKart[pd.DataFrame]):
    data_task: gokart.TaskOnKart[pd.DataFrame] = gokart.TaskInstanceParameter()

    def run(self):
        df = self.load(self.data_task)
        self.dump(df.dropna())

class SaveResult(gokart.TaskOnKart[None]):
    process_task: gokart.TaskOnKart[pd.DataFrame] = gokart.TaskInstanceParameter()

    def run(self):
        df = self.load(self.process_task)
        df.to_csv('output.csv')
        self.dump(None)

# パイプライン構築
pipeline = SaveResult(
    process_task=ProcessData(data_task=LoadData())
)
gokart.build(pipeline)
```

---

## Type-Safe Pipeline

```python
import gokart
import luigi

class IntProducer(gokart.TaskOnKart[int]):
    value: int = luigi.IntParameter(default=10)

    def run(self):
        self.dump(self.value)

class IntConsumer(gokart.TaskOnKart[int]):
    producer: gokart.TaskOnKart[int] = gokart.TaskInstanceParameter()

    def run(self):
        value: int = self.load(self.producer)
        self.dump(value * 2)

# mypyで型チェック可能
task = IntConsumer(producer=IntProducer())
```

---

## Pandera Schema Validation

panderaを使ったDataFrameのスキーマ検証（mojitoパターン）

```python
import gokart
import pandas as pd
import pandera as pa
from pandera.typing import DataFrame, Series

class UserSchema(pa.DataFrameModel):
    """ユーザーデータのスキーマ"""
    user_id: Series[int] = pa.Field(gt=0, coerce=True)
    name: Series[str] = pa.Field(str_length={'min_value': 1})
    email: Series[str] = pa.Field(str_matches=r'^[\w\.-]+@[\w\.-]+\.\w+$')

    class Config:
        strict = 'filter'  # スキーマにないカラムを削除

class LoadUsers(gokart.TaskOnKart[DataFrame[UserSchema]]):
    def run(self):
        df = pd.read_csv('users.csv')
        validated_df = df.pipe(DataFrame[UserSchema])
        self.dump(validated_df)

class ProcessUsers(gokart.TaskOnKart[DataFrame[UserSchema]]):
    users_task: gokart.TaskOnKart[DataFrame[UserSchema]] = gokart.TaskInstanceParameter()

    def run(self):
        df = self.load(self.users_task)
        # dfはDataFrame[UserSchema]として型推論される
        self.dump(df)
```

---

## Pydantic with SerializableParameter

Pydanticモデルをパラメータとして使用（mojitoパターン）

```python
import json
from typing import Annotated, Literal
import gokart
import luigi
from pydantic import BaseModel, Field, SecretStr

Env = Literal['dev', 'qa', 'prod']

class SlackConfig(BaseModel):
    """Slack通知の設定"""
    token: Annotated[SecretStr, Field(description='Slack token')]
    channel: Annotated[str, Field(description='通知先チャンネル')]

    def gokart_serialize(self) -> str:
        # シークレットはキャッシュキーに含めない
        return 'noop'

    @classmethod
    def gokart_deserialize(cls, s: str) -> 'SlackConfig':
        return cls.model_validate(json.loads(s))

class S3Config(BaseModel):
    """S3設定"""
    bucket_name: Annotated[str, Field(description='バケット名')]
    prefix: Annotated[str, Field(description='プレフィックス')]

    def gokart_serialize(self) -> str:
        return json.dumps({'bucket_name': self.bucket_name, 'prefix': self.prefix})

    @classmethod
    def gokart_deserialize(cls, s: str) -> 'S3Config':
        return cls.model_validate(json.loads(s))

class UploadTask(gokart.TaskOnKart[None]):
    env: Env = luigi.ChoiceParameter(choices=['dev', 'qa', 'prod'])
    s3_config: S3Config = gokart.SerializableParameter(object_type=S3Config)
    slack_config: SlackConfig = gokart.SerializableParameter(object_type=SlackConfig)

    def run(self):
        # s3_config, slack_configをPydanticモデルとして使用可能
        self.dump(None)
```

---

## Multiple Inputs

### requires()でdictを返す

```python
from typing import Any

class CombineData(gokart.TaskOnKart[pd.DataFrame]):
    users_task: gokart.TaskOnKart[pd.DataFrame] = gokart.TaskInstanceParameter()
    orders_task: gokart.TaskOnKart[pd.DataFrame] = gokart.TaskInstanceParameter()

    def requires(self) -> dict[str, gokart.TaskOnKart[Any] | list[gokart.TaskOnKart[Any]]]:
        return {
            'users': self.users_task,
            'orders': self.orders_task,
        }

    def run(self):
        users = self.load(self.users_task)
        orders = self.load(self.orders_task)
        self.dump(users.merge(orders, on='user_id'))
```

### ListTaskInstanceParameterで可変長タスク

```python
from typing import Any

class AggregateResults(gokart.TaskOnKart[pd.DataFrame]):
    tasks: list[gokart.TaskOnKart[pd.DataFrame]] = gokart.ListTaskInstanceParameter()
    indirect_depends_tasks: list[gokart.TaskOnKart[Any]] = gokart.ListTaskInstanceParameter(
        description='完了を待つが結果は使わないタスク'
    )

    def requires(self) -> dict[str, gokart.TaskOnKart[Any] | list[gokart.TaskOnKart[Any]]]:
        return {
            'tasks': self.tasks,
            **{f'indirect_{i}': t for i, t in enumerate(self.indirect_depends_tasks)},
        }

    def run(self):
        dfs = [self.load(t) for t in self.tasks]
        self.dump(pd.concat(dfs))
```

---

## Multiple Outputs

```python
class SplitData(gokart.TaskOnKart[None]):
    def output(self):
        return {
            'train': self.make_target('train.pkl'),
            'test': self.make_target('test.pkl'),
        }

    def run(self):
        df = self.load()
        train, test = train_test_split(df, test_size=0.2)
        self.dump(train, 'train')
        self.dump(test, 'test')
```

---

## ML Model Training

```python
import gokart
import luigi
import joblib
from sklearn.ensemble import RandomForestClassifier

class TrainRandomForest(gokart.TaskOnKart[RandomForestClassifier]):
    n_estimators: int = luigi.IntParameter(default=100)
    data_task: gokart.TaskOnKart[tuple[pd.DataFrame, pd.Series]] = gokart.TaskInstanceParameter()

    def output(self):
        return self.make_model_target(
            'models/random_forest.zip',
            save_function=lambda model, path: joblib.dump(model, path),
            load_function=joblib.load,
        )

    def run(self):
        X_train, y_train = self.load(self.data_task)
        model = RandomForestClassifier(n_estimators=self.n_estimators)
        model.fit(X_train, y_train)
        self.dump(model)
```

---

## Pipeline Class Pattern

複雑なパイプラインをクラスとして組み立てる（mojitoパターン）

```python
import datetime
from typing import Any, Literal, cast
import gokart
import luigi
from pandera.typing import DataFrame

class PipelineConfig(BaseModel):
    """パイプラインの設定"""
    company_id: int
    deploy_stage: Literal['validation', 'production']

    def gokart_serialize(self) -> str:
        return json.dumps({'company_id': self.company_id, 'deploy_stage': self.deploy_stage})

    @classmethod
    def gokart_deserialize(cls, s: str) -> 'PipelineConfig':
        return cls.model_validate(json.loads(s))

class MyPipeline(gokart.TaskOnKart[None]):
    """パイプラインのエンドポイントタスク"""
    env: Literal['dev', 'prod'] = luigi.ChoiceParameter(choices=['dev', 'prod'])
    asof: datetime.date = luigi.DateParameter()
    config: PipelineConfig = gokart.SerializableParameter(object_type=PipelineConfig)
    dry_run: bool = luigi.BoolParameter(default=False)

    def requires(self) -> dict[str, gokart.TaskOnKart[Any] | list[gokart.TaskOnKart[Any]]]:
        # validationモードでは何もしない
        if self.config.deploy_stage != 'production':
            return {}

        # パイプラインを構築
        load_task = self._build_load_task()
        process_task = self._build_process_task(load_task)
        upload_task = self._build_upload_task(process_task)
        return {'upload': upload_task}

    def _build_load_task(self) -> gokart.TaskOnKart[DataFrame[InputSchema]]:
        return LoadDataTask(company_id=self.config.company_id, asof=self.asof)

    def _build_process_task(
        self,
        load_task: gokart.TaskOnKart[DataFrame[InputSchema]],
    ) -> gokart.TaskOnKart[DataFrame[OutputSchema]]:
        return ProcessDataTask(input_task=load_task)

    def _build_upload_task(
        self,
        process_task: gokart.TaskOnKart[DataFrame[OutputSchema]],
    ) -> gokart.TaskOnKart[None]:
        return UploadTask(
            data_task=process_task,
            env=self.env,
            dry_run=self.dry_run,
        )

    def run(self):
        self.dump(None)
```

---

## Declarative Pipeline Pattern

requires()内でパイプライン全体を宣言的に構築する（jasmineパターン/ioパターン）

### 仕組み

1. **1つのPipelineクラス**がエントリーポイントとなり、全体を制御
2. `requires()`内で**タスクインスタンス**を変数に代入→次タスクの引数として渡す
3. 渡されるのは**実行結果ではなくタスクオブジェクト**
4. 実際の実行結果は`run()`内で`self.load()`して取得

```
Pipeline.requires()内での構築:
  DownloadA() ─┐
               ├─→ JoinAB(a=downloadA, b=downloadB) ─→ ProcessC(input=joinAB)
  DownloadB() ─┘

実行時:
  1. DownloadA.run() → 結果をキャッシュ
  2. DownloadB.run() → 結果をキャッシュ
  3. JoinAB.run() → self.load(self.a), self.load(self.b) でA,Bの結果を取得
  4. ProcessC.run() → self.load(self.input) でJoinABの結果を取得
```

パイプラインの流れがrequires()を読むだけで把握でき、見通しが良い。

```python
import gokart
import luigi
from datetime import date, datetime

class RunMRModel(gokart.TaskOnKart[None]):
    """MRスコア算出パイプライン（jasmineパターン）"""
    from_date: date = luigi.DateParameter()
    to_date: date = luigi.DateParameter()
    asof: datetime = luigi.DateSecondParameter(default=datetime.now())
    segment_method: str = luigi.Parameter(default='all')
    muraseg_id: int = luigi.IntParameter(default=580)

    def requires(self):
        # ========== データ取得 ==========
        action_data = PreprocessActionLog(
            from_date=self.from_date,
            to_date=self.to_date,
        )
        target_user = DownloadUserMetaData(cache_key_date=self.asof)

        # ========== 前処理 ==========
        user_segment = SplitSegment(
            asof=self.asof,
            target_user=target_user,
            segment_method=self.segment_method,
            muraseg_id=self.muraseg_id,
        )

        # ========== test群の処理 ==========
        test_action_data = GetSegmentedActionLogByPrefix(
            action_data=action_data,
            user_segment=user_segment,
            target_prefix='test',
        )
        test_user_segment = GetSegmentedUserDataByPrefix(
            user_segment=user_segment,
            target_prefix='test',
        )
        test_score = PredictModel(
            action_data=test_action_data,
            user_segment=test_user_segment,
        )

        # ========== ctrl群の処理 ==========
        ctrl_action_data = GetSegmentedActionLogByPrefix(
            action_data=action_data,
            user_segment=user_segment,
            target_prefix='ctrl',
        )
        ctrl_user_segment = GetSegmentedUserDataByPrefix(
            user_segment=user_segment,
            target_prefix='ctrl',
        )
        ctrl_score = PredictModel(
            action_data=ctrl_action_data,
            user_segment=ctrl_user_segment,
        )

        # ========== 結果統合・アップロード ==========
        scores = FlattenTask(target=[test_score, ctrl_score])
        result = UploadScore(score=scores)

        return result
```

### FlattenTaskヘルパー

```python
from typing import TypeVar, Sequence
import gokart
import pandas as pd

T = TypeVar('T')

class FlattenTask(gokart.TaskOnKart[pd.DataFrame]):
    """複数タスクの結果を結合するヘルパー"""
    target: Sequence[gokart.TaskOnKart[pd.DataFrame]] = gokart.ListTaskInstanceParameter()

    def requires(self):
        return self.target

    def run(self):
        dfs = [self.load(t) for t in self.target]
        self.dump(pd.concat(dfs, ignore_index=True))
```

### 依存関係だけを張るパターン

結果は使わないが、そのタスクが完了してから実行したい場合（バリデーション、アサーションなど）：

```python
class SendGridMailTask(M3Io[str]):
    mail_data_task: gokart.TaskOnKart[DataFrame] = gokart.TaskInstanceParameter()
    # 結果は使わないが、これらが成功してから実行したい
    assert_allowed_domains: gokart.TaskOnKart[None] = gokart.TaskInstanceParameter()
    assert_placeholders: gokart.TaskOnKart[None] = gokart.TaskInstanceParameter()

    def requires(self):
        return {
            'mail_data': self.mail_data_task,
            'assert_domains': self.assert_allowed_domains,   # 結果は使わない
            'assert_placeholders': self.assert_placeholders, # 結果は使わない
        }

    def run(self):
        mail_data = self.load('mail_data')  # これだけ使う
        # assert_domains, assert_placeholdersはload()しない
        self.dump(send_mail(mail_data))
```

**ユースケース**:

- バリデーションタスクが成功してからデータ送信
- アラート通知タスクが完了してからメイン処理
- 複数の前提条件チェックを並列実行後にメイン処理

### キャッシュ無効化パターン

実行時刻をパラメータに含めることで毎回実行させる。

```python
from datetime import datetime

class FetchLatestData(gokart.TaskOnKart[pd.DataFrame]):
    """外部から最新データを取得（毎回実行）"""
    # 実行時刻をキャッシュキーに含める
    _cache_key_datetime: datetime = luigi.DateSecondParameter(default=datetime.now())

    def run(self):
        df = fetch_from_external_api()
        self.dump(df)
```

---

## API Call Decomposition Pattern

外部APIコール（ChatGPT等）を1リクエスト1タスクに分解する。

キャッシュが効くため、途中で失敗しても再実行時に成功済みのリクエストをスキップできる。
**pipelineパターンと組み合わせて使用可能**（mekongでも両方を併用している）。

```python
import os
from typing import Dict, Tuple
import gokart
import luigi
from openai import OpenAI

# 1リクエスト = 1タスク
class TagWithChatGPT(gokart.TaskOnKart[dict]):
    """1テキストに対するタグ付けタスク"""
    text: str = luigi.Parameter()
    tag_names: Tuple[str, ...] = luigi.TupleParameter()
    gpt_model: str = luigi.Parameter(significant=False)  # キャッシュキーに含めない

    def run(self):
        result = self._call_api(self.text, self.tag_names, self.gpt_model)
        self.dump(result)

    @classmethod
    def _call_api(cls, text: str, tag_names: Tuple[str, ...], gpt_model: str) -> dict:
        """API呼び出し（テスト可能）"""
        client = OpenAI(
            api_key=os.getenv('OPENAI_API_KEY'),
            max_retries=3,
            timeout=60.0,
        )
        response = client.chat.completions.create(
            model=gpt_model,
            messages=[
                {'role': 'system', 'content': 'タグ付けシステム...'},
                {'role': 'user', 'content': f'text: {text}, tags: {tag_names}'},
            ],
            temperature=0.0,
        )
        return {'text': text, 'result': response.choices[0].message.content}


# 複数テキストを並列処理
class TagTexts(gokart.TaskOnKart[Dict[str, dict]]):
    """複数テキストへのタグ付け（バッチ）"""
    texts: Tuple[str, ...] = luigi.TupleParameter()
    gpt_model: str = luigi.Parameter(significant=False)

    def requires(self):
        # 各テキストに対して個別タスクを生成
        return {
            text: TagWithChatGPT(
                text=text,
                tag_names=('tag1', 'tag2'),
                gpt_model=self.gpt_model,
            )
            for text in self.texts
        }

    def run(self):
        results: Dict[str, dict] = self.load()
        self.dump(results)


# さらに大規模な場合：バッチを分割して並列実行
class ConcatTagTexts(gokart.TaskOnKart[Dict[str, dict]]):
    """複数のTagTextsタスクの結果を結合

    大量のテキストを小さなバッチに分割し、並列実行後に結合する。
    """
    tag_texts_tasks: list[gokart.TaskOnKart[Dict[str, dict]]] = gokart.ListTaskInstanceParameter()

    def requires(self):
        return self.tag_texts_tasks

    def run(self):
        all_results: Dict[str, dict] = {}
        for task in self.tag_texts_tasks:
            results = self.load(task)
            all_results.update(results)
        self.dump(all_results)


# 使用例
def create_tagging_pipeline(texts: list[str], batch_size: int = 10) -> ConcatTagTexts:
    """大量テキストを分割してタグ付けパイプラインを構築"""
    batches = [tuple(texts[i:i+batch_size]) for i in range(0, len(texts), batch_size)]
    tag_tasks = [
        TagTexts(texts=batch, gpt_model='gpt-4o-mini')
        for batch in batches
    ]
    return ConcatTagTexts(tag_texts_tasks=tag_tasks)
```

### メリット

1. **途中再開可能**: 100件中50件目で失敗しても、再実行時に成功済み49件はキャッシュから読み込み
2. **並列実行**: luigiのworker数に応じて並列処理可能
3. **コスト管理**: significant=Falseでモデル変更時にキャッシュ無効化を防ぐ
4. **リトライ**: OpenAI clientのmax_retriesで自動リトライ

### 動的タスク生成の制約

**タスク数**が依存タスクの結果に依存する場合のみ、`requires()`内で動的にタスクを生成できない：

| ケース                   | 例                                     | requires()内で可能か      |
| ------------------------ | -------------------------------------- | ------------------------- |
| タスク数が事前に確定     | パラメータで渡されたリスト             | ✅ ループでタスク生成可能 |
| タスク数が依存タスク次第 | 前タスクの出力件数だけタスクを作りたい | ❌ 件数が不明なので不可能 |

**注意**: pipelineパターンでは依存タスクの**実行結果**を受け渡すことは可能。制約があるのは「タスク数の動的決定」のみ。

```python
# ❌ できない: requires()が呼ばれる時点で件数が不明
class SendMailsPerItem(gokart.TaskOnKart[str]):
    mail_data_task = gokart.TaskInstanceParameter()

    def requires(self):
        mail_list = ???  # ← 件数がわからないのでタスクを何個作ればいいか不明
        return [SendOneMail(mail=m) for m in mail_list]

# ✅ 解決策1: run()内で一括処理（キャッシュは粒度が粗くなる）
class SendMails(gokart.TaskOnKart[str]):
    mail_data_task = gokart.TaskInstanceParameter()

    def run(self):
        mail_list = self.load(self.mail_data_task)
        for mail in mail_list:
            send_mail(mail)  # 一括処理
        self.dump("done")

# ✅ 解決策2: pipelineパターンで実行結果を受け渡す
# タスク数は固定だが、各タスクに前タスクの結果を渡して処理
class ProcessPipeline(gokart.TaskOnKart[None]):
    def requires(self):
        download = DownloadData(...)
        process = ProcessData(input_data=download)  # ← タスクインスタンスを渡す
        send = SendMail(processed_data=process)     # ← 結果がチェーンで流れる
        return send

# ✅ 解決策3: 2段階gokart.build()パターン（推奨）
# 1回目のbuildで件数を確定し、2回目で動的にタスクを生成・実行
# → 「2段階gokart.build()パターン」セクション参照
```

---

## 2段階gokart.build()パターン

依存タスクの結果に基づいてタスク数を動的に決めたい場合は、**2回のgokart.build()**を使う（mekongパターン）。

```python
# batch/daily_tagging.py（バッチスクリプト）
def main(asof_date: str, n_workers: int = 50):
    # ========== 1回目のbuild: データ取得 ==========
    daily_survey_report = gokart.build(
        DownloadRecentDailyMXSurveyReport(asof_date=asof_date),
        log_level=logging.DEBUG,
    )

    if len(daily_survey_report) == 0:
        return

    # ========== Pythonで動的にタスクを生成 ==========
    texts = extract_texts(mx_data=daily_survey_report)
    tag_texts_tasks = []
    for i in range(0, len(texts), 100):  # ← 件数に基づいてループ
        texts_chunk = texts[i : i + 100]
        tag_texts_tasks.append(TagTexts(texts=tuple(texts_chunk), gpt_model='gpt-4o'))

    # ========== 2回目のbuild: 動的に生成したタスクを実行 ==========
    tagged_texts = gokart.build(
        ConcatTagTexts(tag_texts_tasks=tag_texts_tasks),
        workers=n_workers,
    )

    # ========== 結果を処理 ==========
    upload_to_bigquery(tagged_texts)


if __name__ == '__main__':
    fire.Fire(main)
```

### 仕組み

```
batch/daily_tagging.py:
  1. gokart.build(DownloadData) → 件数確定（例: 10000件）
  2. Pythonでループ: 100件ずつTagTextsタスクを100個生成
  3. gokart.build(ConcatTagTexts(tasks=[...])) → 100個を並列実行
```

### ポイント

| 特徴                       | 説明                                       |
| -------------------------- | ------------------------------------------ |
| **2回のgokart.build()**    | 1回目で件数を確定、2回目で動的タスクを実行 |
| **バッチスクリプトで制御** | Pipelineクラスではなくbatch/\*.pyで制御    |
| **途中再開可能**           | 個々のTagTextsはキャッシュされる           |
| **並列実行**               | workers引数で並列数を制御                  |
| **大量データ対応**         | 10000件→100件×100タスクのように分割        |

### Pipelineパターンとの使い分け

| パターン                 | 用途                 | タスク数     |
| ------------------------ | -------------------- | ------------ |
| **Pipelineパターン**     | 固定的なワークフロー | 事前に確定   |
| **2段階build()パターン** | 件数に応じた動的処理 | 実行時に決定 |

両者を組み合わせることも可能（1回目のbuildでPipelineを実行し、その結果で2回目のタスクを生成）。

---

## Testable Task Pattern

ビジネスロジックを`_run`クラスメソッドに分離してテストしやすくする（mojitoパターン）

```python
import gokart
from pandera.typing import DataFrame

class TransformTask(gokart.TaskOnKart[DataFrame[OutputSchema]]):
    input_task: gokart.TaskOnKart[DataFrame[InputSchema]] = gokart.TaskInstanceParameter()

    def requires(self) -> dict[str, gokart.TaskOnKart[Any]]:
        return {'input': self.input_task}

    def run(self):
        df = self.load(self.input_task)
        result = self._run(df)
        self.dump(result)

    @classmethod
    def _run(cls, df: DataFrame[InputSchema]) -> DataFrame[OutputSchema]:
        """ビジネスロジック（テスト可能）"""
        return df.assign(
            new_column=df['value'] * 2,
        ).pipe(DataFrame[OutputSchema])

# テストコード
class TestTransformTask:
    def test_run(self):
        input_df = DataFrame[InputSchema](pd.DataFrame({'value': [1, 2, 3]}))
        result = TransformTask._run(input_df)
        expected = DataFrame[OutputSchema](pd.DataFrame({'value': [1, 2, 3], 'new_column': [2, 4, 6]}))
        pd.testing.assert_frame_equal(result, expected)
```

---

## Config Injection

### luigi.Configとiniファイル

```python
import luigi

class ProjectConfig(luigi.Config):
    workspace: str = luigi.Parameter()
    environment: str = luigi.Parameter(default='dev')

class BigQueryConfig(luigi.Config):
    project_id: str = luigi.Parameter()
    dataset_id: str = luigi.Parameter()
```

### conf/base.ini

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

### main.py

```python
import gokart

if __name__ == '__main__':
    gokart.add_config('./conf/base.ini')
    gokart.run()
```

### pyproject.toml（mypy設定）

```toml
[tool.mypy]
plugins = ["pandera.mypy", "gokart.mypy"]
strict = true
```
