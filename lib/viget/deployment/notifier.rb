require 'tinder'

module Viget
  module Deployment
    class Notifier

      class RoomNotFoundError < Exception; end

      def initialize(subdomain, room_names, token, use_ssl, github_base_url, announce_token = nil)
        @subdomain       = subdomain
        @room_names      = room_names
        @token           = token
        @use_ssl         = use_ssl
        @github_base_url = github_base_url
        @announce_token  = announce_token
      end

      def announce_token
        @announce_token || ":bell: :hammer:"
      end

      def announce(username, revision_number, commit_message, application_name, branch, stage)
        commit_url = "#{@github_base_url}/commit/#{revision_number}"

        message =  %{#{announce_token} -> [CAP] }
        message << %{#{username} just deployed "#{commit_message}" (#{commit_url}) }
        message << %{from origin/#{branch} to #{application_name}/#{stage}.}

        speak(message)
      end

      def notified_room_names
        @notified_room_names ||= []
      end

      private

      def speak(message)
        rooms.each do |name, room|
          if room && room.speak(message)
            self.notified_room_names << name
          end
        end
      end

      def room_names
        Array(@room_names)
      end

      def credentials
        {:token => @token}
      end

      def ssl?
        @use_ssl == true
      end

      def client_options
        {:ssl => ssl?}.merge(credentials)
      end

      def repository_path(url)
        URI.parse(url).path
      end

      def client
        @client ||= Tinder::Campfire.new(@subdomain, client_options)
      end

      def rooms
        room_names.inject({}) {|m, n| m.merge(n => client.find_room_by_name(n)) }
      end

    end
  end
end