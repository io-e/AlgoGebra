import { firefox } from '@playwright/test';
const b = await firefox.launch({ headless: true });
const p = await b.newPage();
await p.goto('file:///tmp/ffsmoke/page.html');
console.log('title=' + await p.title() + ' version=' + b.version() + ' ua=' + await p.evaluate(() => navigator.userAgent));
await p.screenshot({ path: '/tmp/ffsmoke/firefox_smoke_GROK_V1.png' });
await b.close();
