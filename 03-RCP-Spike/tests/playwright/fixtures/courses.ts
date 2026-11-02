// CLAUDE_V1 — Shared fixtures for W-09 Playwright tests
import { test as base, expect, type Page } from '@playwright/test';

export interface CourseFixtures {
  coursePage: Page;
}

export const test = base.extend<CourseFixtures>({
  coursePage: async ({ page }, use) => {
    await page.goto('/course-host.html');
    await use(page);
  },
});

export { expect };

// GROK_V1: wait for the API AND a warm CAS (evalCommandCAS returns '?' for a few seconds after load)
export async function waitForAppletReady(page: Page, timeoutMs = 45_000): Promise<void> {
  await page.waitForFunction(
    () => {
      const applet = (window as any).ggbApplet;
      if (!applet || typeof applet.evalCommandCAS !== 'function') return false;
      try { return applet.evalCommandCAS('1+1') === '2'; } catch { return false; }
    },
    undefined,
    { timeout: timeoutMs, polling: 500 },
  );
}

// GROK_V1: tree is loaded asynchronously after ggbOnInit; step nodes carry data-step-index
export function stepButtons(page: Page) {
  return page.locator('#tree-root button[data-step-index]');
}
export async function waitForCourseLoaded(page: Page, timeoutMs = 20_000): Promise<void> {
  await expect(stepButtons(page).first()).toBeVisible({ timeout: timeoutMs });
}

export async function evalCAS(page: Page, expr: string): Promise<string> {
  return page.evaluate(
    (e) => (window as any).ggbApplet.evalCommandCAS(e),
    expr,
  );
}

export async function evalCommand(page: Page, cmd: string): Promise<boolean> {
  return page.evaluate(
    (c) => (window as any).ggbApplet.evalCommand(c),
    cmd,
  );
}

export async function objectExists(page: Page, name: string): Promise<boolean> {
  return page.evaluate(
    (n) => (window as any).ggbApplet.exists(n),
    name,
  );
}
