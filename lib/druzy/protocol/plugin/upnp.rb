require 'druzy/protocol/plugin/upnp/version'

require 'druzy/protocol'
require 'easy_upnp/ssdp_searcher'

module Druzy
  module Protocol
    module Plugin
      module Upnp
        
        class UpnpDiscoverer < Druzy::Protocol::Discoverer
          
          @@urn_connection_manager='urn:schemas-upnp-org:service:ConnectionManager:1'
          @@urn_rendering_control='urn:schemas-upnp-org:service:RenderingControl:1'
          
          def start_discoverer(delay=10, identifier=nil, &discovery_listener)
            searcher = EasyUpnp::SsdpSearcher.new
            devices = searcher.search('upnp:rootdevice')
            for device in devices
              begin
                if device.all_services.include?(@@urn_connection_manager) && device.all_services.include?(@@urn_rendering_control) 
                  puts device.device_name
                end             
              rescue
              
              end
            end
          end
          
          def stop_discoverer
          end
          
          def restart_discoverer
          end
        end
        
      end
    end
  end
end