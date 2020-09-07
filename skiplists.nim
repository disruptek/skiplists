import std/sequtils
import std/hashes
import std/random

import grok

const
  skiplistsChecks {.booldefine.} = true
  skiplistsGrowth {.intdefine.} = 4

when (NimMajor, NimMinor) <= (1, 2):
  type
    SkipListError* = object of IndexError ##
      ## A specified index that should have existed did not.
    SkipListDefect* = object of AssertionError ##
      ## A defect was detected in the SkipList implementation.
else:
  type
    SkipListError* = object of IndexDefect ##
      ## A specified index that should have existed did not.
    SkipListDefect* = object of AssertionDefect ##
      ## A defect was detected in the SkipList implementation.

type
  EmptySkipListError* = object of ValueError ##
    ## An empty SkipList is invalid for this operation.

  SkipListObj[T] = object
    over: SkipList[T]
    down: SkipList[T]
    value: T
  SkipList*[T] = ref SkipListObj[T]

  SkipListPred*[T] = proc(up: SkipList[T]; here: SkipList[T];
                          child: SkipList[T]): bool ##
    ## The predicate used to determine whether the SkipList
    ## will grow during an add() operation.
    ##
    ## :up: a larger scope of the SkipList, perhaps top-most
    ## :here: a narrower scope of the SkipList
    ## :child: a SkipList holding the new value

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

proc rank*(s: SkipList): int =
  ## The higher the rank, the shorter the SkipList.
  if not s.isNil:
    var s = s
    while not s.down.isNil:
      assert s.down.value == s.value,
        "s.down is " & $s.down.value & " while s is " & $s.value
      inc result
      s = s.down

proc bottom*(s: SkipList): SkipList =
  ## Traverse to the longest SkipList, which holds all values.
  if not s.isNil:
    result = s
    while not result.down.isNil:
      assert result.down.value == result.value
      result = result.down

proc newSkipList*[T](value: T): SkipList[T] =
  ## Instantiate a SkipList from value `value`.
  result = SkipList[T](value: value)

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
    cmp.Less
  elif a.value == b.value:
    cmp.Equal
  else:
    cmp.More

template `<>`(a, b: SkipList): cmp =
  ## Compare SkipList `a` and `b`.
  if a.isNil or b.isNil:
    if a.isNil and b.isNil:
      cmp.Equal
    else:
      cmp.Undefined
  elif a === b:
    cmp.Equal
  else:
    a[] <> b[]

proc `<`*(a, b: SkipList): bool =
  ## `true` if SkipList `a` is less than SkipList `b`, else `false`.
  case a <> b
  of cmp.Less:
    result = true
  of cmp.Undefined:
    raise newException(EmptySkipListError, "invalid comparison")
  else:
    result = false

proc `==`*(a, b: SkipList): bool =
  ## `true` if SkipList `a` is equal to SkipList `b`, else `false`.
  case a <> b
  of cmp.Equal:
    result = true
  of cmp.Undefined:
    raise newException(EmptySkipListError, "invalid comparison")
  else:
    result = false

# ref equality semantics demand this!
template `<=`*(a, b: SkipList): bool =
  ## `true` if SkipList `a` is less or equal to SkipList `b`, else `false`.
  a < b or a == b

# ref equality semantics demand this!
template `>=`*(a, b: SkipList): bool =
  ## `true` if SkipList `a` is more or equal to SkipList `b`, else `false`.
  a > b or a == b

template iterIt(s: typed; body: untyped) =
  if not s.isNil:
    var
      it {.inject.} = s
    while not it.down.isNil:
      assert it.value == it.down.value,
             $it.value & " out of order iter " & $it.down.value
      it = it.down
    body
    while not it.over.isNil:
      assert it.value <= it.over.value,
             $it.value & " out of order iter " & $it.over.value
      it = it.over
      body

iterator rank(s: SkipList): SkipList =
  ## Yield each member of SkipList `s` rank.
  var s = s
  while not s.isNil:
    yield s
    s = s.over

iterator file(s: SkipList): SkipList =
  ## Yield each member of SkipList `s` file.
  var s = s
  while not s.isNil:
    yield s
    s = s.down

iterator values[T](s: SkipList[T]): string =
  ## Yield each peer value of SkipList `s`.
  var s = s
  while not s.isNil:
    when defined(release):
      yield $s.value
    else:
      if s.down.isNil:
        yield $s.value & " x " & $(cast[int](s))
      else:
        yield $s.value & " d " & $(cast[int](s.down))
    s = s.over

