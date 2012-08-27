/* 
 * Javascript for /curriculums/:id/edit view.
 */

(function() {

  function NameChangeModal(selectors) {
    this.$modal   = $(selectors.modal);
    this.buttons  = $.map(selectors.buttons, function(selector) {
      return $(selector);
    });

    this.$inputBox      = $(selectors.inputBox);
    this.$modalErrorBox = $(selectors.errorBox);
    this.$loadingMask   = $(selectors.loading);
    this.loading        = false;
    this.newName        = false;

    var that = this;
    $(selectors.modal)
      .on("hidden", function() {
        /* Reset modal */
        that.hideErrorMsg();
      })
      .on("hide", function(evt) {
        /* Disable hiding if loading */
        if (that.loading) evt.preventDefault();
      });
  }

  NameChangeModal.prototype.stateToLoading = function() {   
    this.loading = true;

    // Disable buttons while loading
    $.each(this.buttons, function(i, $button) {
      $button.prop("disabled", true);
      $button.addClass("button-disabled");
    });

    this.hideErrorMsg();

    this.$loadingMask.removeClass("hide");

    /* Save the name so we can update the page later */
    this.newName = this.$inputBox.val();
  };

  NameChangeModal.prototype.stateToDefault = function() {
    // Enable buttons
    $.each(this.buttons, function(i, $button) {
      $button.prop("disabled", false);
      $button.removeClass("button-disabled");
    });

    this.loading = false;

    this.$loadingMask.addClass("hide");
  };

  NameChangeModal.prototype.hide = function() {
    // Forward hide to bootstrap hide()
    this.hideErrorMsg();
    this.$modal.modal("hide");
  };

  NameChangeModal.prototype.showErrorMsg = function(heading, msg) {
    this.$modalErrorBox.addClass("hide");

    this.$modalErrorBox.html("<strong>" + heading + "</strong> " + msg);

    this.$modalErrorBox.removeClass("hide");
  };

  NameChangeModal.prototype.hideErrorMsg = function() {
    this.$modalErrorBox.addClass("hide");
  };


  /* Init */
  $(function() {

    var modal = new NameChangeModal({
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