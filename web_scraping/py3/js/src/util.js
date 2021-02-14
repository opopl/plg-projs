

module.exports = {
  'get' : function(obj,key,def=null){
      var value = (key in obj) ? obj.key : def;
      return value;
  }
}

