require 'viget/deployment/deploy_notifier'

Capistrano::Configuration.instance.load do
  after 'deploy:restart', 'deploy:notify:notification'

  namespace :deploy do
    namespace :notify do
      def required_vars
        [:deploy_notification_url, :deploy_notification_channel]
      end

      def missing_vars
        required_vars.select { |k| fetch(k, nil).nil? }
      end

      desc 'Send deploy notification'
      task :notification do
        if missing_vars.any?
          logger.important "Missing values for #{missing_vars.inspect}, skipping notification"
          next
        end

        notifier = Viget::Deployment::DeployNotifier.new(self, fetch(:deploy_notification_url))

        notifier.notify

        logger.important "Deploy notification sent to '#{fetch(:deploy_notification_channel)}'"
      end
    end
  end
end

