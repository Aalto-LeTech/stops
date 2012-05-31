$(document).ready(function(){
  var element = $('#paths');
  if (element.length > 0) {
    new PathViewer(element);
  }
});
