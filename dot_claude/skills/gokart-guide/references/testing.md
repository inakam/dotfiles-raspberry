# gokart Testing Best Practices

## Table of Contents
- Testing Philosophy
- Basic Task Testing
- Testing with Dependencies
- Testing with Pandera
- Common Testing Patterns

## Testing Philosophy

### Key Principles

1. **Minimize Mocking**: Only mock external dependencies (APIs, databases)
2. **No Fixtures for Test Data**: Keep test data inline with assertions
3. **Test Actual Task Execution**: Use `gokart.build()` or `test_run()` when possible

### What to Mock

**Mock:**
- External API calls
- Database connections
- File system operations (when testing logic, not I/O)
- Time-dependent functions

**Don't Mock:**
- gokart's internal mechanisms
- Task dependencies (use real tasks instead)
- Data transformations

## Basic Task Testing

### Simple Task Test

```python
import gokart
from gokart import build

class SimpleTask(gokart.TaskOnKart[int]):
    n: int = luigi.IntParameter()

    def run(self):
        result = self.n * 2
        self.dump(result)

def test_simple_task():
    # Execute task and get result
    result = build(SimpleTask(n=5))

    # Assert result
    assert result == 10
```

### Testing with test_run

```python
from gokart.testing import test_run

def test_simple_task_with_test_run():
    # test_run returns the output directly
    result = test_run(SimpleTask(n=5))
    assert result == 10
```

### Testing Task with Validation

```python
import pytest

class ValidatedTask(gokart.TaskOnKart[int]):
    n: int = luigi.IntParameter()

    def run(self):
        if self.n < 0:
            raise ValueError("n must be non-negative")
        self.dump(self.n * 2)

def test_validated_task_success():
    result = test_run(ValidatedTask(n=5))
    assert result == 10

def test_validated_task_failure():
    with pytest.raises(ValueError, match="n must be non-negative"):
        test_run(ValidatedTask(n=-1))
```

## Testing with Dependencies

### Testing Task Dependencies

Don't mock dependencies - use real task instances:

```python
class DataTask(gokart.TaskOnKart[list]):
    def run(self):
        self.dump([1, 2, 3, 4, 5])

class SumTask(gokart.TaskOnKart[int]):
    data: gokart.TaskOnKart[list] = gokart.TaskInstanceParameter()

    def requires(self):
        return self.data

    def run(self):
        values = self.load(self.data)
        self.dump(sum(values))

def test_sum_task():
    # Use actual dependency task
    result = test_run(SumTask(data=DataTask()))
    assert result == 15
```

### Testing Complex Dependencies

```python
class TaskA(gokart.TaskOnKart[int]):
    value: int = luigi.IntParameter()

    def run(self):
        self.dump(self.value)

class TaskB(gokart.TaskOnKart[int]):
    value: int = luigi.IntParameter()

    def run(self):
        self.dump(self.value * 2)

class CombineTask(gokart.TaskOnKart[int]):
    a: gokart.TaskOnKart[int] = gokart.TaskInstanceParameter()
    b: gokart.TaskOnKart[int] = gokart.TaskInstanceParameter()

    def requires(self):
        return dict(a=self.a, b=self.b)

    def run(self):
        a_val = self.load(self.a)
        b_val = self.load(self.b)
        self.dump(a_val + b_val)

def test_combine_task():
    # Test with different input combinations
    result = test_run(
        CombineTask(
            a=TaskA(value=10),
            b=TaskB(value=5)
        )
    )
    # TaskA(10) -> 10, TaskB(5) -> 10, sum -> 20
    assert result == 20

def test_combine_task_different_values():
    result = test_run(
        CombineTask(
            a=TaskA(value=3),
            b=TaskB(value=7)
        )
    )
    # TaskA(3) -> 3, TaskB(7) -> 14, sum -> 17
    assert result == 17
```

### Testing with Property-based Dependencies

```python
class DynamicTask(gokart.TaskOnKart[int]):
    date: str = luigi.Parameter()
    multiplier: int = luigi.IntParameter()

    def requires(self):
        return self.data_task

    def run(self):
        data = self.load(self.data_task)
        self.dump(data * self.multiplier)

    @property
    def data_task(self) -> DataForDateTask:
        return DataForDateTask(date=self.date)

def test_dynamic_task():
    result = test_run(DynamicTask(date='2024-01-01', multiplier=3))
    # Assumes DataForDateTask('2024-01-01') returns 5
    assert result == 15
```

