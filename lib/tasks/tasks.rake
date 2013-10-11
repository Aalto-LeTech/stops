namespace :db do
  desc "Recalculate cached data"
  task :refresh_cache => :environment do
    CompetenceNode.find_each do |node|
      puts node.localized_name
      node.update_prereqs_cache()
    end
    puts "done"
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
    
    stats.each do |stat|
      puts "%02d, %03d, %s" % [stat[1], stat[2], "#{stat[0].course_code} #{stat[0].localized_name}"]
    end
  end
end 
