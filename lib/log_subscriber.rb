module Scenariotest
  class LogSubscriber < ActiveSupport::LogSubscriber
    def load(event)
      name = event.payload[:name]
      info "  " << color("Scenariotest Loaded (%.1fms) %s" % [event.duration, name], GREEN, true).to_s << "\n\n"
    end

    def dump(event)
      name = event.payload[:name]
      info "  " << color("Scenariotest Dumped (%.1fms) %s" % [event.duration, name], YELLOW, true).to_s << "\n\n"
    end

    def logger
      ActiveRecord::Base.logger
    end
  end
end

Scenariotest::LogSubscriber.attach_to :scenariotest
