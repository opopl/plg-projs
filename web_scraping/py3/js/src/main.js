

$(function(){

/*  var form = document.createElement("form"); */
  //form.setAttribute("method", "post"); 

  //var inp_xpath = document.createElement('input');
  
  //inp_xpath.value = '//head';
  //inp_xpath.type = 'text';
  
  //form.appendChild(inp_xpath);
  
  /*document.body.prepend(form);*/

  var header = document.createElement('div');
  header.className = 'flex-header';

  var left = document.createElement('div');
  var right = document.createElement('div');

  var container = document.createElement('div');
  container.className = 'flex-container';

  var left = document.createElement('div');
  left.className = 'flex-left';

  var right = document.createElement('div');
  right.className = 'flex-right';

  var code = document.createElement('div');
  code.className = 'code';

  var pre = document.createElement('pre');
  $(code).append($(pre));

  $(pre).text($('html').html());

  $(right).append($(code));

  $('body').children().each(function(){
     $(left).append($(this).clone());
  });

  $(container).append( $(left) );
  $(container).append( $(right) );

  $('body').children().remove();

  $(container).append( $(header) );
  $('body').append($(container));



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

});

