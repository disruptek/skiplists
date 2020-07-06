import std/hashes
import std/random
import std/algorithm

when defined(nimdoc):
  import std/macros
  import std/strutils
  var
    exampleCounter {.compileTime.}: int

macro ex(x: untyped): untyped =
  result = x
  when defined(nimdoc):
    for node in x.last:
      if node.kind == nnkCall:
        if node[0].kind == nnkIdent:
          if $node[0] == "runnableExamples":
            inc exampleCounter
            let id = repr(x[0])
            hint "fig. $1 for $2:" % [ $exampleCounter, $id ]
            hint indent(repr(node[1]), 4) & "\n"

type
  SkipListError* = object of IndexError
  NilSkipListError* = object of ValueError

  SkipListObj[T] = object
    over: SkipList[T]
    down: SkipList[T]
    value: T
  SkipList*[T] = ref SkipListObj[T]

  SkipListPred*[T] = proc(up: SkipList[T];
                          here: SkipList[T];
                          child: SkipList[T]): bool

  cmp* {.pure.} = enum ## Comparisons between SkipLists
    Undefined
    Less
    Equal
    More

#
# TODO:
# faster p=.5 version
# slower version that counts search steps for p() solicitation
# version that knows your list index
# lengths, girths, etc.
#

converter toSeq[T](s: SkipList[T]): seq[T]

template staySorted(s: SkipList; body: untyped): untyped =
  try:
    body
  finally:
    when not defined(release):
      if not s.isNil:
        doAssert toSeq(s) == sorted(toSeq(s))

proc newSkipList*[T](v: T): SkipList[T] =
  ## Instantiate a SkipList from value `v`.
  result = SkipList[T](value: v)
  when false:
    for i in 2 .. initialSize:
      result = SkipList[T](value: v, down: result)

proc toSkipList*[T](values: var seq[T]): SkipList[T] =
  ## Instantiate a SkipList from values `values`.  Will sort the input.
  sort(values)
  if len(values) > 0:
    result = values[0].newSkipList
    var s = result
    for item in values[1..^1]:
      s.over = item.newSkipList
      s = s.over

proc toSkipList*[T](values: openArray[T]): SkipList[T] =
  ## Create a SkipList from an openArray `values`.
  for item in items(values):
    if result.isNil:
      result = newSkipList(item)
    else:
      add(result, item)

proc isEmpty*(s: SkipList): bool =
  ## True if SkipList `s` holds no items.
  result = true
  for full in items(s):
    result = false
    break

proc defaultPred(up: SkipList; here: SkipList; child: SkipList): bool =
  result = rand(1 .. 4) == 1

func `===`*(a, b: SkipList): bool =
  ## `true` if SkipLists `a` and `b` share the same memory, else `false`.
  result = cast[int](a) == cast[int](b)

template `=!=`*(a, b: SkipList): bool =
  ## `false` if SkipLists `a` and `b` share the same memory, else `true`.
  not(a === b)

template `<>`(a, b: SkipListObj): cmp =
  if a.value < b.value:
    Less
  elif a.value == b.value:
    Equal
  else:
    More

template `<>`(a, b: SkipList): cmp =
  ## Compare SkipList `a` and `b`.
  if a.isNil or b.isNil:
    if a.isNil and b.isNil:
      Equal
    else:
      Undefined
  elif a === b:
    Equal
  else:
    a[] <> b[]

proc `<`*(a, b: SkipList): bool =
  case a <> b
  of Less:
    result = true
  of Undefined:
    raise newException(NilSkipListError, "nil skiplist comparison")
  else:
    discard

proc `==`*(a, b: SkipList): bool =
  ## `true` if SkipList `a` is equal to SkipList `b`, else `false`.
  case a <> b
  of Equal:
    result = true
  of Undefined:
    raise newException(NilSkipListError, "nil skiplist comparison")
  else:
    discard

template iterIt(s: typed; body: untyped): untyped =
  if not s.isNil:
    var
      it {.inject.} = s
    while not it.down.isNil:
      it = it.down
    body
    while not it.over.isNil:
      it = it.over
      body

iterator mitems*[T](s: var SkipList[T]): var T {.ex.} =
  ## Iterate over mutable entries in SkipList `s`.
  runnableExamples:
    var s = "foo".newSkipList
    for item in mitems(s):
      item.add "bar"
    for item in items(s):
      assert item == "foobar"

  iterIt(s):
    yield it.value

iterator items*[T](s: SkipList[T]): T {.ex.} =
  ## Iterate over entries in SkipList `s`.
  runnableExamples:
    var s = 3.newSkipList
    for item in items(s):
      assert item == 3

  iterIt(s):
    yield it.value

iterator pairs*[T](s: SkipList[T]): tuple[index: int, value: T] {.ex.} =
  ## Iterate over entries in SkipList `s`.
  runnableExamples:
    var s = 3.newSkipList
    for index, value in pairs(s):
      assert index == 0
      assert value == 3

  var index = 0
  iterIt(s):
    yield (index: index, value: it.value)
    inc index

proc hash*(s: SkipList): Hash =
  var h: Hash = 0
  for item in items(s):
    h = h !& hash(item)
  result = !$h

