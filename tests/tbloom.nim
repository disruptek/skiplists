import std/random
import std/strformat
import std/intsets
import std/times

import testes
import bloom

testes:
  ## bloom filter test parameters:
  const
    k = 20            ## layer count
    n = 65535         ## layer size
    x = 100_000       ## random entries
    y = 100_000_000   ## highest integer
  var filter: Bloom[k, n]
  var found = initIntSet()
  var count, unfound: int

  randomize()

  ## setup some random data
  count = 0
  while count < x:
    let q = rand(y)
    if q notin found:
      found.incl q
      inc count

  ## perform insertion on the filter
  for q in found:
    filter.add q

  ## save a needle
  var needle: int
  while true:
    needle = rand(y)
    if needle notin found:
      break

  echo fmt"filter has {k} layers of {n} units; distribution:"
  echo filter
  echo fmt"filter size: {filter.sizeof} bytes"

  ## calculate false positives
  count = 0
  while unfound != x:
    let q = rand(y)
    if q notin found:
      inc unfound
      if q in filter:
        inc count
  echo fmt"{count} false positives, or {100 * count / x:0.2f}%"
  assert count.float < 0.02 * x, "too many false positives"

  ## calculate false negatives
  count = 0
  for q in found.items:
    if q notin filter:
      inc count
  echo fmt"{count} false negatives, or {100 * count / x:0.2f}%"
  assert count == 0, "unexpected false negative"

  ## check the speed against a relatively fast datastructure
  let clock = cpuTime()
  if needle in found:
    quit 1
  let lap = cpuTime()
  if needle in filter:
    quit 1
  let done = cpuTime()
  echo fmt"bloom was {100 * ((done - lap) / (lap - clock)):0.2f}% faster"
