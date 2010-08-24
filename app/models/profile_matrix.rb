require 'csv'

 
class ProfileMatrix

  @@relation_types = {'T' => SUPPORTING_PREREQ, 'V' => STRICT_PREREQ}
  
  
  def initialize(csv, curriculum, locale)
    @matrix = CSV.read(csv.path, :quote_char => '"')
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
  
  # Reads course codes and skills in the left. If a course or skill does not exist in the database, creates it. Populates the @prereq_skills array.
  def process_prereqs
    @prereq_skills = Array.new(@row_count)  # Array will contain skill objects. Indexing matches the rows of the original matrix.
  
    Skill.transaction do
      for row in 0...@row_count
        code = (@matrix[row][0] || '').strip
        
        # Skip rows that do not begin with a course code
        next unless code =~ COURSE_CODE_FORMAT
        
        # Parse course attributes
        name = (@matrix[row][1] || '').strip
        credits = (@matrix[row][2] || '').strip
        
        # Insert or update course
        course = Course.find_by_code(code)
        if course
          # Update existing course
          course.credits = credits
          course.save
        else
          # Create new course
          course = Course.create(:code => code, :curriculum_id => @curriculum.id, :credits => credits.gsub(',','.').to_f)
          description = CourseDescription.new(:locale => @locale, :name => name)
          description.course = course
          description.save
        end
        
        
        # Read skills until we encounter the next course
        skill_position = 0
        begin
          skill_description = @matrix[row][4]
          
          # Skip blank rows
          if skill_description.blank?
            row += 1
            next
          end

          # Parse attributes
          skill_credits = @matrix[row][5] || '0'
          
          # Insert or update skill
          skill = Skill.find(:first, :conditions => {:course_code => code, :position => skill_position})
          
          unless skill
            skill = Skill.create(:course_code => code, :credits => skill_credits.gsub(',','.').to_f, :position => skill_position)
            SkillDescription.create(:skill_id => skill.id, :locale => @locale, :description => skill_description)
          end
          
          @prereq_skills[row] = skill
          
          skill_position += 1
          row += 1
        end while row < @row_count and @matrix[row][0].blank?
      end 
    end # transaction
  end
  
  
  # Reads profiles
  def process_header
    Profile.delete_all
    
    @profiles = Array.new
    
    profile_counter = 1
    profile = nil
    Profile.transaction do
      for col in 7...@col_count
        profile_name = (@matrix[1][col] || '').strip
        
        # Skip blank columns
        if profile_name.blank?
          @profiles[col] = profile
          next
        end
        
        # Create new profile
        profile = Profile.create(:curriculum_id => @curriculum.id, :position => profile_counter)
        ProfileDescription.create(:profile_id => profile.id, :locale => @locale, :name => profile_name)
        
        @profiles[col] = profile
        
        profile_counter += 1
      end 
    end # transaction
  end
  
  
  def process_relations
    return unless @prereq_skills && @profiles
    
    areas = Area.find(:all, :order => 'position')
    areas.each do |area|
      puts "area_id=#{area.id}  area_position=#{area.position}"
    end
    
    course_relations = Hash.new
    
    ProfileSkill.delete_all
    
    Profile.transaction do
      
      for row in 16...@row_count
        for col in 7...@col_count
          
          unless @matrix[1][col].blank?
            # Reset are counter when encountering the next profile
            area_counter = 1
          end
            
          relation_type = @@relation_types[(@matrix[row][col] || '').strip.upcase]
          
          if relation_type
            if @profiles[col].nil?
              puts "Unknown profile in column #{col}"
              next
            end
            
            if @prereq_skills[row].nil?
              puts "Unknown skill in row #{row}"
              next
            end
            
            if areas[area_counter].nil?
              puts "Unknown area: row #{row}, area #{area_counter}"
              next
            end
            
            
            # Add skill prereq
            ProfileSkill.create(:profile_id => @profiles[col].id, :skill_id => @prereq_skills[row].id, :area_id => areas[area_counter].id, :requirement => relation_type)
            
            # Add course prereq if this profile-course pair has not been added
            course_prereq = course_relations["#{@profiles[col].id}#{@prereq_skills[row].course_code}"]
            if course_prereq.nil? || (course_prereq == SUPPORTING_PREREQ && relation_type == STRICT_PREREQ)
              # Insert if it does not exist
              p = ProfileCourse.find(:first, :conditions => {:profile_id => @profiles[col].id, :course_id => @prereq_skills[row].course.id})
              if p.nil? || p.requirement == SUPPORTING_PREREQ && relation_type == STRICT_PREREQ
                ProfileCourse.delete_all(["profile_id = ? AND course_id = ?", @profiles[col].id, @prereq_skills[row].course.id])
                ProfileCourse.create(:profile_id => @profiles[col].id, :course_id => @prereq_skills[row].course.id, :requirement => relation_type)
              end
              
              # Make a note that this relation has been added
              course_relations["#{@profiles[col].id}#{@prereq_skills[row].course_code}"] = relation_type
            end
            
            area_counter += 1
          end
        end
      end
    
    end # transaction
  end
  
end