## Testing with Pandera

### Testing DataFrame Tasks

```python
import pandas as pd
import pandera.pandas as pa
from pandera.typing.pandas import DataFrame, Series

class InputSchema(pa.DataFrameModel):
    user_id: Series[int] = pa.Field(gt=0)
    score: Series[float] = pa.Field(ge=0, le=100)

class OutputSchema(pa.DataFrameModel):
    user_id: Series[int]
    score: Series[float]
    grade: Series[str]

class GradeTask(gokart.TaskOnKart[DataFrame[OutputSchema]]):
    source: gokart.TaskOnKart[DataFrame[InputSchema]] = gokart.TaskInstanceParameter()

    def requires(self):
        return self.source

    def run(self):
        df = self.load(self.source)
        result = self._assign_grades(df)
        self.dump(result)

    def _assign_grades(self, df: DataFrame[InputSchema]) -> DataFrame[OutputSchema]:
        return DataFrame[OutputSchema](
            df.assign(
                grade=lambda x: x['score'].apply(
                    lambda s: 'A' if s >= 90 else 'B' if s >= 80 else 'C'
                )
            )
        )

# Create a test data task
class TestInputTask(gokart.TaskOnKart[DataFrame[InputSchema]]):
    def run(self):
        # Test data defined inline
        df = pd.DataFrame({
            'user_id': [1, 2, 3],
            'score': [95.0, 85.0, 75.0]
        })
        self.dump(DataFrame[InputSchema](df))

def test_grade_task():
    result = test_run(GradeTask(source=TestInputTask()))

    # Assert shape
    assert len(result) == 3

    # Assert grades
    assert result.loc[result['user_id'] == 1, 'grade'].iloc[0] == 'A'
    assert result.loc[result['user_id'] == 2, 'grade'].iloc[0] == 'B'
    assert result.loc[result['user_id'] == 3, 'grade'].iloc[0] == 'C'

    # Assert schema validation passed (implicit in test_run)
    assert 'grade' in result.columns
```

### Testing Schema Validation

```python
def test_grade_task_validates_output():
    # Test that invalid output raises error
    class InvalidOutputTask(gokart.TaskOnKart[DataFrame[OutputSchema]]):
        def run(self):
            # Missing 'grade' column - should fail
            df = pd.DataFrame({
                'user_id': [1, 2],
                'score': [95.0, 85.0]
            })
            self.dump(DataFrame[OutputSchema](df))

    with pytest.raises(pa.errors.SchemaError):
        test_run(InvalidOutputTask())
```

### Testing with Multiple DataFrame Inputs

```python
class UserSchema(pa.DataFrameModel):
    user_id: Series[int]
    name: Series[str]

class ScoreSchema(pa.DataFrameModel):
    user_id: Series[int]
    score: Series[float]

class MergedSchema(pa.DataFrameModel):
    user_id: Series[int]
    name: Series[str]
    score: Series[float]

class MergeTask(gokart.TaskOnKart[DataFrame[MergedSchema]]):
    users: gokart.TaskOnKart[DataFrame[UserSchema]] = gokart.TaskInstanceParameter()
    scores: gokart.TaskOnKart[DataFrame[ScoreSchema]] = gokart.TaskInstanceParameter()

    def requires(self):
        return dict(users=self.users, scores=self.scores)

    def run(self):
        users_df = self.load(self.users)
        scores_df = self.load(self.scores)

        merged = users_df.merge(scores_df, on='user_id')
        self.dump(DataFrame[MergedSchema](merged))

class TestUsersTask(gokart.TaskOnKart[DataFrame[UserSchema]]):
    def run(self):
        df = pd.DataFrame({
            'user_id': [1, 2, 3],
            'name': ['Alice', 'Bob', 'Charlie']
        })
        self.dump(DataFrame[UserSchema](df))

class TestScoresTask(gokart.TaskOnKart[DataFrame[ScoreSchema]]):
    def run(self):
        df = pd.DataFrame({
            'user_id': [1, 2, 3],
            'score': [95.0, 85.0, 75.0]
        })
        self.dump(DataFrame[ScoreSchema](df))

def test_merge_task():
    result = test_run(
        MergeTask(
            users=TestUsersTask(),
            scores=TestScoresTask()
        )
    )

    assert len(result) == 3
    assert set(result.columns) == {'user_id', 'name', 'score'}

    # Test specific row
    alice = result[result['name'] == 'Alice'].iloc[0]
    assert alice['user_id'] == 1
    assert alice['score'] == 95.0
```

