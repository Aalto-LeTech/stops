class Invitation < ActiveRecord::Base
  before_create :generate_token
  attr_accessible :email, :expires_at
  
  # Generates a unique token
  def generate_token
    begin
      self.token = Digest::SHA1.hexdigest([Time.now, rand].join)
    end while Invitation.exists?(:token => self.token)
  end
end
