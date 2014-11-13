module Manmailer
  def self.shoot_email(recipient, subject, content, from_email, from_name, format='text')
    if recipient.is_a?(User)
      unless recipient.permits_to_be_emailed
        puts "Not sending email to #{recipient.email} because they don't want to be emailed."
        return
      end
      recipient = recipient.email
    end

    message = {"from_email" => from_email,
                "from_name" => from_name,
                "subject" => subject,
                "to" => [{"email" => recipient}]}

    case format
      when 'text' then message["text"] = content
      when 'html' then message["html"] = content
    end

    result = MANDRILL.messages.send(message)
  end
end