proc find*[T](s: SkipList[T]; v: SkipList[T]; r: var SkipList[T]): bool =
  if not s.isNil:
    if v == s:
      result = true
    else:
      r = s
      while true:
        case v <> r.over
        of Undefined:
          if r.down.isNil:
            break
          else:
            r = r.down
        of More:
          r = r.over
        of Equal:
          r = r.over
          result = true
          break
        of Less:
          raise newException(SkipListError, "skiplist corrupt")

proc find*[T](s: SkipList[T]; v: T): SkipList[T] =
  if not find(s, v, result):
    raise newException(KeyError, "not found")

proc find*[T](s: SkipList[T]; v: T; r: var SkipList[T]): bool =
  let v = SkipList[T](value: v)
  result = find(s, v, r)
  when not defined(release):
    block found:
      for n in items(s):
        if n > v:
          assert not result
          break found
        elif n == v:
          assert result
          break found
      assert not result

proc count*(s: SkipList): int {.ex.} =
  ## Count the number of entries in SkipList `s`.
  runnableExamples:
    var s = 3.newSkipList
    assert count(s) == 1
    s.add 5
    assert count(s) == 2

  for item in items(s):
    inc result

converter toSeq[T](s: SkipList[T]): seq[T] =
  if not s.isNil:
    let
      size = count(s)
    result = newSeqOfCap[T](size)
    setLen(result, size)
    for index, item in pairs(s):
      result[index] = item

proc `==`*[T](s: SkipList[T]; q: openArray[T]): bool =
  block unequal:
    var i = 0
    for item in items(s):
      if i <= q.high:
        if item != q[i]:
          break unequal
      else:
        break unequal
      inc i
    result = i == q.len

proc `$`(s: SkipList): string =
  ## a string representing SkipList `s`
  result = $(toSeq(s))
  result[0] = '*'
  if not s.isNil:
    if not s.down.isNil:
      result.add " -> "
      result.add $s.down

proc contains*[T](s: SkipList[T]; v: SkipList[T]): bool =
  var n: SkipList[T]
  result = s.find(v, n)

proc contains*[T](s: SkipList[T]; v: T): bool {.ex.} =
  runnableExamples:
    var s = SkipList[int]
    assert 5 notin s
    s.add 5
    s.add 9
    assert 9 in s
    assert 5 in s

  let n = SkipList[T](value: v)
  result = n in s

proc append[T](s: var SkipList[T]; n: SkipList[T]; up: var SkipList[T];
               pred: SkipListPred[T] = defaultPred): bool =
  if s.isNil:
    raise newException(ValueError, "nil skiplist")
  else:
    assert n >= s
    if s.down.isNil:
      result = s != n # don't grow duplicates
      s.over = SkipList[T](over: s.over, value: n.value)
      assert s.over =!= s.over.over
    else:
      result = append(s.down, n, s, pred = pred)
    if result and s =!= up:
      if (unlikely) pred(up, s, n):
        up.over = SkipList[T](over: up.over, value: n.value, down: s.over)

proc insert[T](s: var SkipList[T]; n: SkipList[T]; up: var SkipList[T];
               pred: SkipListPred[T] = defaultPred) =
  staySorted(s):
    if s.isNil:
      raise newException(ValueError, "nil skiplist")
    else:
      assert n < s
      if s.down.isNil:
        s = SkipList[T](over: s, value: n.value)
      else:
        insert(s.down, n, s, pred = pred)
      if s =!= up:
        assert n <= up
        if n < up:
          # insertions always grow
          up = SkipList[T](over: up, value: n.value, down: s)

proc add*[T](s: var SkipList[T]; n: SkipList[T];
             pred: SkipListPred[T] = defaultPred) =
  ## insert a SkipList `n` into SkipList `s`
  staySorted(s):
    if s.isNil:
      s = n
    else:
      case s <> n
      of More:
        insert(s, n, s, pred = pred)
      of Equal:
        discard append(s, n, s, pred = pred)
      of Less:
        case s.over <> n
        of Undefined, More:
          discard append(s, n, s, pred = pred)
        else:
          add(s.over, n, pred = pred)
      of Undefined:
        raise newException(SkipListError, "skiplist corrupt")

proc add*[T](s: var SkipList[T]; v: T; pred: SkipListPred[T] = defaultPred) =
  ## insert a value `v` in SkipList `s`
  var n = SkipList[T](value: v)
  add(s, n, pred = pred)

when isMainModule:
  import std/unittest

  proc `<`[T](s: SkipList[T]; v: T): bool = s.value < v
  proc `==`[T](s: SkipList[T]; v: T): bool = s.value == v
  proc `<`[T](v: T; s: SkipList[T]): bool = v < s.value
  proc `==`[T](v: T; s: SkipList[T]): bool = v == s.value

  suite "skiplists":
    let a = 1.newSkipList

    test "simple comparisons":
      let b = 2.newSkipList
      let c = 1.newSkipList
      check:
        a == [1]
        a < b
        a <= c
        c >= a
        b > a
        b >= a
        a <= b
        a != b
        a == c

    test "nils and stuff":
      var
        n: SkipList[int]
        m: SkipList[int]
      expect NilSkipListError:
        discard a != n
      expect NilSkipListError:
        discard n != a
      check:
        n == m
        n == []
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
      expect KeyError:
        check f.find(11) == []
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
