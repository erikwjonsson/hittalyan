#encoding: utf-8

require_relative '../init.rb'

p = []

# ==============================================
# Production packages for production deployment
# ==============================================
p << Package.new(sku: 'START',
                 name: 'Start',
                 description: ''\
                 'Startpaketet innehåller 30 dagars prenumeration på '\
                 'lägenhetsutskick. Vi bjuder på 75 SMS som starbonus.',
                 payson_description: 'Startpaket: 30 dagar, 75 SMS',
                 unit_price_in_ore: 223.20*100,
                 premium_days: 30,
                 sms_account: 75,
                 active: true,
                 show_to_premium: false)

p << Package.new(sku: 'PREMIUM30',
                 name: '30 dagar',
                 description: ''\
                 '30-dagarspaketet innehåller 30 dagars prenumeration på '\
                 'lägenhetsutskick.',
                 payson_description: '30-dagarspaket: 30 dagar',
                 unit_price_in_ore: 111.6*100,
                 premium_days: 30,
                 active: true,
                 show_to_premium: true)

p << Package.new(sku: 'SMS50',
                 name: 'SMS50',
                 description: ''\
                 'SMS50-paketet innehåller 50 SMS.',
                 payson_description: 'SMS50: 50 SMS',
                 unit_price_in_ore: 24*100,
                 sms_account: 50,
                 show_to_premium: true)

p << Package.new(sku: 'SMS150',
                 name: 'SMS150',
                 description: ''\
                 'SMS150-paketet innehåller 150 SMS.',
                 payson_description: 'SMS150: 150 SMS',
                 unit_price_in_ore: 60*100,
                 sms_account: 150,
                 show_to_premium: true)

p << Package.new(sku: 'SMS300',
                 name: 'SMS300',
                 description: ''\
                 'SMS300-paketet innehåller 300 SMS.',
                 payson_description: 'SMS300: 300 SMS',
                 unit_price_in_ore: 88*100,
                 sms_account: 300,
                 show_to_premium: true)

# ==========================================
# Test packages for development and testing
# ==========================================
unless production?
  p << Package.new(sku: 'TEST',
                   name: 'Test',
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
