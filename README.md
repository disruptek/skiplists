# skiplists

[![Test Matrix](https://github.com/disruptek/skiplists/workflows/CI/badge.svg)](https://github.com/disruptek/skiplists/actions?query=workflow%3ACI)
[![GitHub release (latest by date)](https://img.shields.io/github/v/release/disruptek/skiplists?style=flat)](https://github.com/disruptek/skiplists/releases/latest)
![Minimum supported Nim version](https://img.shields.io/badge/nim-1.0.8%2B-informational?style=flat&logo=nim)
[![License](https://img.shields.io/github/license/disruptek/skiplists?style=flat)](#license)
[![buy me a coffee](https://img.shields.io/badge/donate-buy%20me%20a%20coffee-orange.svg)](https://www.buymeacoffee.com/disruptek)

A _skip list_ is an ordered linked-list. Skip lists can be stacked such that
a shorter parent skip list can serve as an index into a larger child list. In
this implementation, such a stack is itself a skip list, as is each element.

## Benefits

Varying the ratio of parent to child length trades space for speed. This
trade-off can be made dynamically while the skip list is in use and it can vary
across different regions of the skip list or even individual values. Skip lists
are friendly to concurrent modification with minimal or localized locking.

For more details, [see the Wikipedia article on Skip Lists](https://en.wikipedia.org/wiki/Skip_list).

## Installation

```
$ git submodule add https://github.com/disruptek/skiplists
$ echo '--path="$config/skiplists/"' >> nim.cfg
```

## Documentation

[See the documentation for the skiplists module as generated directly from the
source.](https://disruptek.github.io/skiplists/skiplists.html)

## Testing

There's a test and a benchmark under `tests/`; the benchmark requires
[criterion](https://disruptek.github.io/criterion).

## License
MIT
