#encoding: utf-8

require_relative '../init.rb'

p = []

# ==============================================
# Production packages for production deployment
# ==============================================
# p << Package.new(sku: 'START',
#                  name: 'Start',
#                  description: ''\
#                  'Startpaketet innehåller 30 dagars prenumeration på '\
#                  'lägenhetstips. Vi bjuder på 75 SMS som startbonus.',
#                  payson_description: 'Startpaket: 30 dagar, 75 SMS',
#                  unit_price_in_ore: 223.20*100,
#                  premium_days: 30,
#                  sms_account: 75,
#                  active: true,
#                  show_to_premium: false,
#                  show_to_trial: true)

p << Package.new(sku: 'PREMIUM30',
                 name: 'HittaLyan 30 dagar',
                 description: ''\
                 'HittaLyan 30 dagar. Innehåller 30 dagars prenumeration på '\
                 'lägenhetstips via e-post.',
                 payson_description: 'HittaLyan 30 dagar',
                 unit_price_in_ore: 11120,
                 premium_days: 30,
                 active: true,
                 show_to_premium: true)

p << Package.new(sku: 'PREMIUM30SMS',
                 name: 'HittaLyan 30 dagar + SMS',
                 description: ''\
                 'HittaLyan 30 dagar + SMS. Innehåller 30 dagars prenumeration på '\
                 'lägenhetstips via e-post och SMS.',
                 payson_description: 'HittaLyan 30 dagar + SMS',
                 unit_price_in_ore: 14320,
                 premium_days: 30,
                 sms_days: 30,
                 active: true,
                 show_to_premium: true)

# p << Package.new(sku: 'SMS50',
#                  name: 'SMS50',
#                  description: ''\
#                  'SMS50-paketet innehåller 50 SMS.',
#                  payson_description: 'SMS50: 50 SMS',
#                  unit_price_in_ore: 24*100,
#                  sms_account: 50,
#                  show_to_premium: true)

# p << Package.new(sku: 'SMS150',
#                  name: 'SMS150',
#                  description: ''\
#                  'SMS150-paketet innehåller 150 SMS.',
#                  payson_description: 'SMS150: 150 SMS',
#                  unit_price_in_ore: 60*100,
#                  sms_account: 150,
#                  show_to_premium: true)

# p << Package.new(sku: 'SMS300',
#                  name: 'SMS300',
#                  description: ''\
#                  'SMS300-paketet innehåller 300 SMS.',
#                  payson_description: 'SMS300: 300 SMS',
#                  unit_price_in_ore: 88*100,
#                  sms_account: 300,
#                  show_to_premium: true)

# ==============================================================
# Special packages for internal use. Never to be shown to users
# ==============================================================

# Package for giving new users a trial period
p << Package.new(sku: 'TRIAL7',
                 name: 'TRIAL7',
                 description: ''\
                 'Ger 7 dagar prenumeration med sms',
                 payson_description: 'TRIAL7: 7 dagar, sms',
                 unit_price_in_ore: 8888*100,
                 premium_days: 7,
                 sms_days: 7,
                 active: true,
                 trial: true,
                 show: false,
                 show_to_premium: false)

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
                   sms_days: 30,
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
