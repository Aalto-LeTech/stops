require 'test_helper'

class CurriculumsControllerTest < ActionController::TestCase
  setup do
    # This is needed to make login work
    activate_authlogic

    @user = users(:admin)
    UserSession.create(@user)
  end

  test "should get index" do
    get :index, :locale => :fi
    assert_response :success
    assert_not_nil assigns(:curriculums)
  end

  test "should get new" do
    get :new, :locale => :fi
    assert_response :success
  end

  test "should create curriculum" do
    assert_difference('Curriculum.count') do
      post :create, { :curriculum => { :start_year => 2014, :end_year => 2022 }, :locale => :fi }
    end

    assert_redirected_to edit_curriculum_path(assigns(:curriculum))
  end

  test "should show curriculum" do
    get :show, :id => curriculums(:one).to_param, :locale => :fi
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => curriculums(:one).to_param, :locale => :fi
    assert_response :success
  end

  test "should update curriculum" do
    put :update, :id => curriculums(:one).to_param, :curriculum => { }, :locale => :fi
    assert_redirected_to curriculum_path(assigns(:curriculum))
  end

  test "should destroy curriculum" do
    assert_difference('Curriculum.count', -1) do
      delete :destroy, :id => curriculums(:one).to_param, :locale => :fi
    end

    assert_redirected_to curriculums_path
  end
end
