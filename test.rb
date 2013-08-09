#encoding: utf-8

loop do
  print "New password: "
  new_password = gets.chomp
  break if new_password == "exit"

  if new_password.length >= 6 && new_password.length <= 64 
    puts "Valid"
  else
    puts "Invalid"
  end
end
