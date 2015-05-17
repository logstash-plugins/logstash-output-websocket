# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/outputs/websocket"

describe "output/websocket" do

  subject(:output) { LogStash::Outputs::WebSocket.new }

  it "should register" do
    expect {output.register}.to_not raise_error
  end
end
