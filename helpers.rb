#
# General helpers
#

# Require all files in a given subdirectory
def require_from_directory(directory)
  Dir[File.join(File.dirname(__FILE__), directory, '*')].each {|file| require file }
end

# Call this method like this:
# log.info(msg)
# log.warn(msg)
# log.error(msg)
def log
  env['rack.logger']
end


# emailer
def shoot_email(email, subject, body)
		Pony.mail({
			to: email,
			via: :smtp,
			via_options: {
				address:              'smtp.gmail.com',
				port:                 '587',
				enable_starttls_auto: true,
				user_name:            'londomolari123', # Obviously this isn't what we're going to be using
				password:             'ABcd12!?',				# No matter how cool and obscure it is
				authentication:       :plain, # :plain, :login, :cram_md5, no auth by default
				domain:               "localhost.localdomain" # the HELO domain provided by the client to the server
			},
			charset: 'UTF-8',
			body: body,
			subject: subject # Something else, perhaps?
		})
		puts "Email sent to #{email}"
  end