def inform_by_email_about_error(e)
  puts 'SENDING EMAIL ABOUT ERROR----------'
  body = <<BODY
The following error was caught at #{Time.now}:
Backtrace:
  #{e.backtrace}
BODY

  Manmailer.shoot_email('hittalyanab@gmail.com.com',
                        "Cubancabal Exception: #{e.class.name}",
                        body,
                        INFO_EMAIL,
                        INFO_NAME,
                        'text')

  puts 'SENT EMAIL ABOUT ERROR*************'
end