import test from "node:test";
import assert from "node:assert/strict";
import request from "supertest";
import { createServer } from "../src/server.js";

test("GET /healthz returns ok", async () => {
  const app = createServer();
  const res = await request(app).get("/healthz");
  assert.equal(res.status, 200);
  assert.deepEqual(res.body, { status: "ok" });
});
