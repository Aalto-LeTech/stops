var profileCourseView = {
  
  showSkillDependencies: function() {
    var element = $(this);
    var skillId = element.data('skill-id');
    var path = element.attr('href');
    
    // Dim other skills
    $('#course-skills-column a').addClass('dim');
    element.removeClass('dim');
    
    // Activate progress bar
    $('#skill-prereqs').html('<div class="progress"></div>');
    $('#skill-future').html('<div class="progress"></div>');
    
    // Get prereqs
    $.get(path + '/prereqs', function(data) {
      $('#skill-prereqs').html(data);
    });
    
    // Get postreqs
    $.get(path + '/future', function(data) {
      $('#skill-future').html(data);
    });
    
    return false;
  },


  showPath: function() {
    
    var element = $(this);
    var skillId = element.data('skill-id');
    var profileId = $('#course-profile-graph').data('profile-id');
    var path = element.attr('href');
    
    // Dim other skills
    $('.course-skills-column a').addClass('dim');
    element.removeClass('dim');
    
    // Activate progress bar
    $('#skill-future').html('<div class="progress"></div>');
    
    // Get prereqs
    $.get(path, function(data) {
      $('#skill-future').html(data);
    });
    
  
    return false;
  }
  
};

$(document).ready(function(){
  
  // Attach event listeners
  $('.course-skill-dependencies .skill').click(profileCourseView.showSkillDependencies);
  $('.course-profile-graph .skill').click(profileCourseView.showPath);
  
});
