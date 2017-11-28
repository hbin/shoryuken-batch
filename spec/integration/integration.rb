require 'shoryuken/batch'

Shoryuken.redis { |r| r.flushdb }

class AnotherWorker
  include Shoryuken::Worker

  def perform
    sleep 10
  end
end

class TestWorker
  include Shoryuken::Worker

  def perform
    sleep 1
    if bid
      batch.jobs do
        AnotherWorker.perform_async
      end
    end
  end
end

class MyCallback
  def on_success(status, options)
    puts "Success #{options} #{status.data}"
  end
  alias_method :multi, :on_success

  def on_complete(status, options)
    puts "Complete #{options} #{status.data}"
  end
end

batch = Shoryuken::Batch.new
batch.description = 'Test batch'
batch.callback_queue = :default
batch.on(:success, 'MyCallback#on_success', to: 'success@gmail.com')
batch.on(:success, 'MyCallback#multi', to: 'success@gmail.com')
batch.on(:complete, MyCallback, to: 'complete@gmail.com')

batch.jobs do
  10.times do
    TestWorker.perform_async
  end
end
puts Shoryuken::Batch::Status.new(batch.bid).data

Thread.new do
  loop do
    sleep 1
    keys = Shoryuken.redis { |r| r.keys('BID-*') }
    puts keys.inspect
  end
end
