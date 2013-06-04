require 'test_helper'

class CourseInstancesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index, :locale => :fi
    assert_response :success
  end

end
