# encoding: utf-8
require "logstash/namespace"
require "logstash/outputs/base"


# This output runs a websocket server and publishes any
# messages to all connected websocket clients.
#
# You can connect to it with ws://<host\>:<port\>/
#
# If no clients are connected, any messages received are ignored.
class LogStash::Outputs::WebSocket < LogStash::Outputs::Base
  config_name "websocket"

  # The address to serve websocket data from
  config :host, :validate => :string, :default => "0.0.0.0"

  # The port to serve websocket data from
  config :port, :validate => :number, :default => 3232

  # Make sure only one instance is ever created
  if self.respond_to?(:workers_not_supported!) # Check for v2.2+ API
    declare_workers_not_supported!("Websocket only supports one worker to prevent text overlap!")
  end


  public
  def register
    require "ftw"
    require "logstash/outputs/websocket/app"
    require "logstash/outputs/websocket/pubsub"

    # Make sure only one instance is ever created 
    workers_not_supported # for pre-v2.2

    @pubsub = LogStash::Outputs::WebSocket::Pubsub.new
    @pubsub.logger = @logger
    @server = Thread.new(@pubsub) do |pubsub|
      begin
        @logger.debug("Starting the websocket pubsub thread", :Host => @host, :Port => @port)
        Rack::Handler::FTW.run(LogStash::Outputs::WebSocket::App.new(pubsub, @logger),
                               :Host => @host, :Port => @port)
      rescue => e
        @logger.error("websocket server failed", :exception => e)
        sleep 1
        retry
      end
    end
  end # def register

  public
  def receive(event)

    @pubsub.publish(event.to_json)
  end # def receive

end # class LogStash::Outputs::Websocket
