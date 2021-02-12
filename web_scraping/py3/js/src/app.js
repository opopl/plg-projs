
var pretty = require('pretty');

function App(){

  this.set_header = function(){

      var header = document.createElement('div');
      header.className = 'flex-header';

      this.$header = $(header);

      this
        .el_btn_reload()
        .el_input_css_delete()
        .el_input_css_show()
      ;
    
      return this;
  };

  this.el_input_css_delete = function(){
      var inp = document.createElement('input');

      inp.type  = 'text';
      inp.id = 'inp_css_delete';
      inp.placeholder = 'CSS (Delete)';

      $(inp)
        .addClass('block')
        .css({ 
           width              : '10%',
           'color'            : 'white',
           'background-color' : 'red',
           'font-size'        : '25px',
           'justify-content'  : 'space-between',
        });

      this.$header.append($(inp));

      return this;
  };

  this.el_input_css_show = function(){
      var inp = document.createElement('input');

      inp.type  = 'text';
      inp.id = 'inp_css_show';
      inp.placeholder = 'CSS (Show)';

      $(inp)
        .addClass('block')
        .css({ 
           width              : '10%',
           'color'            : 'black',
           'background-color' : 'white',
           'font-size'        : '25px',
           'justify-content'  : 'space-between',
        });

      this.$header.append($(inp));

      return this;
  };

  this.el_btn_reload = function(){
      var btn = document.createElement('input');
      btn.type  = 'button';
      btn.value = 'Reload';
      btn.id = 'btn_reload';
      $(btn).addClass('block').css({ width: '10%' });
    
      this.$header.append($(btn));

      return this;
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

  this.set_pane_links = function(){
      var pane = document.createElement('div');
      pane.className = 'flex-header';

      var a = document.createElement('a');
      a.href  = '../core.html';
      a.textContent = 'CORE';
      $(a).addClass('block').css({ width: '10%' });
    
      $(pane).append($(a));

      this.$pane_links = $(pane);

    return this;
  };

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
    //$('body').append(this.$pane_links);
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
        .set_left()
        .set_right()
        .set_container()
        .set_pane_links()
        .body_append()
        .events()
     ;

    return this;
  }

}

export default App;


