#require 'csv'
require 'fastercsv/lib/faster_csv'
 
class PrereqMatrix

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
  
  # Reads course codes and skills in the left. If the course or skill does not exist in the database, creates it. Populates the @prereq_skills array.
  def process_prereqs
    @prereq_skills = Array.new(@row_count)
  
    Skill.transaction do
      row = 6
      while row < @row_count
        code = @matrix[row][0]  # Course code in the left column
        
        # Skip blank rows
        if code.blank?
          row += 1
          next
        end
        
        # Parse course attributes
        code.strip!
        name = (@matrix[row][1] || '').strip
        period = (@matrix[row][2] || '').strip
        credits = (@matrix[row][3] || '').strip
        
        # Insert or update course
        course = Course.find(:first, :conditions => {:code => code, :curriculum_id => @curriculum.id})
        if course
          # Update existing course
          course.credits = credits
          course.save
        else
          # Create new course
          course = Course.create(:code => code, :curriculum_id => @curriculum.id, :credits => credits.gsub(',','.').to_f)
          
          # FIXME: description is not specific to curriculum. Check if description exists.
          description = CourseDescription.new(:locale => @locale, :name => name)
          description.course = course
          description.save
          #CourseDescription.create(:code => code, :locale => @locale, :name => name)
        end
        
        
        # Read skills until we encounter the next course
        skill_position = 0
        begin
          skill_description = @matrix[row][5]
          
          # Skip blank rows
          if skill_description.blank?
            row += 1
            next
          end

          # Parse attributes
          skill_credits = @matrix[row][6] || '0'
          level = @matrix[row][7] || '0'
          
          # Insert or update skill
          skill = Skill.find(:first, :conditions => {:course_id => course.id, :position => skill_position})
          
          unless skill
            skill = Skill.create(:course_id => course.id, :credits => skill_credits.gsub(',','.').to_f, :level => level.to_i, :position => skill_position)
            SkillDescription.create(:skill_id => skill.id, :locale => @locale, :description => skill_description)
          end
          
          # Save for later use
          @prereq_skills[row] = skill
          
          skill_position += 1
          row += 1
        end while row < @row_count and @matrix[row][0].blank?
      end 
    end # transaction
  end
  
  
  # Reads course codes and skills in the top. Populates the @skills array.
  def process_header
    @skills = Array.new(@col_count)
  
    Skill.transaction do
      col = 8
      while col < @col_count
        code = @matrix[0][col]   # Course code
        
        # Skip blank cols
        if code.blank?
          col += 1
          next
        end
        
        course = Course.find(:first, :conditions => {:code => code.strip, :curriculum_id => @curriculum.id})
          
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
          skill = Skill.find(:first, :conditions => {:course_id => course.id, :position => skill_position})
          
          unless skill
            puts "  SKILL #{skill_position} NOT FOUND"
            col += 1
            next
          end
          
          # Delete existing relations to avoid duplicates
          skill.prereqs.clear
          
          # Save for later use
          @skills[col] = skill
          
          skill_position += 1
          col += 1
        end while col < @col_count and @matrix[0][col].blank?
      end 
    end # transaction
  end
  
  
  def process_relations
    return unless @skills and @prereq_skills
    
    course_relations = Hash.new
    
    SkillPrereq.transaction do
      
      for row in 6...@row_count
        for col in 8...@col_count
          next if @skills[col].nil?
            
          relation_type = @@relation_types[(@matrix[row][col] || '').strip.upcase]
          
          if relation_type
            # Add skill prereq
            SkillPrereq.create(:skill_id => @skills[col].id, :prereq_id => @prereq_skills[row].id, :requirement => relation_type)
            
            # Add course prereq
            course_prereq = course_relations["#{@skills[col].course_id}#{@prereq_skills[row].course_id}"]
            if course_prereq.nil? || (course_prereq == SUPPORTING_PREREQ && relation_type == STRICT_PREREQ)
              # Insert if it does not exist
              p = CoursePrereq.find(:first, :conditions => {:course_id => @skills[col].course_id, :prereq_id => @prereq_skills[row].course_id})
              if p.nil? || p.requirement == SUPPORTING_PREREQ && relation_type == STRICT_PREREQ
                CoursePrereq.delete_all(["course_id = ? AND prereq_id = ?", @skills[col].course_id, @prereq_skills[row].course_id])
                CoursePrereq.create(:course_id => @skills[col].course_id, :prereq_id => @prereq_skills[row].course_id, :requirement => relation_type)
              end
              
              # Make a note that this relation has been added
              course_relations["#{@skills[col].course_id}#{@prereq_skills[row].course_id}"] = relation_type
            end
            
          end
        end
      end
    
    end # transaction
  end
  
end
