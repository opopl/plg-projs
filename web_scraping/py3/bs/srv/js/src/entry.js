
// css
require('../../css/style.css');
require('../../css/form.css');
require('../../css/dropdown.css');

// js
//window.$ = require('jquery');
require('webpack-jquery-ui');
require('webpack-jquery-ui/css');


import { App } from './appa.js';
//var app =  require('./app.js');

$(function(){
  window.app =  new App();
  app.run();
});