proc `$`(s: SkipList): string {.raises: [].} =
  ## A string representing SkipList `s`; intentionally not exported.
  if s.isNil:
    result = "\n*[]"
  else:
    var q = sequtils.toSeq s.values
    result = $q
    result[0] = '*'
    result = "\n" & result
    if not s.down.isNil:
      result.add $s.down

when defined(release) or not skiplistsChecks:
  template check(s: SkipList; args: varargs[string, `$`]) = discard
else:
  import std/strutils

  proc check(s: SkipList; args: varargs[string, `$`]) =
    ## Check a SkipList for validity; `args` informs error messages.
    var msg = join(args, " ")
    try:
      for r in s.file:
        assert r <> s in {Equal}
        for n in rank(r):
          if not n.over.isNil:
            if n.down.isNil:
              # dupes are permitted at the bottom
              assert n <> n.over in {Less, Equal}
            else:
              # no dupes in normal rank
              assert n <> n.over in {Less}
          if not n.down.isNil:
            # all members of the rank should have the same, uh, rank
            assert n.rank == r.rank
            # down links should always be equal
            assert n <> n.down in {Equal}
    except Exception as e:
      if msg.len > 0:
        msg &= "; "
      msg &= e.msg
      echo "check input:\n", $s
      raise newException(SkipListDefect, msg)

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
    result = i == q.len

proc hash*(s: SkipList): Hash =
  ## The `Hash` of SkipList `s` is a function of all its values.
  var h: Hash = 0
  for item in items(s):
    h = h !& hash(item)
  result = !$h

proc find[T](s: SkipList[T]; value: SkipList[T]; r: var SkipList[T]): bool =
  ## Find the SkipList `value` in SkipList `s`, storing the result in `r`;
  ## returns `true` if the value was found, else `false`.
  if not s.isNil:
    r = s
    if value <> r == Equal:
      result = true
    else:
      while true:
      case value <> r.over
        of cmp.Undefined:
          if r.down.isNil:
            break
          else:
            r = r.down
        of cmp.More:
          r = r.over
        of cmp.Equal:
          r = r.over
          result = true
          break
        of cmp.Less:
          raise newException(SkipListDefect, "out of order")

proc find*[T](s: SkipList[T]; value: T): SkipList[T] =
  ## Find the SkipList holding `value` in SkipList `s`; raises a KeyError`
  ## if the value was not found.
  if not find(s, SkipList[T](value: value), result):
    raise newException(KeyError, "not found")

proc find*[T](s: SkipList[T]; value: T; r: var SkipList[T]): bool =
  ## Find `value` in SkipList `s`, storing the result in `r`;
  ## returns `true` if the value was found, else `false`.
  result = find(s, SkipList[T](value: value), r)

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
    when false and defined(gcDestructors):
      for item in items(s):
        assert result.len <= size
        add(result, item)
    else:
      setLen(result, size)
      for index, item in pairs(s):
        result[index] = item

proc contains[T](s: SkipList[T]; v: SkipList[T]): bool =
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

proc constrain(s: var SkipList; n: SkipList;
               narrow: var SkipList; parent: var SkipList;
               comp: set[cmp] = {Less, Equal}): cmp =
  ## Scope SkipList `s` to surround `n`, storing the result in `narrow`
  ## and a SkipList with a larger rank in `parent`, if possible. Supply
  ## `comp` to denote satisfactory cmp values for peers.
  assert comp - {Less, Equal} == {}
  result = s <> n
  if result in comp:
    narrow = s
    var test = result
    while test in comp:
      assert narrow <> narrow.over in {Less, Equal, Undefined}
      test = narrow.over <> n
      if test in comp:
        narrow = narrow.over
        result = test
      elif test in {Undefined, More}:
        if not narrow.down.isNil:
          assert narrow <> narrow.down == Equal, $narrow
          parent = narrow
          test = constrain(narrow.down, n, narrow, parent, comp)
          if test in comp:
            result = test
            break
          elif parent.rank == narrow.rank:
            assert false, "probably not what you want"

proc append[T](s: var SkipList[T]; v: T): SkipList[T] {.inline.} =
  ## The primitive append operation.
  assert not s.isNil
  assert v >= s.value, "out of order append"
  result = s
  if s.down.isNil:
    s.over = SkipList[T](over: s.over, value: v)
  else:
    s.over = SkipList[T](over: s.over, value: v,
                         down: append(s.down, v))
    assert s <> s.down == Equal
    assert s.over <> s.over.down == Equal

