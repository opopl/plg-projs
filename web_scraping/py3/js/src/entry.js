
// css
require('../../css/style.css');

// js
window.$ = require('jquery');

import { App } from './app.js';
//var app =  require('./app.js');

$(function(){
  window.app =  new App();
  app.run();
});

