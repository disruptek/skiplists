version = "0.4.2"
author = "disruptek"
description = "skiplists"
license = "MIT"

requires "https://github.com/disruptek/testes >= 0.7.1 & < 1.0.0"
requires "https://github.com/disruptek/grok < 1.0.0"
requires "https://github.com/disruptek/criterion < 1.0.0"

task test, "run unit tests":
  when defined(windows):
    exec "testes.cmd"
  else:
    exec findExe"testes"
