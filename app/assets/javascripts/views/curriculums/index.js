//= require views/curriculums/action_modal.js

/*
 * Javascript for /curriculums view.
 */

(function() {

  /* Init */
  $(function() {

    var locale = $("#delete-modal-strings").data("locale");

    function curriculum_url(id) {
      if ($.isNumeric(id)) return "/" + locale + "/curriculums/" + id;
      else
        throw "curriculum_url received an id that is not a number!";
    }

    var modal = new o4.ActionModal({
          modal:    "#delete-modal",
          buttons:  ["#delete-modal button"],
          inputBox: "",
          errorBox: "#delete-modal-error-box",
          loading:  "#delete-modal-loading"
        }),
        i18n  = $("#delete-modal-strings").data();


    /*
     * JS for delete confirmation modal
     */
    $button = $("#delete-modal-delete-button");

    $button.on("ajax:before", function(evt) {
      modal.stateToLoading();
    });

    $button.on("ajax:success", function(evt, data, status, xhr) {
      modal.stateToDefault();
      modal.hide();
    });

    $button.on("ajax:error", function() {
      modal.stateToDefault();
      modal.showErrorMsg(i18n['errorHeading'], i18n['changeFailed']);
    });

    $('#curriculums-table').on("click", 'a[data-initiate-delete="true"]', function(evt) {
      var $targetButton = $(evt.target);

      /* Update delete URL */
      var url = curriculum_url($targetButton.data('targetId'));
      $("#delete-modal-delete-button").attr("href", url);

      /* Update the name of the curriculum to be deleted */
      var curriculumName = $targetButton
                            .parent()
                            .parent()
                            .find('td[data-name="true"]')
                            .text();
      $("#delete-modal-target-name").text(curriculumName);

      modal.show();
    });

  });

})();
