#require 'csv'
require 'faster_csv'
 
class PrereqMatrix < CsvMatrix

  @@relation_types = {'T' => SUPPORTING_PREREQ, 'V' => STRICT_PREREQ}
  
  
  def initialize(csv, curriculum, locale)
    @matrix = FasterCSV.read(csv.path, :quote_char => '"')
    @row_count = @matrix.size
    @col_count = @row_count > 0 ? @matrix[0].size : 0
    @locale = locale.to_s
    @curriculum = curriculum
  end
  
  
  def process
    process_prereqs
    process_header
    process_relations
  end

  # Reads course codes and skills in the top. Populates the @cols_skills array.
  def process_header
    @cols_skills = Array.new(@col_count)
    @cols_courses = Array.new(@col_count)
  
    Skill.transaction do
      col = 8
      while col < @col_count
        code = @matrix[0][col]   # Course code
        
        # Skip blank cols
        if code.blank?
          col += 1
          next
        end
        
        code.strip!
        
        # Find course
        scoped_course = ScopedCourse.where(:code => code, :curriculum_id => @curriculum.id).first
        unless scoped_course
          puts "Header row contains an unknown course: #{code}"
          next
        end
        
        # Reset course prereqs
        scoped_course.course_prereqs.clear
          
        # Read skills until we encounter the next course
        skill_position = 0
        begin
          skill_description = @matrix[2][col]
          
          # Skip blank rows
          if skill_description.blank?
            col += 1
            next
          end

          # Load skill
          skill = Skill.where(:skillable_type => 'ScopedCourse', :skillable_id => scoped_course.id, :position => skill_position).first
          #course_skill = CourseSkill.where(['scoped_course_id = ? AND position = ?', scoped_course.id, skill_position]).joins(:skill).first
          
          unless skill
            puts "  SKILL #{skill_position} NOT FOUND"
            col += 1
            next
          end
          
          # Delete existing relations to avoid duplicates
          skill.prereqs.clear
          
          # Save for later use
          @cols_skills[col] = skill
          @cols_courses[col] = scoped_course
          
          skill_position += 1
          col += 1
        end while col < @col_count and @matrix[0][col].blank?
      end 
    end # transaction
  end
  
  
  def process_relations
    return unless @cols_skills and @rows_skills
    
    handled_courses = Hash.new
    
    SkillPrereq.transaction do
      
      for row in 6...@row_count
        for col in 8...@col_count
          next if @cols_skills[col].nil?
            
          relation_type = @@relation_types[(@matrix[row][col] || '').strip.upcase]
          next unless relation_type
          
          # Add skill prereq
          SkillPrereq.create(:skill_id => @cols_skills[col].id, :prereq_id => @rows_skills[row].id, :requirement => relation_type)
          
          # Add course prereq
          course_prereq = handled_courses["#{@cols_courses[col].id}-#{@rows_courses[row].id}"]
          
          if course_prereq.nil? || (course_prereq == SUPPORTING_PREREQ && relation_type == STRICT_PREREQ)
            # Does it exist?
            p = CoursePrereq.where(:scoped_course_id => @cols_courses[col].id, :scoped_prereq_id => @rows_courses[row].id).first
            
            # Insert if it does not exist
            if p.nil? || p.requirement == SUPPORTING_PREREQ && relation_type == STRICT_PREREQ  # FIXME: is this correct if we upload a changed matrix with reduced requirements
              CoursePrereq.delete_all(["scoped_course_id = ? AND scoped_prereq_id = ?", @cols_courses[col].id, @rows_courses[row].id])
              CoursePrereq.create(:scoped_course_id => @cols_courses[col].id, :scoped_prereq_id => @rows_courses[row].id, :requirement => relation_type)
            end
            
            # Make a note that this relation has been added
            handled_courses["#{@cols_courses[col].id}-#{@rows_courses[row].id}"] = relation_type
          end
        end
      end
    
    end # transaction
  end
  
end