## Common Testing Patterns

### Parameterized Tests

```python
import pytest

class MultiplyTask(gokart.TaskOnKart[int]):
    n: int = luigi.IntParameter()
    multiplier: int = luigi.IntParameter()

    def run(self):
        self.dump(self.n * self.multiplier)

@pytest.mark.parametrize('n,multiplier,expected', [
    (5, 2, 10),
    (3, 3, 9),
    (10, 0, 0),
    (-5, 2, -10),
])
def test_multiply_task(n, multiplier, expected):
    result = test_run(MultiplyTask(n=n, multiplier=multiplier))
    assert result == expected
```

### Testing Error Cases

```python
class DivideTask(gokart.TaskOnKart[float]):
    a: int = luigi.IntParameter()
    b: int = luigi.IntParameter()

    def run(self):
        if self.b == 0:
            raise ValueError("Division by zero")
        self.dump(self.a / self.b)

def test_divide_task_success():
    result = test_run(DivideTask(a=10, b=2))
    assert result == 5.0

def test_divide_task_zero_division():
    with pytest.raises(ValueError, match="Division by zero"):
        test_run(DivideTask(a=10, b=0))
```

### Testing with External API (Mocking Allowed)

```python
from unittest.mock import patch

class FetchUserDataTask(gokart.TaskOnKart[dict]):
    user_id: int = luigi.IntParameter()

    def run(self):
        data = self._fetch_from_api(self.user_id)
        self.dump(data)

    def _fetch_from_api(self, user_id: int) -> dict:
        # External API call
        import requests
        response = requests.get(f'https://api.example.com/users/{user_id}')
        return response.json()

def test_fetch_user_data_task():
    # Mock the API call
    mock_response = {'id': 123, 'name': 'Alice', 'email': 'alice@example.com'}

    with patch.object(FetchUserDataTask, '_fetch_from_api', return_value=mock_response):
        result = test_run(FetchUserDataTask(user_id=123))

    assert result == mock_response
    assert result['name'] == 'Alice'
```

### Testing Task Chain

```python
class RawDataTask(gokart.TaskOnKart[list]):
    def run(self):
        self.dump([1, 2, 3, 4, 5])

class FilterTask(gokart.TaskOnKart[list]):
    source: gokart.TaskOnKart[list] = gokart.TaskInstanceParameter()
    threshold: int = luigi.IntParameter()

    def requires(self):
        return self.source

    def run(self):
        data = self.load(self.source)
        filtered = [x for x in data if x > self.threshold]
        self.dump(filtered)

class SumTask(gokart.TaskOnKart[int]):
    source: gokart.TaskOnKart[list] = gokart.TaskInstanceParameter()

    def requires(self):
        return self.source

    def run(self):
        data = self.load(self.source)
        self.dump(sum(data))

def test_task_chain():
    # Test entire pipeline
    result = test_run(
        SumTask(
            source=FilterTask(
                source=RawDataTask(),
                threshold=2
            )
        )
    )
    # RawDataTask -> [1,2,3,4,5]
    # FilterTask(threshold=2) -> [3,4,5]
    # SumTask -> 12
    assert result == 12
```

### Testing with Temporary Workspace

```python
import tempfile
import os

def test_task_with_workspace():
    with tempfile.TemporaryDirectory() as tmpdir:
        # Run task with custom workspace
        task = SimpleTask(
            n=5,
            workspace_directory=tmpdir
        )
        result = test_run(task)

        assert result == 10

        # Verify output file was created
        output_files = os.listdir(tmpdir)
        assert len(output_files) > 0
```
