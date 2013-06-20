#encoding: utf-8
require_relative 'init'
  
users = []
to = :everyone
subject = "Prova lägenhetstips från HittaLyan gratis i 7 dagar"
file = "free_trial"

LOG.info "To: #{to}"
LOG.info "Subject: #{subject}"
LOG.info "Source File: #{file}"

if to == :everyone
  users = User.all
else
  users = [User.find_by(email: to)]
end

users.each do |user|
  LOG.info "Shooting mail to: #{user.email}"
  Mailer.shoot_email(user,
                     subject,
                     render_mail(file, binding),
                     'html')
end