proc insert[T](s: var SkipList[T]; v: T): SkipList[T] {.inline.} =
  ## The primitive insert operation.
  assert not s.isNil
  assert v <= s.value, "out of order insert"
  if s.down.isNil:
    result = SkipList[T](over: s, value: v)
  else:
    result = SkipList[T](over: s, value: v,
                         down: insert(s.down, v))
    assert result <> result.down == Equal
    assert result.over <> result.over.down == Equal

proc remove*[T](s: var SkipList[T]; n: SkipList[T]): bool =
  ## Remove SkipList `n` from SkipList `s`; returns `true` if `s` changed.
  ##
  ## :s: The source SkipList
  ## :n: The SkipList to remove
  var p, parent: SkipList[T]
  case constrain(s, n, p, parent, comp = {Less})
  of cmp.Undefined, cmp.More:
    discard
  of cmp.Less:
    var q = p.bottom
    if q.over <> n in {cmp.Equal}:
      # dupe exists; only remove the dupe
      q.over = q.over.over
      result = true
    else:
      # remove the entire file
      if p.over <> n in {cmp.Equal}:
        result = true
        while not p.isNil:
          p.over = p.over.over
          p = p.down
  of cmp.Equal:
    # we need to mutate s
    var q = s.bottom
    result = true
    if q.over <> q in {cmp.Equal}:
      # it's a dupe; simple to handle
      q.over = q.over.over
    else:
      # just omit the entire file
      s = s.over

proc remove*[T](s: var SkipList[T]; value: T): bool {.discardable.} =
  ## Remove `value` from SkipList `s`; returns `true` if `s` changed.
  result = remove(s, newSkipList value)
  check s

proc grow[T](s: var SkipList[T]; n: SkipList[T]): bool =
  ## `true` if we grew.
  var p, parent: SkipList[T]
  var c = constrain(s, n, p, parent, comp = {cmp.Less})
  result = c in {cmp.Equal, cmp.Less}
  case c
  of cmp.Undefined, cmp.More:
    discard
  of Equal:
    assert s.rank == p.rank
    assert s <> n == cmp.Equal
    # add a rank; we're already as tall as possible
    s = SkipList[T](value: n.value, down: s)
  of cmp.Less:
    assert p.over <> n in {cmp.Equal}
    # if s and p aren't the same skiplist but they have the same rank,
    if s =!= p and s.rank == p.rank:
      # add a rank with s and p nodes
      s = SkipList[T](value: s.value, down: s,
                      over: SkipList[T](value: n.value, down: p.over))
    elif s.rank != p.rank:
      # confirm that grow received input that was "close"
      raise newException(SkipListDefect, "s.rank != p.rank")
    elif parent.isNil:
      # essentially, add a rank with s and p values
      s = SkipList[T](value: s.value, down: s,
                      over: SkipList[T](value: n.value, down: p.over))
    # this is a non-recursive append, basically
    else:
      parent.over = SkipList[T](value: n.value, over: parent.over)

proc add[T](s: var SkipList[T]; n: SkipList[T]; pred: SkipListPred[T]) =
  ## Add SkipList `n` into SkipList `s`.
  if s.isNil:
    s = n
  else:
    var p, parent: SkipList[T]
    case constrain(s, n, p, parent, comp = {cmp.Less})
    of cmp.Undefined:
      discard
    of cmp.More:
      # create a new file for this value
      s = insert(s, n.value)
    of cmp.Equal:
      # the head is equal to the new value
      # just append it at the bottom; dupes don't make good indices
      p = s.bottom
      discard append(p, n.value)
    of cmp.Less:
      # go ahead and append it
      discard append(p, n.value)
      if parent.isNil:
        parent = s
      while pred(parent, p, n):
        discard grow(parent, n)

proc add*[T](s: var SkipList[T]; v: T; pred: SkipListPred[T] = defaultPred) =
  ## Add a value `v` into SkipList `s`.
  add(s, SkipList[T](value: v), pred = pred)
  check s, "add()"

proc toSkipList*[T](values: openArray[T] = @[]): SkipList[T] =
  ## Create a SkipList from an openArray `values`.
  for item in items(values):
    if result.isNil:
      result = newSkipList(item)
    else:
      add(result, item)
  check result, "toSkipList()"

proc clear*(s: var SkipList) =
  ## Empty SkipList `s` of all entries.
  s = nil

template append*[T](s: var SkipList[T]; value: T) =
  ## Alias for `add(s, value)`.
  add(s, value)
