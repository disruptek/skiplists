import std/strutils
import std/intsets
import std/sequtils

import criterion
import skiplists

when not defined(danger):
  {.fatal: "useless outside of -d:danger, right?".}

var cfg = newDefaultConfig()

benchmark cfg:

  var
    rick = toSeq(0 .. 100_000)

  var q = toSkipList(rick)

  var x = initIntSet()
  for i in rick:
    incl(x, i)

  proc make_intset() {.measure.} =
    var s = initIntSet()
    for i in rick:
      incl(s, i)

  proc make_skiplist_seq() {.measure.} =
    var s {.used.} = toSkipList(rick)

  when false:
    proc make_skiplist_naive() {.measure.} =
      var s: SkipList[int]
      for i in rick:
        add(s, i)

  proc contains_intset() {.measure.} =
    for i in rick:
      discard i in x

  proc contains_skiplist() {.measure.} =
    for i in rick:
      discard i in q
