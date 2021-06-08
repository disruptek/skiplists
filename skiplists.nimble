version = "0.5.4"
author = "disruptek"
description = "skiplists"
license = "MIT"

requires "https://github.com/disruptek/grok < 1.0.0"
when not defined(release):
  requires "https://github.com/disruptek/balls >= 3.0.0 & < 4.0.0"
  requires "https://github.com/disruptek/criterion < 1.0.0"

task test, "run unit tests":
  when defined(windows):
    exec "balls.cmd"
  else:
    exec findExe"balls"
