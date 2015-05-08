#encoding: utf-8

require_relative '../init.rb'

packages = []

# ==============================================
# Production packages for production deployment
# ==============================================

packages << Package.new(sku: 'PREMIUM30SMS',
                 name: 'HittaLyan 30 dagar + SMS',
                 description: ''\
                 'HittaLyan 30 dagar + SMS. Innehåller 30 dagars prenumeration på '\
                 'lägenhetstips via e-post och SMS.',
                 payson_description: 'HittaLyan 30 dagar + SMS',
                 unit_price_in_ore: 23840, #298 SEK with VAT
                 premium_days: 30,
                 sms_days: 30,
                 active: true,
                 show_to: ['non_premium'])

packages << Package.new(sku: 'PREMIUM30SMSRENEWAL',
                 name: '*Förnya* HittaLyan 30 dagar + SMS',
                 description: ''\
                 '*Förnya* HittaLyan 30 dagar + SMS. Innehåller 30 dagars prenumeration på '\
                 'lägenhetstips via e-post och SMS.',
                 payson_description: '*Förnya* HittaLyan 30 dagar + SMS',
                 unit_price_in_ore: 7120, #89 SEK with VAT
                 premium_days: 30,
                 sms_days: 30,
                 active: true,
                 show_to: ['premium'])

# ==============================================================
# Special packages for internal use. Never to be shown to users
# ==============================================================

# Package for giving new users a trial period
packages << Package.new(sku: 'TRIAL7',
                 name: 'TRIAL7',
                 description: ''\
                 'Ger 7 dagar prenumeration med sms',
                 payson_description: 'TRIAL7: 7 dagar, sms',
                 unit_price_in_ore: 8888*100,
                 premium_days: 7,
                 sms_days: 7,
                 active: true,
                 trial: true)

# Package for giving referrals free days
packages << Package.new(sku: 'REFERRAL',
                 name: 'REFERRAL',
                 description: ''\
                 'Ger 10 dagar prenumeration med sms',
                 payson_description: 'REFERRAL: 10 dagar, sms',
                 unit_price_in_ore: 8888*100,
                 premium_days: 10,
                 sms_days: 10,
                 active: true)

# ==========================================
# Test packages for development and testing
# ==========================================
unless production?
  packages << Package.new(sku: 'TEST',
                   name: 'Test',
                   description: 'Detta är ett TESTpaket för utvecklingssyften',
                   payson_description: 'TESTpaket: 30 dagar, sms: 300',
                   unit_price_in_ore: 10*100,
                   premium_days: 30,
                   sms_days: 30,
                   active: true,
                   show_to: ['premium', 'non_premium'])
end

# Remove all old packages
Package.destroy_all

# Save them all to database
packages.each_with_index do |p, i|
  p.priority = i
  p.save!
end
