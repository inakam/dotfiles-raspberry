---
name: gokart
description: M3社が開発したPythonの機械学習パイプラインツールgokartに関する深い知識とベストプラクティスを提供する。Use when reviewing gokart task designs, implementing type-safe ML pipelines, writing gokart tests, or working with gokart and Pandera integration. Trigger when user mentions gokart, TaskOnKart, TaskInstanceParameter, Pandera DataFrames with gokart, or requests code review for ML pipeline tasks.
---

# gokart

## Overview

This skill provides comprehensive guidance for gokart, M3's machine learning pipeline library. It focuses on type-safe task design, Pandera integration, and testing best practices to enable effective design reviews and implementation.

## Core Principles

gokart development follows these principles:

1. **Type Safety First**: Always use generic type annotations (`TaskOnKart[T]`) and typed parameters
2. **Pandera for DataFrames**: Use `DataFrame[Schema]` instead of `pd.DataFrame` for better type safety
3. **Instance-based Loading**: Load with task instances (`self.load(self.task)`), not string keys
4. **Minimal Mocking in Tests**: Only mock external dependencies (APIs, databases)

## Quick Reference

### Type-Safe Task Pattern

```python
import gokart
import pandera.pandas as pa
from pandera.typing.pandas import DataFrame, Series

class InputSchema(pa.DataFrameModel):
    user_id: Series[int] = pa.Field(gt=0)
    score: Series[float]

class OutputSchema(InputSchema):
    grade: Series[str]

class ProcessTask(gokart.TaskOnKart[DataFrame[OutputSchema]]):
    source: gokart.TaskOnKart[DataFrame[InputSchema]] = gokart.TaskInstanceParameter()

    def requires(self):
        return self.source

    def run(self):
        df = self.load(self.source)  # Type-safe: DataFrame[InputSchema]
        result = self._add_grades(df)
        self.dump(result)

    def _add_grades(self, df: DataFrame[InputSchema]) -> DataFrame[OutputSchema]:
        return DataFrame[OutputSchema](
            df.assign(grade=lambda x: x['score'].apply(
                lambda s: 'A' if s >= 90 else 'B'
            ))
        )
```

### Testing Pattern

```python
from gokart.testing import test_run

class TestDataTask(gokart.TaskOnKart[DataFrame[InputSchema]]):
    def run(self):
        df = pd.DataFrame({'user_id': [1, 2], 'score': [95.0, 85.0]})
        self.dump(DataFrame[InputSchema](df))

def test_process_task():
    result = test_run(ProcessTask(source=TestDataTask()))
    assert len(result) == 2
    assert result['grade'].tolist() == ['A', 'B']
```

## Design Review Workflow

When reviewing gokart code:

1. **Check Type Safety**
   - All `TaskOnKart` have generic types
   - All `TaskInstanceParameter` have type annotations
   - Load methods use task instances, not strings

2. **Check Pandera Integration**
   - DataFrames use `DataFrame[Schema]`
   - Schemas defined with proper validation rules
   - Output validation performed

3. **Check Task Structure**
   - Dependencies use property methods when needed
   - `run()` method is concise
   - Error handling present

4. **Check Tests**
   - Tests use `test_run()` or `build()`
   - Minimal mocking (only external dependencies)
   - Test data inline, not in fixtures

See [review_checklist.md](references/review_checklist.md) for comprehensive checklist.

## Common Review Points

### ✅ Good Patterns

```python
# Type-safe with Pandera
class MyTask(gokart.TaskOnKart[DataFrame[OutputSchema]]):
    source: gokart.TaskOnKart[DataFrame[InputSchema]] = gokart.TaskInstanceParameter()

    def requires(self):
        return self.source

    def run(self):
        data = self.load(self.source)  # Type-safe
        self.dump(self._process(data))

    def _process(self, df: DataFrame[InputSchema]) -> DataFrame[OutputSchema]:
        ...
```

### ❌ Anti-Patterns to Avoid

```python
# Missing types
class MyTask(gokart.TaskOnKart):  # ❌ No generic type
    source = gokart.TaskInstanceParameter()  # ❌ No type annotation

    def requires(self):
        return dict(source=self.source)

    def run(self):
        data = self.load('source')  # ❌ String key, not instance
        df = self.load_data_frame()  # ❌ Deprecated method
        self.dump(data)
```

### Property-Based Dependencies

When instantiating tasks in `requires()`, use property methods:

```python
class MyTask(gokart.TaskOnKart[int]):
    date: str = luigi.Parameter()

    def requires(self):
        return self.data_task  # ✅ Use property

    def run(self):
        data = self.load(self.data_task)  # ✅ Type-safe
        self.dump(data * 2)

    @property
    def data_task(self) -> DataTask:
        return DataTask(date=self.date)
```

## Detailed Resources

For in-depth information, see these reference files:

### [best_practices.md](references/best_practices.md)
Comprehensive guide covering:
- Type safety guidelines
- Task design patterns
- Common anti-patterns
- Pandera integration patterns

**When to read**: Implementing new tasks, refactoring existing code, or need detailed pattern examples.

### [testing.md](references/testing.md)
Testing guidelines covering:
- Testing philosophy (minimal mocking)
- Basic task testing
- Testing with dependencies
- Testing with Pandera
- Common testing patterns

**When to read**: Writing tests for gokart tasks, setting up test infrastructure, or debugging test issues.

### [review_checklist.md](references/review_checklist.md)
Systematic checklist for design reviews covering:
- Type safety review points
- Task structure review
- Pandera integration review
- Code quality review
- Common anti-patterns

**When to read**: Conducting code reviews, self-reviewing before PR, or need structured review guidance.

## Key Review Questions

Use these questions to guide reviews:

1. **Type Safety**
   - Does every `TaskOnKart` have a generic type?
   - Are all `TaskInstanceParameter` type-annotated?
   - Is `self.load()` called with task instances?

2. **Pandera**
   - Are DataFrames typed as `DataFrame[Schema]`?
   - Are schemas defined with validation rules?
   - Is output validation performed?

3. **Structure**
   - Are dependencies clear and well-organized?
   - Is complex logic extracted to methods?
   - Are property methods used for dynamic dependencies?

4. **Tests**
   - Do tests use `test_run()` or `build()`?
   - Is mocking minimized?
   - Is test data inline with assertions?

## Example Review Comment

When reviewing code, provide structured feedback:

```markdown
## Type Safety Issues

1. ❌ `TaskA` missing generic type annotation
   - Change `class TaskA(gokart.TaskOnKart):`
   - To `class TaskA(gokart.TaskOnKart[DataFrame[OutputSchema]]):`

2. ❌ String-based loading in `TaskB.run()`
   - Change `data = self.load('source')`
   - To `data = self.load(self.source)`

3. ✅ Good use of Pandera schemas in `TaskC`

## Suggestions

- Consider extracting the complex transformation logic in `TaskA.run()`
  to a private `_transform()` method
- Add validation for empty DataFrames in `TaskB`
```
