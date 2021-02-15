
// css
require('../../css/style.css');

// js
window.$ = require('jquery');

var App = require('./app.js');

$(function(){
  window.app =  new App();
  app.run();
});

