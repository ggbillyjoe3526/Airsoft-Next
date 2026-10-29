Task: KI2 · QA commit a141fef · Verdict: Pass (re-check after fix round 1, worker commit ba29fb2)

Blocking: none. The earlier finding (slide drawn forward through a reload, slide_back captured before the skeleton
flushed) is fixed: SlideLockPose (game/play/slide_lock_pose.gd) holds the slide bone over any clip; my two tests that
failed before (test_ki2_qa.gd any-moment reload, rendered back through the reload) now pass unedited, reading the
drawn slide after process frames. test_slide_lock.gd now asserts locked is more than 1 cm from home (no longer vacuous).

Advisory: none new. A hidden (switched-away) pistol keeps its modifier active until it is shown again; harmless, it is
hidden and the pose is recomputed on return (pinned below).

Checked: reloads begun at every moment of the last shot's Fire clip, idle lock after the last shot, release at
slide_release_at, tactical reload (never locks, drawn home), cut by switch, holster, or elimination mid-reload and a
new round (re-locks while empty, home when loaded), hidden view, bottomless, Realistic colours, a model without the
slide bone or SlideLock clip (the AEG: attach returns null, and null anim too), exactly one modifier on the pistol's
skeleton and none on the rifle, replica switching adds and frees no nodes, freeing the view frees every modifier
(node count back to baseline). The third-person figures never call SlideLockPose.attach (only replica_view.gd does);
test_figure_mix passes.

Tests added in tests/unit/test_ki2_qa.gd (15 total now; 6 new this round, each fails if the modifier is missing, on
the null or count asserts, or if the hold is not released, which I checked by reading the code paths, not by reverting
game/): modifier only on the pistol and on its skeleton; no modifier for a model without slide bone or clip; Realistic
colours view holds the slide back; switching back and forth leaves node count unchanged; a pistol hidden while locked
returns loaded and home with the hold released; freeing the view leaves no modifier behind.

Suite: test_ki2_qa, test_slide_lock, test_hands_feel, test_figure_mix, test_cyber_pistol: 55 of 55, 35 s.
tools/smoke_test.sh passes (zero script errors). gdlint clean. Full parts not run (machine load).
Not testable here: how the slide looks on screen with Forward+ (owner: fire the pistol dry, reload at once, watch the
slide stay back until the magazine seats).
