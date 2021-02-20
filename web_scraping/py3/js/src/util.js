

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
	httpGetAsync : function(theUrl, callback)
	{
	    var xmlHttp = new XMLHttpRequest();
	    xmlHttp.onreadystatechange = function() { 
	        if (xmlHttp.readyState == 4 && xmlHttp.status == 200)
	            callback(xmlHttp.responseText);
	    }
	    xmlHttp.open("GET", theUrl, true); // true for asynchronous 
	    xmlHttp.send(null);
	}
};
