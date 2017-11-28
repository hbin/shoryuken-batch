require 'spec_helper'

describe Shoryuken::Batch::Middleware do
  describe Shoryuken::Batch::Middleware::ServerMiddleware do
    context 'when without batch' do
      it 'just yields' do
        yielded = false
        expect(Shoryuken::Batch).not_to receive(:process_successful_job)
        expect(Shoryuken::Batch).not_to receive(:process_failed_job)
        subject.call(nil, {}, nil) { yielded = true }
        expect(yielded).to be_truthy
      end
    end

    context 'when in batch' do
      let(:bid) { 'SAMPLEBID' }
      let(:jid) { 'SAMPLEJID' }
      context 'when successful' do
        it 'yields' do
          yielded = false
          subject.call(nil, { 'bid' => bid, 'jid' => jid }, nil) { yielded = true }
          expect(yielded).to be_truthy
        end

        it 'calls process_successful_job' do
          expect(Shoryuken::Batch).to receive(:process_successful_job).with(bid, nil)
          subject.call(nil, { 'bid' => bid }, nil) {}
        end
      end

      context 'when failed' do
        it 'calls process_failed_job and reraises exception' do
          reraised = false
          expect(Shoryuken::Batch).to receive(:process_failed_job)
          begin
            subject.call(nil, { 'bid' => bid }, nil) { raise 'ERR' }
          rescue
            reraised = true
          end
          expect(reraised).to be_truthy
        end
      end
    end
  end

  describe Shoryuken::Batch::Middleware::ClientMiddleware do
    context 'when without batch' do
      it 'just yields' do
        yielded = false
        expect(Shoryuken::Batch).not_to receive(:increment_job_queue)
        subject.call(nil, {}, nil) { yielded = true }
        expect(yielded).to be_truthy
      end
    end

    context 'when in batch' do
      let(:bid) { 'SAMPLEBID' }
      let(:jid) { 'SAMPLEJID' }
      before { Thread.current[:bid] = Shoryuken::Batch.new(bid) }

      it 'yields' do
        yielded = false
        subject.call(nil, { 'jid' => jid }, nil) { yielded = true }
        expect(yielded).to be_truthy
      end

      it 'increments job queue' do
        # expect(Shoryuken::Batch).to receive(:increment_job_queue).with(bid)
        # subject.call(nil, { 'jid' => jid }, nil) {}
      end

      it 'assigns bid to msg' do
        msg = { 'jid' => jid }
        subject.call(nil, msg, nil) {}
        expect(msg[:bid]).to eq(bid)
      end
    end
  end
end

describe Shoryuken::Batch::Middleware do
  let(:config) { class_double(Shoryuken) }
  let(:client_middleware) { double(Shoryuken::Middleware::Chain) }

  context 'client' do
    it 'adds client middleware' do
      expect(Shoryuken).to receive(:configure_client).and_yield(config)
      expect(config).to receive(:client_middleware).and_yield(client_middleware)
      expect(client_middleware).to receive(:add).with(Shoryuken::Batch::Middleware::ClientMiddleware)
      Shoryuken::Batch::Middleware.configure
    end
  end

  context 'server' do
    let(:server_middleware) { double(Shoryuken::Middleware::Chain) }

    it 'adds client and server middleware' do
      expect(Shoryuken).to receive(:configure_server).and_yield(config)
      expect(config).to receive(:client_middleware).and_yield(client_middleware)
      expect(config).to receive(:server_middleware).and_yield(server_middleware)
      expect(client_middleware).to receive(:add).with(Shoryuken::Batch::Middleware::ClientMiddleware)
      expect(server_middleware).to receive(:add).with(Shoryuken::Batch::Middleware::ServerMiddleware)
      Shoryuken::Batch::Middleware.configure
    end
  end

  context 'worker' do
    it 'defines method bid' do
      expect(Shoryuken::Worker.instance_methods).to include(:bid)
    end

    it 'defines method batch' do
      expect(Shoryuken::Worker.instance_methods).to include(:batch)
    end

    it 'defines method valid_within_batch?' do
      expect(Shoryuken::Worker.instance_methods).to include(:valid_within_batch?)
    end
  end
end
