namespace :db do
  desc "Recalculate cached data"
  task :refresh_cache => :environment do
    CompetenceNode.find_each do |node|
      puts node.localized_name
      node.update_prereqs_cache()
    end
    puts "done"
    
    # Temporary hack: Add hard-coded course prereqs
    forced_prereqs = {74 => [37, 36, 10, 11, 15, 9, 35, 39, 40, 34]}
    forced_prereqs.each do |node_id, prereq_ids|
      prereq_ids.each do |prereq_id|
        NodePrereq.create(:competence_node_id => node_id, :prereq_id => prereq_id, :requirement => STRICT_PREREQ)
      end
    end
  end
  
  task :link_stats => :environment do
    stats = []
    
    ScopedCourse.find_each do |node|
      prereq_to_courses_count = node.strict_prereq_to_courses.size
      
      prereq_to_skills_count = 0
      node.skills.each do |skill|
        prereq_to_skills_count += skill.skill_prereq_to.size
      end
      
      stats << [node, prereq_to_courses_count, prereq_to_skills_count, prereq_to_courses_count * 1000 + prereq_to_skills_count]
    end
    
    stats.sort! {|a, b| a[3] <=> b[3] }
    
    
    Competence.where(:parent_competence_id => nil).find_each do |competence|
      puts competence.localized_name
      mandatory_courses = competence.recursive_prereq_courses
      
      stats.each do |stat|
        next unless mandatory_courses.include?(stat[0])
        puts "%02d, %03d, %s" % [stat[1], stat[2], "#{stat[0].course_code} #{stat[0].localized_name}"]
      end
      
      
      competence.children.each do |child_competence|
        puts child_competence.localized_name
        supporting_courses = child_competence.supporting_prereq_courses
        
        stats.each do |stat|
          next unless supporting_courses.include?(stat[0])
          puts "%02d, %03d, %s" % [stat[1], stat[2], "#{stat[0].course_code} #{stat[0].localized_name}"]
        end
        puts
      end
      puts
    end
  end
end 
