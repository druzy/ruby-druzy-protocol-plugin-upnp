require 'druzy/protocol/plugin/upnp/version'
require 'druzy/server'
require 'easy_upnp/ssdp_searcher'
require 'filemagic'
require 'nokogiri'

module Druzy
  module Protocol
    module Plugin
      module Upnp
        
        PORT=15322
        
        class UpnpDiscoverer < Druzy::Protocol::Discoverer
          
          @@urn_connection_manager='urn:schemas-upnp-org:service:ConnectionManager:1'
          @@urn_rendering_control='urn:schemas-upnp-org:service:RenderingControl:1'
          
          def start_discoverer(delay=10, identifier=nil)
            searcher = EasyUpnp::SsdpSearcher.new
            devices = searcher.search('upnp:rootdevice')
            for device in devices
              begin
                if device.all_services.include?(@@urn_connection_manager) && device.all_services.include?(@@urn_rendering_control) 
                  if block_given?
                    yield(UpnpRenderer.new(device))
                  end
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
        
        class UpnpRenderer < Druzy::Protocol::Renderer
          
          def initialize(easy_upnp)
            @av_transport = easy_upnp.service('urn:schemas-upnp-org:service:AVTransport:1')
            @rendering_control = easy_upnp.service('urn:schemas-upnp-org:service:RenderingControl:1')
            @connection_manager = easy_upnp.service('urn:schemas-upnp-org:service:ConnectionManager:1')
            @av_transport_id=nil
            @connection_id=nil
            @rcs_id=nil
            
            document = open(easy_upnp.service_definition(easy_upnp.all_services.first)[:location]) { |f| f.read }
            xml = Nokogiri::XML(document)
            xml.remove_namespaces!
            url_base=xml.xpath("//URLBase").text
            url_icon=url_base+xml.xpath("//device/iconList/icon/url").first.text
            
            super(easy_upnp.uuid,"upnp",easy_upnp.device_name,url_icon)
            
          end
          
          def play
            @av_transport.Play({:InstanceID => @av_transport_id, :Speed => "1"})
          end
          
          def pause
            @av_transport.Pause({:InstanceID => @av_transport_id})
          end
          
          def stop
            puts "dans stop"
            puts @av_transport.Stop({:InstanceID => @av_transport_id})
            puts "apres"
          end
          
          def send(file)
            #vérification du protocol
            protocols = @connection_manager.GetProtocolInfo[:Sink]
            mimetype=FileMagic.new(FileMagic::MAGIC_MIME_TYPE).file(file)
            ask_protocol="http-get:*:"+mimetype+":*"
            if protocols[ask_protocol] != nil
              if @connection_id == nil || @av_transport_id == nil || rcs_id == nil
                ids=@connection_manager.PrepareForConnection({:RemoteProtocolInfo => ask_protocol, :PeerConnectionManager => "/", :PeerConnectionID => -1, :Direction => "Output"})
                @connection_id = ids[:ConnectionID]
                @av_transport_id = ids[:AVTransportID]
                @rcs_id = ids[:RcsID] 
              end
              
              #ajout du fichier au serveur
              r=Druzy::Server::RestrictedFileServer.instance(PORT)
              r.add_file(file)
              
              #preparation de currentUriMetadata
              xml = %Q(<DIDL-Lite xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/" xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/">
  <item id="#{r.get_address(file)}" parentID="0" restricted="false">
    <dc:title>#{File.basename(file,".*")}</dc:title>
    <dc:creator></dc:creator>
    <upnp:class>
      object.item
    </upnp:class>
    <res protocolInfo="#{ask_protocol}">
      #{r.get_address(file)}
    </res>
  </item>
</DIDL-Lite>)
              #envoie de l'url au renderer
              @av_transport.SetAVTransportURI({:InstanceID => @av_transport_id, :CurrentURI => r.get_address(file), :CurrentURIMetaData => xml})
            end
              
          end
        
        end
        
      end
    end
  end
end

if __FILE__ == $0
 
  
  up=Druzy::Protocol::Plugin::Upnp::UpnpDiscoverer.new
  up.start_discoverer{ |device|
    device.send("/home/druzy/elliot.mp4")
    device.play
    sleep(10)
    device.pause
    sleep(5)
    device.play
    sleep(5)
    device.stop
  }
  
  Thread.list.each{|t| t.join if t!=Thread.main}
end