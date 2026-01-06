# gokart Best Practices

## Table of Contents
- Type Safety Guidelines
- Task Design Patterns
- Common Anti-Patterns
- Pandera Integration

## Type Safety Guidelines

### Always Specify Generic Types

**Good:**
```python
class DataTask(gokart.TaskOnKart[pd.DataFrame]):
    def run(self):
        df = pd.DataFrame({'a': [1, 2, 3]})
        self.dump(df)

class ProcessTask(gokart.TaskOnKart[int]):
    source: gokart.TaskOnKart[pd.DataFrame] = gokart.TaskInstanceParameter()

    def requires(self):
        return self.source

    def run(self):
        df = self.load(self.source)  # Type-safe: mypy knows this is pd.DataFrame
        result = len(df)
        self.dump(result)
```

**Bad:**
```python
# Missing generic type
class DataTask(gokart.TaskOnKart):
    def run(self):
        df = pd.DataFrame({'a': [1, 2, 3]})
        self.dump(df)

# No type safety
class ProcessTask(gokart.TaskOnKart):
    source = gokart.TaskInstanceParameter()

    def run(self):
        df = self.load(self.source)  # mypy doesn't know the type
        result = len(df)
        self.dump(result)
```

### Use TaskInstanceParameter with Type Annotations

**Good:**
```python
class AddTask(gokart.TaskOnKart[int]):
    a: gokart.TaskOnKart[int] = gokart.TaskInstanceParameter()
    b: gokart.TaskOnKart[int] = gokart.TaskInstanceParameter()

    def requires(self):
        return dict(a=self.a, b=self.b)

    def run(self):
        # Type-safe loading
        a = self.load(self.a)  # mypy knows this is int
        b = self.load(self.b)  # mypy knows this is int
        self.dump(a + b)
```

**Bad:**
```python
class AddTask(gokart.TaskOnKart[int]):
    a = gokart.TaskInstanceParameter()
    b = gokart.TaskInstanceParameter()

    def requires(self):
        return dict(a=self.a, b=self.b)

    def run(self):
        # Not type-safe - using string keys
        a = self.load('a')  # mypy doesn't know the type
        b = self.load('b')  # mypy doesn't know the type
        self.dump(a + b)
```

### Load with Task Instances, Not String Keys

**Good:**
```python
class MyTask(gokart.TaskOnKart[str]):
    input_task: gokart.TaskOnKart[int] = gokart.TaskInstanceParameter()

    def requires(self):
        return self.input_task

    def run(self):
        # Pass task instance to load
        value = self.load(self.input_task)  # Type-safe
        self.dump(f"Value: {value}")
```

**Bad:**
```python
class MyTask(gokart.TaskOnKart[str]):
    input_task: gokart.TaskOnKart[int] = gokart.TaskInstanceParameter()

    def requires(self):
        return dict(input=self.input_task)

    def run(self):
        # Using string key - loses type information
        value = self.load('input')  # Not type-safe
        self.dump(f"Value: {value}")
```

## Task Design Patterns

### Use Property Methods for Dynamic Dependencies

When you need to instantiate tasks in `requires()`, define them as properties to maintain type safety.

**Good:**
```python
class TaskA(gokart.TaskOnKart[int]):
    date: str = luigi.Parameter()

    def requires(self):
        return dict(b=self.b)

    def run(self):
        data = self.load(self.b)  # Type-safe
        self.dump(data * 2)

    @property
    def b(self) -> TaskB:
        return TaskB(date=self.date)
```

**Bad:**
```python
class TaskA(gokart.TaskOnKart[int]):
    date: str = luigi.Parameter()

    def requires(self):
        # Instantiating here loses type information
        b = TaskB(date=self.date)
        return dict(b=b)

    def run(self):
        data = self.load('b')  # Not type-safe
        self.dump(data * 2)
```

### Multiple Dependencies with Property Methods

