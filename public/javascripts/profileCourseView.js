var profileCourseView = {
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
  $('.skill').click(profileCourseView.showPath);
});


