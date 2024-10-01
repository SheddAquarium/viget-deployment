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
          emoji: app_emoji,
          environment: environment,
          currentRevision: current_revision,
          commitURL: commit_url,
          commitMessage: commit_message,
          user: user,
          branch: branch,
          branchURL: branch_url,
          environmentURL: app_url
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
        cap.fetch(:app_emoji, '2705')
      end

      def app_url
        cap.fetch(:app_url, nil)
      end

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

        request = Net::HTTP::Post.new(app_uri.request_uri, {'Content-Type' =>'application/json'})
        request.body = payload.to_json

        http.request(request)
      end

    end
  end
end
