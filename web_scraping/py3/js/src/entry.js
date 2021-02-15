
// css
require('../../css/style.css');

// js
window.$ = require('jquery');

import { App } from './app.js';

$(function(){
  window.app =  new App();
  app.run();
});

