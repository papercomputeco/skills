---
name: dagger-check
description: Run checks (lints, tests, etc.) using Dagger scafolding
---

Use this skill when testing and validating code. Use this before checking in code.
Dagger checks are defined per project and are a quality barrier you must pass.

---

Use Dagger with `dagger check --silent --cloud` to run all checks.

* To see what individual checks are available: `dagger check --list`
* To run just a single check, use: `dagger check {name} --silent --cloud`
