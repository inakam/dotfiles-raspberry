# gokart Design Review Checklist

This checklist provides systematic review points for gokart task implementations.

## Type Safety Review

### ✅ Generic Type Annotations

- [ ] All `TaskOnKart` classes have generic type annotation (`TaskOnKart[T]`)
- [ ] Generic type accurately reflects the dumped data type
- [ ] Complex types use proper type hints (`DataFrame[Schema]`, `List[int]`, `Dict[str, Any]`)

**Example:**
```python
# ✅ Good
class MyTask(gokart.TaskOnKart[DataFrame[UserSchema]]):
    ...

# ❌ Bad - Missing generic type
class MyTask(gokart.TaskOnKart):
    ...
```

### ✅ TaskInstanceParameter Type Annotations

- [ ] All `TaskInstanceParameter` have type annotations
- [ ] Type annotations match the expected task output type
- [ ] For DataFrames, Pandera schema is specified when available

**Example:**
```python
# ✅ Good
source: gokart.TaskOnKart[DataFrame[InputSchema]] = gokart.TaskInstanceParameter()

# ❌ Bad - Missing type annotation
source = gokart.TaskInstanceParameter()

# ❌ Bad - Using pd.DataFrame instead of Pandera
source: gokart.TaskOnKart[pd.DataFrame] = gokart.TaskInstanceParameter()
```

### ✅ Load Method Usage

- [ ] `self.load()` receives task instances, not string keys
- [ ] No usage of deprecated `load_data_frame()` method
- [ ] Load calls match the task instance parameters

**Example:**
```python
# ✅ Good
data = self.load(self.source_task)

# ❌ Bad - Using string key
data = self.load('source_task')

# ❌ Bad - Using deprecated method
df = self.load_data_frame()
```

## Task Structure Review

### ✅ Dependency Management

- [ ] Dependencies defined in `requires()` method
- [ ] Dependencies instantiated in `requires()` are defined as `@property` methods
- [ ] Property methods have proper return type annotations

**Example:**
```python
# ✅ Good
class MyTask(gokart.TaskOnKart[int]):
    date: str = luigi.Parameter()

    def requires(self):
        return self.data_task

    @property
    def data_task(self) -> DataTask:
        return DataTask(date=self.date)

    def run(self):
        data = self.load(self.data_task)
        ...

# ❌ Bad - Instantiation in requires() without property
class MyTask(gokart.TaskOnKart[int]):
    date: str = luigi.Parameter()

    def requires(self):
        task = DataTask(date=self.date)  # Loses type info
        return dict(data=task)

    def run(self):
        data = self.load('data')  # Not type-safe
        ...
```

### ✅ Parameter Definition

- [ ] All task parameters have type annotations
- [ ] Parameter defaults are appropriate
- [ ] Parameters use appropriate Luigi parameter types

**Example:**
```python
# ✅ Good
class MyTask(gokart.TaskOnKart[int]):
    threshold: int = luigi.IntParameter(default=10)
    mode: str = luigi.Parameter()
    enabled: bool = gokart.ExplicitBoolParameter(default=True)

# ❌ Bad - Missing type annotations
class MyTask(gokart.TaskOnKart[int]):
    threshold = luigi.IntParameter(default=10)
    mode = luigi.Parameter()
```

### ✅ Output Definition

- [ ] `run()` method calls `self.dump()` exactly once (or once per output key)
- [ ] Dumped data type matches the generic type annotation
- [ ] For multiple outputs, `output()` method is properly defined

**Example:**
```python
# ✅ Good - Single output
class MyTask(gokart.TaskOnKart[int]):
    def run(self):
        result = compute()
        self.dump(result)

# ✅ Good - Multiple outputs
class MyTask(gokart.TaskOnKart):
    def output(self):
        return {
            'model': self.make_target('model.pkl'),
            'metrics': self.make_target('metrics.pkl')
        }

    def run(self):
        model, metrics = train()
        self.dump(model, 'model')
        self.dump(metrics, 'metrics')

# ❌ Bad - Missing dump
class MyTask(gokart.TaskOnKart[int]):
    def run(self):
        result = compute()
        # Forgot to dump!
```

## Pandera Integration Review

### ✅ Schema Definition

- [ ] DataFrames have Pandera schema defined
- [ ] Schema uses proper type hints for columns
- [ ] Schema includes validation rules (constraints) where appropriate
- [ ] Schema naming follows convention (`*Schema`)

**Example:**
```python
# ✅ Good
class UserSchema(pa.DataFrameModel):
    user_id: Series[int] = pa.Field(gt=0)
    age: Series[int] = pa.Field(ge=0, le=150)
    email: Series[str]

# ❌ Bad - Using plain pd.DataFrame
def process_users(df: pd.DataFrame) -> pd.DataFrame:
    ...
```

### ✅ DataFrame Type Usage

- [ ] `DataFrame[Schema]` used instead of `pd.DataFrame` in type hints
- [ ] Task generic type specifies Pandera DataFrame type
- [ ] TaskInstanceParameter specifies Pandera DataFrame type

