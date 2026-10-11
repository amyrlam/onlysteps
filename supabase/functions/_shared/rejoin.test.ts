import { test } from "node:test";
import assert from "node:assert/strict";
import { rejoinRequestMessage } from "./rejoin.ts";

test("rejoinRequestMessage escapes the group name and links to the group", () => {
  const msg = rejoinRequestMessage({
    appName: "App",
    groupName: "<!channel> & co",
    groupUrl: "https://example.test/groups/1",
  });
  assert.equal(msg.text, "🙋 Someone removed from *&lt;!channel&gt; &amp; co* asked to rejoin.");
  assert.deepEqual(msg.blocks[1], {
    type: "context",
    elements: [{ type: "mrkdwn", text: "The group owner can approve or dismiss it in <https://example.test/groups/1|App>." }],
  });
});

test("rejoinRequestMessage works without a group URL", () => {
  const msg = rejoinRequestMessage({ appName: "App", groupName: "Walkers" });
  assert.deepEqual(msg.blocks[1], {
    type: "context",
    elements: [{ type: "mrkdwn", text: "The group owner can approve or dismiss it in App." }],
  });
});
