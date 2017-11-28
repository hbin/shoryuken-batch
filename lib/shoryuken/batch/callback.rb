module Shoryuken
  class Batch
    module Callback
      class Worker
        include Shoryuken::Worker

        shoryuken_options auto_delete: true, auto_visibility_timeout: true

        def perform(_, body)
          jcb = JSON.parse(body)

          event = jcb['event']
          bid = jcb['bid']
          parent_bid = jcb['parent_bid']
          clazz = jcb['job_class']
          opts = jcb['arguments']

          return unless %w[success complete].include?(event)

          clazz, method = clazz.split('#') if clazz.class == String && clazz.include?('#')
          method = "on_#{event}" if method.nil?
          status = Shoryuken::Batch::Status.new(bid)
          clazz.constantize.new.send(method, status, opts)

          send(event.to_sym, bid, status, parent_bid)
        end

        def success(bid, _, parent_bid)
          if parent_bid
            _, _, success, pending, children = Shoryuken.redis do |r|
              r.multi do
                r.sadd("BID-#{parent_bid}-success", bid)
                r.expire("BID-#{parent_bid}-success", Shoryuken::Batch::BID_EXPIRE_TTL)
                r.scard("BID-#{parent_bid}-success")
                r.hincrby("BID-#{parent_bid}", 'pending', 0)
                r.hincrby("BID-#{parent_bid}", 'children', 0)
              end
            end

            Batch.enqueue_callbacks(:success, parent_bid) if pending.to_i.zero? && children == success
          end

          Shoryuken.redis do |r|
            r.del "BID-#{bid}", "BID-#{bid}-success", "BID-#{bid}-complete", "BID-#{bid}-jids", "BID-#{bid}-failed"
          end
        end

        def complete(bid, _, parent_bid)
          if parent_bid
            _, complete, pending, children, failure = Shoryuken.redis do |r|
              r.multi do
                r.sadd("BID-#{parent_bid}-complete", bid)
                r.scard("BID-#{parent_bid}-complete")
                r.hincrby("BID-#{parent_bid}", 'pending', 0)
                r.hincrby("BID-#{parent_bid}", 'children', 0)
                r.hlen("BID-#{parent_bid}-failed")
              end
            end

            Batch.enqueue_callbacks(:complete, parent_bid) if complete == children && pending == failure
          end

          pending, children, success = Shoryuken.redis do |r|
            r.multi do
              r.hincrby("BID-#{bid}", 'pending', 0)
              r.hincrby("BID-#{bid}", 'children', 0)
              r.scard("BID-#{bid}-success")
            end
          end
        end
      end
    end
  end
end
