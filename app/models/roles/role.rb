
class Role < ActiveRecord::Base
  belongs_to :user
  
  attr_accessible :user, :target
end
