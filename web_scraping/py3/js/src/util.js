

module.exports = {
  get : function(obj,key,def=null){
      var value = (key in obj) ? obj[key] : def;
      return value;
  },
	encode_html : function(text) {
	  return $("<textarea/>")
	    .text(text)
	    .html();
	}
};
