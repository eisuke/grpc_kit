# frozen_string_literal: true

require 'grpc_kit'

class LoggingInterceptor < GRPC::ClientInterceptor
  def request_response(request: nil, call: nil, method: nil, metadata: nil)
    now = Time.now.to_i
    GrpcKit.logger.info("Started request #{request}, method=#{method.name}, service_name=#{method.receiver.class.service_name}")
    yield.tap do
      GrpcKit.logger.info("Elapsed Time: #{Time.now.to_i - now}")
    end
  end

  def client_streamer(requests: nil, call: nil, method: nil, metadata: nil)
    yield
  end

  def server_streamer(request: nil, call: nil, method: nil, metadata: nil)
    GrpcKit.logger.info("Started request method=#{method.name}, service_name=#{method.receiver.class.service_name}")
    yield(LoggingStream.new(call))
  end

  def bidi_streamer(requests: nil, call: nil, method: nil, metadata: nil)
    yield
  end

  class LoggingStream
    def initialize(stream)
      @stream = stream
    end

    def send(msg, **opts)
      GrpcKit.logger.info("logging interceptor send #{msg}")
      @stream.send(msg, **opts)
    end

    def recv
      @stream.recv.tap do |v|
        GrpcKit.logger.info("logging interceptor recv #{v}")
      end
    end
  end
end