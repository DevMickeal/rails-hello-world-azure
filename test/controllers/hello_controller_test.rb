require "test_helper"

class HelloControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get "/hello"
    assert_response :success
  end
end
