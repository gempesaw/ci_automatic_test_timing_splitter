# CiAutomaticTestTimingSplitter

> _It is a truth universally acknowledged, that a developer in
> possession of an overgrown test suite, must be in want of a cat._

CI Automatic TestTiming Splitter (`cats`) takes as input a directory of
JUnit XML test results, and can split/group the test files for you such that
your test suite can run in parallel as fast as possible.

`cats` has three operating modes:

- show you the timings and predicted outcomes for all parallel runs

- print out the test files you need to run on a certain index of
  machine, so that your CI knows which jobs to run where

- determine the optimal number of parallel test suites to run at once,
  based on the longest running test time

## Usage

The repo produces an elixir executable; you can run it anywhere you
have an erlang run time. Alternatively, we also publish a docker image
that you can run anywhere.

```
docker run -v ./junit-timings:/junit-timings gempesaw/cats -d /junit-timings
```

### options

There are three available flags:

- `-d` / `--timings-directory`: **required** the path to where your
  JUnit XML test result files are.
