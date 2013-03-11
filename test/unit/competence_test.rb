require 'test_helper'

class CompetenceTest < ActiveSupport::TestCase

  context "A Competence" do

    setup do 
      @competence     = FactoryGirl.create :competence
      @scoped_course  = FactoryGirl.create :scoped_course
    end

    should "not allow 'parent_competence' to refer to itself" do
      @competence.parent_competence = @competence
      assert_raise ActiveRecord::RecordInvalid do 
        @competence.save! 
      end
    end

    should "not allow 'parent_competence' to refer to a ScopedCourse" do
      assert_raise ActiveRecord::AssociationTypeMismatch, ActiveRecord::RecordInvalid do 
        @competence.parent_competence = @scoped_course
        @competence.save!
      end
    end

    should "be allowed to not to belong to any containing Competence" do
      assert @competence.parent_competence.nil?
    end

  end
end