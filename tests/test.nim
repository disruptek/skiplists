import std/strutils
import std/random

import testes

# access internal fields
include skiplists

testes:

  ## convenience
  proc `==`[T](s: SkipList[T]; v: T): bool = s.value == v
  block:
    ## ignore this
    proc `<`[T](s: SkipList[T]; v: T): bool = s.value < v
    proc `<`[T](v: T; s: SkipList[T]): bool =
      when defined(gcDestructors):
        result = not s.isNil and v < s.value
      else:
        if s.isNil:
          raise newException(NilSkipListError, "nil skiplist comparison")
        else:
          v < s.value

    proc `==`[T](v: T; s: SkipList[T]): bool =
      when defined(gcDestructors):
        result = not s.isNil and v == s.value
      else:
        if s.isNil:
          raise newException(NilSkipListError, "nil skiplist comparison")
        else:
          result = v == s.value

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
    except NilSkipListError:
      discard
    try:
      discard n != a
      assert false, "expected an exception"
    except NilSkipListError:
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
    ## adding stuff out of order
    var
      s = 5.newSkipList
    assert s == [5], $s
    s.add 9
    assert s == [5, 9], $s
    s.add 7
    assert s == [5, 7, 9], $s
    s.add 3
    assert s == [3, 5, 7, 9], $s
    s.add 11
    assert s == [3, 5, 7, 9, 11], $s
    s.add 5
    assert s == [3, 5, 5, 7, 9, 11], $s
    s.add 9
    assert s == [3, 5, 5, 7, 9, 9, 11], $s
    s.add 3
    assert s == [3, 3, 5, 5, 7, 9, 9, 11], $s
    s.add 11
    assert s == [3, 3, 5, 5, 7, 9, 9, 11, 11], $s

  test "conversion":
    const q = @[1, 2, 4, 5, 6]
    ## conversion of seq to skiplist
    var s = q.toSkipList
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

  test "optimization":
    ## create a big list
    var
      s: SkipList[int]
    const
      size = 100_000
    randomize()
    for i in 1 .. size:
      s.add rand(size)
    ## make sure it's the right size
    s = s.bottom
    assert count(s) == size, "length was " & $len(s)
