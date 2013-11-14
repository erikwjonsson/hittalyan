require 'minitest'
require 'minitest/autorun'
require_relative '../init'

class UserTest < Minitest::Test
  UNIT_TEST_USER_EMAIL = "unittesting@example.com"
  UNIT_TEST_USER_PASSWORD = "averysecurepassword"
  def setup
    @user = User.create!(email: UNIT_TEST_USER_EMAIL,
                         hashed_password: UNIT_TEST_USER_PASSWORD)
  end

  def test_mobile_number_local_swedish
    @user.mobile_number = "070 123 45 67"
    @user.save!

    assert_equal("+46701234567", @user.mobile_number)
  end

  def test_mobile_number_international_swedish_with_plus
    @user.mobile_number = "+46 70 123 45 67"
    @user.save!

    assert_equal("+46701234567", @user.mobile_number)
  end

  def test_mobile_number_international_swedish_with_double_zero
    @user.mobile_number = "0046 70 123 45 67"
    @user.save!

    assert_equal("+46701234567", @user.mobile_number)
  end

  def test_mobile_nonswedish_noninternational_raises_exception
    @user.mobile_number = "123 456 789"
    assert_raises(User::MalformedMobileNumber) do 
      @user.save!
    end
  end


  def test_authenticate_correct_password
    authenticated_user = User.authenticate(UNIT_TEST_USER_EMAIL, 
                                           UNIT_TEST_USER_PASSWORD)

    assert_equal(@user.email, authenticated_user.email)
  end

  def test_authenticate_incorrect_password
    authenticated_user = User.authenticate(UNIT_TEST_USER_EMAIL, 
                                           "thewrongpassword")
    refute(authenticated_user)
  end

  def test_change_password_correct_current_password
    new_password = "anotherverysecurepassword"
    @user.change_password(new_password, UNIT_TEST_USER_PASSWORD)

    authenticated_user = User.authenticate(UNIT_TEST_USER_EMAIL, 
                                           new_password)
    assert_equal(@user.email, authenticated_user.email)
  end

  def test_change_password_incorrect_current_password
    new_password = "anotherverysecurepassword"
    assert_raises(User::WrongPassword) do
      @user.change_password(new_password, "thewrongpassword")
    end
  end

  def test_change_password_with_new_insecure_password
    new_password = "abc"
    assert_raises(User::NewPasswordFailedValidation) do
      @user.change_password(new_password, UNIT_TEST_USER_PASSWORD)
    end
  end

  def test_has_password_with_correct_password
    assert(@user.has_password?(UNIT_TEST_USER_PASSWORD))
  end

  def test_has_password_with_incorrect_password
    refute(@user.has_password?("thewrongpassword"))
  end

  def teardown
    @user.destroy
  end
end
