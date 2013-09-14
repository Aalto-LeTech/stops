namespace :db do
  desc "Recalculate cached data"
  task :refresh_cache => :environment do
    CompetenceNode.find_each do |node|
      puts node.localized_name
      node.update_prereqs_cache()
    end
    puts "done"
  end
end 
