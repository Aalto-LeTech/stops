module CoursesHelper

  def skill_prereq(skill_id, prereq_id)
    p = SkillPrereq.find(:first, :conditions => {:skill_id => skill_id, :prereq_id => prereq_id})
    
    return '' unless p
    
    case p.requirement
    when STRICT_PREREQ
      return '<span style="font-size: 125%;">&diams;</span>'.html_safe
    when SUPPORTING_PREREQ
      return '<span style="font-size: 125%; color: gray;">&bull;</span>'.html_safe
    else
      return ''
    end
  end


  def scoped_course_comment(field)
    "<textarea name='comments[#{field}]' class='input-xxlarge' rows='5'>#{html_escape(@scoped_course.comment(field))}</textarea>".html_safe
  end
  
end
