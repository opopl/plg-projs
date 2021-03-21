
var pretty = require('pretty');
var util = require('./util.js');
//
//

require('../../css/aria-dropdown.css');
require('../../css/jquery.dataTables.css');

require('./aria-dropdown.js');

require( 'datatables.net' );

//const fs = require('fs-extra');
const yaml = require('js-yaml');

function App(){

//@set_header
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

//@@ reload
  this.reload = function(){

      var r = this._url();
      console.log(r);

      var $fr = $('#ifr_page_src');
      $fr.attr({ src : r.url_src });

      try{
        //$fr.get(0).contentDocument.location.reload(true);
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

//@@ set_pane
  this.set_pane = function(){
      console.log('[App] set pane');

      this.$pane = $('<div/>').addClass('flex-row');
      this.$pane.css({ background : 'green' });

      var els = [];

      var tipes = 'log dbrid img img_clean cache core core_clean clean'.split(' ');
      var tipes_txt = 'head meta link script'.split(' ');

      els.push(
            this.$$select({
              id : 'menu_tipes',
              css : {
                width : '50px',
              },
              items    : tipes,
              selected : this.tipe,
            }),
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
            this.$$select({
              id : 'menu_tipes_txt',
              css : {
                width : '50px',
              },
              items    : tipes_txt,
              selected : this.tipe,
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

      var $date = $('<input type="text" />');
      $date
         .attr({ id : 'inp_page_date' })
         .addClass('bs_date')
         ;
      els.push( $date );

      for (let el of els) {
        this.$pane.append(el);
      };


      return this;
  };

//@@ $$select
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

//@@ $$menu
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

//@@ $$btn
  this.$$btn = function(ref={}){
      var value = util.get(ref,'value','');
      var id    = util.get(ref,'id','');
      var css   = util.get(ref,'css',{});
      var attr  = util.get(ref,'attr',{});

      var btn = document.createElement('input');
      btn.type  = 'button';

      if (id) { btn.id = id; }
      if (value) { btn.value = value; }

      $(btn).addClass('block').css({ 
        width: '10%',
        ...css
      });
      $(btn).attr(attr);

      return $(btn);
  };

//@@ $$a_href
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

//@@ $$input
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

//@@ on_form_submit
  this.on_form_submit = function(){
      var $f = $( "#div_form_new form" );
      
      $f.submit(function( event ) {
        //alert( $f.find('') );
        var d = $f.serialize();
        var jx = $.ajax({
           method  : 'POST',
           data    : d,
           url     : '/json/page/add',
           success : function(data){
             console.log(data);
           },
           error   : function(data){
             console.log(data);
           },
        });
        
        event.preventDefault();
      });

      return this;
  };

//@@ on_enter
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

//@@ register_on_enter
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

//@@ func_enter_url
  this.func_enter_url = function(){
     var $slf = this;

     return function(e){
        var url = $(this).val();
        var id = $(this).attr('id');

        var win = window.open(url, "_blank");

        return 1;
        //window.location = "/html/page/" + $slf.rid + "/" + $slf.tipe;
     };

     return this;
  };

//@@ func_enter_rid
  this.func_enter_rid = function(){
     var $slf = this;

     return function(e){
        $slf.rid = $(this).val();

        window.location = "/html/page/" + $slf.rid + "/" + $slf.tipe;
     };

     return this;
  };

//@@ func_enter_sel
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

//@@ on_click_tags
  this.on_click_tags = function(){
     let $slf = this;

     $('#opt_page_tags input[type="button"]').on('click',function() {
       var tag = $(this).val();

       var tags_s = tag;  

       var jx = $.ajax({
        method  : 'GET',
        data    : { tags : tags_s },
        url     : '/json/pages',
        success : function(data){
          $('#ta_page_src, #ifr_page_src').hide();

          $slf.pages = util.get(data,'pages',[]);

          $slf.list_pages();
        },
        error   : function(data){},
       });
     });

     return this;
  };

//@@ list_pics
  this.list_pics = function(){
     let $slf = this;

     var cols_t = [
            { 
              data : 'inum',
              title : 'inum',
              render : function (data, type, row){
                var inum = data;
                if (type == 'display') {
                  var $d = $('<div><input type="button"></input></div>');
                  $d
                    .find('input')
                    .addClass('btn_pic_inum')
                    .addClass('block')
                    .attr({ 'inum' : inum });
                  return $d.html();
                }
                return data;
              }
            },
            { 
              data : 'caption',
              title : 'caption',
            },
            { 
              data  : 'pic_url',
              title : 'pic_url',
              render : function (data, type, row){
                var pic_url = data;
                if (type == 'display') {
                  var $d = $('<div><a></a></div>');
                  $d
                    .find('a')
                    .attr({ 'href' : pic_url });
                  return $d.html();
                }
                return data;
              }
            },
      ];

      $('.mydatatable').remove();

      var $tb_div = $('<div/>');
      $tb_div
        .attr({ id : 'tb_div_pics' })
        .addClass('dohide')
        .addClass('mydatatable')
        ;

      var $tb = $('<table/>');
      $tb.append($('thead'));
      $tb.append($('tbody'));
      $tb.append($('tfoot'));

      var id = 'tb_list_pics';
      $tb.attr({ 
          //id   : id,
          width : '100%',
          border : 1,
      });
      $tb_div.append($tb);
      $('#container').append($tb_div);

      $tb.dataTable({ 
          data    : $slf.page.pics,
          columns : cols_t,
          paging  : true,
          buttons: [
            'copy', 'excel', 'pdf'
          ],
          //fixedHeader: {
            //header: true,
            //footer: true
          //}
      });

     return this;
  };

//@@ list_pages
  this.list_pages = function(){
     let $slf = this;

     var cols_t = [
            { 
              data : 'rid',
              title : 'rid',
              render : function (data, type, row){
                var rid = data;
                if (type == 'display') {
                  var $d = $('<div><a></a></div>');
                  var href = $slf._href_rid(rid);
                  $d.find('a').attr({ href : href }).text(rid);
                  return $d.html();
                }
                return rid;
              }
            },
            { 
              data : 'date',
              title : 'date',
              render : function (data, type, row){
                var date = data;
                if (type == 'display') {
                  var $d = $('<div><input type="text" ></input></div>');
                  var $inpd = $d.find('input');

                  $inpd
                      .addClass('bs_date_item')
                      .attr({ value : date })
                      ;
                  var h = $d.html();
                  return h;
                }
                return date;
              }
            },
            { 
              data  : 'title',
              title : 'title',
            },
      ];

      $('.mydatatable').remove();

      var $tb_div = $('<div/>');
      $tb_div
        .attr({ id : 'tb_div_pages' })
        .addClass('dohide')
        .addClass('mydatatable')
        ;

      var $tb = $('<table/>');
      $tb.append($('thead'));
      $tb.append($('tbody'));
      $tb.append($('tfoot'));

      var id = 'tb_list_pages';
      $tb.attr({ 
          //id   : id,
          width : '100%',
          border : 1,
      });
      $tb_div.append($tb);
      $('#container').append($tb_div);

      $tb.dataTable({ 
          data    : $slf.pages,
          columns : cols_t,
          paging  : true,
          buttons: [
            'copy', 'excel', 'pdf'
          ],
          //fixedHeader: {
            //header: true,
            //footer: true
          //}
      });

      this.set_ui_date({ 
         el : $('.bs_date_item'),
         css : {
            color              : 'white',
            'background-color' : 'gray',
         }
      });

     return this;
  };

//@@ on_click_img
  this.on_click_img = function(){
     let $slf = this;

     return this;
  };

//@@ on_click_author
  this.on_click_author = function(){
     let $slf = this;

     $('#opt_page_author input[type="button"]').on('click',function() {
       var auth_id = $(this).attr('auth_id');

       var jx = $.ajax({
        method  : 'GET',
        data    : { author_id : auth_id },
        url     : '/json/pages',
        success : function(data){
          $('#ta_page_src, #ifr_page_src').hide();

          $slf.pages = util.get(data,'pages',[]);
          $slf.list_pages();
        },
        error   : function(data){},
       });
     });

     return this;
  };

//@@ on_click
  this.on_click = function(){
     let $slf = this;
     $('#btn_reload').on('click',function() {
        $slf.reload();
     });

     this
        .on_click_tags()
        .on_click_author()
        .on_click_img()
        ;

     
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

//@@ _url
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

//@@ _href_rid
  this._href_rid = function(rid,tipe='clean'){
    return '/html/page/' + rid + '/' + tipe;
  };

//@@ _code
  this._code = function(el){
    var html = $(el).wrap('<div/>').parent().html();
    html = pretty(html);

    return html;
  };

//@@ update_left
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

//@@ opt_page_init
  this.opt_page_init = function(){ 

    $('#opt_page_img').find('button').addClass('block');
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
      var auth_id = author_ids[i];

      var author='';
      var jx = $.ajax({
          method  : 'POST',
          data    : { id : auth_id },
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
         value : author,
         attr : { auth_id : auth_id },
         css : {
           width : 'auto'
         }
      });

      $('#opt_page_author').append($btn);
    };

    return this;
  };

//@@ opt_page_show
  this.opt_page_show = function(opt='url'){ 
    var $slf = this;

    $('#control_items').children().hide();
    var id = '#opt_page_' + opt;

    $('.dohide').hide();
    $(id).show();

    if (id == '#opt_page_new') {
       $('#ifr_page_src, #ta_page_src').hide();
       $('#div_form_new').show();
       return this;
    }
    else if (id == '#opt_page_img') {
       $('#ifr_page_src, #ta_page_src').hide();

       var jx = $.ajax({
         method  : 'GET',
         data    : {},
         url     : '/json/page/' + $slf.rid + '/pics',
         success : function(data){
           var pics = util.get(data,'pics',[]);

           $slf.page.pics = pics;

           $slf.list_pics();
         },
         error   : function(data){},
       });

       return this;
    }
 
    this.ui_restore();

    return this;
  };

//@@ ui_restore
  this.ui_restore = function(){ 

    $('#ifr_page_src, #ta_page_src').show();
    $('.dohide').hide();

    this.set_ui_visible();

    return this;
  };

//@@ set_ui_select
  this.set_ui_select = function(){
    var $slf = this;

    this.jquery_ui_selectmenu({ 
        id : '#menu_tipes_txt',
        cb : {
          selectmenuchange : function(){
            $slf.tipe = $(this).val();
            let href = '/html/page/' + $slf.rid + '/' + $slf.tipe;

            window.location = href;
          }
        }
    });

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

//@@ set_ui_visible
  this.set_ui_visible = function(){
    $('.dohide').hide();

    if('script head meta link'.split(' ').includes(this.tipe)){
      $('#ta_page_src').show();
      $('#ifr_page_src').hide();
    }

    if('log dbrid img img_clean'.split(' ').includes(this.tipe)){
      $('#ta_page_src').hide();
      $('#ifr_page_src')
          .css({ width : '100%' })
          .removeAttr('sandbox')
          ;
    }

    return this;
  };

//@@ set_ui_date
  this.set_ui_date = function(ref={}){
    var date     = util.get(ref, 'date', '');

    //var $el  = $('#inp_page_date');
    var $el  = $('.bs_date');
    var $el  = util.get(ref, 'el', $el);

    var css  = util.get(ref, 'css', {});

    if (date) { 
       $el.val(date);
    }

    $el
        .addClass('block')
        .css({ 
           color : 'black', 
           width : 'auto',
           ...css
        })
        .datepicker({
           dateFormat: "dd_mm_yy",
        });

    return this;
  };

//@@ set_ui
  this.set_ui = function(){

    this
      .set_ui_select()
      .set_ui_visible()
      .set_ui_date({ 
         date : this.page.date,
         el : $('#inp_page_date'),
      })
      .opt_page_init()
      .opt_page_show();

    return this;
  };

//@@ body_append
  this.body_append = function(){
  
    $('body').prepend(this.$header);
    $('body').prepend(this.$pane);

    return this;
  };

//@@ events
  this.events = function(){

    this
        .on_click()
        .on_enter()
        .on_form_submit()
    ;

    return this;
  };

//@@ ajax_page
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

//@@ parse_url
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

//@@ rnt_reset
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

//@@ init
  this.init = function(){
    console.log('[App] init');

    this.files = {};
    this.dirs = {};
    this.page = {};

    this.rnt_reset();

    return this;
  };

//@@ set_css
  this.set_css = function(){
    var ids = '#opt_page_url #opt_page_title #opt_page_title_h'.split(' ');

    for (var i = 0; i < ids.length; i++) {
        var id = ids[i];

        $(id).css({ 
          'text-align' : 'left',
          'width'      : '100%',
        });
    };

    $('#div_form_new input').addClass('block');

    return this;
  };

//@@ run
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

//@@ jquery_ui_selectmenu
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

