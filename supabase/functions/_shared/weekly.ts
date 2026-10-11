// Pure helpers for the weekly winner post. No Deno or Node APIs here, so the
// web app (test post) and the Edge Function (scheduled post) share this file.

export type LeaderboardRow = {
  user_id: string;
  display_name: string;
  total_steps: number;
  rank: number;
};

export type SlackSchedule = {
  post_weekday: number; // ISO weekday, 1 = Monday
  post_hour: number; // 0-23
  last_posted_week: string | null; // yyyy-mm-dd (a Monday)
};

const WEEKDAYS: Record<string, number> = { Mon: 1, Tue: 2, Wed: 3, Thu: 4, Fri: 5, Sat: 6, Sun: 7 };

/** Calendar date, ISO weekday and hour of `now` in time zone `tz`. */
export function localParts(now: Date, tz: string) {
  const parts = Object.fromEntries(
    new Intl.DateTimeFormat("en-US", {
      timeZone: tz,
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
      weekday: "short",
      hour: "2-digit",
      hourCycle: "h23",
    })
      .formatToParts(now)
      .map((p) => [p.type, p.value]),
  );
  return {
    date: `${parts.year}-${parts.month}-${parts.day}`,
    weekday: WEEKDAYS[parts.weekday],
    hour: Number(parts.hour),
  };
}

/** Adds `days` to a yyyy-mm-dd date string. */
export function addDays(date: string, days: number): string {
  const d = new Date(`${date}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() + days);
  return d.toISOString().slice(0, 10);
}

/** Monday of the week containing `now`, in `tz`. */
export function weekStart(now: Date, tz: string): string {
  const { date, weekday } = localParts(now, tz);
  return addDays(date, 1 - weekday);
}

/**
 * The week (its Monday) to announce now, or null if nothing is due.
 * A post becomes due once the group's local time passes the configured
 * weekday and hour, and stays due until it is sent, so a missed hourly run
 * catches up on the next one.
 */
export function dueWeek(schedule: SlackSchedule, now: Date, tz: string): string | null {
  const { weekday, hour } = localParts(now, tz);
  const reached = weekday > schedule.post_weekday || (weekday === schedule.post_weekday && hour >= schedule.post_hour);
  if (!reached) return null;
  const previous = addDays(weekStart(now, tz), -7);
  return schedule.last_posted_week === previous ? null : previous;
}

const fmt = (n: number) => n.toLocaleString("en-US");

/** Escapes text for Slack mrkdwn so names can't add mentions or links. */
export const slackEscape = (s: string) => s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");

function formatRange(weekStartDate: string): string {
  const opts: Intl.DateTimeFormatOptions = { month: "short", day: "numeric", timeZone: "UTC" };
  const start = new Date(`${weekStartDate}T00:00:00Z`);
  const end = new Date(`${addDays(weekStartDate, 6)}T00:00:00Z`);
  return `${start.toLocaleDateString("en-US", opts)} – ${end.toLocaleDateString("en-US", opts)}`;
}

// Slack rejects section text over 3,000 characters, so long ties are cut short.
const MAX_LISTED = 10;

/** "A and B", "A, B and C", or "A, B, … and N others" past MAX_LISTED. */
function listNames(names: string[]) {
  if (names.length > MAX_LISTED) {
    const others = names.length - MAX_LISTED;
    return `${names.slice(0, MAX_LISTED).join(", ")} and ${others} ${others === 1 ? "other" : "others"}`;
  }
  return names.length <= 2 ? names.join(" and ") : `${names.slice(0, -1).join(", ")} and ${names.at(-1)}`;
}

/** Slack incoming-webhook payload announcing the week's winner(s). */
export function winnerMessage(opts: {
  appName: string;
  groupName: string;
  weekStart: string;
  rows: LeaderboardRow[];
  groupUrl?: string;
  test?: boolean;
}) {
  const { appName, weekStart: ws, rows, groupUrl, test } = opts;
  const groupName = slackEscape(opts.groupName);
  const name = (r: LeaderboardRow) => slackEscape(r.display_name);
  const range = formatRange(ws);
  const active = rows.filter((r) => r.total_steps > 0);
  const winners = active.filter((r) => r.rank === 1);
  const medals = ["🥇", "🥈", "🥉"];

  let headline: string;
  if (winners.length === 0) {
    headline = `No steps logged in *${groupName}* for ${range}. New week, fresh start! 👟`;
  } else if (winners.length === 1) {
    headline = `🏆 *${name(winners[0])}* won *${groupName}* for ${range} with *${fmt(winners[0].total_steps)}* steps!`;
  } else {
    const names = listNames(winners.map((w) => `*${name(w)}*`));
    headline = `🏆 It's a tie in *${groupName}* for ${range}: ${names} with *${fmt(winners[0].total_steps)}* steps each!`;
  }

  const onPodium = active.filter((r) => r.rank <= 3);
  const podiumLines = onPodium
    .slice(0, MAX_LISTED)
    .map((r) => `${medals[r.rank - 1]} ${name(r)} · ${fmt(r.total_steps)}`);
  if (onPodium.length > MAX_LISTED) podiumLines.push(`…and ${onPodium.length - MAX_LISTED} more`);
  const podium = podiumLines.join("\n");

  const prefix = test ? "_Test post from " + appName + "._\n" : "";
  const text = `${prefix}${headline}`;
  const blocks: unknown[] = [{ type: "section", text: { type: "mrkdwn", text } }];
  if (podium) blocks.push({ type: "section", text: { type: "mrkdwn", text: podium } });
  if (groupUrl) {
    blocks.push({
      type: "context",
      elements: [{ type: "mrkdwn", text: `<${groupUrl}|See the full leaderboard in ${appName}>` }],
    });
  }
  return { text, blocks };
}
