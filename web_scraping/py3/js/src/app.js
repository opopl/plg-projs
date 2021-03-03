
var pretty = require('pretty');
var util = require('./util.js');
//

//const fs = require('fs-extra');
const yaml = require('js-yaml');

function App(){

  this.set_header = function(){
    console.log('[App] set_header');

      //var header = document.createElement('div');
      //header.className = 'flex-row';
      //this.$header = $(header);

      this.$header = $('<div/>').addClass('flex-row');

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

  this.set_foot = function(){
      this.$foot = $('<div/>').addClass('flex-row');
      this.$foot.css({ background : 'green' });

      return this;
  };

  this.set_pane = function(){

      this.$pane = $('<div/>').addClass('flex-row');
      this.$pane.css({ background : 'green' });

      var els = [];

      var tipes = 'log dbrid cache core core_clean clean img img_clean'.split(' ');

      els.push(
            this.$$select({
              id : 'menu_tipes',
              css : {
                width : '50px',
              },
              items    : tipes,
              selected : this.tipe,
            })
      );

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

  this.$$select = function(ref={}){
      var id    = util.get(ref,'id','');
      var items = util.get(ref,'items',[]);
      var css   = util.get(ref,'css',{});

      var selected   = util.get(ref,'selected','');

      var $slc = $('<select/>');
      $slc
       .addClass('block')
       .css({ 
           width              : '100px',
           'background-color' : 'white',
           'color'            : 'black',
           ...css
       });

      if (id) { $slc.attr({ id : id }); }
      for (var i = 0; i < items.length; i++) {
         let val = items[i];

         let $opt = $('<option/>');
         $opt.text(val);

         if (selected == val) {
           $opt.attr({ selected : 1 });
         }

         $slc.append($opt);
      };

      return $slc;
  };

  this.$$menu = function(ref={}){
      var id    = util.get(ref,'id','');
      var items = util.get(ref,'items',[]);

      var $menu = $('<div/>');
      if (id) { $menu.attr({ id : id }); }

      for(let item of items){
         let $li = $('<li/>');
         $li.append($(item));
         $menu.append($li);
      }

      var m = $menu.menu();
      m.menu('collapseAll');

      return $menu;
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

     var $slf = this;
     return function(e){
        $slf.rid = $(this).val();

        window.location = "/html/page/" + $slf.rid + "/" + $slf.tipe;
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

    //let doc = this.$left.get(0).contentWindow.document;
    //doc.open();
    //doc.write(html);
    //doc.close();

    html = encodeURIComponent(html);
    let src = 'data:text/html;charset=utf-8,' + html;
    this.$left.attr({ src : src });

    return this;
  };

  this.body_append = function(){
  
    $('body').prepend(this.$header);
    $('body').prepend(this.$pane);
    $('body').append(this.$foot);

    var $slf = this;
    this.jquery_ui_selectmenu({ 
        id : '#menu_tipes',
        cb : {
          selectmenuchange : function(){
            $slf.tipe = $(this).val();
            let href = '/html/page/' + $slf.rid + '/' + $slf.tipe;

            window.location = href;
          }
        }
    });

    return this;
  };

  this.copy_html = function(){
    console.log('[App] copy_html');

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

    console.log('[App] parse_url');

    this.url$ = new URL(window.location);
    this.url_path = this.url$.pathname;

    var m = this.url_path.match(/\/html\/page\/(\d+)\/(\w+)/);
    if (m) { 
      this.rid  = m[1]; 
      this.tipe = m[2]; 
    }

    return this;
  };

  this.init = function(){
    this.files = {};
    this.dirs = {};

    return this;
  };

  this.run = function(){
    console.log('[App] start run');

    this
        .init()
        .parse_url()
        .copy_html()
        .set_header()
        .set_pane()
        .set_foot()
        .body_append()
        .events()
     ;

    return this;
  }

  this.jquery_ui_selectmenu = function(ref={}){
    var id    = util.get(ref,'id','');
    var cb    = util.get(ref,'cb',{});
    var $el   = util.get(ref,'el','');

    if (id) { $el = $(id) }

    if (!$el) { return this }

    $el.selectmenu();

    for(var key of util.keys(cb)) {
      var f_cb = util.get(cb,key);
      if (!f_cb) { continue }

      $el.on(key,f_cb);
    }

    return this;
  };

}

//eof
module.exports = { App }
//export default App

