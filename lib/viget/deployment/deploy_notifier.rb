require 'net/http'
require 'uri'
require 'json'

module Viget
  module Deployment
    class DeployNotifier
      attr_reader :cap, :deploy_notification_url

      def initialize(cap, deploy_notification_url)
        @cap = cap
        @deploy_notification_url = deploy_notification_url
      end

      def notify
        post(payload)
      end

      def payload
        {
          "title": app_username, #<Environment> deploy
          "sections": [{
            "title": "[#{current_revision}](#{commit_url})", #revision number link to commit in github
            "text": commit_message, #commit message from git
            "facts": [{
                        "name": "Deployed By", #header
                        "value": user, #deployer
                      }, {
                        "name": "Branch", #header
                        "value": "[#{branch_url}](#{branch})", #branch name link to branch in github
                      }, {
                        "name": "URL", #header
                        "value": app_url, #environment url
                      }]
          }]
        }
      end

      private

      def app_uri
        URI.parse(deploy_notification_url)
      end

      def app_username
        cap.fetch(:app_username, "#{app_emoji} #{environment} Deploy")
      end

      def app_emoji
        cap.fetch(:app_emoji, '(bell)')
      end

      def app_url
        cap.fetch(:app_url, nil)
      end

      # def color
      #   case environment
      #   when 'Integration'
      #     '#d16d4e'
      #   when 'Staging'
      #     '#7c82d1'
      #   else
      #     '#23d15a'
      #   end
      # end

      # def fallback
      #   "#{current_revision}: #{commit_message}"
      # end

      def environment
        cap.fetch(:stage).to_s.split('_').map(&:capitalize).join(' ')
      end

      def git_username
        username = cap.run_locally('git config --get user.name')

        username unless username.nil? or username == ''
      end

      def user
        git_username || ENV['USER']
      end

      def github_url
        repository_url = cap.fetch(:repository)
        path           = repository_url.gsub(%r{(^git@github\.com:?|\.git$)}, '')

        "https://github.com/#{path}"
      end

      def branch_url
        branch = cap.fetch(:branch).to_s.split('/').last

        "#{github_url}/commits/#{branch}"
      end

      def commit_url
        "#{github_url}/commit/#{current_revision}"
      end

      def commit_message
        @commit_message ||= cap.capture(%{cd #{cap.current_path}; git show --pretty=format:"%s - %an" HEAD | head -n 1}).strip
      end

      def current_revision
        cap.current_revision
      end

      def branch
        cap.fetch(:branch)
      end

      def post(payload)
        http = Net::HTTP.new(app_uri.host, app_uri.port)
        http.use_ssl = true

        request = Net::HTTP::Post.new(app_uri.request_uri)
        request.set_form_data(payload: JSON.generate(payload))

        http.request(request)
      end

      # def clean(thinger)
      #   opts = {
      #     invalid: :replace,
      #     undef:   :replace,
      #     replace: ''
      #   }
      #
      #   thinger.encode(Encoding.find('ASCII'), opts)
      # end

    end
  end
end
