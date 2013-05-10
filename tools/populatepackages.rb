#encoding: utf-8

require_relative '../init.rb'

p = []
# ==========================================
# Test packages for development and testing
# ==========================================
p << Package.new(name: 'Test',
                 description: 'Detta är ett TESTpaket för utvecklingssyften',
                 payson_description: 'TESTpaket: 30 dagar, sms: 300',
                 unit_price_in_ore: 10*100,
                 premium_days: 30,
                 sms_account: 300,
                 active: true)

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
                 active: true)

p << Package.new(name: 'Beta',
                 description: ''\
                 'Betapaketet innehåller 30 dagars prenumeration på '\
                 'lägenhetsutskick samt 10 sms.',
                 payson_description: 'Standardpaket: 30 dagar, sms: 10',
                 unit_price_in_ore: 100*100,
                 premium_days: 30,
                 sms_account: 10,
                 active: true)

# Save them all to database
p.each(&:save)
