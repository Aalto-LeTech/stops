var profileCourseView = {
  
  showSkillDependencies: function() {
    var element = $(this);
    //var url = element.data('url');
    var skillId = element.data('skill-id');
    
    // Dim other skills
    $('#course-skills-column div').addClass('dim');
    element.removeClass('dim');
    
    // Activate progress bar
    $('#skill-prereqs').html('<img src="/images/progress.gif" />')
    $('#skill-future').html('<img src="/images/progress.gif" />')
    
    // Get prereqs
    // FIXME: hardcoded locale
    $.get('/fi/skills/' + skillId + '/prereqs', function(data) {
      $('#skill-prereqs').html(data);
    });
    
    // Get postreqs
    $.get('/fi/skills/' + skillId + '/future', function(data) {
      $('#skill-future').html(data);
    });
  },


  showPath: function() {
    
    var element = $(this);
    var skillId = element.data('skill-id');
    var profileId = $('#course-profile-graph').data('profile-id');
    
    // Dim other skills
    $('.course-skills-column div').addClass('dim');
    element.removeClass('dim');
    
    // Activate progress bar
    $('#skill-future').html('<img src="/images/progress.gif" />')
    
    // Get prereqs
    // FIXME: hardcoded locale
    $.get('/fi/skills/' + skillId + '/profilepath?profile_id=' + profileId, function(data) {
      $('#skill-future').html(data);
    });
    
  }
  
};

$(document).ready(function(){
  
  // Attach event listeners
  $('.course-skill-dependencies .skill').click(profileCourseView.showSkillDependencies);
  $('.course-profile-graph .skill').click(profileCourseView.showPath);
  
  
});


