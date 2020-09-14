module Sidekiq
  module Search
    module WebExtension

      def self.registered(app)
        view_path = File.join(File.expand_path("..", __FILE__), "views")

        app.helpers do
          def safe_relative_time(time)
            time = if time.is_a?(Numeric)
              Time.at(time)
            else
              Time.parse(time)
            end

            relative_time(time)
          end
        end

        app.get "/search" do
          @jobs = []

          if params['query'].present?
            @jobs = Sidekiq::Search.find_jobs(query: params['query'], type: params['type'])
          end

          render(:erb, File.read(File.join(view_path, "index.erb")))
        end

        app.get "/search/:jid" do
          halt 404 unless params['jid']
          render(:erb, File.read(File.join(view_path, "item.erb")))
        end
      end
    end
  end
end
