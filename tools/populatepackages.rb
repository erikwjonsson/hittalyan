#encoding: utf-8

require_relative '../init.rb'
Package.create!(name: 'Standard',
                description: 'Beskrivning för kunden så att kunden fattar.',
                payson_description: 'Standardpaket: 30 dagar, sms: 300',
                unit_price_in_ore: 240*100,
                premium_days: 30,
                sms_account: 300)
