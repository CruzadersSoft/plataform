require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "new" do
    get new_user_path
    assert_response :success
  end

  test "create with valid credentials" do
    post users_path, params: {
      user: {
        email_address: "teste@example.com",
        password: "123456",
        password_confirmation: "123456"
      }
    }

    assert_redirected_to root_path
  end

  test "create with invalid credentials" do
    post users_path, params: {
      user: {
        email_address: "",
        password: "123456",
        password_confirmation: "123456"
    }    }

    assert_response :unprocessable_entity
  end
end
