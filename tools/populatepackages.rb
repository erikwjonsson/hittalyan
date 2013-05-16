#encoding: utf-8

require_relative '../init.rb'

p = []

# ==============================================
# Production packages for production deployment
# ==============================================
p << Package.new(name: 'Standard',
                 description: ''\
                 'Standardpaketet innehåller 30 dagars prenumeration på '\
                 'lägenhetsutskick (300 SMS ingår om SMS-utskick önskas).',
                 payson_description: 'Standardpaket: 30 dagar, sms: 300',
                 unit_price_in_ore: 240*100,
                 premium_days: 30,
                 sms_account: 300,
                 active: true,
                 show_to_premium: false)

p << Package.new(name: 'Förlängning',
                 description: ''\
                 'Förlängningspaketet innehåller 30 dagars prenumeration på '\
                 'lägenhetsutskick (300 SMS ingår om SMS-utskick önskas).',
                 payson_description: 'Förlängningspaket: 30 dagar, sms: 300',
                 unit_price_in_ore: 120*100,
                 premium_days: 30,
                 sms_account: 300,
                 active: true,
                 show_to_premium: true)

p << Package.new(name: 'SMS300',
                 description: ''\
                 'SMS300-paketet innehåller 300 SMS.',
                 payson_description: 'SMS300: sms: 300',
                 unit_price_in_ore: 200*100,
                 sms_account: 300,
                 show_to_premium: true)

# ==========================================
# Test packages for development and testing
# ==========================================
unless production?
  p << Package.new(name: 'Test',
                   description: 'Detta är ett TESTpaket för utvecklingssyften',
                   payson_description: 'TESTpaket: 30 dagar, sms: 300',
                   unit_price_in_ore: 10*100,
                   premium_days: 30,
                   sms_account: 300,
                   active: true,
                   show_to_premium: true)
end

# Remove all old packages
Package.destroy_all

# Save them all to database
p.each_with_index do |o, i|
  o.priority = i
  o.save
end
