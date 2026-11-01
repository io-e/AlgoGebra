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

export async function waitForAppletReady(page: Page, timeoutMs = 30_000): Promise<void> {
  await page.waitForFunction(
    () => {
      const applet = (window as any).ggbApplet;
      return applet && typeof applet.evalCommandCAS === 'function';
    },
    { timeout: timeoutMs },
  );
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
