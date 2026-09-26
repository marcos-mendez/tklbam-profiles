# Test coverage baseline

Measured on 2026-09-24 against upstream master (2e38ada), following the
project decision 0003 (90 percent floor per repository, 95 percent for every
file our changes touch).

## Measured baseline on the default branch: 100 percent (2026-09-26)

Pull request #1 merged on 2026-09-26 (merge commit 71b3766) and brought
`tests/coverage.sh` with it: 4 of 4 lines of the moodle profile accounted for by tests/check-profile.sh, 100 percent. The gate in
`.github/workflows/tests.yml` is set to 100, the measured number rounded
down, and is only ever raised. The sections that follow record the state
before the merge.

## Baseline before the merge: 0 percent, nothing measured

The repository holds 157 files: 150 tklbam profile lists at the top level
(one per appliance, each line a path to include or, with a leading `-`, to
exclude; 154 path lines in all), `README.md`, `.gitignore`, one Python
script and two shell hooks. Profile lists are data, not executable code,
but they are what tklbam applies on backup and restore, so a wrong path
silently loses data. There is no test suite and no coverage tool. Line
counts are lines neither blank nor comment.

Inventory command:

    find . -type f -not -path './.git/*' | while read f; do \
      head -1 "$f" | grep -q '^#!' && echo "$(grep -cvE '^\s*(#|$)' "$f") $f"; done

| File | Kind | Lines | Measured |
|------|------|-------|----------|
| bin/make-profile | Python 2 (pypy shebang) | 176 | 0 percent, no test |
| hooks/openldap/migrate-slapd | shell | 20 | 0 percent, no test |
| hooks/redmine/12-to-13-fix-database-config | shell | 12 | 0 percent, no test |
| 150 profile lists | data | 154 path lines | not checked by any test |

Total executable: 3 files, 208 lines, 0 percent measured.

## Our branches and the 95 percent bar

| Branch | File touched | Automated test |
|--------|--------------|----------------|
| fix/moodle-dataroot | moodle (profile list, 6 lines) | None. Dropping the stale `/var/lib/moodle` paths and excluding the moodledata cache, localcache, sessions and temp directories was verified by hand with a backup and restore on a VM. |

The profile is data, so "95 percent" for it means: every line is parsed
by a test and every path it names is checked against the appliance it
describes.

## Plan to reach 90 percent per file

Priority order (size: small under 30 lines of test, medium under 150,
large above):

1. `moodle` (small). A test that parses the file, asserts each line is an
   absolute path or an exclusion, and asserts the four excluded paths sit
   under `/var/www/moodledata`, which the core profile already includes
   through `/var/www`.
2. Profile lint over all 150 lists (small, one parametrized test): every
   non-comment line is `/abs/path` or `-/abs/path`, no duplicates, no
   trailing spaces, no exclusion without a covering inclusion in the same
   file or in the core profile. This catches the class of bug fixed on
   fix/moodle-dataroot for every appliance at once.
3. `hooks/openldap/migrate-slapd` (small) and
   `hooks/redmine/12-to-13-fix-database-config` (small). Shell tests
   against a scratch root with stub `slapcat`, `slapadd`, `systemctl` and
   a fixture `database.yml`; assert the rewritten config and the exit
   codes. Coverage from `bash -x` traces (kcov when the decision 0003 open
   item settles).
4. `bin/make-profile` (medium). It runs under the tklbam pypy2
   interpreter, so `coverage` for Python 3 cannot measure it as is. Port
   it to Python 3 first (176 lines, mostly path walking and list output),
   then test it with `pytest` against a scratch tree: include and exclude
   lines, a missing directory, the output ordering. Until the port, the
   file stays at 0 percent and is the one item in this repository that
   blocks the floor.
5. Path existence per appliance (large, open item). The honest test for a
   profile is a built appliance in which every included path exists and
   every excluded path is a cache the application recreates. This needs
   the LXC runner from decision 0003 and one build per appliance, so it
   is planned with the appliance recipe question left open there. A host
   in such a fixture is addressed over IPv6 (`2001:db8::/32`).

Steps 1 to 4 bring every executable file and the touched profile to the
bar; step 5 is what makes the remaining 149 profiles trustworthy.
