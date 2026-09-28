// Verificação local do artefacto de pesquisa. Requer Playwright já instalado.
const { chromium } = require(process.env.TRAINFORGE_PLAYWRIGHT_PATH || 'playwright');
const fs = require('node:fs');
const path = require('node:path');
(async () => {
  const browser = await chromium.launch({ headless: true, executablePath: process.env.TRAINFORGE_BROWSER_PATH });
  try {
    const page = await browser.newPage();
    const errors=[]; page.on('pageerror', e => errors.push(e.message));
    const results=[];
    for (const viewport of [{width:1280,height:1000},{width:390,height:844}]) {
      await page.setViewportSize(viewport);
      await page.goto(process.env.TRAINFORGE_GUIDE_URL || 'http://127.0.0.1:8747/guia-rotulos.html');
      await page.locator('h1').waitFor();
      const layout = await page.evaluate(() => ({bodyWidth:document.documentElement.scrollWidth,viewportWidth:innerWidth,lessons:document.querySelectorAll('.lesson').length,tableRows:document.querySelectorAll('tbody tr').length,notice:document.querySelector('.notice').textContent}));
      if(layout.bodyWidth>layout.viewportWidth || layout.lessons!==12 || layout.tableRows!==9 || !layout.notice.includes('fictícios'))throw Error('Falha de apresentação: '+JSON.stringify(layout));
      await page.screenshot({path:path.join(__dirname,'../raw/n07-guia-'+viewport.width+'.png')});
      await page.locator('summary').first().click();
      if(await page.locator('details').first().getAttribute('open')===null)throw Error('Detalhe não abriu');
      results.push({viewport,...layout,detailToggleWorks:true});
    }
    if(errors.length)throw Error(errors.join(';'));
    const result={tool:'Playwright local headless; runtime existente; sem perfil do utilizador',date:'2026-09-28',checks:results,pageErrors:errors,screenCaptures:'../raw/n07-guia-{1280,390}.png; locais, não versionadas',scope:'Referência HTML; não Figma nem app. Acesso somente à página local; não testa links externos.'};
    fs.writeFileSync(path.join(__dirname,'validacao-visual.json'),JSON.stringify(result,null,2)+'\n');
    console.log(JSON.stringify({verifiedViewports:results.length,pageErrors:errors.length}));
  } finally { await browser.close(); }
})().catch(e=>{console.error(e.message);process.exitCode=1});
