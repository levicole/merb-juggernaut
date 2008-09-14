require 'yaml'
require 'socket'
require 'erb'

module Juggernaut
  CONFIG = YAML::load(ERB.new(IO.read("#{Merb.root}/config/juggernaut_hosts.yml")).result).freeze unless const_defined?(:CONFIG)
  CR = "\0"  unless const_defined?(:CR)
  
  include Merb::SessionMixin
  
  class << self
    
    def send_to_all(data)
      fc = {
        :command   => :broadcast,
        :body      => data, 
        :type      => :to_channels,
        :channels  => []
      }
      send_data(fc)
    end
    
    def send_to_channels(data, channels)
      fc = {
        :command   => :broadcast,
        :body      => data, 
        :type      => :to_channels,
        :channels  => channels
      }
      send_data(fc)
    end
    alias send_to_channel send_to_channels
    
    def send_to_clients(data, client_ids)
      fc = {
        :command    => :broadcast,
        :body       => data, 
        :type       => :to_clients,
        :client_ids => client_ids
      }
      send_data(fc)
    end
    alias send_to_client send_to_clients
    
    def send_to_clients_on_channels(data, client_ids, channels)
      fc = {
        :command    => :broadcast,
        :body       => data, 
        :type       => :to_clients,
        :client_ids => client_ids,
        :channels   => channels
      }
      send_data(fc)
    end
    alias send_to_client_on_channel send_to_clients_on_channels
    alias send_to_client_on_channel send_to_clients_on_channels
    
    def remove_channels_from_clients(client_ids, channels)
      fc = {
        :command    => :query,
        :type       => :remove_channels_from_client,
        :client_ids => client_ids,
        :channels   => channels
      }
      send_data(fc)
    end
    alias remove_channel_from_client remove_channels_from_clients
    alias remove_channels_from_client remove_channels_from_clients
    
    def remove_all_channels(channels)
      fc = {
        :command    => :query,
        :type       => :remove_all_channels,
        :channels   => channels
      }
      send_data(fc)
    end
    
    def show_clients
      fc = {
        :command  => :query,
        :type     => :show_clients
      }
      send_data(fc, true).flatten
    end
    
    def show_client(client_id)
      fc = {
        :command    => :query,
        :type       => :show_client,
        :client_id  => client_id
      }
      send_data(fc, true).flatten[0]
    end
    
    def show_clients_for_channels(channels)
      fc = {
        :command    => :query,
        :type       => :show_clients_for_channels,
        :channels   => channels
      }
      send_data(fc, true).flatten
    end
    alias show_clients_for_channel show_clients_for_channels

    def send_data(hash, response = false)
      hash[:channels]   = hash[:channels].to_a   if hash[:channels]
      hash[:client_ids] = hash[:client_ids].to_a if hash[:client_ids]
      
      res = []
      hosts.each do |address|
        begin
          hash[:secret_key] = address[:secret_key] if address[:secret_key]
          
          @socket = TCPSocket.new(address[:host], address[:port])
          # the \0 is to mirror flash
          @socket.print(hash.to_json + CR)
          @socket.flush
          res << @socket.readline(CR) if response
        ensure
          @socket.close if @socket and !@socket.closed?
        end
      end
      res.collect {|r| ActiveSupport::JSON.decode(r.chomp!(CR)) } if response
    end
    
  private
    
    def hosts
      CONFIG[:hosts].select {|h| 
        !h[:environment] or h[:environment].to_s == Merb.env
      }
    end
    
  end
  
  module Helper  

    def juggernaut(options = {})
      hosts = Juggernaut::CONFIG[:hosts].select {|h| !h[:environment] or h[:environment] == Merb.env.to_sym }
      random_host = hosts[rand(hosts.length)]
      
      cookies[:_jug_session_id] ||= rand_uuid
      
      options = {
        :host                 => (random_host[:public_host] || random_host[:host]),
        :port                 => (random_host[:public_port] || random_host[:port]),
        :width                => '0px',
        :height               => '0px',
        :session_id           => cookies[:_jug_session_id],
        :swf_address          => "/media/juggernaut.swf",
        :ei_swf_address       => "/media/expressinstall.swf",
        :flash_version        => 8,
        :flash_color          => "#fff",
        :swf_name             => "juggernaut_flash",
        :bridge_name          => "juggernaut",
        :debug                => (Merb.env == 'development'),
        :reconnect_attempts   => 3,
        :reconnect_intervals  => 3
      }.merge(options)
      "<script type=\"text/javascript\">jQuery(document).ready(function(){
        jQuery.Juggernaut.initialize(#{options.to_json})
      });</script>"
    end
    
  end
end
