import { test } from "node:test";
import assert from "node:assert/strict";
import { dueWeek, localParts, weekStart, winnerMessage } from "./weekly.ts";

const NY = "America/New_York";

test("localParts uses the group's time zone", () => {
  // 2026-10-12 03:30 UTC is Sunday 23:30 in New York.
  const p = localParts(new Date("2026-10-12T03:30:00Z"), NY);
  assert.deepEqual(p, { date: "2026-10-11", weekday: 7, hour: 23 });
});

test("weekStart is the local Monday", () => {
  assert.equal(weekStart(new Date("2026-10-11T12:00:00Z"), NY), "2026-10-05");
  assert.equal(weekStart(new Date("2026-10-12T14:00:00Z"), NY), "2026-10-12");
});

test("dueWeek fires at Monday 9am local, once", () => {
  const schedule = { post_weekday: 1, post_hour: 9, last_posted_week: null };
  // Monday 8:59 local: not yet.
  assert.equal(dueWeek(schedule, new Date("2026-10-12T12:59:00Z"), NY), null);
  // Monday 9:05 local: announce the week of Oct 5.
  assert.equal(dueWeek(schedule, new Date("2026-10-12T13:05:00Z"), NY), "2026-10-05");
  // Already posted: nothing.
  assert.equal(dueWeek({ ...schedule, last_posted_week: "2026-10-05" }, new Date("2026-10-12T15:00:00Z"), NY), null);
  // Missed Monday entirely: Tuesday still catches up.
  assert.equal(dueWeek(schedule, new Date("2026-10-13T02:00:00Z"), NY), "2026-10-05");
});

test("dueWeek respects a custom day and hour", () => {
  const schedule = { post_weekday: 5, post_hour: 17, last_posted_week: null };
  assert.equal(dueWeek(schedule, new Date("2026-10-16T20:00:00Z"), NY), null); // Fri 16:00
  assert.equal(dueWeek(schedule, new Date("2026-10-16T21:00:00Z"), NY), "2026-10-05"); // Fri 17:00
});

test("winnerMessage names a single winner", () => {
  const msg = winnerMessage({
    appName: "OnlySteps",
    groupName: "Office",
    weekStart: "2026-10-05",
    rows: [
      { user_id: "a", display_name: "Amy", total_steps: 70123, rank: 1 },
      { user_id: "b", display_name: "Bo", total_steps: 50000, rank: 2 },
    ],
  });
  assert.match(msg.text, /\*Amy\* won \*Office\* for Oct 5 – Oct 11 with \*70,123\* steps/);
});

test("winnerMessage handles ties and empty weeks", () => {
  const tie = winnerMessage({
    appName: "OnlySteps",
    groupName: "Office",
    weekStart: "2026-10-05",
    rows: [
      { user_id: "a", display_name: "Amy", total_steps: 100, rank: 1 },
      { user_id: "b", display_name: "Bo", total_steps: 100, rank: 1 },
    ],
  });
  assert.match(tie.text, /tie.*\*Amy\* and \*Bo\*/);
  const empty = winnerMessage({
    appName: "OnlySteps",
    groupName: "Office",
    weekStart: "2026-10-05",
    rows: [{ user_id: "a", display_name: "Amy", total_steps: 0, rank: 1 }],
  });
  assert.match(empty.text, /No steps logged/);
});

test("winnerMessage escapes names so they can't ping the channel", () => {
  const msg = winnerMessage({
    appName: "OnlySteps",
    groupName: "R&D <team>",
    weekStart: "2026-10-05",
    rows: [{ user_id: "a", display_name: "<!channel>", total_steps: 10, rank: 1 }],
  });
  assert.ok(!msg.text.includes("<!channel>"));
  assert.match(msg.text, /\*&lt;!channel&gt;\* won \*R&amp;D &lt;team&gt;\*/);
});

test("winnerMessage keeps a huge tie under Slack's section limit", () => {
  const rows = Array.from({ length: 200 }, (_, i) => ({
    user_id: String(i),
    display_name: "N".repeat(40),
    total_steps: 5000,
    rank: 1,
  }));
  const msg = winnerMessage({ appName: "OnlySteps", groupName: "Office", weekStart: "2026-10-05", rows });
  assert.match(msg.text, /and 190 others/);
  for (const block of msg.blocks as { text?: { text: string } }[]) {
    if (block.text) assert.ok(block.text.text.length <= 3000, `section is ${block.text.text.length} chars`);
  }
  assert.match((msg.blocks[1] as { text: { text: string } }).text.text, /…and 190 more$/);
});

test("winnerMessage lists three-way ties with commas", () => {
  const rows = ["Amy", "Bo", "Cy"].map((display_name, i) => ({ user_id: String(i), display_name, total_steps: 9, rank: 1 }));
  const msg = winnerMessage({ appName: "OnlySteps", groupName: "Office", weekStart: "2026-10-05", rows });
  assert.match(msg.text, /\*Amy\*, \*Bo\* and \*Cy\*/);
});
