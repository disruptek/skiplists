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
  assert a == [1]

  block:
    ## simple comparisons
    template comparisons =
      assert a < b
      assert a <= c
      assert c >= a
      assert b > a
      assert b >= a
      assert a <= b
      assert a != b
      assert a == c
      assert c == a

    let b = 2.newSkipList
    let c = 1.newSkipList
    comparisons()
    a.add 3
    comparisons()

  test "nils and stuff":
    var
      n: SkipList[int]
      m: SkipList[int]
    try:
      discard a != n
      assert false, "expected an exception"
    except EmptySkipListError:
      discard
    try:
      discard n != a
      assert false, "expected an exception"
    except EmptySkipListError:
      discard
    assert n == m
    assert n == []
    n.add 5
    assert n == [5]

  test "finding things":
    var f: SkipList[int]
    var r: SkipList[int]
    for n in countDown(10, 0):
      f.add n
    for n in countUp(0, 10):
      assert n in f
      if n < 10:
        assert f.find(n).over.value == n + 1
    try:
      assert f.find(11) == []
      assert false, "expected an exception"
    except KeyError:
      discard
    assert f.find(11, r) == false

  block:
    ## add()
    testes:
      ## adding stuff out of order
      var
        s = 5.newSkipList
      assert s == [5], $s
      s.add 9
      check s
      assert s == [5, 9], $s
      s.add 7
      check s
      assert s == [5, 7, 9], $s
      s.add 3
      check s
      assert s == [3, 5, 7, 9], $s
      s.add 11
      check s
      assert s == [3, 5, 7, 9, 11], $s
      s.add 5
      check s
      assert s == [3, 5, 5, 7, 9, 11], $s
      s.add 9
      check s
      assert s == [3, 5, 5, 7, 9, 9, 11], $s
      s.add 3
      check s
      assert s == [3, 3, 5, 5, 7, 9, 9, 11], $s
      s.add 11
      check s
      assert s == [3, 3, 5, 5, 7, 9, 9, 11, 11], $s

  block:
    ## remove()
    testes:
      var
        s = [3, 3, 5, 5, 7, 9, 9, 11, 11].toSkipList
      check s
      ## remove mid-list
      assert s.remove 9
      assert s == [3, 3, 5, 5, 7, 9, 11, 11], $s
      assert count(s) == 8
      check s
      ## remove tail-equal
      assert s.remove 11
      assert s == [3, 3, 5, 5, 7, 9, 11], $s
      assert count(s) == 7
      check s
      ## remove tail
      assert s.remove 11
      assert s == [3, 3, 5, 5, 7, 9], $s
      assert count(s) == 6
      check s
      ## remove head-equal
      assert s.remove 3
      assert s == [3, 5, 5, 7, 9], $s
      assert count(s) == 5
      check s
      ## remove head
      assert s.remove 3
      assert s == [5, 5, 7, 9], $s
      assert count(s) == 4
      check s
      ## missing removals
      assert not s.remove(1)
      assert not s.remove(6)
      assert not s.remove(10)
      check s

  test "conversion":
    const q = @[1, 2, 4, 5, 6]
    ## conversion of seq to skiplist
    var s = q.toSkipList
    var mt = toSkipList[int]()
    ## find the bottom
    s = s.bottom
    ## confirm the length
    assert count(s) == len(q), $s
    ## confirm equality
    assert s == q, $s
    ## match indices
    for i, n in pairs(q):
      assert not s.isNil
      assert s == n, "index $1 did not match $2" % [ $i, $n ]
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
        assert len(r) >= 1
        if Equal in mode:
          assert r[0].value <= i
        else:
          assert r[0].value < i
        if len(r) >= 2:
          assert r[1].value >= i
          #echo i, " between ", r[0].value, " and ", r[1].value
        #else:
        #  echo i, " versus ", r[0].value
        let q = sequtils.toSeq items(p)
        assert sorted(q) == q
        for n in items(q):
          if mode == {Less, Equal}:
            assert n <= i, $n & " not <= " & $i
          elif mode == {Less}:
            assert n < i, $n & " not < " & $i
          elif mode == {Equal}:
            assert n == i, $n & " not == " & $i
          break

      else:
        assert p.isNil

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
      assert count(s) == z, "length was " & $len(s)
      var l = toSeq s
      ## make sure toSeq makes sense
      assert len(l) == z
      ## make sure it's sorted
      assert sorted(l) == l
      shuffle l
      ## random removals
      while len(l) > 0:
        let old = $s
        s.remove pop(l)
        if z <= 1_000:
          assert len(l) == count(s),
            "expected " & $len(l) & " found " & $count(s) & "\n" & old & "\n" & $s
      assert count(s) == 0, $count(s) & " remain"
