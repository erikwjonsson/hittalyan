#encoding: utf-8

require_relative '../init.rb'

c = []

# =============================================
# Production coupons for production deployment
# =============================================
# c << Coupon.new(code: "1234test",
#                 description: 
#                 discount_in_percentage_units: 25,
#                 valid: true)

# ===========================================================
# Coupon to use when there is no coupon.
# This really needs to be here.
# DO NOT REMOVE OR MODIFY unless you know what you're doing.
# ===========================================================
c << Coupon.new(code: "NONE",
                description: "Not a valid code/coupon",
                discount_in_percentage_units: 0,
                valid: false)

# =========================================
# Test coupons for development and testing
# =========================================
unless production?
  c << Coupon.new(code: "VALID1234",
                  description: "This is a TESTcoupon for testing purposes. VALID",
                  discount_in_percentage_units: 25,
                  valid: true)
  
  c << Coupon.new(code: "INVALID1234",
                  description: "This is a TESTcoupon for testing purposes. INVALID",
                  discount_in_percentage_units: 25,
                  valid: false)
end

# Remove all old coupons
Coupon.destroy_all

# Save them all to database
c.each do |o|
  o.save
end
