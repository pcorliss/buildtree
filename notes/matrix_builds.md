# Matrix Builds

How do we do them?

```yaml
matrix:
  foo:
    FOO: 'bar'
    FOO: 'foo'
  animal:
    ANIMAL: 'dog'
    ANIMAL: 'cat'
    ANIMAL: 'cow'
  lights:
    LIGHTS: ON
    LIGHTS: OFF
```

Might produce 12 (2 * 3 * 2) combinations.
Each with a set of environment variables.

What about languages? Could we override those selections?

Maybe we'd write the above like so. Which would produce the same number
of combinations. but could be injected at the end or beginning of the
build process.

```yaml
matrix:
  env:
    FOO: foo
    FOO: bar
  env:
    ANIMAL: 'cat'
    ANIMAL: 'dog'
    ANIMAL: 'cow'
  cmd:
    - lights on
    - lights off
```

We'll need a mechanism to kick off builds in parralel
