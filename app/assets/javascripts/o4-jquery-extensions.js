(function ($) {
  var numOf = function(str) {
    var num = parseInt(str, 10);
    if (num) return num;
    else return 0;
  }; 

  // Accessor to retrieve margins as numbers 
  $.fn.margin = function() {
    var res = { 
      top: numOf(this.css('margin-top')),
      right: numOf(this.css('margin-right')),
      bottom: numOf(this.css('margin-bottom')),
      left: numOf(this.css('margin-left'))
    };
    return res;
  };
})(jQuery);
