import std/sequtils
import std/hashes
import std/random
import std/algorithm

const
  skiplistsCheckOrder {.booldefine.} = true
  skiplistsGrowth {.intdefine.} = 4

when defined(nimdoc):
  import std/macros
  import std/strutils
  var
    exampleCounter {.compileTime.}: int

macro ex(x: untyped) =
  ## make an example out of this punk proc
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

when (NimMajor, NimMinor) <= (1, 2):
  type SkipListError* = object of IndexError
else:
  type SkipListError* = object of IndexDefect

type
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

template staySorted(s: SkipList; body: typed) =
  when skiplistsCheckOrder and not defined(release):
    try:
      body
    finally:
      when not defined(release):
        if not s.isNil:
          assert toSeq(s) == sorted(toSeq s)
  else:
    body

proc height*(s: SkipList): int =
  if not s.isNil:
    var s = s
    while not s.down.isNil:
      assert s.down.value == s.value,
        "s.down is " & $s.down.value & " while s is " & $s.value
      inc result
      s = s.down

proc bottom*(s: SkipList): SkipList =
  if not s.isNil:
    result = s
    while not result.down.isNil:
      assert result.down.value == result.value
      result = result.down

proc newSkipList*[T](v: T): SkipList[T] =
  ## Instantiate a SkipList from value `v`.
  result = SkipList[T](value: v)

proc isEmpty*(s: SkipList): bool =
  ## True if SkipList `s` holds no items.
  result = true
  for full in items(s):
    result = false
    break

proc defaultPred(up: SkipList; here: SkipList; child: SkipList): bool =
  result = rand(1 .. skiplistsGrowth) == 1

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
  ## `true` if SkipList `a` is less than SkipList `b`, else `false`.
  case a <> b
  of Less:
    result = true
  of Undefined:
    raise newException(NilSkipListError, "nil skiplist comparison")
  else:
    result = false

proc `==`*(a, b: SkipList): bool =
  ## `true` if SkipList `a` is equal to SkipList `b`, else `false`.
  case a <> b
  of Equal:
    result = true
  of Undefined:
    raise newException(NilSkipListError, "nil skiplist comparison")
  else:
    result = false

template `<=`*(a, b: SkipList): bool =
  ## `true` if SkipList `a` is less or equal to SkipList `b`, else `false`.
  a < b or a == b

template iterIt(s: typed; body: untyped) =
  if not s.isNil:
    var
      it {.inject.} = s
    while not it.down.isNil:
      assert it.value == it.down.value,
             $it.value & " versus " & $it.down.value
      it = it.down
    body
    while not it.over.isNil:
      assert it.value <= it.over.value,
             $it.value & " versus " & $it.over.value
      it = it.over
      body

iterator mitems*[T](s: var SkipList[T]): var T {.ex.} =
  ## Iterate over mutable entries in SkipList `s`.
  runnableExamples:
    var s = newSkipList"foo"
    for item in mitems(s):
      item.add "bar"
    for item in items(s):
      assert item == "foobar"

  iterIt(s):
    yield it.value

iterator values[T](s: SkipList[T]): T =
  ## Yield each peer value of SkipList `s`.
  var s = s
  while not s.isNil:
    yield s.value
    s = s.over

iterator items*[T](s: SkipList[T]): T {.ex.} =
  ## Iterate over entries in SkipList `s`.
  runnableExamples:
    var s = newSkipList 3
    for item in items(s):
      assert item == 3

  iterIt(s):
    yield it.value

iterator pairs*[T](s: SkipList[T]): tuple[index: int, value: T] {.ex.} =
  ## Iterate over entries in SkipList `s`.
  runnableExamples:
    var s = newSkipList 3
    for index, value in pairs(s):
      assert index == 0
      assert value == 3

  var index = 0
  iterIt(s):
    yield (index: index, value: it.value)
    inc index

proc `==`*[T](s: SkipList[T]; q: openArray[T]): bool =
  ## `true` if SkipList `s` holds the same values as openArray `q`.
  block unequal:
    var i = 0
    for item in items(s):
      if i <= high(q):
        if item != q[i]:
          break unequal
      else:
        break unequal
      inc i
    result = i == len(q)

proc hash*(s: SkipList): Hash =
  ## The `Hash` of SkipList `s` is a function of all its values.
  var h: Hash = 0
  for item in items(s):
    h = h !& hash(item)
  result = !$h

proc find*[T](s: SkipList[T]; v: SkipList[T]; r: var SkipList[T]): bool =
  if not s.isNil:
    r = s
    if v == s:
      result = true
    else:
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
  if not find(s, SkipList[T](value: v), result):
    raise newException(KeyError, "not found")

proc find*[T](s: SkipList[T]; v: T; r: var SkipList[T]): bool =
  result = find(s, SkipList[T](value: v), r)

proc count*(s: SkipList): int {.ex.} =
  ## Count the number of entries in SkipList `s`.
  runnableExamples:
    var s: SkipList[int]
    assert count(s) == 0
    s.add 3
    assert count(s) == 1
    s.add 5
    assert count(s) == 2

  if not s.isNil:
    inc result
    var s = s
    while not s.down.isNil:
      s = s.down
    while not s.over.isNil:
      inc result
      s = s.over

converter toSeq[T](s: SkipList[T]): seq[T] =
  ## Convert SkipList `s` into a sequence.
  if not s.isNil:
    let
      size = count(s)
    result = newSeqOfCap[T](size)
    when true:
      setLen(result, size)
      for index, item in pairs(s):
        result[index] = item
    else:
      when defined(gcDestructors):
        for item in items(s):
          assert len(result) <= size
          add(result, item)
      else:
        setLen(result, size)
        for index, item in pairs(s):
          result[index] = item

