require 'minitest'
require 'minitest/autorun'
require 'minitest/reporters'
Minitest::Reporters.use! [Minitest::Reporters::SpecReporter.new]

require_relative '../init'

class UserTest < Minitest::Test
  UNIT_TEST_USER_EMAIL = "unittesting@example.com"
  UNIT_TEST_USER_PASSWORD = "averysecurepassword"

  RETURNING_UNIT_TEST_USER_EMAIL = "returning_" + UNIT_TEST_USER_EMAIL

  def tabula_rasa
    EmailHash.destroy_all(hashed_email: Encryption.encrypt(User::SALT, UNIT_TEST_USER_EMAIL))
    EmailHash.destroy_all(hashed_email: Encryption.encrypt(User::SALT, RETURNING_UNIT_TEST_USER_EMAIL))
    User.destroy_all(email: UNIT_TEST_USER_EMAIL)
    User.destroy_all(email: RETURNING_UNIT_TEST_USER_EMAIL)
  end

  def setup
    tabula_rasa

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


  def test_apply_package_trial_sets_active
    @user.apply_package(Packages::PACKAGE_BY_SKU["TRIAL7"])

    assert(@user.active)
  end

  def test_apply_package_trial_sets_trial
    @user.apply_package(Packages::PACKAGE_BY_SKU["TRIAL7"])

    assert(@user.trial)
  end

  def test_reregistering_will_not_reactivate_trial
    def create_returning_user
      puts "Creating the returning user"
      returning_user = User.create!(email: RETURNING_UNIT_TEST_USER_EMAIL,
                                    hashed_password: UNIT_TEST_USER_PASSWORD)
      returning_user.apply_package(Packages::PACKAGE_BY_SKU["TRIAL7"])
      returning_user
    end
    
    returning_user = create_returning_user
    returning_user.destroy
    returning_user = create_returning_user
  
    refute(returning_user.active)
  end

  def test_apply_package_premium30sms_on_inactive_user_adds_30_days_and_sms
    refute(@user.active)
    @user.apply_package(Packages::PACKAGE_BY_SKU.fetch("PREMIUM30SMS"))
    
    assert_equal(1.day.from_now.midnight + 30.days, @user.premium_until)
    assert_equal(1.day.from_now.midnight + 30.days, @user.sms_until)
  end

  def test_apply_package_premium30sms_on_active_user_adds_30_days_and_sms_from_premium_until
    @user.apply_package(Packages::PACKAGE_BY_SKU["PREMIUM30SMS"])
    original_premium_until = @user.premium_until.dup
    @user.apply_package(Packages::PACKAGE_BY_SKU["PREMIUM30SMS"])

    assert_equal(original_premium_until + 30.days, @user.premium_until)
    assert_equal(original_premium_until + 30.days, @user.sms_until)
  end

  def teardown
    tabula_rasa
  end
end
