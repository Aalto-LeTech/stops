/* 
 * Javascript for /curriculums/:id/edit view.
 */

(function() {

  /* Init */
  $(function() {

    var modal = new o4.ActionModal({
          modal:    "#edit-modal", 
          buttons:  ["#edit-modal button"], 
          inputBox: "#curriculum_name", 
          errorBox: "#edit-modal-error-box",
          loading:  "#edit-modal-loading"
        }),
        i18n  = $("#edit-modal-strings").data();

    /* 
     * JS for change name -modal
     */
    var $form = $("#edit-modal-form");
    $form.on("ajax:before", function(evt) {
      if (modal.$inputBox.val() === '') {
        modal.showErrorMsg(i18n['errorHeading'], i18n['boxEmpty']);
        modal.stateToDefault();

        return false;
      }

      modal.stateToLoading();
    });

    $form.on("ajax:success", function(evt, data, status, xhr) {
      // Close modal and update name on the page
      modal.stateToDefault();
      modal.hide();
      
      $("#name-heading").text(modal.newName);
    });

    $form.on("ajax:error", function() {
      // Show error on the form
      modal.stateToDefault();
      modal.showErrorMsg(i18n['errorHeading'], i18n['changeFailed']);
    });

    $("#edit-modal-form-submit").click(function() {
      /* Submits Curriculum name change form */
      $("#edit-modal-form").submit();
    });

  });
})();



/* 
 *  New course form logic
 */

(function() {

  function showNewCourseErrorMessage(message) {
    var $error_box          = $("#new-course-box-error-message"),
        $error_box_contents = $error_box.find("div.course-error-contents");

    $error_box_contents.html(message);
    $error_box.removeClass("hide");
  }

  function hideNewCourseErrorMessage() {
    $("#new-course-box-error-message").addClass("hide");
  }

  function showNewCourseSavingMessage() {
    $("#new-course-box-saving-message").removeClass("hide");
    $("#new-course-box-loading-icon").removeClass("hide");
  }

  function hideNewCourseSavingMessage() {
    $("#new-course-box-loading-icon").addClass("hide");
    $("#new-course-box-saving-message").addClass("hide");
  }
  

  /* Initialization */
  $(function() {
    var $new_course_button             = $("#new-course-button"),
        $new_course_box_loading_icon   = $("#new-course-box-loading-icon"),
        new_course_box_error_message   = $("#metadata").data("course-box-error-message"),
        new_course_save_failed_message = $("#metadata").data("new-course-save-failed-message");

    /* Handle success and error of saving new course */
    $("#new-course-box-content")
      .on("ajax:beforeSend", "form", function() {
        $("#new-course-box").addClass("hide");
        hideNewCourseErrorMessage();
        showNewCourseSavingMessage();
      })
      .on("ajax:success", "form", function() {
        hideNewCourseSavingMessage();
        $new_course_button.removeClass("button-disabled");
      })
      .on("ajax:error", "form", function() {
        hideNewCourseSavingMessage();
        showNewCourseErrorMessage(new_course_save_failed_message);
        $("#new-course-box-validation-message").addClass("hide");
        $("#new-course-box").removeClass("hide");
      });

    /* Save new course button */
    $("#new-course-box > .new-course-box-footer > .save-button").click(function() {
      /* Check that all locales have required descriptions */
      var descs = $("input.new-course-field", "#new-course-box"),
          dataIsValid = true;
      descs.each(function() {
        if ($(this).val().length === 0) {
          dataIsValid = false;
        }
      });  

      if (dataIsValid) {
        $("#new-course-box-content > form").submit(); // Success & failure handling above
        
      } else {
        /* Show validation error message */
        $("#new-course-box-validation-message").removeClass("hide");
      }
    });

    function closeNewCourseBox() {
      $("#new-course-box").addClass("hide");
      $new_course_button.removeClass("button-disabled");
    }

    /* Cancel & close buttons */ 
    $("#new-course-box > .new-course-box-footer > .cancel-button").click(closeNewCourseBox);
    $("#new-course-box > .new-course-close").click(closeNewCourseBox);


    /* Listeners to update view on new course -button click */
    $("#new-course-button")
      .on("ajax:before", function(evt) {
        if ($new_course_button.hasClass("button-disabled")) {
          /* Request already in progress, do nothing */
          return false;
        } else {
          /* Show loading icon and disable button */
          hideNewCourseErrorMessage();
          $new_course_box_loading_icon.removeClass("hide");
          $new_course_button.addClass("button-disabled");

          return true;   /* Allow Rails UJS to perform AJAX-request */
        }
      })
      .on("ajax:success", function(evt) {
        $new_course_box_loading_icon.addClass("hide");
        $("#new-course-box-validation-message").addClass("hide");
      })
      .on("ajax:error", function(evt) {
        $new_course_box_loading_icon.addClass("hide");
        $new_course_button.removeClass("button-disabled");
        showNewCourseErrorMessage(new_course_box_error_message);

      });

  });


  /* Code for handling different form options */
  (function() {
    var $contents = $('#new-course-box-content');
    $('#new-course-box-content').on('change', '#course-form-teaching-lang', function() {
      console.log("Course form: CHANGE event caught...");
      var $this = $(this);
      var $formGroups = $contents.find('.form-control-group');
      var otherFields = $formGroups.filter('[data-name-locale="fi"]');
      otherFields = otherFields.add($formGroups.filter('[data-name-locale="sv"]').first());
      
      /* If English is selected as the teaching language of the course,
         slide up the fields for the other locales. */
      if ($this.val() === 'en') {
        otherFields.slideUp();
      } else {
        otherFields.slideDown();
      }
    });
  })();

})();
