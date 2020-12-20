version = "0.4.2"
author = "disruptek"
description = "skiplists"
license = "MIT"

requires "https://github.com/disruptek/testes >= 0.6.0 & < 1.0.0"
requires "https://github.com/disruptek/grok < 1.0.0"
requires "https://github.com/disruptek/criterion < 1.0.0"

import std/[strutils, os, tables]

const
  directory = "tests"
  hints = "--hint[Cc]=off --hint[Link]=off --hint[Conf]=off " &
          "--hint[Processing]=off"
  pattern = "nim $1 --gc:$2 $3 --run " & hints & " $4"

type
  Compilers = enum c, cpp
  Optimizations = enum debug, release, danger
  Models = enum refc, markAndSweep, arc, orc

proc attempt(cmd: string): bool =
  echo "$ " & cmd
  try:
    exec cmd
    result = true
  except OSError:
    echo "test `" & cmd & "` failed; compiler:"
    exec "nim --version"

# set some default matrix members
var opt = {debug: @[""]}.toTable
var cp = @[c]
# the default gc varies with version
var gc =
  when (NimMajor, NimMinor) >= (1, 2):
    {arc}
  else:
    {refc}

# remote ci expands the matrix
when getEnv("GITHUB_ACTIONS", "false") == "true":
  cp.add cpp
  gc.incl refc
  gc.incl markAndSweep
  if arc in gc:
    gc.incl orc
  # add other optimization levels with defines
  for o in {release, danger}:
    opt[o] = opt.getOrDefault(o, @[]) & @["--define:" & $o]

proc perform(fn: string) =
  if not fn.fileExists:
    echo "test file missing: ", fn
  else:
    for opt, options in opt.pairs:
      for gc in gc.items:
        for cp in cp.items:
          let run = pattern % [$cp, $gc, options.join(" "), fn]
          if not attempt(run):
            case $NimMajor & "." & $NimMinor
            of "1.4":
              if gc > orc:
                continue
            of "1.2":
              if gc > arc:
                continue
            else:
              discard
            # i don't care if cpp works anymore
            if cp != cpp:
              quit 1

task test, "run unit tests":
  for test in directory.listFiles:
    if test.startsWith(directory / "t") and test.endsWith(".nim"):
      perform test
