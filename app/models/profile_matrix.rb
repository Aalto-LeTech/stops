require 'csv'
#require 'faster_csv'


class ProfileMatrix < CsvMatrix

  @@relation_types = {'T' => SUPPORTING_PREREQ, 'V' => STRICT_PREREQ}


  def initialize(csv, curriculum, locale)
    @matrix = CSV.read(csv.path, :quote_char => '"')
    @row_count = @matrix.size
    @col_count = @row_count > 0 ? @matrix[0].size : 0
    @locale = locale.to_s
    @curriculum = curriculum
  end


  def process
    process_profile
    process_prereqs
    process_header
    process_relations
  end

  def process_profile
    # Create new profile
    @profile = Profile.create(:curriculum_id => @curriculum.id)
    #ProfileDescription.create(:profile_id => @profile.id, :locale => @locale, :name => profile_name.strip)
  end

  # Reads profiles at the top
  def process_header
    @competences = Array.new  # Holds copies so that profiles don't have to be re-loaded on the next iteration
    @skills = Array.new

    competence_counter = 1
    competence = nil
    Competence.transaction do
      col = 8
      while col < @col_count
        competence_name = @matrix[0][col]
        competence_description = @matrix[1][col]

        # Skip blank columns
        if competence_name.blank?
          col += 1
          next
        end

        # Create new competence
        competence = Competence.create(:profile_id => @profile.id, :level => competence_counter)
        CompetenceDescription.create(:competence_id => competence.id, :locale => @locale, :name => competence_name.strip, :description => competence_description.strip)

        competence_counter += 1

        # Read skills until we encounter the next competence
        skill_position = 0
        begin
          skill_description = @matrix[3][col]

          # Skip blank rows
          if skill_description.blank?
            col += 1
            next
          end

          # Create skill
          skill = Skill.create(:position => skill_position, :skillable => competence)
          SkillDescription.create(:skill_id => skill.id, :locale => @locale, :description => skill_description.strip)

          unless skill
            puts "Failed to create skill for profile. col=#{col}"
          end

          # Save for later use
          @skills[col] = skill
          @competences[col] = competence

          skill_position += 1
          col += 1
        end while col < @col_count and @matrix[1][col].blank?
      end
    end # transaction

  end


  def process_relations
    return unless @competences && @skills && @rows_skills

    handled_courses = Hash.new  # holds the information about which prereqs have already been added to avoid unnecessary database actions

    Competence.transaction do
      for row in 6...@row_count
        for col in 8...@col_count
          next if @competences[col].nil?

          # Skip empty cells
          next if (@matrix[row][col] || '').strip.blank?

          if @competences[col].nil?
            puts "Unknown competence in column #{col}"
            next
          end

          if @skills[col].nil?
            puts "Unknown skill in column #{col}"
            next
          end

          if @rows_skills[row].nil?
            puts "Unknown skill in row #{row}"
            next
          end

          # Add skill prereq
          SkillPrereq.create(:skill_id => @skills[col].id, :prereq_id => @rows_skills[row].id, :requirement => STRICT_PREREQ)

          # Add course prereq if this competence-course pair has not been added
          course_prereq = handled_courses["#{@competences[col].id}-#{@rows_courses[row].id}"]

          if course_prereq.nil?
            # Does it exist?
            p = CompetenceCourse.where(:competence_id => @competences[col].id, :scoped_course_id => @rows_courses[row].id).first

            # Insert if it does not exist
            if p.nil?
              CompetenceCourse.delete_all(["competence_id = ? AND scoped_course_id = ?", @competences[col].id, @rows_courses[row].id])
              CompetenceCourse.create(:competence_id => @competences[col].id, :scoped_course_id => @rows_courses[row].id, :requirement => STRICT_PREREQ)
            end

            # Make a note that this relation has been added
            handled_courses["#{@competences[col].id}-#{@rows_courses[row].id}"] = STRICT_PREREQ
          end
        end
      end

    end # transaction
  end

end
