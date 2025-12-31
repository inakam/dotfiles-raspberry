# gokart Testing Guide

## Table of Contents

1. [Testable Task Pattern](#testable-task-pattern)
2. [Unit Testing](#unit-testing)
3. [Testing with Mock](#testing-with-mock)
4. [Empty DataFrame Testing](#empty-dataframe-testing)
5. [Integration Testing](#integration-testing)
6. [Test Fixtures](#test-fixtures)

---

## Testable Task Pattern

**推奨**: ビジネスロジックを`_run`クラスメソッドに分離してテストしやすくする。

### 実装

```python
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
        """ビジネスロジック（gokartに依存しない純粋関数）"""
        return df.assign(
            new_column=df['value'] * 2,
        ).pipe(DataFrame[OutputSchema])
```

### テスト

```python
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

## Unit Testing

### pytestを使用（推奨）

```python
import pytest
import tempfile
import shutil
import gokart

@pytest.fixture
def workspace():
    temp_dir = tempfile.mkdtemp()
    yield temp_dir
    shutil.rmtree(temp_dir)

def test_my_task(workspace):
    task = MyTask(workspace_directory=workspace)
    result = gokart.build(task)
    assert result == expected
```

### 基本的なテスト構造（unittest）

```python
import unittest
import tempfile
import shutil
import gokart

class TestMyTask(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.mkdtemp()

    def tearDown(self):
        shutil.rmtree(self.temp_dir)

    def test_my_task(self):
        task = MyTask(
            workspace_directory=self.temp_dir,
            param='test_value'
        )
        output = gokart.build(task)
        self.assertEqual(output, expected_value)
```

---

## Testing with Mock

### load()のモック

```python
from unittest.mock import patch, MagicMock
import pandas as pd

class TestProcessTask(unittest.TestCase):
    def test_process_with_mock_input(self):
        mock_df = pd.DataFrame({'col': [1, 2, 3]})

        with patch.object(ProcessTask, 'load', return_value=mock_df):
            task = ProcessTask(workspace_directory=self.temp_dir)
            with patch.object(task, 'dump') as mock_dump:
                task.run()
                mock_dump.assert_called_once()
                result = mock_dump.call_args[0][0]
                self.assertEqual(len(result), 3)
```

### 完全なパイプラインテスト

```python
def test_pipeline(self):
    end_task = EndTask(
        middle_task=MiddleTask(
            start_task=StartTask()
        ),
        workspace_directory=self.temp_dir
    )
    result = gokart.build(end_task)
    assert result is not None
```

---

## Empty DataFrame Testing

### gokart.test_run

```python
# CLIから空DataFrameテスト実行
# python main.py MyTask --test-run-pandas=true --local-scheduler

# コードから
from gokart.testing import try_to_run_test_for_empty_data_frame

cmdline_args = ['MyTask', '--local-scheduler', '--test-run-pandas=true']
try_to_run_test_for_empty_data_frame(cmdline_args)
```

### fail_on_empty_dumpのテスト

```python
from gokart.task import EmptyDumpError

def test_empty_dataframe_raises_error(self):
    task = MyTask(
        workspace_directory=self.temp_dir,
        fail_on_empty_dump=True
    )

    with pytest.raises(EmptyDumpError):
        gokart.build(task)
```

### assert_frame_contents_equal

```python
from gokart.testing import assert_frame_contents_equal

def test_dataframe_output(self):
    result = gokart.build(MyTask())
    expected = pd.DataFrame({'a': [1, 2], 'b': [3, 4]})
    assert_frame_contents_equal(result, expected)
```

---

## Integration Testing

### S3モック（moto使用）

```python
import boto3
from moto import mock_s3

@mock_s3
def test_s3_output(self):
    conn = boto3.resource('s3', region_name='us-east-1')
    conn.create_bucket(Bucket='test-bucket')

    task = MyTask(workspace_directory='s3://test-bucket/outputs/')
    result = gokart.build(task)
    assert result is not None
```

### BigQueryエミュレータ（bqemulatormanager使用）

```python
from bqemulatormanager import BQEmulatorManager

@pytest.fixture(scope='session')
def bq_emulator():
    with BQEmulatorManager() as manager:
        yield manager

def test_bq_task(bq_emulator):
    # BigQueryを使用するタスクのテスト
    pass
```

---

## Test Fixtures

### conftest.py（推奨）

```python
import pytest
import tempfile
import shutil
import os
import pandas as pd
from unittest.mock import patch

@pytest.fixture(scope='function')
def gokart_workspace():
    """gokartテスト用一時ワークスペース"""
    temp_dir = tempfile.mkdtemp()
    yield temp_dir
    shutil.rmtree(temp_dir)

@pytest.fixture(scope='function')
def sample_dataframe():
    """テスト用サンプルDataFrame"""
    return pd.DataFrame({
        'id': [1, 2, 3],
        'name': ['a', 'b', 'c'],
        'value': [10.0, 20.0, 30.0]
    })

@pytest.fixture
def mock_task_output(sample_dataframe):
    """タスク出力をモックするfixture"""
    def _mock(task_class):
        return patch.object(task_class, 'load', return_value=sample_dataframe)
    return _mock
```

### pandera型付きfixtureの例

```python
from pandera.typing import DataFrame

@pytest.fixture
def input_df() -> DataFrame[InputSchema]:
    """スキーマ付きテスト用DataFrame"""
    return pd.DataFrame({
        'user_id': [1, 2, 3],
        'name': ['Alice', 'Bob', 'Charlie'],
    }).pipe(DataFrame[InputSchema])
```

### pytest環境変数（pyproject.toml）

```toml
[tool.pytest.ini_options]
testpaths = ["test"]
addopts = "-s -v --durations=0"

[tool.pytest_env]
SLACK_TOKEN = "dummy"
SLACK_CHANNEL = "dummy"
```
