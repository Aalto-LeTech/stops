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
      current_skill_id,
      pagination;
 
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
      $.get(searchURL, { q: query, sid: current_skill_id }, updateSearchResults);

    } else {
      pagination.disable();
      $searchResults.html("");
    }
  } 

  var $paginationFooter;

  /* Scroll listener for endless pagination */
  function _endlesslyPaginate(evt) {
    var $window = $(window),
        bottomPos =  $window.scrollTop() + $window.height();

    if (bottomPos - $paginationFooter.offset().top > 30) {
      /* When the bottom of the screen is 12 pixels past the top of
       * the footer. */
      console.log("Should show a hint!");
      pagination.showHint(); 
    }

    /* Old condition: $(document).height() - bottomPos < 2 */
    if (bottomPos - ($paginationFooter.offset().top + 
      $paginationFooter.outerHeight(true)) > 2) {
      /* Fetch more search results */
      console.log("Should paginate!");
      pagination.loadMore();
    }

  }

  /* Class for handling pagination AJAX-calls and page updates. */
  function _PaginationLoader() {
    this.enabled = false;
    this.moreResultsAvailable = true;
    this.message = false;   /* Values: "hint", "loading", "nomoreresults", false */
    this.paginationSeq = 2; /* Which batch should be loaded next */
    this.ajaxCallInProgress = false;

    this.$paginationHint         = $("#skill-endless-pagination-hint");
    this.$paginationLoadingIcon  = $("#skill-endless-pagination-loading");
    this.$paginationNoResultsMsg = $("#skill-endless-pagination-no-results-msg");

    this._msgToJQuery = {
      hint:           this.$paginationHint,
      loading:        this.$paginationLoadingIcon,
      nomoreresults:  this.$paginationNoResultsMsg
    };
  }

  /* Load more results and display them on the page. */
  _PaginationLoader.prototype.loadMore = function() {
    if (this.enabled && this.moreResultsAvailable && !this.ajaxCallInProgress) {

      var loader = this; /* Binding for _handleSuccess and _handleFailure */

      /* Bind handlers to an instance that allows each request's 
       * handling to be cancelled. This is needed so that cancelled
       * AJAX call can still call old callbacks without side effects. */
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
              console.log("handleSuccess: No more results available");
              /* No more search results can be found */
              loader.moreResultsAvailable = false;
              loader._showMsg("nomoreresults");
            } else {
              $("#skill-search-results").append(data);

              loader.paginationSeq += 1;
              loader.ajaxCallInProgress = false;

              loader._hideAllMsgs();
            }
          } else {
            console.log("Endless paging: Successful AJAX-call CANCELLED!");
          }
        }

        function _handleFailure(data, textStatus, xhr) {
          if (!instance.cancelled) {
            /* Only handle the event if the handling hasn't been cancelled */
            loader.ajaxCallInProgress = false;
            // TODO Show error message
          }
        }

        return instance;
      }


      this.ajaxCallInProgress = bindHandlersToInstance();
      var query = $searchbox.val().trim();

      console.log("About to make an AJAX-query. ajaxCallInProgress? " + !!this.ajaxCallInProgress);
      console.log("ajaxCallInProgress object: " + this.ajaxCallInProgress);
      
      this._showMsg("loading");

      $.get(searchURL, 
        { 
          q:    query, 
          p:    this.paginationSeq,
          sid:  current_skill_id
        }, 
        this.ajaxCallInProgress.success
      ).error(this.ajaxCallInProgress.failure);
    }
  }

  _PaginationLoader.prototype._hideAllMsgs = function(duration, callback) {
    if (arguments.length === 1 && $.isFunction(duration)) {
      callback = duration;
      duration = 300;
    } else {
      duration = duration || 300; // milliseconds
    }
    
    allMsgs = this.$paginationHint.add(this.$paginationLoadingIcon);
    allMsgs = allMsgs.add(this.$paginationNoResultsMsg);

    /* Stop ongoing animations */
    allMsgs.stop();

    if ($.isFunction(callback)) {
      var finished = 0; /* Hide callback is called once per matched element,
                         * so we need to wait until all msgs have been hidden. */
      allMsgs.hide(duration, function() {
        if (++finished === allMsgs.length) {
          callback();
        }
      });
    } else {
      allMsgs.hide(duration);
    }

    this.message = false;
  }

  _PaginationLoader.prototype._showMsg = function(message) {
    var loader = this;
    this._hideAllMsgs(function() {
      loader._msgToJQuery[message].show(300);
    });
  };

  _PaginationLoader.prototype.showHint = function() {
    if (this.enabled && this.moreResultsAvailable && !this.isLoading() && !this.message) {
      console.log("Trying to show hint");
      this.$paginationHint.show("slow");
      this.message = "hint";
    }
  };

  /* Reset pagination to beginning and cancel possible AJAX-call
   * whose handlers have not yet been called. This should be
   * called each time search box query is changed. */
  _PaginationLoader.prototype.reset = function() {
    if (this.ajaxCallInProgress) this.ajaxCallInProgress.cancel();
    this.ajaxCallInProgress = false;
    this.paginationSeq = 2;
    this.moreResultsAvailable = true;
    this._hideAllMsgs();
  };

  _PaginationLoader.prototype.isLoading = function() {
    return this.ajaxCallInProgress ? true : false;
  };

  /* Methods to enable and disable PaginationLoader. */
  _PaginationLoader.prototype.disable = function() {
    this.enabled = false;
  };

  _PaginationLoader.prototype.enable = function() {
    this.enabled = true;
  };



  /* Localized prerequirement add/remove button strings */
  var prereqAddTextStr,
      prereqAddingTextStr,
      prereqRemoveTextStr,
      prereqRemovingTextStr;

  /* Companion class for prerequirement buttons to handle view state */
  var ButtonCompanion = function(state, button) {
    /* States: adding, removing, readyToAdd, readyToRemove */
    var states = { adding: null, removing: null, readyToAdd: null, readyToRemove: null };

    this.currentState = state in states ? state : readyToAdd;
    this.$button = $(button);
  }

  ButtonCompanion.prototype.stateTo = function(state) {
    if (state === 'adding') {

      this.$button.addClass("button-disabled");
      this.$button.text(prereqAddingTextStr);

    } else if (state === 'removing') {

      this.$button.addClass("button-disabled");
      this.$button.text(prereqRemovingTextStr);

    } else if (state === 'readyToAdd') {

      this.$button.addClass("skill-add-prereq-button");
      this.$button.removeClass("skill-remove-prereq-button");
      this.$button.text(prereqAddTextStr);
      this.$button.removeClass("button-disabled");

    } else if (state === 'readyToRemove') {

      this.$button.addClass("skill-remove-prereq-button");
      this.$button.removeClass("skill-add-prereq-button");
      this.$button.text(prereqRemoveTextStr);
      this.$button.removeClass("button-disabled");

    }
  };


  var prereqAddURL,
      prereqRemoveURL,
      skillIdRegexp = /^(search|prereq)-skill-id-(\d+)$/;

  /* Click event listener to add the selected skill from search results 
   * as a prerequirement. */
  function _addSearchedPrereqOnClick() {
    var $this           = $(this),
        $skillRow       = $this.parent().parent(),
        skillIdRegexp   = /^(search|prereq)-skill-id-(\d+)$/,
        id_match        = $skillRow.attr("id").match(skillIdRegexp),
        prereqSkillId   = id_match[2],
        buttonComp      = $this.data("button-companion");

    /* Lazily initialize ButtonCompanion object */
    if (!buttonComp) {
      buttonComp = new ButtonCompanion("readyToAdd", this);
      $this.data("button-companion", buttonComp);
    }

    function _parseSkillTemplateLocals($skillElem, includeCourseDetails) {
      var idStr       = $skillElem.attr("id"),
          skillId     = idStr.match(skillIdRegexp)[2],
          courseId    = $skillElem.data("for-course"),
          skillDesc   = $skillElem.find("td:first-child").text(),
          $courseElem = $("#search-course-id-" + courseId);

      var locals = {
        course_id: courseId,
        button_text: prereqRemoveTextStr
      };

      if (includeCourseDetails) {
        /* Include local to render both the course and its skill */
        locals.course_skills = [
          {
            id: skillId,
            description: skillDesc
          }
        ];

        locals.render_whole_course = true;
        locals.course_code = $courseElem.find("span.skill-search-course-code").text().trim();
        locals.course_name = $courseElem.find("span.skill-search-course-name").text().trim();
      } else {
        /* Include locals for rendering just one skill */
        locals.skill_id           = skillId;
        locals.skill_description  = skillDesc;
      }

      return locals;
    }

    buttonComp.stateTo("adding");
    $.post(prereqAddURL, { prereq_id: prereqSkillId }, function() {
      /* Render skill template and add the result to current prerequirements listing */
      var courseId = $skillRow.data("for-course"),
          courseShouldBeRendered = 
            $("#prereq-course-id-" + courseId, "#skill-current-prereqs").length === 0;
      if (courseShouldBeRendered) {
        /* Course does not yet exist in prequirements listing and needs to
         * be added. */
        var templ_locals = _parseSkillTemplateLocals($skillRow, true);
        
      } else {
        /* Course already exists in prerequirements listing */
        var templ_locals = _parseSkillTemplateLocals($skillRow);
      }
      
      var rendered_html = JST['templates/_current_course_with_prereq_skills'](templ_locals);

      if (courseShouldBeRendered) {
        $("#skill-current-prereqs tbody").prepend(rendered_html);
      } else {
        $("#prereq-course-id-" + courseId, "#skill-current-prereqs").after(rendered_html);
      }
      
      buttonComp.stateTo("readyToRemove");
    }).error(function() {
      console.log("AJAX update failed!");
      
      // TODO Failure notification
      buttonComp.stateTo("readyToAdd");
    });
  }

  /* Click handler for removing a searched prerequirement skill
   * from prerequirements. This handler handles both current prerequirements'
   * buttons and search results' buttons. */
  function _removeSearchedPrereqOnClick() {
    var $this           = $(this),
        $skillRow       = $this.parent().parent(),
        skillIdRegexp   = /^(search|prereq)-skill-id-(\d+)$/,
        id_match        = $skillRow.attr("id").match(skillIdRegexp),
        /* Button located either in prereq listing or search results */
        buttonLocation  = id_match[1], 
        prereqSkillId   = id_match[2];


    var $prereqButton, $searchResultButton;
    if (buttonLocation === "prereq") {
      $prereqButton = $this;
      $searchResultButton = $('#search-skill-id-' + prereqSkillId + 
        ' button[data-button-type="add-remove-prereq"]').first();
    } else {
      $searchResultButton = $this;
      $prereqButton = $('#prereq-skill-id-' + prereqSkillId + 
        ' button[data-button-type="add-remove-prereq"]').first();
    }

    function _laxyInitButtonCompanion($button) {
      var companion;
      if (!$button) { 
        var b = false; }
      if ($button && $button.length !== 0) { /* Do this only if we have a button */
        companion = $button.data("button-companion");
        /* Lazily initialize ButtonCompanion object */
        if (!companion) {
          companion = new ButtonCompanion("readyToAdd", $button[0]);  /* ButtonCompanion takes plain DOM-object */
          $prereqButton.data("button-companion", companion);
        }
      }
      return companion;
    }

    var prereqButtonComp        = _laxyInitButtonCompanion($prereqButton),
        searchResultButtonComp  = _laxyInitButtonCompanion($searchResultButton);

    if (prereqButtonComp) prereqButtonComp.stateTo("removing");
    if (searchResultButtonComp) searchResultButtonComp.stateTo("removing");

    /* Remove skill from prerequirements */
    $.post(prereqRemoveURL, { prereq_id: prereqSkillId }, function() {
      /* TODO Remove skill (and possibly course) from prerequirements listing */
      if ($prereqButton.length !== 0) {
        var courseId          = $skillRow.data("for-course"),
            $courseSkills     = $('tr[data-for-course="' + courseId + '"]', 
                                  "#skill-current-prereqs > tbody"),
            $skillToBeRemoved = $prereqButton.parent().parent();

        /* Remove from current prerequirements list */
        if ($courseSkills.length === 1) {
          /* The whole course element needs to be removed from view. */
          var $courseAndSkill = $("#prereq-course-id-" + courseId);
          $courseAndSkill = $courseAndSkill.add($skillToBeRemoved);

          $courseAndSkill.fadeOut("slow", function() {
            $courseAndSkill.detach();
          });
        
        } else {
          /* Only the skill element needs to be removed */
          $skillToBeRemoved.fadeOut("slow", function() {
            $(this).detach();
          });
        }
        
      }
      if (searchResultButtonComp) searchResultButtonComp.stateTo("readyToAdd");
    }).error(function() {
      console.log("AJAX update failed!");
      
      // TODO Failure notification
      if (prereqButtonComp) prereqButtonComp.stateTo("readyToRemove");
      if (searchResultButtonComp) searchResultButtonComp.stateTo("readyToRemove");
    });

  }


  /* Initialization */
  function _init() {
    var $metadata           = $("#metadata");
    $searchbox              = $("#skill-search-box");
    $searchResults          = $("#skill-search-results");
    $paginationFooter       = $("#skill-endless-pagination-footer");

    current_skill_id        = $metadata.data("skill-id");
    searchURL               = $metadata.data("skill-search-url");
    prereqAddURL            = $metadata.data("skill-prereq-add-url");
    prereqRemoveURL         = $metadata.data("skill-prereq-remove-url");

    /* Fetch localized strings for prerequirement add/remove buttons */
    prereqAddTextStr        = $metadata.data("prereq-add-text");
    prereqRemoveTextStr     = $metadata.data("prereq-remove-text");
    prereqAddingTextStr     = $metadata.data("prereq-adding-text");
    prereqRemovingTextStr   = $metadata.data("prereq-removing-text");

    pagination = new _PaginationLoader();

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
    $("#skill-current-prereqs").on("click", "button.skill-remove-prereq-button:not(.button-disabled)",
      _removeSearchedPrereqOnClick);

    /* Buttons of search results */
    $("#skill-search-results").on("click", "button.skill-add-prereq-button", 
      _addSearchedPrereqOnClick);

    $("#skill-search-results").on("click", "button.skill-remove-prereq-button", 
      _removeSearchedPrereqOnClick);

  };

  /* Module access object */
  return {
    initialize: _init,
    PaginationLoader: _PaginationLoader
  }

})();
