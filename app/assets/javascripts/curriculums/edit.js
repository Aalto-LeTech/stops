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