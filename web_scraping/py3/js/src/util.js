

var a = {
  'get' : function(obj,key,default=null){
      var value = (key in obj) ? obj.key : default;
      return value;
  }
}

module.exports = a;
