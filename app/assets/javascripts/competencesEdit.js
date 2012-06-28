(function() {
  var skillPrereqEditUrl = false; 

  var clickHandler = function(evt) {
    var selected = $(this).parent()[0];
    var $first = $("#skills > li:first-child");
    var top = $first.position().top, left = $first.position().left;
    
    $("#skills > li").off("click");

    // Load new partial view
    //$("#dynamic-content-box").load(skillPrereqEditUrl); 
  
    var skill_id_string = $(selected).attr("id");
    var id_regexp = /skill-(\d+)/;
    var skill_id = id_regexp.exec(skill_id_string)[1];
    $.get(skillPrereqEditUrl, { 'skill_id': skill_id }, function(data, textStatus, xhr) {
      $("#dynamic-content-box").html(data); 
      prereq.initialization();
    });
  };
  

  $(function() {
    skillPrereqEditUrl = $("#metadata").data("skill-prereq-edit-url");
    $("#skills > li > .competence-skill-desc").each(function() {
      $(this).click(clickHandler); 
    });
  });

})();


/* Makes a debounced function of a function. A debounced function
 * is only executed after a given time period, unless the function
 * is called again within that period, which restarts the period timing.
 * Thus, the function call is effectively delayed until no more function calls
 * occur during the defined period. */
var makeDebouncedFunction = function(waitPeriod, func) {
  var timer;
      
  return function() {
    var targetFunc = func,
        args = arguments,
        contextObj = this;
    if (timer) clearTimeout(timer); 
    timer = setTimeout(function() {
      timer = false;
      /* Call the original function with the original arguments
       * using the orignal execution context. */
      targetFunc.apply(contextObj, args);
    }, waitPeriod);
  }
};


/* Skill prerequirements editing */
var prereq = (function() {
  var $searchbox,
      $searchResults,
      searchURL;
 
  function _searchListener() {
    var query = $searchbox.val().trim();

    if (query !== "") {
      $.get(searchURL, { q: query }, updateSearchResults);

      function updateSearchResults(data, textStatus, xhr) {
        $searchResults.html(data); 
      } 
    } else {
      $searchResults.html("");
    }
  } 

  /* Initialization */
  function _init() {
    $searchbox = $("#skill-search-box");
    $searchResults = $("#skill-search-results");
    searchURL = $("#metadata").data("skill-search-url")

    /* After the last keystroke, perform search after
     * the specified delay has elapsed, unless the last
     * key was enter, in which case search is performed
     * immediately.  */
    var delay = 500; // milliseconds
    $searchbox.keyup((function() {
      var debouncedFunc = makeDebouncedFunction(delay, _searchListener);
      return function(evt) {
        if(evt.which === 13) {
          /* Enter pressed! Perform search immediately instead of
           * debouncing */
          _searchListener();
        } else debouncedFunc();
      }
    })());
  };

  /* Module access object */
  return {
    searchListener: _searchListener,
    initialization: _init
  }

})();
