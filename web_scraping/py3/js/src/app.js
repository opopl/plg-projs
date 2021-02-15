
var pretty = require('pretty');
var util = require('./util.js');
//

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
        })
      ];

      for (let el of els) {
        this.$header.append(el);
      };

      return this;
  };

  this.set_pane = function(){

      this.$pane = $('<div/>').addClass('flex-header');

      this.$pane.css({ background : 'green' });

      var els = [];

      var tipes = [ 'core', 'clean' ];

      for(let tipe of tipes ){
         let href = tipe + '.html';

         els.push(
            this.$$a_href({
              href : href,
              txt  : tipe,
              id    : 'href_' + tipe,
            })
         );
      }

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

  this.$$input = function(ref={}){

      var id  = util.get(ref,'id');
      var plc = util.get(ref,'plc');
      var css = util.get(ref,'css',{});

      var inp = document.createElement('input');

      inp.type  = 'text';

      if (id) { inp.id = id; }
      if (plc) { inp.placeholder = plc; }

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
      this
        .on_enter_css_show()
        .on_enter_css_delete()
        ;

      return this;
  };

  this.on_enter_css_delete = function(){

     var $i = $('#inp_css_delete');
     var $slf = this;

     $i.bind("enterKey",function(e){
        var css = $(this).val();

        if (!css) {
          window.location.reload(true);
          return;
        }

        $slf.$left.children().remove();

        $slf.$html_clone.find(css).remove();

        $slf.$html_clone.find('body').children().each(function(){
           $slf.$left.append($(this).clone());
        });

        $slf.$right.find('pre').text($slf._code($slf.$html_clone));

     });

     $i.keyup(function(e){
        if(e.keyCode == 13) {
            $(this).trigger("enterKey");
        }
     });

     return this;
  };

  this.on_enter_css_unwrap = function(){
     return this;
  };

  this.on_enter_css_show = function(){

     var $i = $('#inp_css_show');
     var $slf = this;

     $i.bind("enterKey",function(e){
        var css = $(this).val();

        if (!css) {
          window.location.reload(true);
          return;
        }

        $slf.$left.children().remove();

        var $found = $slf.$html_clone.find(css).clone();

        $slf.$right.find('pre').text('');

        var _txt = '';
        $found.each(function(){
           var _el = $(this);
           $slf.$left.append(_el);

           _txt += $slf._code(_el) + '\n';
           //_txt += $slf._code(_el) + '<br/>\n';
           //console.log(_txt);
           //console.log(_el.html());
        });

        //$slf.$right.find('pre').text( this._code($found) );
        $slf.$right.find('pre').text( _txt );

     });

     $i.keyup(function(e){
        if(e.keyCode == 13) {
            $(this).trigger("enterKey");
        }
     });

     return this;
  };

  this.on_click = function(){
     $('#btn_reload').on('click',function() {
        window.location.reload(true);
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

  this.set_left = function(ref={}){

    var left = document.createElement('div');
    left.className = 'flex-left';

    this.$body_clone.children().each(function(){
       $(left).append($(this).clone());
    });

    this.$left = $(left);

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
    $('body').children().remove();
  
    $('body').append(this.$header);
    $('body').append(this.$pane);
    $('body').append(this.$container);

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

  this.run = function(){
 
    this
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
//export default App;

module.exports = { App }

