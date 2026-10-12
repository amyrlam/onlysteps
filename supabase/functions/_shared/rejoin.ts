// Slack message for a request to rejoin a group. Runtime-neutral, like weekly.ts.
import { slackEscape } from "./weekly.ts";

/**
 * Slack incoming-webhook payload telling a group's channel that someone the
 * owner removed asked to rejoin. The channel is shared with the whole group,
 * so the requester isn't named here; the owner sees who it is in the app.
 */
export function rejoinRequestMessage(opts: { appName: string; groupName: string; groupUrl?: string }) {
  const { appName, groupUrl } = opts;
  const groupName = slackEscape(opts.groupName);
  const text = `🙋 Someone removed from *${groupName}* asked to rejoin.`;
  const action = groupUrl
    ? `The group owner can approve or dismiss it in <${groupUrl}|${appName}>.`
    : `The group owner can approve or dismiss it in ${appName}.`;
  return {
    text,
    blocks: [
      { type: "section", text: { type: "mrkdwn", text } },
      { type: "context", elements: [{ type: "mrkdwn", text: action }] },
    ],
  };
}
