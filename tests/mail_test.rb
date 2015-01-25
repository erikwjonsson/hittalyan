require 'minitest'
require 'minitest/autorun'
require 'minitest/reporters'
Minitest::Reporters.use! [Minitest::Reporters::SpecReporter.new]

require_relative '../init'

class MailTest < Minitest::Test
  UNIT_TEST_USER_EMAIL = "unittesting@example.com"
  UNIT_TEST_USER_PASSWORD = "averysecurepassword"

  def setup
    tabula_rasa
    @user = User.create!(email: UNIT_TEST_USER_EMAIL,
                         hashed_password: UNIT_TEST_USER_PASSWORD)

  end

  def tabula_rasa
    User.destroy_all(email: UNIT_TEST_USER_EMAIL)
  end

  def teardown
    tabula_rasa
  end


  def test_mails_have_access_to_used_variables
    # Amend this list of variables when necessary.
    # TODO: Better way checking this than a unit test?
    template_variables = {
      user: @user
    }

    template_names.each do |template_name|
      begin 
        render_mail(template_name, template_variables)
      rescue NoMethodError => e
        refute(true, "The template '#{template_name}' doesn't have access to one or more of the variables/methods used in the template.\n#{e}")
      end
    end
  end


  private

  # I'm sure there's a better way of doing this...
  def template_names
    Dir[File.join(File.dirname(__FILE__), '../mails', '*')]
      .select { |file| file unless File.directory?(file) }
      .map { |file| file.split('/').last.split('.').first }
  end
end
