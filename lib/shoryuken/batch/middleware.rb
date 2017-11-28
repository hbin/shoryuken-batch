require_relative 'extension/worker'

module Shoryuken
  class Batch
    module Middleware
      class ClientMiddleware
        def call(sqs_msg)
          if (batch = Thread.current[:bid])
            msg = JSON.parse(sqs_msg[:message_body])
            batch.increment_job_queue(msg['job_id']) if (msg[:bid] = batch.bid)
            sqs_msg[:message_body] = msg.to_json
          end

          yield
        end
      end

      class ServerMiddleware
        def call(_worker, _queue, sqs_msg, _body)
          msg = JSON.parse(sqs_msg.body)

          if (bid = msg.delete('bid'))
            begin
              Thread.current[:bid] = Shoryuken::Batch.new(bid)
              yield
              Thread.current[:bid] = nil
              Batch.process_successful_job(bid, msg['job_id'])
            rescue
              Batch.process_failed_job(bid, msg['job_id'])
              raise
            ensure
              Thread.current[:bid] = nil
            end
          else
            yield
          end
        end
      end

      def self.configure
        Shoryuken.configure_client do |config|
          config.client_middleware do |chain|
            chain.add Shoryuken::Batch::Middleware::ClientMiddleware
          end
        end

        Shoryuken.configure_server do |config|
          config.client_middleware do |chain|
            chain.add Shoryuken::Batch::Middleware::ClientMiddleware
          end

          config.server_middleware do |chain|
            chain.add Shoryuken::Batch::Middleware::ServerMiddleware
          end
        end

        Shoryuken::Worker.send(:include, Shoryuken::Batch::Extension::Worker)
      end
    end
  end
end

Shoryuken::Batch::Middleware.configure
