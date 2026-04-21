require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get index when authentication" do
    get home_index_url
    assert_redirected_to new_session_path
  end
end
