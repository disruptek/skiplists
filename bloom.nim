import std/hashes

type
  Bloomable = concept c ##
    ## The item may be used in a bloom filter if it may be hashed.
    hash(c) is int

  Bloom*[K, N: static int] = array[K, set[range[0'u16 .. uint16(N-1)]]]  ##
  ## A bloom filter of `K` layers and `N` entries per layer.

proc bucket(k, n: int; h: Hash): uint16 =
  ## Produce a hash value that is sized appropriately for a set layer.
  var h: Hash = h
  if k !=  0:
    h = h !& hash(n)
    h = h !& hash(k) # make it harder for people to mix sets
    h = !$h
  result = uint16((h.int and uint16.high.int) mod n)

proc contains*[K, N](bloom: Bloom[K, N]; item: Bloomable): bool =
  ## Yields `false` only if the `item` is not in the `bloom` filter.
  let h = hash item
  for k, bloom in bloom.pairs:
    if bucket(k, N, h) notin bloom:
      return false
  result = true

template operator[K, N](x: typed; a, b: Bloom[K, N]): Bloom[K, N] =
  ## A convenience for specifying bloom filter operators.
  var c: Bloom[K, N]
  for k in a.low .. a.high:
    c[k] = x(a[k], b[k])

proc `and`*[K, N](a, b: Bloom[K, N]): Bloom[K, N] =
  ## A bitwise `and` of filters `a` and `b`.
  `and`.operator(a, b)

proc `or`*[K, N](a, b: Bloom[K, N]): Bloom[K, N] =
  ## A bitwise `or` of filters `a` and `b`.
  `or`.operator(a, b)

proc add*[K, N](bloom: var Bloom[K, N]; item: Bloomable) =
  ## Record the `item` as a member of the `bloom` filter.
  let h = hash item
  when false:  # work around a nim bug in the cpp backend
    for k, bloom in bloom.mpairs:
      bloom.incl bucket(k, N, h)
  else:
    for k in bloom.low .. bloom.high:
      bloom[k].incl bucket(k, N, h)

proc del*(bloom: var Bloom; item: Bloomable) =
  ## Unsupported by bloom filters; yields a compile-time error.
  {.error: "one cannot delete entries from the bloom filter".}

proc `$`*[K, N](bloom: Bloom[K, N]): string =
  ## Render the `bloom` filter distribution as a `string`.
  for k, bloom in bloom.pairs:
    if k != 0:
      result.add "\n"
    result.add $k & ": " & $(len bloom) & " of " & $N

proc clear*(bloom: var Bloom) =
  ## Empty the `bloom` filter.
  bloom = default Bloom
