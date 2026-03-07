const https = require('https');
const url = 'https://gestion.colegiowinterhill.cl/';

https.get(url, (res) => {
  let body = '';
  res.on('data', d => body += d);
  res.on('end', () => {
    // Extract script and CSS tags
    const scripts = body.match(/src="[^"]+\.js"/g) || [];
    const cssLinks = body.match(/href="[^"]+\.css"/g) || [];
    console.log('HTTP Status:', res.statusCode);
    console.log('Scripts found:', scripts.length);
    scripts.forEach(s => console.log('  ', s));
    console.log('CSS links:', cssLinks.length);
    cssLinks.forEach(c => console.log('  ', c));
    
    // Check if the main chunk names match what we expect
    const mainScript = scripts.find(s => s.includes('/assets/index-'));
    console.log('\nMain JS bundle:', mainScript || 'NOT FOUND');
    
    // Check for modulepreload hints
    const preloads = body.match(/modulepreload[^>]+href="[^"]+"/g) || [];
    console.log('\nPreloaded modules:', preloads.length);
    preloads.forEach(p => console.log('  ', p));
  });
}).on('error', e => console.error('Error:', e.message));
