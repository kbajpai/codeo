# Issue #152 — issue

Requested by the engineer: "Is it a good idea that \"codeo home container\" runs actually on physical machine & only the issues run on a container? I am just trying to brainstorm ideas."

## Where this stands

Filed as #152 (https://github.com/kbajpai/codeo/issues/152). Role check passed (home container). No duplicate: #55 introduced the home container, #133 the host `codeo` command, #73 is the precedent for an evaluation issue. The repository has no Issue Types.

## Questions

1. **Kind of issue.** Evaluation (like #73), change request, or don't file yet?
   **Answer:** Evaluation issue.

2. **Motivation.** Home can't run Docker · overhead of a container · duplicates the `codeo` host command · just exploring?
   **Answer:** All four.

3. **Hosts.** Linux · macOS · Windows/WSL?
   **Answer:** All three.

4. **Criteria the evaluation judges.** Role guard · host access/safety · setup & upkeep · what it unlocks?
   **Answer:** All four.

5. **Deliverable.** Committed doc + follow-up issues only on a change, or a closing comment?
   **Answer:** Committed doc + follow-ups.

6. **Out of scope.** Building it · issue containers · sbx for home?
   **Answer:** Issue containers only. Building the recommendation falls to the follow-ups (from Q5); home in an sbx sandbox may be one of the options compared.

## Draft

**Title:** Evaluate running the home role on the host instead of in the `codeo-home` container, and recommend keep, move or hybrid
**Labels:** `question`, `documentation` (as #73). No type (`issue-types` prints nothing). No priority or effort.
Body: `body.md` in this directory.

## Outcome

## Log

- 2026-11-21 — questions 1-6 asked and answered in the conversation; draft approved at the review gate · cost: 6m · opus-5-5 60k in + 826k cached / 7k out
- 2026-11-21 — approved and filed as #152
