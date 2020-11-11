version = "0.4.0"
author = "disruptek"
description = "skiplists"
license = "MIT"

requires "https://github.com/disruptek/testes >= 0.2.2 & < 1.0.0"
requires "https://github.com/disruptek/grok < 1.0.0"
requires "https://github.com/disruptek/criterion < 1.0.0"

proc execCmd(cmd: string) =
  echo "exec: " & cmd
  exec cmd

proc execTest(test: string) =
  when getEnv("GITHUB_ACTIONS", "false") != "true":
    execCmd "nim c            --define:skiplistsChecks -f -r " & test
    when (NimMajor, NimMinor) >= (1, 2):
      execCmd "nim c --gc:arc --define:skiplistsChecks -f -r " & test
      execCmd "nim c --gc:arc --define:danger -f -r " & test
  else:
    execCmd "nim c   --define:skiplistsChecks -f -r " & test
    execCmd "nim cpp --define:skiplistsChecks -f -r " & test
    execCmd "nim c   --define:danger -r -f " & test
    execCmd "nim cpp --define:danger -r -f " & test
    when (NimMajor, NimMinor) >= (1, 2):
      execCmd "nim c   --gc:arc -d:danger -r -f " & test
      execCmd "nim cpp --gc:arc -d:danger -r -f " & test

task test, "run tests for ci":
  execTest("tests/test.nim")
