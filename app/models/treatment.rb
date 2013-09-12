class Treatment < ActiveRecord::Base
  
  def self.get_treatment(studentnumber)
    treatment = Treatment.find_by_studentnumber(studentnumber)
    return treatment.treatment if treatment
    
    return rand().round + 1
  end

end
