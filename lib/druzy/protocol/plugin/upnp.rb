require_relative 'upnp/version'

require 'druzy/server'
require 'druzy/upnp/ssdp'
require 'filemagic'

require 'druzy/protocol' if $0 == __FILE__

module Druzy
  module Protocol
    module Plugin
      module Upnp

        PORT=15322

        class UpnpDiscoverer < Druzy::Protocol::Discoverer

          def start_discoverer(kwargs={})
            kwargs[:delay] ||=10
            kwargs[:identifier] ||= Druzy::Upnp::Ssdp::MEDIA_RENDERER if kwargs[:type] == 'renderer'
            kwargs[:identifier] ||= Druzy::Upnp::Ssdp::MEDIA_SERVER if kwargs[:type] == 'server'

            searcher = Druzy::Upnp::Ssdp.new.search(kwargs[:identifier], kwargs[:delay]) do |device|
              if block_given?
                yield UpnpRenderer.new(device) if kwargs[:type] == 'renderer'

                #TODO yield UpnpServer.new(device) if kwargs[:type] == 'server'
              end
            end
          end

          def stop_discoverer
          end

          def restart_discoverer
          end
        end

        class UpnpRenderer < Druzy::Protocol::Renderer

          def initialize(druzy_device)
            @druzy_device =  druzy_device

            @av_transport_id=nil
            @connection_id=nil
            @rcs_id=nil

            super(@druzy_device.udn,"upnp",@druzy_device.friendly_name,@druzy_device.icon_list.first)

            @druzy_device.service_list.each do |service|
              service.subscribe do |event|
                puts event
              end
            end
          end

          def play
            @druzy_device.AVTransport.Play("InstanceID" => @av_transport_id, "Speed" => 1)
          end

          def pause
            @druzy_device.AVTransport.Pause("InstanceID" => @av_transport_id)
          end

          def stop
            @druzy_device.AVTransport.Stop("InstanceID" => @av_transport_id)
          end

          def send(file)
            #vérification du protocol
            protocols = @druzy_device.ConnectionManager.GetProtocolInfo["Sink"]
            mimetype=FileMagic.new(FileMagic::MAGIC_MIME_TYPE).file(file)
            ask_protocol="http-get:*:"+mimetype+":*"
            if protocols[ask_protocol] != nil
              if @connection_id == nil || @av_transport_id == nil || @rcs_id == nil
                ids=@druzy_device.ConnectionManager.PrepareForConnection("RemoteProtocolInfo" => ask_protocol, "PeerConnectionManager" => "/", "PeerConnectionID" => -1, "Direction" => "Output")
                @connection_id = ids["ConnectionID"]
                @av_transport_id = ids["AVTransportID"]
                @rcs_id = ids["RcsID"]
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
              @druzy_device.AVTransport.SetAVTransportURI("InstanceID" => @av_transport_id, "CurrentURI" => r.get_address(file), "CurrentURIMetaData" => xml)
            end

          end

        end

      end
    end
  end
end

if __FILE__ == $0


  up=Druzy::Protocol::Plugin::Upnp::UpnpDiscoverer.new
  up.start_discoverer(:delay => 10, :type => 'renderer' ) do |device|
    puts device.identifier
    puts device.name
  end

  Thread.list.each{|t| t.join if t!=Thread.main}
end
