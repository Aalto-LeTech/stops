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
    var url = element.data('url');
    var skillId = element.data('skill-id');
    var profileId = $('#course-profile-graph').data('profile-id');
    
    $('#skill-future').css('background-image', 'url("/images/progress.gif")');
    
    //$('#skill-future').html("<%= escape_javascript(render 'profilepath', :paths => @paths) %>");  
//     $.ajax({url: url,
//             context: element,
//             //data: {profileId: profileId},
//             dataType: 'html'
//     });

    
    //$.post($(this).attr('href'), { _method: 'delete' });

    jQuery.ajax({
        async: true, 
        url: url,
        type: 'GET',
        data: { _method:'GET' }, 
        success: function(){alert('ok')},
        error: function(request){ alert('Sorry, there was an error!!!')}
    });
    
    
    

    $('#skill-future').css('background-image', 'none');
    
    alert(skillId);
  }
  
};

$(document).ready(function(){
  
  // Attach event listeners
  $('.course-skill-dependencies .skill').click(profileCourseView.showSkillDependencies);
});


