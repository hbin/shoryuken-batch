module Shoryuken
  class Batch
    class Status
      attr_reader :bid

      def initialize(bid)
        @bid = bid
      end

      def join
        raise 'Not supported'
      end

      def description
        Shoryuken.redis { |r| r.hget("BID-#{bid}", 'description') }
      end

      def pending
        Shoryuken.redis { |r| r.hget("BID-#{bid}", 'pending') }.to_i
      end

      def failures
        Shoryuken.redis { |r| r.scard("BID-#{bid}-failed") }.to_i
      end

      def created_at
        Shoryuken.redis { |r| r.hget("BID-#{bid}", 'created_at') }
      end

      def total
        Shoryuken.redis { |r| r.hget("BID-#{bid}", 'total') }.to_i
      end

      def parent_bid
        Shoryuken.redis { |r| r.hget("BID-#{bid}", 'parent_bid') }
      end

      def failure_info
        Shoryuken.redis { |r| r.smembers("BID-#{bid}-failed") } || []
      end

      def complete?
        Shoryuken.redis { |r| r.hget("BID-#{bid}", 'complete') } == 'true'
      end

      def child_count
        Shoryuken.redis { |r| r.hget("BID-#{bid}", 'children') }.to_i
      end

      def data
        {
          total: total,
          failures: failures,
          pending: pending,
          created_at: created_at,
          complete: complete?,
          failure_info: failure_info,
          parent_bid: parent_bid
        }
      end
    end
  end
end
