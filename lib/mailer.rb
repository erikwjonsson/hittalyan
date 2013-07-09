module Mailer
  OUR_STANDARD_EMAIL = "HittaLyan <info@hittalyan.se>"
  def self.shoot_email(recipient, subject, message, format='text', sender=OUR_STANDARD_EMAIL)
    if recipient.is_a?(User)
      unless recipient.permits_to_be_emailed
        puts "Not sending email to #{recipient.email} because they don't want to be emailed."
        return
      end
      recipient = recipient.email
    end
    
    email_params = {from: sender,
                    to: recipient,
                    subject: subject}
    case format
    when 'text' then email_params[:text] = message
    when 'html' then email_params[:html] = message
    end

    RestClient.post("https://api:key-0rvupmvv2y18ty9o2z6vkwc8qo2l3b85"\
    "@api.mailgun.net/v2/lingonberryprod.mailgun.org/messages", email_params)
  end
end