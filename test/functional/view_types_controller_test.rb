require 'test_helper'

class ViewTypesControllerTest < ActionController::TestCase
  setup do
    @view_type = view_types(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:view_types)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create view_type" do
    assert_difference('ViewType.count') do
      post :create, view_type: {  }
    end

    assert_redirected_to view_type_path(assigns(:view_type))
  end

  test "should show view_type" do
    get :show, id: @view_type
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @view_type
    assert_response :success
  end

  test "should update view_type" do
    put :update, id: @view_type, view_type: {  }
    assert_redirected_to view_type_path(assigns(:view_type))
  end

  test "should destroy view_type" do
    assert_difference('ViewType.count', -1) do
      delete :destroy, id: @view_type
    end

    assert_redirected_to view_types_path
  end
end
