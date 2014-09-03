require 'test_helper'

class TransitionTypesControllerTest < ActionController::TestCase
  setup do
    @transition_type = transition_types(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:transition_types)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create transition_type" do
    assert_difference('TransitionType.count') do
      post :create, transition_type: {  }
    end

    assert_redirected_to transition_type_path(assigns(:transition_type))
  end

  test "should show transition_type" do
    get :show, id: @transition_type
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @transition_type
    assert_response :success
  end

  test "should update transition_type" do
    put :update, id: @transition_type, transition_type: {  }
    assert_redirected_to transition_type_path(assigns(:transition_type))
  end

  test "should destroy transition_type" do
    assert_difference('TransitionType.count', -1) do
      delete :destroy, id: @transition_type
    end

    assert_redirected_to transition_types_path
  end
end
