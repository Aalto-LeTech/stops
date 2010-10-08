#require 'csv'
require 'fastercsv/lib/faster_csv'

 
class ProfileMatrix < CsvMatrix

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
  
  # Reads course codes and skills in the left. If a course or skill does not exist in the database, create it. Populates the @prereq_skills array.
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
        abstract_course = insert_or_update_abstract_course(code, name, @locale, nil)
        scoped_course = insert_or_update_scoped_course(abstract_course, @curriculum, credits, nil)
        
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
          skill = Skill.where(:scoped_course_id => scoped_course.id, :position => skill_position).first
          
          unless skill
            skill = Skill.create(:scoped_course_id => scoped_course.id, :credits => skill_credits.gsub(',','.').to_f, :position => skill_position)
            SkillDescription.create(:skill_id => skill.id, :locale => @locale, :description => skill_description.strip)  # FIXME: language versions
          end
          
          # Save for later use
          @prereq_skills[row] = skill
          
          skill_position += 1
          row += 1
        end while row < @row_count and @matrix[row][0].blank?
      end 
    end # transaction
  end
  
  
  # Reads profiles
  def process_header
    @curriculum.profiles.clear
    
    @profiles = Array.new  # Holds copies so that profiles don't have to be re-loaded on the next iteration
    @skills = Array.new
    
    profile_counter = 1
    profile = nil
    Profile.transaction do
      col = 7
      while col < @col_count
        profile_name = @matrix[1][col]
        
        # Skip blank columns
        if profile_name.blank?
          col += 1
          next
        end
        
        # Create new profile
        profile = Profile.create(:curriculum_id => @curriculum.id, :position => profile_counter)
        ProfileDescription.create(:profile_id => profile.id, :locale => @locale, :name => profile_name.strip)
        
        @profiles[col] = profile
        
        profile_counter += 1
        
        
        # Read skills until we encounter the next profile
        skill_position = 0
        begin
          skill_description = @matrix[2][col]
          
          # Skip blank rows
          if skill_description.blank?
            col += 1
            next
          end

          # Create skill
          skill = Skill.create(:position => skill_position)
          SkillDescription.create(:skill_id => skill.id, :locale => @locale, :description => skill_description.strip)
          profile.skills << skill
          
          unless skill
            puts "Failed to create skill for profile. col=#{col}"
          end
          
          # Save for later use
          @skills[col] = skill
          @profiles[col] = profile
          
          skill_position += 1
          col += 1
        end while col < @col_count and @matrix[1][col].blank?
      end 
    end # transaction
    
  end
  
  
  def process_relations
    return unless @profiles && @skills && @prereq_skills
    
    course_relations = Hash.new  # holds the information about which prereqs have already been added to avoid unnecessary database actions
    
    Profile.transaction do
      for row in 16...@row_count
        for col in 7...@col_count
          
          unless @matrix[1][col].blank?
            # Reset counter when encountering the next profile
            skill_counter = 1
          end
          
          # Is this strict or supporting prereq
          relation_type = @@relation_types[(@matrix[row][col] || '').strip.upcase]
          next unless relation_type
            
          if @profiles[col].nil?
            puts "Unknown profile in column #{col}"
            next
          end
          
          if @skills[col].nil?
            puts "Unknown skill in column #{col}"
            next
          end
          
          if @prereq_skills[row].nil?
            puts "Unknown skill in row #{row}"
            next
          end
          
          # Add skill prereq
          SkillPrereq.create(:skill_id => @skills[col].id, :prereq_id => @prereq_skills[row].id, :requirement => relation_type)
          
          # Add course prereq if this profile-course pair has not been added
          course_prereq = course_relations["#{@profiles[col].id}#{@prereq_skills[row].scoped_course_id}"]
          if course_prereq.nil? || (course_prereq == SUPPORTING_PREREQ && relation_type == STRICT_PREREQ)
            # Insert if it does not exist
            p = ProfileCourse.find(:first, :conditions => {:profile_id => @profiles[col].id, :scoped_course_id => @prereq_skills[row].scoped_course_id})
            if p.nil? || p.requirement == SUPPORTING_PREREQ && relation_type == STRICT_PREREQ
              ProfileCourse.delete_all(["profile_id = ? AND scoped_course_id = ?", @profiles[col].id, @prereq_skills[row].scoped_course_id])
              ProfileCourse.create(:profile_id => @profiles[col].id, :scoped_course_id => @prereq_skills[row].scoped_course_id, :requirement => relation_type)
            end
            
            # Make a note that this relation has been added
            course_relations["#{@profiles[col].id}#{@prereq_skills[row].scoped_course_id}"] = relation_type
          end
          
          skill_counter += 1
        end
      end
    
    end # transaction
  end
  
end
