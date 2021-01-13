import std/sequtils
import std/algorithm
import std/strutils
import std/random

import testes

# access internal fields
include skiplists

randomize()

testes:

  ## convenience
  proc `==`[T](s: SkipList[T]; v: T): bool = s.value == v

  var a = 1.newSkipList
  check a == [1]

  block:
    ## simple comparisons
    template comparisons =
      check "comparisons":
        a < b
        a <= c
        c >= a
        b > a
        b >= a
        a <= b
        a != b
        a == c
        c == a

    let b = 2.newSkipList
    let c = 1.newSkipList
    comparisons()
    a.add 3
    comparisons()

  test "nils and stuff":
    var
      n: SkipList[int]
      m: SkipList[int]
    expect SkipListEmptyError:
      discard a != n
    expect SkipListEmptyError:
      discard n != a
    check n == m
    check n == []
    n.add 5
    check n == [5]

  test "finding things":
    var f: SkipList[int]
    var r: SkipList[int]
    for n in countDown(10, 0):
      f.add n
    for n in countUp(0, 10):
      check n in f
      if n < 10:
        check f.find(n).over.value == n + 1
    try:
      check f.find(11) == []
      check false, "expected an exception"
    except KeyError:
      discard
    check f.find(11, r) == false

  block:
    ## add()
    testes:
      ## adding stuff out of order
      var
        s = 5.newSkipList
      check s == [5], $s
      s.add 9
      checkList s
      check s == [5, 9], $s
      s.add 7
      checkList s
      check s == [5, 7, 9], $s
      s.add 3
      checkList s
      check s == [3, 5, 7, 9], $s
      s.add 11
      checkList s
      check s == [3, 5, 7, 9, 11], $s
      s.add 5
      checkList s
      check s == [3, 5, 5, 7, 9, 11], $s
      s.add 9
      checkList s
      check s == [3, 5, 5, 7, 9, 9, 11], $s
      s.add 3
      checkList s
      check s == [3, 3, 5, 5, 7, 9, 9, 11], $s
      s.add 11
      checkList s
      check s == [3, 3, 5, 5, 7, 9, 9, 11, 11], $s

  block:
    ## remove()
    testes:
      var
        s = [3, 3, 5, 5, 7, 9, 9, 11, 11].toSkipList
      checkList s
      ## remove mid-list
      check s.remove 9
      check s == [3, 3, 5, 5, 7, 9, 11, 11], $s
      check count(s) == 8
      checkList s
      ## remove tail-equal
      check s.remove 11
      check s == [3, 3, 5, 5, 7, 9, 11], $s
      check count(s) == 7
      checkList s
      ## remove tail
      check s.remove 11
      check s == [3, 3, 5, 5, 7, 9], $s
      check count(s) == 6
      checkList s
      ## remove head-equal
      check s.remove 3
      check s == [3, 5, 5, 7, 9], $s
      check count(s) == 5
      checkList s
      ## remove head
      check s.remove 3
      check s == [5, 5, 7, 9], $s
      check count(s) == 4
      checkList s
      ## missing removals
      check not s.remove(1)
      check not s.remove(6)
      check not s.remove(10)
      checkList s

  test "conversion":
    const q = @[1, 2, 4, 5, 6]
    ## conversion of seq to skiplist
    var s = q.toSkipList
    var mt {.used.} = toSkipList[int]()
    ## find the bottom
    s = s.bottom
    ## confirm the length
    check count(s) == len(q), $s
    ## confirm equality
    check s == q, $s
    ## match indices
    for i, n in pairs(q):
      check not s.isNil
      check s == n, "index $1 did not match $2" % [ $i, $n ]
      s = s.over

  block:
    ## constrain
    template assertConstrain[T](s: SkipList[T]; i: T; mode: set[cmp]) =
      var p, parent: SkipList[T]
      let c = constrain(s, newSkipList i, p, parent, mode)
      #echo count(p), " items ", mode, " for ", i
      if c in mode:
        #echo $p
        let r = sequtils.toSeq rank(p)
        check len(r) >= 1
        if Equal in mode:
          check r[0].value <= i
        else:
          check r[0].value < i
        if len(r) >= 2:
          check r[1].value >= i
          #echo i, " between ", r[0].value, " and ", r[1].value
        #else:
        #  echo i, " versus ", r[0].value
        let q = sequtils.toSeq items(p)
        check sorted(q) == q
        for n in items(q):
          if mode == {Less, Equal}:
            check n <= i, $n & " not <= " & $i
          elif mode == {Less}:
            check n < i, $n & " not < " & $i
          elif mode == {Equal}:
            check n == i, $n & " not == " & $i
          break

      else:
        check p.isNil

    var
      s: SkipList[int]
    const
      size = 100
    for i in 1 .. size:
      s.add rand(size)
      assertConstrain(s, i, {Less})
      assertConstrain(s, i, {Less, Equal})

  test "optimization":
    var
      s: SkipList[int]
    const
      sizes =
        when skiplistsChecks:
          [10, 100]
        else:
          [10, 100, 1_000, 10_000]
    for z in sizes:
      ## create a big list
      for i in 1 .. z:
        s.add rand(z)
      ## make sure it's the right size
      check count(s) == z, "length was " & $len(s)
      var l = toSeq s
      ## make sure toSeq makes sense
      check len(l) == z
      ## make sure it's sorted
      check sorted(l) == l
      shuffle l
      ## random removals
      while len(l) > 0:
        let old = $s
        s.remove pop(l)
        if z <= 1_000:
          check len(l) == count(s),
            "expected " & $len(l) & " found " & $count(s) & "\n" & old & "\n" & $s
      check count(s) == 0, $count(s) & " remain"
