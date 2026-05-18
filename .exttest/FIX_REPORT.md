# lstparsR — fetch_ofv() / Eigenvalue Bug Fix Report

## Reported issue
- Source: Christiane (co-author)
- Symptoms:
  - `OFV not found in lst file. Returning NA.`
  - `Eigenvalue section not found. Returning NA.`
- Reported as reproducible across several unrelated projects.

## Root cause(s) found

Both warnings were **false positives** — the parsers themselves were already
correct for the OFV / eigenvalue formats Christiane uses (commit `0e7c73d`
had already broadened the regexes). The remaining issue was that the parsers
warned even in cases where the absence of an OFV or eigenvalue block is
**expected and intentional**:

1. **`fetch_ofv()`** warned for `$SIMULATION ONLYSIMULATION` runs (e.g. the
   `vpc_simulation.1*.lst` files). Such runs perform no estimation and
   produce no OFV; `NA` is the correct answer and no warning should be
   emitted.

2. **`fetch_condn()`** warned for runs whose `$COV` step ran successfully but
   used `EIGENVLS. PRINTED: NO` (e.g. `long_lst.lst`, `test.lst`). In that
   case NONMEM intentionally omits the eigenvalue block, even though
   `STANDARD ERROR OF ESTIMATE` is present.

In both cases the parser correctly returned `NA`, but the spurious warning
made it look like a parser bug. Christiane's report combined many of these
false positives; once stripped out, no real parse failures remained in her
files.

## Files in `.exttest/_collected_lst/` surveyed
- Total `.lst` files: 7638
- OFV-warning files before fix: 14 (all `vpc_simulation.1*`)
- Eigenvalue-warning files before fix: 2 (`long_lst.lst`, `test.lst`)
- After fix: **0 OFV warnings, 0 eigenvalue warnings**

## Code changes
- `R/utils-internal.R`: added internal helpers `.has_estimation_step()` and
  `.eigenvalues_suppressed()`.
- `R/fetch_ofv.R`: before warning, return `NA_real_` silently if no
  estimation-step markers (`#OBJT:`, `#OBJV:`, `#METH:`, `MINIMIZATION
  SUCCESSFUL/TERMINATED`, `MINIMUM VALUE OF OBJECTIVE FUNCTION`,
  `OBJECTIVE FUNCTION EVALUATIONS`, `BURN-IN ITERATIONS`) are present.
- `R/fetch_condn.R`: after the `$COV` check, return `NA_real_` silently if
  `EIGENVLS. PRINTED: NO` is found.

## Tests added
- `inst/testdata/sim_only_no_ofv.lst` — minimal `$SIMULATION ONLYSIMULATION`
  fixture, ~25 lines.
- `inst/testdata/eigen_printed_no.lst` — minimal fixture with
  `EIGENVLS. PRINTED: NO` and `STANDARD ERROR OF ESTIMATE`, ~25 lines.
- `tests/testthat/test-fetch_ofv.R` — new `expect_no_warning(...)` /
  `expect_true(is.na(...))` test for the sim-only case; existing empty-lst
  test updated to include a `MINIMIZATION SUCCESSFUL` marker so it still
  exercises the warning path.
- `tests/testthat/test-fetch_condn.R` — new test for the
  `EIGENVLS. PRINTED: NO` case.

## Validation
- `devtools::test()`: **PASS 73, FAIL 0, WARN 0, SKIP 0**.
- `devtools::check()`: **0 errors, 0 warnings, 1 note** related to package
  internals (`future file timestamps`); 2 pre-existing vignette-related
  warnings caused by `pandoc` not being installed in the local dev
  environment — unrelated to this change.
- External harness (`.exttest/run_exttest.R`) over 7638 files:
  - `ofv`     OK 7638, FAIL 0, WARN **0** (was 14)
  - `condn`   OK 7638, FAIL 0, WARN **0** (was 2)
  - `thetas`, `etas`, `sigmas`: unchanged (the 1191 failures are
    expected — `$SIMULATION`-only files with no detectable estimation
    method — outside the scope of this bug fix).

## Suggestions for further improvement (NOT implemented)
- For `$SIMULATION`-only files, `fetch_thetas()` / `fetch_etas()` /
  `fetch_sigmas()` currently `stop()` with "Could not detect a known
  estimation method". Consider making this an `NA`-returning behavior
  consistent with `fetch_ofv()` / `fetch_condn()`.
- The 3 pre-existing `.parse_vector_block` "IDs but values" warnings on
  unusual THETA blocks could be investigated separately; not related to
  this report.
- Consider exposing a `verbose`/`warn` argument on the fetchers to allow
  programmatic suppression of all warnings without `suppressWarnings()`.

## Diagnostic answer for Christiane

Liebe Christiane,

der Bug war kein Parser-Fehler — die OFV- und Eigenwert-Werte wurden in
deinen Dateien immer korrekt eingelesen (Ergebnis war `NA`, was richtig
ist). Das Problem war, dass die Funktionen in zwei legitimen Fällen
*trotzdem* gewarnt haben:

1. **`fetch_ofv()`** hat bei reinen `$SIMULATION ONLYSIMULATION`-Runs
   (z. B. deinen `vpc_simulation.1`-Dateien) gewarnt, obwohl solche
   Läufe per Definition keinen OFV haben.
2. **`fetch_condn()`** hat gewarnt, wenn `$COV` lief, aber im Output
   `EIGENVLS. PRINTED: NO` stand — also der Nutzer das Drucken der
   Eigenwerte explizit ausgeschaltet hat.

Beide Fälle geben jetzt `NA` **ohne** Warnung zurück. Echte Parser-Fehler
(z. B. `$EST` lief, aber OFV nicht lesbar) lösen weiterhin eine Warnung
aus. Update auf `lstparsR 0.1.1`, dann sind die Warnings weg.

Liebe Grüße,
Raban
