class SurveyAnswer < ActiveRecord::Base
  belongs_to :user
  
  def self.export
    File.open 'survey_answers.json', 'w' do |file|
      SurveyAnswer.order(:studentnumber).find_each do |answers|
        file.puts "{'login': '#{answers.login}', 'studentnumber': '#{answers.studentnumber}', 'answers': #{answers.payload} }"
      end
    end
  end
  
end
