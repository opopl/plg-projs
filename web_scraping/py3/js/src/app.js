
function App(){

  this.set_header = function(){

      var header = document.createElement('div');
      header.className = 'flex-header';

      this.$header = $(header);

      this
        .btn_reload()
        .input_css()
      ;
    
      return this;
  };

  this.input_css = function(){
      var inp = document.createElement('input');
      inp.type  = 'text';
      inp.id = 'inp_css';
      inp.placeholder = 'Enter CSS Selector';

      $(inp)
        .addClass('block')
        .css({ 
           width: '10%',
           'color': 'black',
           'background-color': 'white',
           'font-size': '25px',
        });

      this.$header.append($(inp));

      return this;
  };

  this.btn_reload = function(){
      var btn = document.createElement('input');
      btn.type  = 'button';
      btn.value = 'Reload';
      btn.id = 'btn_reload';
      $(btn).addClass('block').css({ width: '10%' });
    
      this.$header.append($(btn));

      return this;
  };

  this.on_enter = function(){

     var $i = $('#inp_css');

     $i.bind("enterKey",function(e){
        var css = $(this).val();
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
  
    $(pre).text(this.$html_clone.html());
  
    $(right).append($(code));

    this.$right = $(right);

    return this;
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
        .body_append()
        .events()
     ;

    return this;
  }

}

export default App;


