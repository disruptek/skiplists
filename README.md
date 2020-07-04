# skiplists

A _skip list_ is an ordered linked-list. Skip lists can be stacked such that a
shorter parent skip list can serve as an index into a larger child list.

- `cpp +/ nim-1.0` [![Build Status](https://travis-ci.org/disruptek/skiplists.svg?branch=master)](https://travis-ci.org/disruptek/skiplists)
- `arc +/ cpp +/ nim-1.3` [![Build Status](https://travis-ci.org/disruptek/skiplists.svg?branch=devel)](https://travis-ci.org/disruptek/skiplists)

## Benefits

Varying the ratio of parent to child length trades space for speed. This
trade-off can be made dynamically while the skip list is in use and it can vary
across different regions of the skip list or even individual values. Skip lists
are friendly to concurrent modification with minimal or localized locking.

For more details, [see the Wikipedia article on Skip Lists](https://en.wikipedia.org/wiki/Skip_list).

## Installation

```
$ git clone https://github.com/disruptek/skiplists
$ echo '--path="$config/skiplists"' >> nim.cfg
```

## Documentation

[See the documentation for the skiplists module as generated directly from the
source.](https://disruptek.github.io/skiplists/skiplists.html)

## Testing

There's a test and a benchmark under `tests/`; the benchmark requires
[criterion](https://disruptek.github.io/criterion).

## License
MIT
