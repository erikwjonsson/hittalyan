module Mailer
  OUR_STANDARD_EMAIL = "HittaLyan <lingonberryprod@gmail.com>"
  def self.shoot_email(recipient, subject, message, sender=OUR_STANDARD_EMAIL, format='text')
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