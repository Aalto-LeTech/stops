module TempCoursesHelper
  
  def temp_course_comment(field)
    "<textarea name='comments[#{field}]' class='input-xxlarge' rows='5'>#{html_escape(@temp_course.comment(field))}</textarea>".html_safe
  end

end
