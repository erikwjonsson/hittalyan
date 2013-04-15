module PaysonAPI
  module Request
    class Payment
      attr_accessor :comment

      alias_method :old_initialize, :initialize
      def initialize(return_url, cancel_url, ipn_url, memo, sender, receivers, comment='')
        old_initialize
        @comment = comment
      end
      
      alias_method :old_to_hash, :to_hash
      def to_hash
        hash = old_to_hash
        hash['custom'] = @comment
      end
    end
  end
end