**Example:**
```python
# ✅ Good
class MyTask(gokart.TaskOnKart[DataFrame[OutputSchema]]):
    source: gokart.TaskOnKart[DataFrame[InputSchema]] = gokart.TaskInstanceParameter()

    def _process(self, df: DataFrame[InputSchema]) -> DataFrame[OutputSchema]:
        ...

# ❌ Bad
class MyTask(gokart.TaskOnKart[pd.DataFrame]):
    source: gokart.TaskOnKart[pd.DataFrame] = gokart.TaskInstanceParameter()

    def _process(self, df: pd.DataFrame) -> pd.DataFrame:
        ...
```

### ✅ Schema Validation

- [ ] Output DataFrames are wrapped with schema type
- [ ] Validation errors are handled appropriately
- [ ] Schema inheritance used when appropriate

**Example:**
```python
# ✅ Good
def run(self):
    df = self.load(self.source)
    processed = self._process(df)
    # Explicit validation
    self.dump(DataFrame[OutputSchema](processed))

# ❌ Bad - No validation
def run(self):
    df = self.load(self.source)
    processed = self._process(df)
    self.dump(processed)  # No schema validation
```

## Code Quality Review

### ✅ Method Organization

- [ ] Complex logic extracted to private methods
- [ ] Private methods have type hints
- [ ] `run()` method is concise and readable
- [ ] No business logic in `requires()` or `output()`

**Example:**
```python
# ✅ Good
class MyTask(gokart.TaskOnKart[DataFrame[OutputSchema]]):
    def run(self):
        data = self.load(self.source)
        cleaned = self._clean_data(data)
        transformed = self._transform(cleaned)
        self.dump(transformed)

    def _clean_data(self, df: DataFrame[InputSchema]) -> DataFrame[InputSchema]:
        ...

    def _transform(self, df: DataFrame[InputSchema]) -> DataFrame[OutputSchema]:
        ...

# ❌ Bad - All logic in run()
class MyTask(gokart.TaskOnKart[DataFrame[OutputSchema]]):
    def run(self):
        data = self.load(self.source)
        # 100 lines of complex logic here
        ...
        self.dump(result)
```

### ✅ Error Handling

- [ ] Input validation performed when necessary
- [ ] Meaningful error messages provided
- [ ] Edge cases handled (empty data, missing values, etc.)

**Example:**
```python
# ✅ Good
def run(self):
    data = self.load(self.source)

    if len(data) == 0:
        raise ValueError("Input data is empty")

    if not all(x >= 0 for x in data):
        raise ValueError("All values must be non-negative")

    result = process(data)
    self.dump(result)
```

### ✅ Documentation

- [ ] Class docstring describes task purpose
- [ ] Complex parameters documented
- [ ] Non-obvious logic has comments explaining WHY (not WHAT)

**Example:**
```python
# ✅ Good
class CalculateMetricsTask(gokart.TaskOnKart[DataFrame[MetricsSchema]]):
    """
    Calculate user engagement metrics from raw event data.

    This task aggregates daily events and computes engagement scores
    based on activity patterns.
    """

    lookback_days: int = luigi.IntParameter(default=7)
    """Number of days to look back for calculating metrics"""

    def run(self):
        events = self.load(self.events_task)

        # Filter to recent events to reduce memory usage
        recent = self._filter_recent_events(events)

        metrics = self._calculate_metrics(recent)
        self.dump(metrics)
```

## Common Anti-Patterns to Check

### ❌ String-based Loading

```python
# Check for this pattern
def run(self):
    data = self.load('task_name')  # ❌ Bad
```

### ❌ Missing Generic Types

```python
# Check for this pattern
class MyTask(gokart.TaskOnKart):  # ❌ Bad - missing [T]
    ...
```

### ❌ load_data_frame Usage

```python
# Check for this pattern
def run(self):
    df = self.load_data_frame()  # ❌ Bad - deprecated
```

### ❌ Untyped Parameters

```python
# Check for this pattern
class MyTask(gokart.TaskOnKart[int]):
    source = gokart.TaskInstanceParameter()  # ❌ Bad - no type
```

### ❌ Plain pd.DataFrame Instead of Pandera

```python
# Check for this pattern
class MyTask(gokart.TaskOnKart[pd.DataFrame]):  # ❌ Bad
    source: gokart.TaskOnKart[pd.DataFrame] = ...  # ❌ Bad
```

## Review Summary Template

Use this template to summarize review findings:

```markdown
## Review Summary

### Type Safety
- ✅ All tasks have generic type annotations
- ⚠️  3 TaskInstanceParameters missing type annotations
- ❌ Found usage of load('string_key') in TaskX

### Pandera Integration
- ✅ Schemas defined for all DataFrames
- ✅ DataFrame[Schema] used consistently
- ✅ Validation performed on outputs

### Code Quality
- ✅ Methods well-organized
- ✅ Error handling present
- ⚠️  Some complex logic could be extracted to private methods

### Action Items
1. Add type annotations to TaskInstanceParameters in TaskA, TaskB, TaskC
2. Replace load('string_key') with load(self.task_instance) in TaskX
3. Extract complex logic in TaskY.run() to private methods
```
