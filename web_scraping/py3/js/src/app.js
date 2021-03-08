
var pretty = require('pretty');
var util = require('./util.js');
//
//

require('../../css/aria-dropdown.css');
require('./aria-dropdown.js');

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

      var r = this._url();
      console.log(r);

      var $fr = $('#ifr_page_src');
      $fr.attr({ src : r.url_src });

      try{
        $fr.get(0).contentDocument.location.reload(true);
      }catch(e){
        console.log(e);
      }

      var $ta = $('#ta_page_src');

      $.get(r.url_code,{}, function(data,status){
        $ta.text(data);
        window.location.reload(true);
      });

      return this;
  };

  this.set_pane = function(){
      console.log('[App] set pane');

      this.$pane = $('<div/>').addClass('flex-row');
      this.$pane.css({ background : 'green' });

      var els = [];

      var tipes = 'log dbrid img img_clean cache core core_clean clean'.split(' ');

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
              txt : this.rid,
            }),
      );

      els.push(
        this.$$btn({
           id : 'btn_prev',
           value : 'Prev',
           css : {
              'background-color' : 'gray',
              'color' : 'yellow',
              width : '5%'
           }
        }),
        this.$$btn({
           id : 'btn_next',
           value : 'Next',
           css : {
              'background-color' : 'gray',
              'color' : 'yellow',
              width : '5%'
           }
        }),
        this.$$btn({
           id : 'btn_last',
           value : 'Last',
           css : {
              'background-color' : 'gray',
              width : '5%'
           }
        }),
       this.$$btn({
           id : 'btn_json',
           value : 'JSON',
           css : {
              'background-color' : 'blue',
              width : '5%'
           }
        }),
       this.$$btn({
           id : 'btn_add',
           value : 'Add',
           css : {
              'background-color' : 'orange',
              'color'            : 'black',
              width              : '5%'
           }
        }),
      );

      els.push(
        $('<input type="text" id="inp_page_date" />')
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

  this.on_form_submit = function(){
      $( "#div_form_new form" ).submit(function( event ) {
        alert( "Handler for .submit() called." );
        event.preventDefault();
      });

      return this;
  };

  this.on_enter = function(){
      //this
        //.on_enter_css_show()
        //.on_enter_css_delete()
        //;

      this
        .register_on_enter('#inp_css_show',this.func_enter_sel({ 
           'type' : 'css' 
        }))
        .register_on_enter('#inp_css_delete',this.func_enter_sel({ 
           'type' : 'css',
           'act'  : 'remove'
        }))
        .register_on_enter('#inp_xpath_show',this.func_enter_sel({ 
           'type' : 'xpath' 
        }))
        .register_on_enter('#inp_xpath_delete',this.func_enter_sel({ 
           'type' : 'xpath',
           'act'  : 'remove'
        }))
        .register_on_enter('#inp_rid',this.func_enter_rid())
        .register_on_enter('#opt_page_url',this.func_enter_url())
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

  this.func_enter_url = function(){
     var $slf = this;

     return function(e){
        var url = $(this).val();
        var id = $(this).attr('id');

        if (url != $slf.page.url) {
          $slf.urlget = { url : url };
          if (id == 'opt_page_url') {
            $(this).hide();

            var els = [
              { 
                 el : $('<label for="give_tags" >Tags:</label>'), 
                 css : { width : 'auto' } 
              },
              { 
                 el : $('<input id="opt_page_give_tags" />'), 
                 css : { width : '20%' } 
              },
            ];

            for (var i = 0; i < els.length; i++) {
              var itm = els[i];

              var $el = util.get(itm,'el');
              var css = util.get(itm,'css',{});

              $el.addClass('block').css(css);

              $(this).parent().append($el);
            };
          }
        }

        return 1;
        //window.location = "/html/page/" + $slf.rid + "/" + $slf.tipe;
     };

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

  this.func_enter_sel = function(ref={}){
     var $slf = this;

     var type = util.get(ref,'type','css');
     var act  = util.get(ref,'act','display');

     return function(e){
        var sel = $(this).val();

        if (!sel) {
          $slf.reload();
          return;
        }

        $slf.rnt[type][act].push(sel);

        var rr = { act : act };
        rr[type] = sel;

        var r = $slf._url(rr);

        $('#ifr_page_src').attr({ src : r.url_src });

        var $ta = $('#ta_page_src');
  
        $.get(r.url_code,{}, function(data,status){
          $ta.text(data);
        });

     };

     return this;
  };

  this.on_click = function(){
     let $slf = this;
     $('#btn_reload').on('click',function() {
        $slf.reload();
     });

     $('#btn_last').on('click',function() {
        window.location = '/html/page/last';
     });

     $('#btn_prev').on('click',function() {
        $slf.rid = Number($slf.rid) - 1;
        window.location = '/html/page/' + $slf.rid;
     });

     $('#btn_next').on('click',function() {
        $slf.rid = Number($slf.rid) + 1;
        window.location = '/html/page/' + $slf.rid;
     });

     $('#btn_add').on('click',function() {
        window.location = '/html/page/add';
     });

     $('#btn_json').on('click',function() {
        $('#ifr_page_src').attr({ src : '/json/page/' + $slf.rid });
     });

     return this;
  };

  this._url = function(ref={}){
     var act = util.get(ref,'act','display')

     var css   = util.get(ref,'css','')
     var xpath = util.get(ref,'xpath','')

     var url = '/html/page/' + this.rid + '/' + this.tipe;

     var url_src  =  url + '/src';
     var url_code =  url + '/code';

     if (css) {
       var css_e = encodeURIComponent(css);
       url_src += '?act=' + act + '&css=' + css_e;
       url_code += '?act=' + act + '&css=' + css_e;
     }
     if (xpath) {
       var xpath_e = encodeURIComponent(xpath);
       url_src += '?act=' + act + '&xpath=' + xpath_e;
       url_code += '?act=' + act + '&xpath=' + xpath_e;
     }

     return {
       'url'      : url,
       'url_code' : url_code,
       'url_src'  : url_src,
     };
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

  this.opt_page_init = function(){ 

    //$('#opt_page_img').find('*').addClass('block');
    $('#opt_page_img').find('button,li').addClass('block');
    $('#opt_page_img').ariaDropdown();

    $('#opt_page_new').find('*').addClass('block').hide();

    $('#opt_page_new').find('*').hide();

    $('#lab_new_url').css({ 
        width              : 'auto',
        color              : 'black',
        'background-color' : 'white',
    });
    $('#input_new_url').css({ 
        width        : '100%',
        'text-align' : 'left',
    });

    var tags_s = util.get(this.page,'tags','');
    var tags = tags_s.split(',');
    for (var i = 0; i < tags.length; i++) {
      var tag = tags[i];
      var $btn = this.$$btn({
         id : 'btn_tag_' + tag,
         value : tag,
         css : {
           width : 'auto'
         }
      });
      $('#opt_page_tags').append($btn);
    };

    var author_ids = util.get(this.page,'author_id','').split(',');
    for (var i = 0; i < author_ids.length; i++) {
      var id = author_ids[i];

      var author='';
      var jx = $.ajax({
          method  : 'POST',
          data    : { id : id },
          url     : '/json/authors',
          success : function(data){
             var a_list = util.get(data,'authors',[]);
             console.log(data);
             if (a_list.length) {
               var a = a_list[0];
               author = util.get(a,'name','');
             }
          },
          error   : function(data){},
          async   : false
      });
      
      var $btn = this.$$btn({
         id : 'btn_author_' + id,
         value : author,
         css : {
           width : 'auto'
         }
      });

      $('#opt_page_author').append($btn);
    };

    return this;
  };

  this.opt_page_show = function(opt='url'){ 

    $('#control_items').children().hide();
    var id = '#opt_page_' + opt;
    $(id).show();

    if (id == '#opt_page_new') {
       $('#ifr_page_src, #ta_page_src').hide();
       $('#div_form_new').show();
       return this;
    }

    this.ui_restore();

    return this;
  };

  this.ui_restore = function(){ 

    $('#ifr_page_src, #ta_page_src').show();
    $('.hide').hide();

    return this;
  };

  this.set_ui_select = function(){
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
    }).jquery_ui_selectmenu({ 
        id : '#select_control',
        opts : {
          style : 'popup'
        },
        cb : {
          selectmenuchange : function(){
            var opt = $(this).val();

            $slf.opt_page_show(opt);

          }
        }
    })

    return this;
  };

  this.set_ui_visible = function(){
    $('.hide').hide();

    return this;
  };

  this.set_ui = function(){

    this
      .set_ui_select()
      .set_ui_visible()
      .opt_page_init()
      .opt_page_show();

    if('log dbrid img img_clean'.split(' ').includes(this.tipe)){
      $('#ta_page_src').hide();
      $('#ifr_page_src')
          .css({ width : '100%' })
          .removeAttr('sandbox')
          ;
    }

    var date = this.page.date;
    $('#inp_page_date')
        .val(date)
        .addClass('block')
        .css({ 
           color : 'black', 
           width : 'auto',
        })
        .datepicker({
           dateFormat: "dd_mm_yy",
        });

    return this;
  };

  this.body_append = function(){
  
    $('body').prepend(this.$header);
    $('body').prepend(this.$pane);


    return this;
  };

  this.events = function(){

    this
        .on_click()
        .on_enter()
        .on_form_submit()
    ;

    return this;
  };

  this.ajax_page = function(){
    console.log('[App] ajax_page');

    var $slf = this;

    var r = $.ajax({
      url : '/json/page/' + this.rid,
      method : 'GET',
      data : {},
      dataType : 'json',
      async: false,
    });

    r.done(function(data){
      $slf.page = data;
    });

    return this;
  };

  this.parse_url = function(){
    console.log('[App] parse_url');

    this.url$     = new URL(window.location);
    this.url_path = this.url$.pathname;

    var $slf = this;

    var m = this.url_path.match(/\/html\/page\/(\d+)\/(\w+)/);
    if (m) { 
      this.rid  = m[1]; 
      this.tipe = m[2]; 
    }

    return this;
  };

  this.rnt_reset = function(){
    this.rnt = {
       xpath : {
         remove : [],
         display : [],
       },
       css : {
         remove : [],
         display : [],
       }
    };
    return this;
  };

  this.init = function(){
    console.log('[App] init');

    this.files = {};
    this.dirs = {};
    this.page = {};

    this.rnt_reset();

    return this;
  };

  this.set_css = function(){
    var ids = '#opt_page_url #opt_page_title #opt_page_title_h'.split(' ');

    for (var i = 0; i < ids.length; i++) {
        var id = ids[i];

        $(id).css({ 
          'text-align' : 'left',
          'width'      : '100%',
        });
    };

    $('#div_form_new form').find('*').addClass('block');

    return this;
  };

  this.run = function(){
    console.log('[App] start run');

    this
        .init()
        .parse_url()
        .ajax_page()
        .set_header()
        .set_pane()
        .body_append()
        .set_ui()
        .set_css()
        .events()
     ;

    return this;
  }

  this.jquery_ui_selectmenu = function(ref={}){
    var id   = util.get(ref,'id','');
    var cb   = util.get(ref,'cb',{});

    var opts = util.get(ref,'opts',{});

    var $el  = util.get(ref,'el','');

    if (id) { $el = $(id) }

    if (!$el) { return this }

    $el.selectmenu({ 
       width : 'auto', 
       ...opts 
    });
    console.log(opts);

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