```python
class ComplexTask(gokart.TaskOnKart[dict]):
    date: str = luigi.Parameter()
    mode: str = luigi.Parameter()

    def requires(self):
        return dict(
            data=self.data_task,
            model=self.model_task,
            config=self.config_task
        )

    def run(self):
        data = self.load(self.data_task)
        model = self.load(self.model_task)
        config = self.load(self.config_task)

        result = process(data, model, config)
        self.dump(result)

    @property
    def data_task(self) -> DataTask:
        return DataTask(date=self.date)

    @property
    def model_task(self) -> ModelTask:
        return ModelTask(mode=self.mode)

    @property
    def config_task(self) -> ConfigTask:
        return ConfigTask()
```

### List Dependencies with Type Safety

```python
from typing import List

class AggregateTask(gokart.TaskOnKart[int]):
    n: int = luigi.IntParameter(default=3)

    def requires(self) -> List[DataTask]:
        return [self._make_task(i) for i in range(self.n)]

    def run(self):
        # Even with list, use task instances if possible
        results = [self.load(task) for task in self.requires()]
        total = sum(results)
        self.dump(total)

    def _make_task(self, i: int) -> DataTask:
        return DataTask(index=i)
```

## Common Anti-Patterns

### ❌ DO NOT use load_data_frame()

`load_data_frame()` is deprecated and should not be used.

**Bad:**
```python
class OldStyleTask(gokart.TaskOnKart):
    def requires(self):
        return DataFrameTask()

    def run(self):
        # DEPRECATED - Do not use
        df = self.load_data_frame()
        ...
```

**Good:**
```python
class ModernTask(gokart.TaskOnKart[pd.DataFrame]):
    source: gokart.TaskOnKart[pd.DataFrame] = gokart.TaskInstanceParameter()

    def requires(self):
        return self.source

    def run(self):
        df = self.load(self.source)
        ...
```

### ❌ DO NOT omit Generic types

**Bad:**
```python
class VagueTask(gokart.TaskOnKart):  # Missing type
    def run(self):
        self.dump(42)
```

**Good:**
```python
class ClearTask(gokart.TaskOnKart[int]):
    def run(self):
        self.dump(42)
```

### ❌ DO NOT use string keys for loading

**Bad:**
```python
class StringKeyTask(gokart.TaskOnKart[int]):
    def requires(self):
        return dict(a=TaskA(), b=TaskB())

    def run(self):
        a = self.load('a')  # Loses type information
        b = self.load('b')
        self.dump(a + b)
```

**Good:**
```python
class TaskInstanceTask(gokart.TaskOnKart[int]):
    a: gokart.TaskOnKart[int] = gokart.TaskInstanceParameter()
    b: gokart.TaskOnKart[int] = gokart.TaskInstanceParameter()

    def requires(self):
        return dict(a=self.a, b=self.b)

    def run(self):
        a = self.load(self.a)  # Type-safe
        b = self.load(self.b)
        self.dump(a + b)
```

## Pandera Integration

### Basic Pandera Usage with gokart

Use Pandera's `DataFrame` type instead of plain `pd.DataFrame` for better type safety and validation.

**Good:**
```python
import pandera.pandas as pa
from pandera.typing.pandas import DataFrame, Series

class InputSchema(pa.DataFrameModel):
    user_id: Series[int] = pa.Field(gt=0)
    age: Series[int] = pa.Field(ge=0, le=150)
    score: Series[float]

class OutputSchema(pa.DataFrameModel):
    user_id: Series[int]
    age: Series[int]
    score: Series[float]
    category: Series[str]

class DataTask(gokart.TaskOnKart[DataFrame[InputSchema]]):
    def run(self):
        df = pd.DataFrame({
            'user_id': [1, 2, 3],
            'age': [25, 30, 35],
            'score': [85.5, 90.0, 95.5]
        })
        self.dump(DataFrame[InputSchema](df))

class ProcessTask(gokart.TaskOnKart[DataFrame[OutputSchema]]):
    source: gokart.TaskOnKart[DataFrame[InputSchema]] = gokart.TaskInstanceParameter()

    def requires(self):
        return self.source

    def run(self):
        df = self.load(self.source)  # Type is DataFrame[InputSchema]
        result = self._process(df)
        self.dump(result)

    def _process(self, df: DataFrame[InputSchema]) -> DataFrame[OutputSchema]:
        return DataFrame[OutputSchema](
            df.assign(category=lambda x: x['age'].apply(
                lambda age: 'young' if age < 30 else 'senior'
            ))
        )
```

