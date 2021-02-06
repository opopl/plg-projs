
(function($) {
  $.fn.onEnter = function(func) {
    this.bind('keypress', function(e) {
      if (e.keyCode == 13) func.apply(this, [e]);    
    });               
    return this; 
  };
})(jQuery);

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
      return this;

  };


  this.on_click = function(){
     $('#btn_reload').on('click',function() {
        window.location.reload(true);
     });

     return this;
  };

  this.set_right = function(){

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

  this.set_left = function(){

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

$(function(){
  window.app =  new App();
  app.run();
});


/*  var form = document.createElement("form"); */
  //form.setAttribute("method", "post"); 

  //var inp_xpath = document.createElement('input');
  
  //inp_xpath.value = '//head';
  //inp_xpath.type = 'text';
  
  //form.appendChild(inp_xpath);
  
  /*document.body.prepend(form);*/





/*  $("#pickList").pickList();*/
  
  //var val = {
      //01: {id: 01, text: 'Isis'},
      //02: {id: 02, text: 'Sophia'},
      //03: {id: 03, text: 'Alice'},
      //04: {id: 04, text: 'Isabella'},
      //05: {id: 05, text: 'Manuela'},
      //06: {id: 06, text: 'Laura'}
  //};

  //var pick = $("#pickList").pickList({ data: val });

  //$('#form_ipp_page input').onEnter(function(){
    //$('#form_ipp_page').submit();
  //});


  //$('.x_navbar_top btn_search').on('click', function(){
    //var url = '/docs/search';

    //var f_done = function(){};
    //var f_fail = function(){};

    //var jqxhr = $.post(url, { keywords : kwd } )
      //.done(f_done)
      //.done(f_fail)
      //.always(function(){});

    //var url_res = '/docs/search/results';

  //});

  //$(".timestamp").each(function(){

    //var ts = Number( $(this).text() );
    //var re = /^\s*(\d+)\s*$/;

    //if (re.test(ts)) {
        //var dt = new Date(ts*1000);
        //var date = dt.toLocaleDateString("en-US");
        //var time = dt.toLocaleTimeString("en-US");

        //$(this).text( [date, time ].join(' ') );

        //$(this).css('background-color','Green');
        //$(this).css('color','White');
    //}
  //});

  //$('.rowid_link').addClass('btn btn-primary');

  //$('.navbar_paginate a').addClass('btn btn-link');

  ////$('#div_headings').jstree();
  //try{
    //$('#div_headings ul.ul_top').menu();
  //}catch(e){
     //js_err( e.error() );
  //}

  //try  {
    ////$( document ).tooltip({});
    ////$( document ).tooltip();

 //[>   $( document ).tooltip({<]
        ////show: {
          ////effect: "slideDown",
          ////delay: 0
        ////}
    //[>});<]
  //} catch(e) {
      //console.error(e);
  //}

  //try  {
    ////$("a").attr('class','button');
    ////$("a.btn_tg").button();
    ////$("a.btn_rid").button();
    ////$("a.btn_rid").addClass('button');
  //} catch(e){
      //console.error(e);
  //}

  //var ov = document.querySelector("#object_viewer");
  //var ov_html = '';
  //if (ov) {
    //var ov_html = ov.contentDocument;
  //}

  //xfu.load_from_src(document, 'textarea' );

  //$('#btn_reload_html').on('click',function(){
    //var uri  = new URI( document.location.href );
    //var data = uri.search(true);
    //var rid  = data.rid;
    //alert(rid);
  //});

  //// pretty printer form
  //$('#form_pp').validate({
    //submitHandler: function(form) {
      //form.submit();
    //}
  //});

 
  //$('#select_url_hist').selectmenu({
    //width: null,
      //change: function( event, data ) {
        //var url  = data.item.value;
    //var form = document.forms.form_pp;

        //form.url = url;

        //form.submit();
      //}
  //});

  //$('#btn_pp_clear_url').on('click',function(){
    //$('#input_pp_url').val('');
  //});

  //$('#btn_pp_reset_cache').on('click',function(){
    //var url = '/util/pp';
    //post(url, { act : 'reset_cache' } );
    ////document.location.href = url;
  //});

  //$('#btn_pp_run').on('click',function(){
    //document.forms['form_pp'].submit();
  //});

  //$('#btn_table_fill').on('click',function(){
    //var url = '/docs/tags';
    //$.post(url, { acts : 'table_fill' })
        //.done(function(){});
  //});

  //$('#btn_table_reset').on('click',function(){
    //var url = '/docs/tags';
    //$.post(url, { acts : 'table_reset' })
        //.done(function(){});
  //});
    
  //$('#btn_pp_clear').on('click',function(){
    //var elems = document.forms.form_pp.elements;
    //for (var i = 0; i < elems.length; i++) {
        //var e = elems[i];
        //e.value = '';
    //};
  //});


