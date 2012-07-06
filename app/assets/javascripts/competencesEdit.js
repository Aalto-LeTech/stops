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
      prereq.initialize();
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
      searchURL,
      pagination = new _PaginationLoader();
 
  /* Search box listener */
  function _searchListener() {
    var query = $searchbox.val().trim();

    function updateSearchResults(data, textStatus, xhr) {
      $searchResults.html(data);
      pagination.enable();
    } 

    /* Reset pagination to default state and cancel
     * possible pagination update. */
    pagination.reset();

    if (query !== "") {
      // TODO Failures should be handled
      $.get(searchURL, { q: query }, updateSearchResults);

    } else {
      pagination.disable();
      $searchResults.html("");
    }
  } 

  /* Scroll listener for endless pagination */
  function _endlesslyPaginate(evt) {
    var $window = $(window),
        bottomPos =  $window.scrollTop() + $window.height(),
        $paginationFooter = $("#skill-endless-pagination-footer");

    if (bottomPos - $paginationFooter.offset().top > 30) {
      /* When the bottom of the screen is 12 pixels past the top of
       * the footer. */
      console.log("Showing hint!");
      if (!pagination.isLoading())
        $paginationFooter.find("#skill-endless-pagination-hint").show("slow");
    } else {
      $paginationFooter.find("#skill-endless-pagination-hint").hide(1000);
    }

    /* Old condition: $(document).height() - bottomPos < 2 */
    if (bottomPos - ($paginationFooter.offset().top + 
      $paginationFooter.outerHeight(true)) > 2) {
      /* Fetch more search results */
      //$("#skill-search-results").append("<p><strong>Pagination activated!</strong></p>");
      console.log("Should paginate!");
      pagination.load();
    }

  }

  /* Class for handling pagination AJAX-calls and page updates. */
  function _PaginationLoader() {
    this.enabled = true;
    this.paginationSeq = 2; /* Which batch should be loaded next */
    this.ajaxCallInProgress = false;
    var loader = this; /* Binding for _handleSuccess and _handleFailure */

    /* Load more results and display them on the page. */
    _PaginationLoader.prototype.load = function() {
      if (this.enabled && !this.ajaxCallInProgress) {
        ajaxCallInProgress = bindHandlersToInstance();
        var query = $searchbox.val().trim();
        
        var $hint = $("#skill-endless-pagination-hint");
        if ($hint.css("display") !== 'none') $hint.hide(300);
        $("#skill-endless-pagination-loading").show("slow");


        $.get(searchURL, 
          { 
            q: query, 
            p: this.paginationSeq 
          }, 
          ajaxCallInProgress.success)
          .error(ajaxCallInProgress.failure);
      }
    }

    /* Reset pagination to beginning and cancel possible AJAX-call
     * whose handlers have not yet been called. This should be
     * called each time search box query is changed. */
    _PaginationLoader.prototype.reset = function() {
      if (this.ajaxCallInProgress) this.ajaxCallInProgress.cancel();
      this.ajaxCallInProgress = false;
      this.paginationSeq = 2;
    }

    _PaginationLoader.prototype.isLoading = function() {
      return this.ajaxCallInProgress ? true : false;
    }

    /* Methods to enable and disable PaginationLoader. */
    _PaginationLoader.prototype.disable = function() {
      this.enabled = false;
    }

    _PaginationLoader.prototype.enable = function() {
      this.enabled = true;
    }

    /* Bind handlers to an instance that allows each request's 
     * handling to be cancelled. */
    function bindHandlersToInstance() {
      var instance = {
        success: _handleSuccess,
        failure: _handleFailure,
        cancelled: false,
        cancel: _cancel
      }

      function _cancel() {
        this.cancelled = true;
      }

      function _handleSuccess(data, textStatus, xhr) {
        if (!instance.cancelled) {
          /* Only handle the event if the handling hasn't been cancelled */
          if (data === 'nothing') {
            /* No more search results can be found */
            loader.disable();
          } else {
            $("#skill-search-results").append(data);

            loader.loadingPagination = false;
            loader.paginationSeq += 1;
            loader.ajaxCallInProgress = false;
          }
        } else {
          console.log("Endless paging: Successful AJAX-call CANCELLED!");
          loader.ajaxCallInProgress = false;
        }

        $("#skill-endless-pagination-loading").hide(400);
      }

      function _handleFailure(data, textStatus, xhr) {
        if (!instance.cancelled) {
          /* Only handle the event if the handling hasn't been cancelled */
          loader.ajaxCallInProgress = false;
        }
      }

      return instance;
    }
  }

  /* Companion class for prerequirement buttons to handle view state */
  var ButtonCompanion = function(state, button) {
    /* States: readyToAdd, loading, readyToRemove */
    var states = { readyToAdd: null, loading: null, readyToRemove: null };

    this.currentState = state in states ? state : readyToAdd;
    this.$button = $(button);
  }

  ButtonCompanion.prototype.stateTo = function(state) {
    if (state === 'loading') {

      this.$button.addClass("button-disabled");
      this.$button.text(this.$button.data("loading-text"));

    } else if (state === 'readyToAdd') {

      this.$button.addClass("skill-add-prereq-button");
      this.$button.removeClass("skill-remove-prereq-button");
      this.$button.text(this.$button.data("add-text"));
      this.$button.removeClass("button-disabled");

    } else if (state === 'readyToRemove') {

      this.$button.addClass("skill-remove-prereq-button");
      this.$button.removeClass("skill-add-prereq-button");
      this.$button.text(this.$button.data("remove-text"));
      this.$button.removeClass("button-disabled");

    }
  };


  var prereqAddURL,
      prereqRemoveURL;

  /* Click event listener to add the selected skill from search results 
   * as a prerequirement. */
  function _addSearchedPrereqOnClick() {
    //alert("Clicked");
    var $this = $(this);
    var prereqSkillId = $this.data("skill-id");
    var buttonComp = $this.data("button-companion");

    /* Lazily initialize ButtonCompanion object */
    if (!buttonComp) {
      buttonComp = new ButtonCompanion("readyToAdd", this);
      $this.data("button-companion", buttonComp);
    }

    buttonComp.stateTo("loading");
    $.post(prereqAddURL, { prereq_id: prereqSkillId }, function() {
      buttonComp.stateTo("readyToRemove");
    }).error(function() {
      console.log("AJAX update failed!");
      
      // TODO Failure notification
      buttonComp.stateTo("readyToAdd");
    });
  }

  /* Click handler for removing a searched prerequirement skill
   * from prerequirements.  */
  function _removeSearchedPrereqOnClick() {
    var $this = $(this),
        prereqSkillId = $this.data("skill-id"),
        buttonComp = $this.data("button-companion");

    /* Lazily initialize ButtonCompanion object */
    if (!buttonComp) {
      buttonComp = new ButtonCompanion("readyToAdd", this);
      $this.data("button-companion", buttonComp);
    }

    buttonComp.stateTo("loading");
    $.post(prereqRemoveURL, { prereq_id: prereqSkillId }, function() {
      buttonComp.stateTo("readyToAdd");
    }).error(function() {
      console.log("AJAX update failed!");
      
      // TODO Failure notification
      buttonComp.stateTo("readyToRemove");
    });

  }

  /* Click handler for removing a current prerequirement from the
   * prerequirements listing on top of the page.  */
  function _removeCurrentPrereqOnClick() {
    var $this = $(this),
        prereqSkillId = false,  // TODO Change these
        buttonComp = false;
  }

  /* Initialization */
  function _init() {
    $searchbox = $("#skill-search-box");
    $searchResults = $("#skill-search-results");
    searchURL = $("#metadata").data("skill-search-url");
    prereqAddURL = $("#metadata").data("skill-prereq-add-url");
    prereqRemoveURL = $("#metadata").data("skill-prereq-remove-url");

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

    $(window).scroll(_endlesslyPaginate);

    /* Buttons of current prerequirements */
    // TODO add it here

    /* Buttons of search results */
    $("#skill-search-results").on("click", "button.skill-add-prereq-button", 
      _addSearchedPrereqOnClick);

    $("#skill-search-results").on("click", "button.skill-remove-prereq-button", 
      _removeSearchedPrereqFromSearchOnClick);

  };

  /* Module access object */
  return {
    initialize: _init,
    PaginationLoader: _PaginationLoader
  }

})();
