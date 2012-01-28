module Scenariotest
  class LogSubscriber < ActiveSupport::LogSubscriber
    def load(event)
      name = event.payload[:name]
      info "  " << color("Scenariotest Loaded (%.1fms) %s" % [event.duration, name], GREEN, false).to_s
    end

    def dump(event)
      name = event.payload[:name]
      info "  " << color("Scenariotest Dumped (%.1fms) %s" % [event.duration, name], YELLOW, false).to_s
    end

    def setup(event)
      name = event.payload[:name]
      info "  " << color("Scenariotest Setup Finished (%.1fms) %s" % [event.duration, name], MAGENTA, true).to_s << "\n\n"
    end

    def logger
      ActiveRecord::Base.logger
    end
  end
end

Scenariotest::LogSubscriber.attach_to :scenariotest
