#!/usr/bin/env node
/**
 * setup-secrets.js — One-command GitHub Actions secrets setup
 *
 * Sets up secrets for openarcade-storefront dual deploy.
 * Can use EITHER VERCEL_TOKEN (classic) OR DEPLOY_HOOK_URL (hook-based, no token).
 *
 * Prerequisites:
 *   GITHUB_TOKEN (always required)
 *
 * Option A — Vercel token-based auth (set all three):
 *   VERCEL_TOKEN, VERCEL_ORG_ID, VERCEL_PROJECT_ID
 *
 * Option B — Vercel deploy hook (no token needed):
 *   DEPLOY_HOOK_URL
 *
 * Optional:
 *   COOLIFY_DEPLOY_URL  — Coolify deploy webhook URL
 *
 * Usage:
 *   node scripts/setup-secrets.js
 *
 * This script sets secrets for isaalia/openarcade-storefront.
 * It uses libsodium-wrappers for GitHub's required encryption.
 */
const https = require("https");
const REPO = "isaalia/openarcade-storefront";
// Also set for developer-portal if it exists:
const SECONDARY_REPO = "isaalia/openarcade-developer-portal";

const REQUIRED_VARS = ["GITHUB_TOKEN"];

async function main() {
  console.log("=== OpenArcade — GitHub Secrets Setup ===\n");

  // Check required env vars
  for (const v of REQUIRED_VARS) {
    if (!process.env[v]) {
      console.error(`❌ ERROR: ${v} is not set`);
      process.exit(1);
    }
  }

  const secrets = {};

  // Option A: Vercel token-based auth
  if (process.env.VERCEL_TOKEN && process.env.VERCEL_ORG_ID && process.env.VERCEL_PROJECT_ID) {
    secrets.VERCEL_TOKEN = process.env.VERCEL_TOKEN;
    secrets.VERCEL_ORG_ID = process.env.VERCEL_ORG_ID;
    secrets.VERCEL_PROJECT_ID = process.env.VERCEL_PROJECT_ID;
    console.log("📋 Mode: Vercel token-based deploy");
  } else {
    console.log("ℹ️  VERCEL_TOKEN/ORG/PROJECT not set — skipping Vercel token secrets");
  }

  // Option B: Vercel deploy hook (no token needed)
  if (process.env.DEPLOY_HOOK_URL) {
    secrets.DEPLOY_HOOK_URL = process.env.DEPLOY_HOOK_URL;
    console.log("📋 Mode: Vercel deploy hook (no token)");
  }

  if (Object.keys(secrets).length === 0 && !process.env.COOLIFY_DEPLOY_URL) {
    console.error("❌ No secrets to set. Set VERCEL_TOKEN+VERCEL_ORG_ID+VERCEL_PROJECT_ID, DEPLOY_HOOK_URL, or COOLIFY_DEPLOY_URL");
    process.exit(1);
  }

  if (process.env.COOLIFY_DEPLOY_URL) {
    secrets.COOLIFY_DEPLOY_URL = process.env.COOLIFY_DEPLOY_URL;
  }

  const repos = [REPO];
  // Check if secondary repo exists
  try {
    const code = await httpRequest("HEAD", `/repos/${SECONDARY_REPO}`, null, true);
    if (code !== 404) repos.push(SECONDARY_REPO);
  } catch {
    // secondary repo not accessible, skip
  }

  for (const repo of repos) {
    console.log(`📦 Repo: ${repo}`);

    // Get public key
    const keyData = await ghRequest("GET", `/repos/${repo}/actions/secrets/public-key`);
    const keyId = keyData.key_id;
    const key = keyData.key;

    console.log(`  Public key ID: ${keyId}`);

    // Load libsodium
    const sodium = require("libsodium-wrappers");
    await sodium.ready;

    for (const [name, value] of Object.entries(secrets)) {
      console.log(`  🔐 Setting ${name}...`);
      const keyBytes = Buffer.from(key, "base64");
      const valueBytes = Buffer.from(value);
      const encryptedBytes = sodium.crypto_box_seal(valueBytes, keyBytes);
      const encryptedValue = Buffer.from(encryptedBytes).toString("base64");

      const body = JSON.stringify({
        encrypted_value: encryptedValue,
        key_id: keyId,
      });

      const status = await ghRequest(
        "PUT",
        `/repos/${repo}/actions/secrets/${name}`,
        body,
        true
      );
      const ok = status === 201 || status === 204;
      console.log(`  ${ok ? "✅" : "⚠️"} ${name} (HTTP ${status})`);
    }
    console.log("");
  }

  console.log("✅ Done!");
  console.log("\nNext steps:");
  console.log("  1. Push to main → triggers deploy-vercel.yml (or deploy-hook.yml) workflow");
  console.log("  2. Verify at https://openarcade-storefront.vercel.app");
  console.log("  3. Check GitHub Actions: https://github.com/isaalia/openarcade-storefront/actions");
  console.log("");
  console.log("Secrets set: " + Object.keys(secrets).join(", "));
  if (secrets.DEPLOY_HOOK_URL) {
    console.log("\n📌 Deploy hook mode active — deploys trigger via webhook, no VERCEL_TOKEN needed.");
    console.log("   The workflow at .github/workflows/deploy-hook.yml will run on push.");
  }
  if (secrets.VERCEL_TOKEN) {
    console.log("\n📌 Token mode active — deploy-vercel.yml will deploy via Vercel CLI.");
  }
}

/** Make a JSON-parsed GitHub API request */
function ghRequest(method, path, body) {
  return new Promise((resolve, reject) => {
    const opts = {
      hostname: "api.github.com",
      path,
      method,
      headers: {
        Authorization: `Bearer ${process.env.GITHUB_TOKEN}`,
        "User-Agent": "openarcade-setup-secrets",
        Accept: "application/vnd.github.v3+json",
      },
    };
    if (body) {
      opts.headers["Content-Type"] = "application/json";
      opts.headers["Content-Length"] = Buffer.byteLength(body);
    }
    const req = https.request(opts, (res) => {
      let data = "";
      res.on("data", (c) => (data += c));
      res.on("end", () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          try {
            resolve(JSON.parse(data));
          } catch {
            resolve(data || res.statusCode);
          }
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${data.slice(0, 200)}`));
        }
      });
    });
    req.on("error", reject);
    if (body) req.write(body);
    req.end();
  });
}

// simple status-code-only version
function httpRequest(method, path, body) {
  return new Promise((resolve, reject) => {
    const opts = {
      hostname: "api.github.com",
      path,
      method,
      headers: {
        Authorization: `Bearer ${process.env.GITHUB_TOKEN}`,
        "User-Agent": "openarcade-setup-secrets",
      },
    };
    const req = https.request(opts, (res) => {
      let data = "";
      res.on("data", (c) => (data += c));
      res.on("end", () => resolve(res.statusCode));
    });
    req.on("error", reject);
    if (body) req.write(body);
    req.end();
  });
}

main().catch((err) => {
  console.error("❌ Error:", err.message);
  process.exit(1);
});
