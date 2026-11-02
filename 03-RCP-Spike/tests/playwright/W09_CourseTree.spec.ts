// CLAUDE_V1 — W-09 Course Tree browser tests (PW-W09-01..10)
// Requires: self-hosted GWT WAR under web-host/GeoGebra/ + HTTP server on :4173
// Evidence: screenshots + traces under 03-RCP-Spike/results/playwright/
// Reference: Handoff_CLAUDE_by_GROK_V1_1.md §3.3
import { test, expect, waitForAppletReady, waitForCourseLoaded, stepButtons, evalCAS, evalCommand, objectExists } from './fixtures/courses';

test.describe('W-09 Course Tree — Web Host', () => {

  // PW-W09-01: page loads, applet host visible, no remote load failure
  test('PW-W09-01 page loads with local applet host', async ({ coursePage }) => {
    const appletHost = coursePage.locator('#applet1');
    await expect(appletHost).toBeVisible({ timeout: 15_000 });

    const consoleErrors: string[] = [];
    coursePage.on('console', (msg) => {
      if (msg.type() === 'error') consoleErrors.push(msg.text());
    });

    // Brief wait to catch late console errors
    await coursePage.waitForTimeout(2_000);
    const remoteFailures = consoleErrors.filter((e) => e.includes('geogebra.org'));
    expect(remoteFailures).toHaveLength(0);
  });

  // PW-W09-02: CAS readiness (1+1 = 2), no stray algebra object
  test('PW-W09-02 CAS readiness check', async ({ coursePage }) => {
    await waitForAppletReady(coursePage);

    const result = await evalCAS(coursePage, '1+1');
    expect(result.trim()).toBe('2');

    // Readiness probe must not create a visible algebra object named "2"
    const has2 = await objectExists(coursePage, '2');
    expect(has2).toBe(false);
  });

  // PW-W09-03: tree renders at least 5 chapters for trig course
  test('PW-W09-03 tree has chapters', async ({ coursePage }) => {
    await waitForAppletReady(coursePage);

    // GROK_V1: top-level chapters only (nested steps are treeitems too)
    await waitForCourseLoaded(coursePage);
    const treeItems = coursePage.locator('#tree-root > [role="treeitem"]');
    const count = await treeItems.count();
    expect(count).toBeGreaterThanOrEqual(5);
  });

  // PW-W09-04: select step 1.1 + run → point O exists
  test('PW-W09-04 run step 1.1 creates point O', async ({ coursePage }) => {
    await waitForAppletReady(coursePage);

    // Click first step (chapter 1, step 1) - GROK_V1: step button, not the chapter treeitem
    await waitForCourseLoaded(coursePage);
    const firstStep = stepButtons(coursePage).first();
    await firstStep.click();

    const runBtn = coursePage.locator('#btn-run');
    await expect(runBtn).toBeEnabled({ timeout: 5_000 });
    await runBtn.click();

    // Wait for command execution
    await coursePage.waitForTimeout(1_000);
    const exists = await objectExists(coursePage, 'O');
    expect(exists).toBe(true);

    // Button should re-enable after execution
    await expect(runBtn).toBeEnabled({ timeout: 5_000 });
  });

  // PW-W09-05: step 1.2 creates a circle
  test('PW-W09-05 run step 1.2 creates circle', async ({ coursePage }) => {
    await waitForAppletReady(coursePage);

    // Run step 1.1 first (prerequisite)
    await waitForCourseLoaded(coursePage);
    const steps = stepButtons(coursePage);
    await steps.first().click();
    await coursePage.locator('#btn-run').click();
    await coursePage.waitForTimeout(500);

    // Now step 1.2
    await steps.nth(1).click();
    await coursePage.locator('#btn-run').click();
    await coursePage.waitForTimeout(1_000);

    const circleExists = await objectExists(coursePage, 'c');
    expect(circleExists).toBe(true);
  });

  // PW-W09-06: CAS identity check step returns pass
  test('PW-W09-06 CAS identity check passes', async ({ coursePage }) => {
    await waitForAppletReady(coursePage);

    const result = await evalCAS(coursePage, 'Simplify(cos(x)^2+sin(x)^2)');
    expect(result.trim()).toBe('1');
  });

  // PW-W09-07: Execute command is blocked by security layer
  test('PW-W09-07 Execute command is blocked', async ({ coursePage }) => {
    await waitForAppletReady(coursePage);

    const blocked = await coursePage.evaluate(() => {
      const ct = (window as any).courseTree;
      return ct && typeof ct.isCommandBlocked === 'function'
        ? ct.isCommandBlocked('Execute("Delete(A)")')
        : null;
    });
    expect(blocked).toBe(true);
  });

  // PW-W09-08: path traversal is rejected
  test('PW-W09-08 path traversal rejected', async ({ coursePage }) => {
    const safe = await coursePage.evaluate(() => {
      const ct = (window as any).courseTree;
      return ct && typeof ct.isOpenPathSafe === 'function'
        ? ct.isOpenPathSafe('../../etc/passwd')
        : null;
    });
    expect(safe).toBe(false);
  });

  // PW-W09-09: keyboard navigation (ArrowDown + Enter)
  test('PW-W09-09 keyboard navigation works', async ({ coursePage }) => {
    await waitForAppletReady(coursePage);

    const treeRoot = coursePage.locator('#tree-root');
    await treeRoot.focus();
    await coursePage.keyboard.press('ArrowDown');
    await coursePage.keyboard.press('ArrowDown');
    await coursePage.keyboard.press('Enter');

    // No freeze: page should still respond within 3s
    await expect(coursePage.locator('#status-bar')).toBeVisible({ timeout: 3_000 });
  });

  // PW-W09-10: mobile viewport — toggle button visible, sidebar toggles
  test('PW-W09-10 mobile responsive layout', async ({ browser }) => {
    const context = await browser.newContext({
      viewport: { width: 375, height: 667 },
    });
    const page = await context.newPage();
    await page.goto('/course-host.html');

    const mobileToggle = page.locator('#mobile-tree-toggle');
    await expect(mobileToggle).toBeVisible({ timeout: 5_000 });

    // Toggle should show/hide the sidebar
    await mobileToggle.click();
    const sidebar = page.locator('#course-tree');
    // After toggle, sidebar visibility should change
    // GROK_V1: the sidebar slides off-canvas via CSS transform, so isVisible() never changes; assert the .open state
    await expect(sidebar).toHaveClass(/(^|\s)open(\s|$)/);
    await mobileToggle.click();
    await expect(sidebar).not.toHaveClass(/(^|\s)open(\s|$)/);

    await context.close();
  });

});
