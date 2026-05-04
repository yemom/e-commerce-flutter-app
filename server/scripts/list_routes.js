#!/usr/bin/env node
const path = require('path');
process.chdir(path.resolve(__dirname, '..'));
const { buildApp } = require('../app');
const app = buildApp();
const routes = [];
app._router.stack.forEach((layer) => {
  if (layer.route && layer.route.path) {
    const methods = Object.keys(layer.route.methods).join(',');
    routes.push(`${methods.toUpperCase()} ${layer.route.path}`);
  } else if (layer.name === 'router' && layer.regexp) {
    routes.push(`MOUNT ${layer.regexp}`);
  }
});
console.log(routes.join('\n'));
