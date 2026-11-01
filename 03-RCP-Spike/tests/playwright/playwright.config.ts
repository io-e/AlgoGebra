// CLAUDE_V1 — Playwright config for W-09 course tree browser tests
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: '.',
  outputDir: '../results/playwright',
  timeout: 60_000,
  expect: { timeout: 10_000 },
  retries: 0,
  reporter: [
    ['list'],
    ['json', { outputFile: '../results/playwright/w09-results.json' }],
    ['html', { open: 'never', outputFolder: '../results/playwright/html-report' }],
  ],
  use: {
    baseURL: 'http://localhost:4173',
    screenshot: 'on',
    trace: 'retain-on-failure',
    video: 'retain-on-failure',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },
    {
      name: 'mobile-safari',
      use: { ...devices['iPhone 13'] },
    },
  ],
  webServer: {
    command: 'npx --yes serve -p 4173 ../../../../web-host',
    port: 4173,
    reuseExistingServer: true,
    timeout: 15_000,
  },
});
