#
# General helpers
#

# Require all files in a given subdirectory
def require_from_directory(directory)
  Dir[File.join(File.dirname(__FILE__), directory, '*')].each do |file|
    require file unless File.directory?(file)
  end
end

# Call this method like this:
# log.info(msg)
# log.warn(msg)
# log.error(msg)
def log
  env['rack.logger']
end

def log_exception(e)
  LOG.error e
  LOG.error e.message
  LOG.error e.backtrace.join("\n")
end

# emailer
# def shoot_email(email, subject, body)
#   Pony.mail({
#     to: email,
#     via: :smtp,
#     via_options: {
#       address:              'smtp.gmail.com',
#       port:                 '587',
#       enable_starttls_auto: true,
#       user_name:            'londomolari123', # Obviously this isn't what we're going to be using
#       password:             'ABcd12!?',				# No matter how cool and obscure it is
#       authentication:       :plain, # :plain, :login, :cram_md5, no auth by default
#       domain:               "localhost.localdomain" # the HELO domain provided by the client to the server
#     },
#     charset: 'UTF-8',
#     body: body,
#     subject: subject # Something else, perhaps?
#   })
#   puts "Email sent to #{email}"
# end

def shoot_email(email, subject, body)
  puts "Shooting email to #{email}"
  RestClient.post "https://api:key-0rvupmvv2y18ty9o2z6vkwc8qo2l3b85"\
  "@api.mailgun.net/v2/lingonberryprod.mailgun.org/messages",
  from: "Hittalyan <lingonberryprod@gmail.com>",
  to: email,
  subject: subject,
  text: body
end

def website_address
  if production?
    "http://www.hittalyan.se/"
  elsif development?
    "http://localhost:4856/"
  elsif test?
    "http://cubancabal.aws.af.cm/"
  end
end

class MongoidExceptionCodifier
  TOO_SHORT_PASSWORD = 'Hashed password is too short (minimum is 6 characters)'
  EMAIL_ALREADY_REGISTERED = 'Email is already taken'

  CODES = {TOO_SHORT_PASSWORD => '0',
           EMAIL_ALREADY_REGISTERED => '1'}

  # Determines the causes of a validation exception,
  # and returns an array of appropriate application error codes.
  # ex - Mongoid::Errors::Validations instance
  def self.codify(ex)
    errors = extract_errors(ex)
    errors.map do |err|
      CODES[err]
    end
  end

  private

    def self.extract_errors(ex)
      /errors were found:(.*)Resolution:/m.match(ex.to_s)[1].strip.split(', ')
    end
end

# Renders an ERB template. If you're unsure about what to pass
# as a_binding you probably want to pass 'binding' (without quotes).
def render_mail(template, a_binding)
  content = File.read("mails/#{template}.html.erb")
  ERB.new(content).result(a_binding)
end