**Bad:**
```python
class DataTask(gokart.TaskOnKart[pd.DataFrame]):  # Loses schema information
    def run(self):
        df = pd.DataFrame({
            'user_id': [1, 2, 3],
            'age': [25, 30, 35],
            'score': [85.5, 90.0, 95.5]
        })
        self.dump(df)

class ProcessTask(gokart.TaskOnKart[pd.DataFrame]):
    source: gokart.TaskOnKart[pd.DataFrame] = gokart.TaskInstanceParameter()

    def requires(self):
        return self.source

    def run(self):
        df = self.load(self.source)  # Unknown schema
        # No type hints about what columns exist
        result = df.assign(category=lambda x: x['age'].apply(
            lambda age: 'young' if age < 30 else 'senior'
        ))
        self.dump(result)
```

### Pandera Validation

```python
class ValidatedTask(gokart.TaskOnKart[DataFrame[OutputSchema]]):
    source: gokart.TaskOnKart[DataFrame[InputSchema]] = gokart.TaskInstanceParameter()

    def requires(self):
        return self.source

    def run(self):
        df = self.load(self.source)

        # Pandera automatically validates on assignment
        try:
            result = DataFrame[OutputSchema](
                df.assign(category='default')
            )
        except pa.errors.SchemaError as exc:
            # Handle validation errors
            print(f"Validation failed: {exc}")
            raise

        self.dump(result)
```

### Complex Schema Inheritance

```python
class BaseSchema(pa.DataFrameModel):
    id: Series[int] = pa.Field(gt=0)
    created_at: Series[str]

class UserSchema(BaseSchema):
    name: Series[str]
    email: Series[str]

class UserWithScoreSchema(UserSchema):
    score: Series[float] = pa.Field(ge=0, le=100)

class FetchUserTask(gokart.TaskOnKart[DataFrame[UserSchema]]):
    def run(self):
        # Fetch user data
        df = fetch_users()
        self.dump(DataFrame[UserSchema](df))

class ScoreUserTask(gokart.TaskOnKart[DataFrame[UserWithScoreSchema]]):
    users: gokart.TaskOnKart[DataFrame[UserSchema]] = gokart.TaskInstanceParameter()

    def requires(self):
        return self.users

    def run(self):
        users = self.load(self.users)
        scored = users.assign(score=calculate_scores(users))
        self.dump(DataFrame[UserWithScoreSchema](scored))
```

### TaskInstanceParameter Best Practice with Pandera

**Very Readable:**
```python
from pandera.typing import DataFrame

class MyTask(gokart.TaskOnKart[DataFrame[OutputSchema]]):
    # Clear what schema is expected
    input_a: gokart.TaskOnKart[DataFrame[SchemaA]] = gokart.TaskInstanceParameter()
    input_b: gokart.TaskOnKart[DataFrame[SchemaB]] = gokart.TaskInstanceParameter()

    def requires(self):
        return dict(a=self.input_a, b=self.input_b)

    def run(self):
        a = self.load(self.input_a)  # DataFrame[SchemaA]
        b = self.load(self.input_b)  # DataFrame[SchemaB]
        result = merge_data(a, b)
        self.dump(result)
```

**Less Readable:**
```python
class MyTask(gokart.TaskOnKart[pd.DataFrame]):
    # Not clear what structure is expected
    input_a: gokart.TaskOnKart[pd.DataFrame] = gokart.TaskInstanceParameter()
    input_b: gokart.TaskOnKart[pd.DataFrame] = gokart.TaskInstanceParameter()

    def requires(self):
        return dict(a=self.input_a, b=self.input_b)

    def run(self):
        a = self.load(self.input_a)  # pd.DataFrame (unknown schema)
        b = self.load(self.input_b)  # pd.DataFrame (unknown schema)
        result = merge_data(a, b)
        self.dump(result)
```
