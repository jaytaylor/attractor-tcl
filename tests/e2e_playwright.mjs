#!/usr/bin/env node

import { spawn, spawnSync } from "node:child_process";
import fs from "node:fs/promises";
import path from "node:path";
import process from "node:process";
import { chromium } from "playwright";

const scriptDir = path.dirname(new URL(import.meta.url).pathname);
const repoRoot = path.resolve(scriptDir, "..");
const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
const artifactRoot = process.env.E2E_PLAYWRIGHT_ARTIFACT_ROOT
  ? path.resolve(process.env.E2E_PLAYWRIGHT_ARTIFACT_ROOT)
  : path.join(repoRoot, ".scratch", "verification", "SPRINT-007", "playwright", `${timestamp}-${process.pid}`);
const runsRoot = path.join(artifactRoot, "runs");
const serverStdoutPath = path.join(artifactRoot, "server.stdout.log");
const serverStderrPath = path.join(artifactRoot, "server.stderr.log");
const screenshotPath = path.join(artifactRoot, "dashboard.png");
const screenshotsDir = path.join(artifactRoot, "screenshots");
const resultPath = path.join(artifactRoot, "result.json");

function resolveProviderAndModel() {
  if (process.env.OPENAI_API_KEY && process.env.OPENAI_API_KEY.trim() !== "") {
    return { provider: "openai", model: process.env.OPENAI_MODEL || "gpt-5.2" };
  }
  if (process.env.ANTHROPIC_API_KEY && process.env.ANTHROPIC_API_KEY.trim() !== "") {
    return { provider: "anthropic", model: process.env.ANTHROPIC_MODEL || "claude-haiku-4-5" };
  }
  if (process.env.GEMINI_API_KEY && process.env.GEMINI_API_KEY.trim() !== "") {
    return { provider: "gemini", model: process.env.GEMINI_MODEL || "gemini-3-flash-preview" };
  }
  throw new Error("no provider API key configured for Playwright e2e");
}

function resolveTclsh() {
  const configured = (process.env.TCLSH || "").trim();
  if (configured !== "") {
    return configured;
  }
  for (const candidate of ["tclsh9.0", "tclsh"]) {
    const probe = spawnSync("bash", ["-lc", `command -v ${candidate}`], { stdio: "ignore" });
    if (probe.status === 0) {
      return candidate;
    }
  }
  return "tclsh";
}

async function waitForServerReady(child, timeoutMs) {
  return await new Promise((resolve, reject) => {
    const start = Date.now();
    let buffer = "";
    let exited = false;

    const onData = (chunk) => {
      buffer += chunk.toString();
      const lines = buffer.split(/\r?\n/);
      buffer = lines.pop() || "";
      for (const line of lines) {
        const trimmed = line.trim();
        if (trimmed === "") {
          continue;
        }
        try {
          const parsed = JSON.parse(trimmed);
          if (parsed.status === "serving" && parsed.web_port) {
            resolve({ web_port: parsed.web_port });
            return;
          }
        } catch (_err) {
          // Ignore non-JSON log lines.
        }
      }
      if (Date.now() - start > timeoutMs && !exited) {
        reject(new Error(`timeout waiting for server readiness after ${timeoutMs}ms`));
      }
    };

    child.stdout.on("data", onData);
    child.on("exit", (code) => {
      exited = true;
      reject(new Error(`server exited before ready (code=${code})`));
    });
    setTimeout(() => {
      if (!exited) {
        reject(new Error(`timeout waiting for server readiness after ${timeoutMs}ms`));
      }
    }, timeoutMs + 50);
  });
}