proc `$`(s: SkipList): string {.raises: [].} =
  ## A string representing SkipList `s`; intentionally not exported.
  if s.isNil:
    result = "*[]"
  else:
    var q = sequtils.toSeq s.values
    when skiplistsCheckOrder:
      assert sorted(q) == q, $q
    result = $q
    result[0] = '*'
    if not s.down.isNil:
      result.add " -> "
      result.add $s.down

proc contains*[T](s: SkipList[T]; v: SkipList[T]): bool =
  ## `true` if the SkipList `s` contains SkipList `v`.
  var n: SkipList[T]
  result = s.find(v, n)

proc contains*[T](s: SkipList[T]; v: T): bool {.ex.} =
  ## `true` if the SkipList `s` contains value `v`.
  runnableExamples:
    var s: SkipList[int]
    assert 5 notin s
    s.add 5
    s.add 9
    assert 9 in s
    assert 5 in s

  let n = SkipList[T](value: v)
  result = n in s

proc append[T](s: var SkipList[T]; v: T; down: SkipList[T] = nil)
  {.inline.} =
  assert not s.isNil
  s.over = SkipList[T](over: s.over, value: v, down: down)

proc insert[T](s: var SkipList[T]; v: T;
               down: SkipList[T] = nil): SkipList[T]
  {.inline.} =
  assert not s.isNil
  result = SkipList[T](over: s, value: v, down: down)

proc append[T](s: var SkipList[T]; n: SkipList[T]; up: var SkipList[T];
               pred: SkipListPred[T] = defaultPred): bool =
  ## Add SkipList `n` into SkipList `s`; returns `true` in the event
  ## that growth is requested by the layer below.
  ##
  ## :s: The source SkipList
  ## :n: The SkipList to append
  ## :up: The SkipList above us; equal to `s` at the top layer.
  ## :pred: The predicate to use for growth.
  assert not n.isNil
  if s.isNil:
    raise newException(ValueError, "nil skiplist")
  else:
    assert s <= n
    var p = s
    # move over to the correct file
    while p.over <> n in {Less, Equal}:
      p = p.over
    if p.down.isNil:
      # consider growing only if this isn't a duplicate value
      result = p != n
      # new object for atomicity
      append(p, n.value)
    else:
      # recurse to the layer below, passing ourselves as "up"
      # here we establish a difference between top-level and lower-level
      result = append(p.down, n, p, pred = pred)

    # result is true if we should consider growing
    # similarly, if the pred fails, don't grow
    result = result and pred(up, p, n)
    # if we are the top level, don't grow
    if result and s =!= up:
      # grow by inserting an over value in our parent
      append(up, n.value, p.over)

proc insert[T](s: var SkipList[T]; n: SkipList[T]; up: var SkipList[T];
               pred: SkipListPred[T] = defaultPred): SkipList[T] =
  ## Prepend SkipList `n` to SkipList `s`; returns new SkipList.
  ##
  ## :s: The source SkipList
  ## :n: The SkipList to prepend
  ## :up: The SkipList above us; equal to `s` at the top layer.
  ## :pred: The predicate to use for growth. (unused)
  staySorted(s):
    if s.isNil:
      raise newException(ValueError, "nil skiplist")
    else:
      assert n < s
      if s.down.isNil:
        result = insert(s, n.value)
      else:
        result = insert(s, n.value, insert(s.down, n, s, pred = pred))

proc add*[T](s: var SkipList[T]; n: SkipList[T];
             pred: SkipListPred[T] = defaultPred) =
  ## Add SkipList `n` into SkipList `s`.
  staySorted(s):
    if s.isNil:
      s = n
    else:
      case s <> n
      of More:
        s = insert(s, n, s, pred = pred)
      of Equal:
        # don't do any growth for dupes
        # XXX: possible optimization point here
        discard append(s, n, s, pred = pred):
      of Less:
        var p = s
        # move over to the correct file
        while p.over <> n in {Less, Equal}:
          p = p.over
        if append(p, n, p, pred = pred):
          if pred(s, p, n):
            if p == s:
              # create a new layer with just one node
              s = SkipList[T](value: s.value, down: s)
            else:
              # create a new layer with two nodes
              s = SkipList[T](value: s.value, down: s,
                              over: SkipList[T](value: p.value, down: p))
      of Undefined:
        raise newException(SkipListError, "skiplist corrupt")

proc add*[T](s: var SkipList[T]; v: T; pred: SkipListPred[T] = defaultPred) =
  ## insert a value `v` in SkipList `s`
  add(s, SkipList[T](value: v), pred = pred)

proc toSkipList*[T](values: var seq[T]): SkipList[T] =
  ## Instantiate a SkipList from values `values`.
  when skiplistsCheckOrder and not defined(release):
    ## Will sort the input.
    sort(values)
  if len(values) > 0:
    result = newSkipList(values[0])
    var s = result
    for item in values[1..^1]:
      s.over = newSkipList(item)
      assert s <= s.over, "unsorted toSkipList input"
      s = s.over
    assert height(result) == 0
    assert count(result) == len(values)

proc toSkipList*[T](values: openArray[T]): SkipList[T] =
  ## Create a SkipList from an openArray `values`.
  for item in items(values):
    if result.isNil:
      result = newSkipList(item)
    else:
      add(result, item)
