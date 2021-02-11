# CI Automatic TestTiming Splitter

> _It is a truth universally acknowledged, that a developer in
> possession of an overgrown test suite, must be in want of `cats`._

**C**I **A**utomatic **T**est Timing **S**plitter (`cats`) takes as input a directory of
JUnit XML test results, and will split/group the test files for you such that
your test suite can run in parallel as fast as possible.

`cats` can do three things of varying usefulness:

- show you the timings and predicted outcomes for all parallel runs

- print out the test files you need to run on a certain index of
  machine, so that your CI knows which jobs to run where

- determine the optimal number of parallel test suites to run at once,
  based on the single longest running test

Note that there are no tests, no error handling, no CLI help, no
documentation, and no graceful anything; use this at your own risk
:pinkieshrug:

## Usage

We publish a docker image that you can run anywhere you already
have docker:

```
docker run -v ./junit-timings:/junit-timings gempesaw/cats -d /junit-timings
```

The repo produces an elixir executable; you can run it anywhere you
have an erlang run time.

```
mix deps.get
mix escript.build
ci_automatic_test_timing_splitter -d /timings
```

### options

There are three available flags:

- `-d` / `--timings-directory`: **required** the path to where your
  JUnit XML test result files are.

- `-c` / `--machine-count`: _optional_ - the count of machines to
  split your tests amongst. if omitted, `cats` will figure out the
  optimal number for you based on the the single longest test running
  in its own machine

- `i` / `--machine-index`: _optional_ - specify an index and `cats`
  will print to `stdout` a list of the filenames that you should
  run. If omitted, `cats` will print out the entire splitting summary
  for your analysis.

### examples

#### cats, why are my tests so slow

```
cats -d ./junit-timings -c 10
```

Alternatively, leave the `-c 10` off and let `cats` decide the parallelism for you.

#### cats, how many jobs do I need

```
cats -d ./junit-timings
```

#### cats, just tell me what to do

So for example, if you have 3 machines to run your tests on, you could
do the following:

```
# on box 1
cats -d ./junit-timings -c 3 -i 0 | your-test-runner

# on box 2
cats -d ./junit-timings -c 3 -i 1 | your-test-runner

# on box 2
cats -d ./junit-timings -c 3 -i 2 | your-test-runner
```

## math ?

It turns out grouping CI test runtimes is a special case of [multiway
number
partitioning](https://en.wikipedia.org/wiki/Multiway_number_partitioning)
and [multiprocessor
scheduling](https://en.wikipedia.org/wiki/Multiprocessor_scheduling)?
We implemented the [greedy number
partitioning](https://en.wikipedia.org/wiki/Greedy_number_partitioning)
algorithm in basically the worst time and space possible O(m *n), but it's
still fast enough because our test suites aren't so big :D
