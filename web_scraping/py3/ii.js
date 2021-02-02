

var form = document.createElement("form"); 
form.setAttribute("method", "post"); 

var inp_xpath = document.createElement('input');

inp_xpath.value = '//head';
inp_xpath.type = 'text';

form.appendChild(inp_xpath);

document.body.prepend(form);
