(function() {

  function showNewSkillErrorMessage(message) {
    var $error_box          = $("#new-skill-box-error-message"),
        $error_box_contents = $error_box.find("div.skill-error-contents");

    $error_box_contents.html(message);
    $error_box.removeClass("hide");
  }

  function hideNewSkillErrorMessage() {
    $("#new-skill-box-error-message").addClass("hide");
  }

  function showNewSkillSavingMessage() {
    $("#new-skill-box-saving-message").removeClass("hide");
    $("#new-skill-box-loading-icon").removeClass("hide");
  }

  function hideNewSkillSavingMessage() {
    $("#new-skill-box-loading-icon").addClass("hide");
    $("#new-skill-box-saving-message").addClass("hide");
  }
  

  /* Initialization */
  $(function() {
    var $new_skill_button             = $("#new-skill-button"),
        $new_skill_box_loading_icon   = $("#new-skill-box-loading-icon"),
        new_skill_box_error_message   = $("#metadata").data("skill-box-error-message"),
        new_skill_save_failed_message = $("#metadata").data("new-skill-save-failed-message");

    /* Handle success and error of saving new skill */
    $("#new-skill-box-content")
      .on("ajax:beforeSend", "form", function() {
        $("#new-skill-box").addClass("hide");
        hideNewSkillErrorMessage();
        showNewSkillSavingMessage();
      })
      .on("ajax:success", "form", function() {
        hideNewSkillSavingMessage();
        $new_skill_button.removeClass("button-disabled");
      })
      .on("ajax:error", "form", function() {
        hideNewSkillSavingMessage();
        showNewSkillErrorMessage(new_skill_save_failed_message);
        $("#new-skill-box-validation-message").addClass("hide");
        $("#new-skill-box").removeClass("hide");
      });

    /* Save new skill button */
    $("#new-skill-box > .new-skill-box-footer > .save-button").click(function() {
      /* Check that all locales have required descriptions */
      var descs = $("input.new-skill-field", "#new-skill-box"),
          dataIsValid = true;
      descs.each(function() {
        if ($(this).val().length === 0) {
          dataIsValid = false;
        }
      });  

      if (dataIsValid) {
        $("#new-skill-box-content > form").submit(); // Success & failure handling above
        
      } else {
        /* Show validation error message */
        $("#new-skill-box-validation-message").removeClass("hide");
      }
    });

    function closeNewSkillBox() {
      $("#new-skill-box").addClass("hide");
      $new_skill_button.removeClass("button-disabled");
    }

    /* Cancel & close buttons */ 
    $("#new-skill-box > .new-skill-box-footer > .cancel-button").click(closeNewSkillBox);
    $("#new-skill-box > .new-skill-close").click(closeNewSkillBox);


    /* Listeners to update view on new skill -button click */
    $("#new-skill-button")
      .on("ajax:before", function(evt) {
        if ($new_skill_button.hasClass("button-disabled")) {
          /* Request already in progress, do nothing */
          return false;
        } else {
          /* Show loading icon and disable button */
          hideNewSkillErrorMessage();
          $new_skill_box_loading_icon.removeClass("hide");
          $new_skill_button.addClass("button-disabled");

          return true;   /* Allow Rails UJS to perform AJAX-request */
        }
      })
      .on("ajax:success", function(evt) {
        $new_skill_box_loading_icon.addClass("hide");
        $("#new-skill-box-validation-message").addClass("hide");
      })
      .on("ajax:error", function(evt) {
        $new_skill_box_loading_icon.addClass("hide");
        $new_skill_button.removeClass("button-disabled");
        showNewSkillErrorMessage(new_skill_box_error_message);

      });

  });

})();
