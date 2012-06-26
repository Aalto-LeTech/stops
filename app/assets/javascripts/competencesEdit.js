(function() {
  var skillPrereqEditUrl = false; 

  var clickHandler = function(evt) {
    var selected = $(this).parent()[0];
    var $first = $("#skills > li:first-child");
    var top = $first.position().top, left = $first.position().left;
    
    /*$("#skills > li").each(function(i, el) {
      var $this = $(this);
      $this.css({
        "top": $this.position().top,
        "left": $this.position().left
      });
    });

    $("#skills > li").each(function(i, el) {
      if (this !== selected) $(this).css("z-index", "-1");
      $(this).addClass("absolute");
      $(this).animate({
        top: top,
        left: left 
      }, {
        duration: 1000,
        complete: function() {"http://localhost:3000/fi/curriculums/1/competences/5/edit_skill_prereqs
          if (this !== selected) $(this).addClass("hide");
          $(selected).addClass("deactivated");
          $(selected).find("a.button-base").addClass("hide");
        }  
      });
      
    }); */


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

    $.get(searchURL, { q: query }, updateSearchResults);

    function updateSearchResults(data, textStatus, xhr) {
      $searchResults.html(data); 
    } 
  } 

  /* Initialization */
  function _init() {
    $searchbox = $("#skill-search-box");
    $searchResults = $("#skill-search-results");
    searchURL = $("#metadata").data("skill-search-url")
    $searchbox.keyup(makeDebouncedFunction(500, _searchListener));
  };

  /* Module access object */
  return {
    searchListener: _searchListener,
    initialization: _init
  }

})();
