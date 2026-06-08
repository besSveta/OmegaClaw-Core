"""
Test: OmegaClaw uploads content  of instructions/test-workflow/SKILL.md into &active_instructions.

Run:
    pytest test_load_md.py -s
"""
from helpers import (
    Checker, dexec, make_prompt, send_prompt, wait_for_file, wait_for_skill_call, find_skill_calls, _response_window,
    read_history, wait_for_skill_match,
)

WAIT = 180

def test_load_md():
    with Checker("upload SKILL.md") as c:
        print(f"\n=== OmegaClaw smoke test (run-id {c.run_id}) ===", flush=True)

        c.verify_clean()
        c.step("connect to IRC and ask agent to load instructions")
        if not send_prompt(make_prompt(c.run_id, "do instruction from test workflow")):
            c.fail("irc", "could not deliver load prompt")
        load_arg = wait_for_skill_call(c.run_id, "load-instructions", timeout=WAIT)
        if load_arg is None:
            c.fail("load-instructions", "not invoked")
        c.ok("load-instructions", load_arg[:80])

        c.step("check correctness of &active_instructions content")
        def has_workflow(s: str) -> bool:
            low = s.lower()
            if any(em in low for em in ("error", "failed")):
                return False
            return "test-workflow" in low

        send_arg = wait_for_skill_match(
            c.run_id, "send", has_workflow, timeout=WAIT,
        )

        if send_arg is None:
            sends = find_skill_calls(c.run_id, "send") or []
            last = sends[-1] if sends else "<none>"
            c.fail("send result", f"expected to include test-workflow, last sends: {last!r}")
        c.ok("send result", send_arg[:120])

        # c.step("check that &active_instructions is cleaned after")
        #
        # def no_workflow(s: str) -> bool:
        #     low = s.lower()
        #     if any(em in low for em in ("error", "failed")):
        #         return False
        #     return ("test-workflow" not in low) and ("active instructions" in low)
        #
        # send_arg = wait_for_skill_match(
        #     c.run_id, "send", no_workflow, timeout=WAIT,
        # )
        # window = _response_window(read_history(), c.run_id)
        # c.step(f"window {window}")
        # if send_arg is None:
        #     sends = find_skill_calls(c.run_id, "send") or []
        #     last = sends[-1] if sends else "<none>"
        #     c.fail("send  result", f"expected do not include test-workflow, last sends: {last!r}")
        # c.ok("send result", send_arg[:120])

        c.done()