async function main() {
  await fs.mkdir(artifactRoot, { recursive: true });
  await fs.mkdir(runsRoot, { recursive: true });
  await fs.mkdir(screenshotsDir, { recursive: true });

  const { provider, model } = resolveProviderAndModel();
  const tclsh = resolveTclsh();

  let baseUrl = process.env.E2E_PLAYWRIGHT_BASE_URL || "";
  let server = null;
  let serverStdout = null;
  let serverStderr = null;
  let step = "init";
  let page = null;
  const stageScreenshots = {};

  async function captureStep(name) {
    if (!page) return;
    const out = path.join(screenshotsDir, `${name}.png`);
    await page.screenshot({ path: out, fullPage: true });
    stageScreenshots[name] = out;
  }

  try {
    if (baseUrl === "") {
      const requestedPort = process.env.E2E_PLAYWRIGHT_PORT || String(17000 + (process.pid % 1000));
      serverStdout = await fs.open(serverStdoutPath, "w");
      serverStderr = await fs.open(serverStderrPath, "w");
      const useDocker = process.env.E2E_PLAYWRIGHT_USE_DOCKER === "1";
      if (useDocker) {
        const dockerArgs = [
          "run",
          "--rm",
          "-p",
          `${requestedPort}:7070`,
          "-e",
          "OPENAI_API_KEY",
          "-e",
          "ANTHROPIC_API_KEY",
          "-e",
          "GEMINI_API_KEY",
          "-e",
          "OPENAI_MODEL",
          "-e",
          "ANTHROPIC_MODEL",
          "-e",
          "GEMINI_MODEL",
          "-e",
          "OPENAI_BASE_URL",
          "-e",
          "ANTHROPIC_BASE_URL",
          "-e",
          "GEMINI_BASE_URL",
          "-v",
          `${repoRoot}:/work`,
          "-w",
          "/work",
          "ubuntu:24.04",
          "bash",
          "-lc",
          "apt-get update >/dev/null && DEBIAN_FRONTEND=noninteractive apt-get install -y tcl tcllib tcl-tls make ca-certificates >/dev/null && ${TCLSH:-tclsh} bin/attractor serve --bind 0.0.0.0 --web-port 7070 --runs-root .scratch/verification/SPRINT-007/playwright-server-runs"
        ];
        server = spawn("docker", dockerArgs, { cwd: repoRoot, env: process.env, stdio: ["ignore", "pipe", "pipe"] });
      } else {
        server = spawn(
          tclsh,
          ["bin/attractor", "serve", "--bind", "127.0.0.1", "--web-port", requestedPort, "--runs-root", runsRoot],
          { cwd: repoRoot, env: process.env, stdio: ["ignore", "pipe", "pipe"] }
        );
      }
      server.stdout.on("data", async (chunk) => {
        await serverStdout.write(chunk);
      });
      server.stderr.on("data", async (chunk) => {
        await serverStderr.write(chunk);
      });

      const ready = await waitForServerReady(server, 30000);
      baseUrl = `http://127.0.0.1:${process.env.E2E_PLAYWRIGHT_USE_DOCKER === "1" ? requestedPort : ready.web_port}`;
    }

    const browser = await chromium.launch({ headless: true });
    const context = await browser.newContext();
    page = await context.newPage();

    step = "open-dashboard";
    await page.goto(baseUrl, { waitUntil: "domcontentloaded", timeout: 30000 });
    await page.waitForSelector("text=Attractor Web Dashboard", { timeout: 60000 });
    await page.waitForSelector("#conn", { timeout: 60000 });
    await captureStep("01-open-dashboard");

    step = "generate-dot";
    await page.selectOption("#provider", provider);
    await page.fill("#model", model);
    await page.fill(
      "#dotPrompt",
      "Create a valid Attractor DOT pipeline with start, one codergen build node with a prompt, and exit. Return only DOT."
    );
    await page.click("#generateBtn");
    await page.waitForFunction(() => {
      const value = document.querySelector("#dot")?.value || "";
      const err = document.querySelector("#runErr")?.textContent || "";
      return value.trim().length > 0 || err.trim().length > 0;
    }, null, { timeout: 120000 });
    {
      const errText = (await page.textContent("#runErr")) || "";
      if (errText.trim() !== "") {
        throw new Error(`generate-dot error: ${errText.trim()}`);
      }
      const dotText = (await page.inputValue("#dot")) || "";
      if (!/^\s*digraph\b/.test(dotText)) {
        throw new Error(`generate-dot returned non-DOT payload: ${dotText.slice(0, 200)}`);
      }
    }
    await captureStep("02-generate-dot");

    step = "preview-dot";
    await page.click("#previewBtn");
    await page.waitForSelector("#graph svg", { timeout: 15000 });
    await captureStep("03-preview-dot");

    step = "iterate-dot";
    await page.fill("#dotChanges", "Add a review gate node before exit.");
    await page.click("#iterateBtn");
    await page.waitForFunction(() => {
      const value = document.querySelector("#dot")?.value || "";
      const err = document.querySelector("#runErr")?.textContent || "";
      return value.trim().length > 0 || err.trim().length > 0;
    }, null, { timeout: 120000 });
    {
      const errText = (await page.textContent("#runErr")) || "";
      if (errText.trim() !== "") {
        throw new Error(`iterate-dot error: ${errText.trim()}`);
      }
      const dotText = (await page.inputValue("#dot")) || "";
      if (!/^\s*digraph\b/.test(dotText)) {
        throw new Error(`iterate-dot returned non-DOT payload: ${dotText.slice(0, 200)}`);
      }
    }
    await captureStep("04-iterate-dot");

    step = "fix-dot";
    await page.fill("#dotFixErr", "syntax error near ';'");
    await page.click("#fixBtn");
    await page.waitForFunction(() => {
      const value = document.querySelector("#dot")?.value || "";
      const err = document.querySelector("#runErr")?.textContent || "";
      return value.trim().length > 0 || err.trim().length > 0;
    }, null, { timeout: 120000 });
    {
      const errText = (await page.textContent("#runErr")) || "";
      if (errText.trim() !== "") {
        throw new Error(`fix-dot error: ${errText.trim()}`);
      }
      const dotText = (await page.inputValue("#dot")) || "";
      if (!/^\s*digraph\b/.test(dotText)) {
        throw new Error(`fix-dot returned non-DOT payload: ${dotText.slice(0, 200)}`);
      }
    }
    await captureStep("05-fix-dot");

    step = "set-known-good-dot";
    await page.fill(
      "#dot",
      "digraph web_e2e { start [shape=Mdiamond]; build [handler=codergen, prompt=\"Say hello in one sentence.\"]; exit [shape=Msquare]; start -> build; build -> exit [label=success, weight=1]; }"
    );
    await captureStep("06-set-known-good-dot");

    step = "start-run";
    await page.click("#runBtn");
    await page.waitForFunction(() => {
      const title = document.querySelector("#title")?.textContent || "";
      return title.startsWith("Run ");
    }, null, { timeout: 60000 });
    await captureStep("07-run-started");

    step = "await-run-complete";
    await page.waitForFunction(() => {
      const summary = document.querySelector("#summary")?.textContent || "";
      return /Status:\s+(success|failed)/i.test(summary);
    }, null, { timeout: 180000 });
    {
      const summaryText = (await page.textContent("#summary")) || "";
      if (!/Status:\s+success/i.test(summaryText)) {
        const errText = ((await page.textContent("#runErr")) || "").trim();
        throw new Error(`run did not succeed: summary=${summaryText.trim()}${errText ? ` error=${errText}` : ""}`);
      }
    }

    step = "await-run-events";
    await page.waitForFunction(() => {
      const events = document.querySelector("#events")?.textContent || "";
      return events.includes("PipelineStarted") && events.includes("PipelineCompleted");
    }, null, { timeout: 60000 });
    await page.waitForFunction(() => {
      const stage = document.querySelector("#stage")?.textContent || "";
      return stage.trim() !== "" && stage.trim() !== "(none)";
    }, null, { timeout: 30000 });
    await captureStep("08-run-completed");

    await page.screenshot({ path: screenshotPath, fullPage: true });

    await fs.writeFile(
      resultPath,
      JSON.stringify(
        {
          status: "passed",
          base_url: baseUrl,
          provider,
          model,
          artifact_root: artifactRoot,
          step,
          screenshot: screenshotPath,
          screenshots: stageScreenshots,
          runs_root: runsRoot
        },
        null,
        2
      )
    );

    await context.close();
    await browser.close();
    console.log(`playwright-e2e ok artifact_root=${artifactRoot}`);
  } catch (err) {
    try {
      if (page) {
        await page.screenshot({ path: screenshotPath, fullPage: true });
      }
    } catch (_screenshotErr) {
      // Best-effort failure evidence.
    }
    await fs.writeFile(
      resultPath,
      JSON.stringify(
        {
          status: "failed",
          base_url: baseUrl,
          provider,
          model,
          artifact_root: artifactRoot,
          step,
          error: String(err && err.message ? err.message : err)
        },
        null,
        2
      )
    );
    throw err;
  } finally {
    if (server) {
      server.kill("SIGTERM");
    }
    if (serverStdout) {
      await serverStdout.close();
    }
    if (serverStderr) {
      await serverStderr.close();
    }
  }
}

main().catch((err) => {
  console.error(`playwright-e2e failed: ${err.message || err}`);
  process.exit(1);
});
