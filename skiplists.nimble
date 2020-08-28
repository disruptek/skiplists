version = "0.1.1"
author = "disruptek"
description = "skiplists"
license = "MIT"

requires "nim >= 1.0.0 & < 2.0.0"
requires "https://github.com/disruptek/testes >= 0.2.2 & < 1.0.0"

proc execCmd(cmd: string) =
  echo "exec: " & cmd
  exec cmd

proc execTest(test: string) =
  when false:
    execCmd "nim c        -f -r " & test
    execCmd "nim c -d:danger -r " & test
  else:
    execCmd "nim c              -r " & test
    execCmd "nim c   -d:danger  -r " & test
    execCmd "nim cpp            -r " & test
    execCmd "nim cpp -d:danger  -r " & test
    when NimMajor >= 1 and NimMinor >= 1:
      #execCmd "nim c --useVersion:1.0 -d:danger -r " & test
      execCmd "nim c  -d:danger -r " & test
      execCmd "nim c   --gc:arc -r " & test
      execCmd "nim cpp --gc:arc -r " & test
