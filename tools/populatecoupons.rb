#encoding: utf-8

require_relative '../init.rb'

c = []

# ==============================================
# Production coupons for production deployment
# ==============================================
# c << Coupon.new(code: "1234test",
#                 description: 
#                 discount_in_percentage_units: 25,
#                 valid: true)

# ============================================
# Coupon to use when there is no coupon
# ============================================
c << Coupon.new(code: "NONE",
                description: "Not a valid code/coupon",
                discount_in_percentage_units: 0,
                valid: false)

# ==========================================
# Test coupons for development and testing
# ==========================================
unless production?
  c << Coupon.new(code: "TEST1234",
                  description: "This is a TESTcoupon for testing purposes",
                  discount_in_percentage_units: 25,
                  valid: true)
end

# Remove all old coupons
Coupon.destroy_all

# Save them all to database
c.each do |o|
  o.save
end
