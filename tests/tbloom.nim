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
  var needle: int

  block:
    ## setup some random data
    count = 0
    randomize()
    while count < x:
      let q = rand(y)
      if q notin found:
        found.incl q
        inc count

  block:
    ## perform insertion on the filter
    for q in found:
      filter.add q

  block:
    ## save a needle
    while true:
      needle = rand(y)
      if needle notin filter:
        if needle notin found:
          break

  block stringification:
    report fmt"filter has {k} layers of {n} units; distribution:"
    report filter
    report fmt"filter size: {filter.sizeof} bytes"

  block:
    ## calculate false positives
    count = 0
    while unfound != x:
      let q = rand(y)
      if q notin found:
        inc unfound
        if q in filter:
          inc count
    report fmt"{count} false positives, or {100 * count / x:0.2f}%"
    check count.float < 0.02 * x

  block:
    ## calculate false negatives
    count = 0
    for q in found.items:
      if q notin filter:
        inc count
    report fmt"{count} false negatives, or {100 * count / x:0.2f}%"
    check count == 0

  block:
    ## check the speed against a relatively fast datastructure
    when defined(windows):
      skip "windows is slow and, apparently, buggy"
    let clock = cpuTime()
    check needle notin found
    let lap = cpuTime()
    check needle notin filter
    let done = cpuTime()
    var (a, b) = (done - lap, lap - clock)
    var fast = "bloom"
    if a > b:
      swap(a, b)
      fast = "intset"
    report fmt"{fast} was {100 * (a / b):0.2f}% faster"
