require 'test_helper'

class Curriculums::SkillsControllerTest < ActionController::TestCase

  context "curriculums/SkillsController" do

    setup do 
      @curriculum = FactoryGirl.create :curriculum
    end

    should "route to curriculums/skills" do
      assert_routing "fi/curriculums/#{@curriculum.id}/skills", { 
        :controller => "curriculums/skills",
        :curriculum_id => @curriculum.to_param, 
        :action => "index",
        :locale => 'fi'
      }
    end

    should "serve successful response when JSON is requested from index" do
      get :index, :curriculum_id => @curriculum.id, :locale => 'fi', :format => :json
      assert_response :success
      assert_not_nil assigns(:skills)
    end
  end

end
