# Add comment
module PaysonAPI
  module Request
    class Payment
      attr_accessor :return_url, :cancel_url, :ipn_url, :memo, :sender, :receivers,
        :locale, :currency, :tracking_id, :invoice_fee, :order_items, :fundings,
        :fees_payer, :guarantee_offered, :comment

      def initialize(return_url, cancel_url, ipn_url, memo, sender, receivers, comment='')
        @return_url = return_url
        @cancel_url = cancel_url
        @ipn_url = ipn_url
        @memo = memo
        @sender = sender
        @receivers = receivers
        @comment = comment
      end
      
      def to_hash
        {}.tap do |hash|
          # Append mandatory params
          hash['returnUrl'] = @return_url
          hash['cancelUrl'] = @cancel_url
          hash['memo'] = @memo
          hash['custom'] = @comment
          hash.merge!(@sender.to_hash)
          hash.merge!(Receiver.to_hash(@receivers))
        
          # Append optional params
          append_locale(hash, @locale) if @locale
          append_currency(hash, @currency) if @currency
          append_fees_payer(hash, @fees_payer) if @fees_payer
          append_guarantee(hash, @guarantee_offered) if @guarantee_offered
          hash.merge!(OrderItem.to_hash(@order_items)) if @order_items
          hash.merge!(Funding.to_hash(@fundings)) if @fundings
          hash['ipnNotificationUrl'] = @ipn_url if @ipn_url
          hash['invoiceFee'] = @invoice_fee if @invoice_fee
          hash['trackingId'] = @tracking_id if @tracking_id
        end
      end

    end
  end
end