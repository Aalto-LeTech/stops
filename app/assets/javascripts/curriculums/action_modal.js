(function(namespace) {
  function ActionModal(selectors) {
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
    this.$modal
      .on("hidden", function() {
        /* Reset modal */
        that.hideErrorMsg();
      })
      .on("hide", function(evt) {
        /* Disable hiding if loading */
        if (that.loading) evt.preventDefault();
      });

  }

  ActionModal.prototype.stateToLoading = function() {   
    this.loading = true;

    // Disable buttons while loading
    $.each(this.buttons, function(i, $button) {
      $button.prop("disabled", true);
      $button.addClass("button-disabled");
    });

    this.hideErrorMsg();

    this.$loadingMask.removeClass("hide");

    if (this.$inputBox.length) { 
      /* Save the name so we can update the page later */
      this.newName = this.$inputBox.val();
    }
  };

  ActionModal.prototype.stateToDefault = function() {
    // Enable buttons
    $.each(this.buttons, function(i, $button) {
      $button.prop("disabled", false);
      $button.removeClass("button-disabled");
    });

    this.loading = false;

    this.$loadingMask.addClass("hide");
  };

  ActionModal.prototype.show = function() {
    this.$modal.modal("show");
  };

  ActionModal.prototype.hide = function() {
    // Forward hide to bootstrap hide()
    this.hideErrorMsg();
    this.$modal.modal("hide");
  };

  ActionModal.prototype.showErrorMsg = function(heading, msg) {
    this.$modalErrorBox.addClass("hide");

    this.$modalErrorBox.html("<strong>" + heading + "</strong> " + msg);

    this.$modalErrorBox.removeClass("hide");
  };

  ActionModal.prototype.hideErrorMsg = function() {
    this.$modalErrorBox.addClass("hide");
  };

  namespace['ActionModal'] = ActionModal;

})(window.o4 || (window.o4 = {}));