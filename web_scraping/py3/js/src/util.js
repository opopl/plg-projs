

module.exports = {
  get : function(obj,key,def=null){
      var value = (key in obj) ? obj[key] : def;
      return value;
  },
  encode_html : function(text) {
    return $("<textarea/>")
      .text(text)
      .html();
  },
  http_get_async : function(url, callback)
  {
      var xml_http = new XMLHttpRequest();
      xml_http.onreadystatechange = function() { 
          if (xml_http.readyState == 4 && xml_http.status == 200)
              callback(xml_http.responseText);
      }
      xml_http.open("GET", url, true); // true for asynchronous 
      xml_http.send(null);
  }
};
