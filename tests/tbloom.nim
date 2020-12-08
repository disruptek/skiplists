import std/random
import std/strformat

import testes
import bloom

testes:
  const
    k = 6
    n = 16384
    x = 10_000
    y = 100_000

  var filter: Bloom[k, n]
  var found: seq[string]
  var wrong, unfound: int

  randomize()

  while found.len != x:
    let q = $rand(y)
    if q notin found:
      filter.add q
      found.add q

  echo fmt"filter has {k} layers of {n} units; distribution:"
  echo filter
  echo fmt"filter size: {filter.sizeof} bytes"

  wrong = 0
  while unfound != x:
    let q = $rand(y)
    if q notin found:
      inc unfound
      if q in filter:
        inc wrong
  echo fmt"{wrong} false positives, or {100 * wrong / x:0.2f}%"

  wrong = 0
  while found.len > 0:
    let q = pop found
    if q notin filter:
      inc wrong
  echo fmt"{wrong} false negatives, or {100 * wrong / x:0.2f}%"

  assert wrong.float < 0.02 * x
