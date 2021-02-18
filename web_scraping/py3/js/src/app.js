
var pretty = require('pretty');
var util = require('./util.js');
//
require('webpack-jquery-ui');
require('webpack-jquery-ui/css');

function App(){

  this.set_header = function(){

      //var header = document.createElement('div');
      //header.className = 'flex-header';
      //this.$header = $(header);

      this.$header = $('<div/>').addClass('flex-header');

      var els = [
        this.$$btn({
          value : 'Reload',
          id    : 'btn_reload',
        }),
        this.$$input({
          id  : 'inp_css_delete',
          plc : 'CSS (Del)',
          css : {
            'background-color' : 'red',
            'color'            : 'white',
          }
        }),
        this.$$input({
          id  : 'inp_css_show',
          plc : 'CSS (Show)',
          css : {
            'background-color' : 'blue',
            'color'            : 'white',
          }
        }),
        this.$$input({
          id  : 'inp_xpath_delete',
          plc : 'XPATH (Del)',
          css : {
            'background-color' : 'red',
            'color'            : 'white',
          }
        }),
        this.$$input({
          id  : 'inp_xpath_show',
          plc : 'XPATH (Show)',
          css : {
            'background-color' : 'blue',
            'color'            : 'white',
          }
        }),
      ];

      for (let el of els) {
        this.$header.append(el);
      };

      return this;
  };

  this.reload = function(){
      window.location.reload(false);
      return this;
  };

  this.set_pane = function(){

      this.$pane = $('<div/>').addClass('flex-header');

      this.$pane.css({ background : 'green' });

      var els = [];

      var tipes = 'log core clean dbrid img img_clean'.split(' ');

      for(let tipe of tipes ){
         let href = tipe + '.html';

         let css = { width : '5%' };
         if (tipe == this.tipe) {
           css['background-color'] = 'blue';
         }
         els.push(
            this.$$a_href({
              href : href,
              txt  : tipe,
              id   : 'href_' + tipe,
              css  : css,
            }),
         );
      }

      els.push(
            this.$$input({
              plc  : 'RID',
              id   : 'inp_rid',
              css  : {
                width : '5%',
                'background-color' : 'white',
                'color'            : 'black',
              },
              txt : util.get(this,'rid'),
            }),
      );

      for (let el of els) {
        this.$pane.append(el);
      };

      return this;
  };

  this.$$btn = function(ref={}){
      var value = util.get(ref,'value','');
      var id    = util.get(ref,'id','');
      var css   = util.get(ref,'css',{});

      var btn = document.createElement('input');
      btn.type  = 'button';

      if (id) { btn.id = id; }
      if (value) { btn.value = value; }

      $(btn).addClass('block').css({ 
        width: '10%',
        ...css
      });

      return $(btn);
  };

  this.$$a_href = function(ref={}){

      var href  = util.get(ref,'href','');
      var txt   = util.get(ref,'txt','');
      var css   = util.get(ref,'css',{});

      var $a = $('<a/>');

      if (txt) { $a.text(txt); }
      if (href) { $a.attr({ href : href }); }

      $a.addClass('block').css({ 
        width: '10%',
        ...css
      });

      return $a;
  };

  this.$$select = function(ref={}){
      var $slc = $('<select/>');

      return $slc;
  };

  this.$$input = function(ref={}){

      var id  = util.get(ref,'id');
      var plc = util.get(ref,'plc');
      var txt = util.get(ref,'txt');
      var css = util.get(ref,'css',{});

      var inp = document.createElement('input');

      inp.type  = 'text';

      if (id) { inp.id = id; }
      if (plc) { inp.placeholder = plc; }
      if (txt) { inp.value = txt; }

      $(inp)
        .addClass('block')
        .css({ 
           width              : '10%',
           'color'            : 'white',
           'background-color' : 'white',
           'font-size'        : '25px',
           'justify-content'  : 'space-between',
           ...css
        });

      return $(inp);
  };

  this.on_enter = function(){
      //this
        //.on_enter_css_show()
        //.on_enter_css_delete()
        //;

      this
        .register_on_enter('#inp_css_show',this.func_enter_css_show())
        .register_on_enter('#inp_css_delete',this.func_enter_css_delete())
        .register_on_enter('#inp_rid',this.func_enter_rid())
        ;

      return this;
  };

  this.register_on_enter = function(sel,func){

     var $i = $(sel);

     $i.bind("enterKey",func);

     $i.keyup(function(e){
        if(e.keyCode == 13) {
            $(this).trigger("enterKey");
        }
     });

     return this;
  };

  this.func_enter_rid = function(){

     return function(e){
        var rid = $(this).val();

        window.location = "../" + rid + "/clean.html";
     };

     return this;
  };

  this.func_enter_css_delete = function(){
     var $slf = this;

     return function(e){
        var css = $(this).val();

        if (!css) {
          $slf.reload();
          return;
        }

        $slf.$html_clone.find(css).remove();

        $slf.update_left();
        $slf.$right.find('pre').text($slf._code($slf.$html_clone));

        //$slf.$left.children().remove();
        //$slf.$html_clone.find('body').children().each(function(){
           //$slf.$left.append($(this).clone());
        //});

     };

     return this;
  };

  this.func_enter_css_show = function(){
     var $slf = this;

     return function(e){
        var css = $(this).val();

        if (!css) {
          $slf.reload();
          return;
        }

        $slf.$left.children().remove();

        var $found = $slf.$html_clone.find(css).clone();

        $slf.$right.find('pre').text('');

        var _txt = '';
        $found.each(function(){
           var _el = $(this);
           //$slf.$left.append(_el);

           _txt += $slf._code(_el) + '\n';
        });

        $slf.update_left({ html : _txt });

        $slf.$right.find('pre').text( _txt );

     };

     return this;
  };

  this.on_click = function(){
     let $slf = this;
     $('#btn_reload').on('click',function() {
        $slf.reload();
     });

     return this;
  };

  this.set_right = function(ref={}){

    var right = document.createElement('div');
    right.className = 'flex-right';

    var code = document.createElement('div');
    code.className = 'code';
  
    var pre = document.createElement('pre');
    $(code).append($(pre));
  
    $(pre).text(this._code(this.$html_clone));
  
    $(right).append($(code));

    this.$right = $(right);

    return this;
  };

  this._code = function(el){
    var html = $(el).wrap('<div/>').parent().html();
    html = pretty(html);

    return html;
  };

  this.update_left = function(ref={}){
    let html = util.get(ref,'html',null);

    if (html == null) {
      let el = this.$html_clone;
      el = util.get(ref,'el',el);
  
      html = this._code(el);
    }

    let src = 'data:text/html;charset=utf-8,' + html;
    this.$left.attr({ src : src });

    return this;
  };

  this.set_left = function(ref={}){

    this.$left = $('<iframe/>');
    this.$left.addClass('flex-left');

    this.update_left();

    //var $slf = this;

/*    this.$left = $('<div/>');*/
    //this.$left.addClass('flex-left');

    //this.$body_clone.children().each(function(){
       //$slf.$left.append($(this).clone());
    /*});*/

    return this;
  };

/*  this.set_pane_links = function(){*/
      //var pane = document.createElement('div');
      //pane.className = 'flex-header';

      //var a = document.createElement('a');
      //a.href  = '../core.html';
      //a.textContent = 'CORE';
      //$(a).addClass('block').css({ width: '10%' });
    
      //$(pane).append($(a));

      //this.$pane_links = $(pane);

    //return this;
  /*};*/

  this.set_container = function(){
      var container = document.createElement('div');
      container.className = 'flex-container';

      this.$container = $(container);

      this.$container.append( this.$left );
      this.$container.append( this.$right );

      return this;
  };

  this.body_append = function(){
  
    if ('core clean'.split(' ').includes(this.tipe)) {
      $('body').children().remove();
      $('body').append(this.$pane);
      $('body').append(this.$header);
      $('body').append(this.$container);
      return this;
    }

    $('body').prepend(this.$pane);

    return this;
  };

  this.copy_html = function(){
    this.$html_bare = $('html').clone();

    this.$body_clone = $('body').clone();

    this.$html_clone = $('html').clone();
    this.$html_clone.find('style,meta').remove();

    return this;
  };

  this.events = function(){

    this
        .on_click()
        .on_enter()
    ;

    return this;
  };

  this.parse_url = function(){

    var parts = this.url_path.split('/');
    var last = parts.pop();
    
    this.rid = parts.pop();

    var m = last.match(/(\w+)\.html$/);
    if (m) { this.tipe = m[1]; }

    return this;
  };

  this.run = function(){
    console.log('[App] start run');

    this.url$ = new URL(window.location);
    this.url_path = this.url$.pathname;

    this
        .parse_url()
        .copy_html()
        .set_header()
        .set_pane()
        .set_left()
        .set_right()
        .set_container()
        .body_append()
        .events()
     ;

    return this;
  }

}

//eof
module.exports = { App }
//export default App

