require 'driver'
require 'log_subscriber'
require 'digest'

module Scenariotest
  class Scenario
    class Defination
      attr_accessor :name, :sha1, :options, :main_blk, :after_blk, :scenario_klass

      def initialize(scenario_klass, name, options, blk)
        self.scenario_klass = scenario_klass
        self.sha1 = options[:source_sha1]
        self.sha1 ||= begin
          source_path = blk.source_location[0].dup
          Digest::SHA1.hexdigest(source_path << File.read(source_path))
        end
        self.name = name
        self.options = options
        self.main_blk = blk

      end

      def root?
        self.options[:req].blank?
      end

      def root_cache_name
        "___root_#{self.name}"
      end

      def call
        loaded = scenario_klass.driver.load(self.name, sha1)

        deps = uniq_dependencies

        unless loaded

          # dump all the reuseable roots
          roots = deps.select{|d| d.root? }
          roots.each do |dep|
            next if scenario_klass.driver.can_load?(dep.root_cache_name, dep.sha1)
            scenario_klass.driver.empty_data(sha1)
            dep_changed_data = scenario_klass.changed do
              dep.main_blk.call
            end
            scenario_klass.driver.dump(dep.root_cache_name, dep.sha1, dep_changed_data, false)
          end

          scenario_klass.driver.empty_data(sha1)
          changed_data = scenario_klass.changed do
            deps.each do |dep|
              if dep.root? && scenario_klass.driver.load(dep.root_cache_name, dep.sha1) # only no dependencies scenarios can be cached
                # loaded from dump
              else
                dep.main_blk.call
              end
            end

            self.main_blk.call

          end

          scenario_klass.driver.dump(name, sha1, changed_data)

        end

        deps.each {|dep| dep.after_blk.call if dep.after_blk }
        self.after_blk.call if self.after_blk
        nil
      end

      def uniq_dependencies(list = [])
        [self.options[:req]].flatten.compact.reverse.each do |name|
          dep = scenario_klass.definations[name]
          scenario_klass.not_defined!(name) if dep.nil?
          dep.uniq_dependencies(list)
          list << dep unless list.include?(dep)
        end
        list
      end

    end

    class << self
      def init
        log("Fixtures are disabled when using Scenariotest.")
        ActiveRecord::TestFixtures.class_eval <<-EOF
          def setup_fixtures
          end
          def teardown_fixtures
          end
        EOF
        @data = {}
        @changed_data_stack = [{}]
        self
      end

      def data
        @data
      end

      def driver
        @driver ||= Scenariotest::Driver.instance
      end

      def log(message)
        Rails.logger.info(message) if const_defined?(:Rails)
      end

      def []=(name, value)
        return if value.nil?
        changed_data_value = if value.is_a?(Array)
          value.map{|v| [v.class.name, v.id]}
        else
          [value.class.name, value.id]
        end

        @changed_data_stack[-1][name] = changed_data_value
        @data[name] = value
      end

      def changed(&blk)
        @changed_data_stack << {}
        blk.call
        changed = @changed_data_stack.pop
        # if @changed_data_stack[-1]
        #   @changed_data_stack[-1].update(changed)
        # end
        changed
      end

      def [](name)
        @data[name]
      end

      def reload
        load __FILE__
      end


      def define name, options = {}, &blk
        definations[name] = Defination.new(self, name, options, blk)
      end

      def after name, &blk
        not_defined!(name) unless definations[name]
        definations[name].after_blk = blk
      end

      def setup(*names)
        self.driver.setup(self, names)
      end

      def invoke(name)
        (load_or_dump = definations[name]) ? load_or_dump.call : not_defined!(name)
      end

      def definations
        (@definations ||= {})
      end

      def not_defined!(name)
        raise("`#{name.inspect}' not defined.")
      end

    end
  end

end
