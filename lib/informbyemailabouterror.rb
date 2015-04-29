def inform_by_email_about_error(e)
  puts 'SENDING EMAIL ABOUT ERROR----------'

  body = <<BODY
#{'***This is a TEST***' unless production?}
The following error was caught at #{Time.now}:
Name:
  #{e.class.name}
Message:
  #{e.message}
Inspect:
  #{e.inspect}
Backtrace:
  #{e.backtrace}
BODY

  Manmailer.shoot_email('hittalyanab@gmail.com',
                        "#{'*Test* ' unless production?}Cubancabal Exception: #{e.class.name}",
                        body,
                        INFO_EMAIL,
                        INFO_NAME,
                        'text')

  puts 'SENT EMAIL ABOUT ERROR*************'
end
