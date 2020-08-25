import testes
import skiplists

testes:

  proc `<`[T](s: SkipList[T]; v: T): bool = s.value < v
  proc `==`[T](s: SkipList[T]; v: T): bool = s.value == v
  proc `<`[T](v: T; s: SkipList[T]): bool =
    when defined(gcDestructors):
      result = not s.isNil and v < s.value
    else:
      if s.isNil:
        raise newException(NilSkipListError, "nil skiplist comparison")
      v < s.value

  proc `==`[T](v: T; s: SkipList[T]): bool =
    when defined(gcDestructors):
      result = not s.isNil and v == s.value
    else:
      if s.isNil:
        raise newException(NilSkipListError, "nil skiplist comparison")
      result = v == s.value

  let a = 1.newSkipList

  test "simple comparisons":
    let b = 2.newSkipList
    let c = 1.newSkipList
    check a == [1]
    check a < b
    check a <= c
    check c >= a
    check b > a
    check b >= a
    check a <= b
    check a != b
    check a == c

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
    check f.find(8).over == 9
    check f.find(3).over == 4
    try:
      check f.find(11) == []
      assert false, "expected an exception"
    except KeyError:
      discard
    check f.find(11, r) == false

  test "adding stuff out of order":
    var
      s = 5.newSkipList
    check s == [5]
    s.add 9
    check s == [5, 9]
    s.add 7
    check s == [5, 7, 9]
    s.add 3
    check s == [3, 5, 7, 9]
    s.add 11
    check s == [3, 5, 7, 9, 11]
    s.add 5
    check s == [3, 5, 5, 7, 9, 11]
    s.add 9
    check s == [3, 5, 5, 7, 9, 9, 11]
    s.add 3
    check s == [3, 3, 5, 5, 7, 9, 9, 11]
    s.add 11
    check s == [3, 3, 5, 5, 7, 9, 9, 11, 11]

  test "sequence conversions":
    var
      s = @[1, 2, 4, 6, 5].toSkipList
    check count(s) == 5
    check s == [1, 2, 4, 5, 6]
