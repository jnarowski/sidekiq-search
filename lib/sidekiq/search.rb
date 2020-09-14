begin
  require "sidekiq/web"
rescue LoadError
  # client-only usage
end

require "sidekiq/api"
require "sidekiq/version"
require_relative "./version"
require_relative "./web_extension"

if defined?(Sidekiq::Web)
  Sidekiq::Web.register Sidekiq::Search::WebExtension
  Sidekiq::Web.tabs["Search"] = "search"
  Sidekiq::Web.settings.locales << File.join(File.dirname(__FILE__), "search/locales")
end


module Sidekiq
  module Search
    class << self

      # WARNING: This is very ineffecient if your queue is big
      def find_job(jid)
        begin
          job = Sidekiq::Failures::FailureSet.new.find_job(jid)
          return { 'state' => 'failed', 'job' => job } if job
        rescue => e
          # do nothing
        end

        begin
          job = Sidekiq::ScheduledSet.new.find_job(jid)
          return { 'state' => 'scheduled', 'job' => job } if job
        rescue => e
          # do nothing
        end

        job = Sidekiq::DeadSet.new.find_job(jid)
        return { 'state' => 'dead', 'job' => job } if job

        job = Sidekiq::Queue.new.find_job(jid)
        return { 'state' => 'enqueued', 'job' => job } if job

        return { 'state' => 'not_found', 'job': nil }
      end

      def find_jobs(query:, type: 'job_id')
        jobs = []

        if type == 'job_id'
          job = find_job(query)
          jobs << job if job
        end

        jobs
      end
    end
  end
end
