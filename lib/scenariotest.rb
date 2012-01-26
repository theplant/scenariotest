require 'driver'
require 'digest'

module Scenariotest
  class Scenario
    class Sha1Lambda
      attr_accessor :sha1, :blk
      def initialize(sha1, &blk)
        self.sha1 = sha1
        self.blk = blk
      end

      def call(dependency_call)
        self.blk.call(dependency_call)
      end
    end

    class << self
      def init
        Rails.logger.info("Fixtures are disabled when using Scenariotest.")
        ActiveRecord::TestFixtures.class_eval <<-EOF
          def setup_fixtures
          end
          def teardown_fixtures
          end
        EOF
        @data = {}
        @changed_data = {}
        self
      end

      def driver
        @driver ||= Scenariotest::Driver.instance
      end

      def []=(name, value)
        return if value.nil?
        changed_data_value = if value.is_a?(Array)
          value.map{|v| [v.class.name, v.id]}
        else
          [value.class.name, value.id]
        end

        @changed_data[name] = changed_data_value
        @data[name] = value
      end

      def changed(dependency_call, &blk)
        if dependency_call # don't clear changed_data
          @changed_data ||= {}
        else
          @changed_data = {}
        end

        blk.call
        @changed_data
      end

      def [](name)
        @data[name]
      end

      def reload
        load __FILE__
      end

      # For not create duplicate calls
      def req(*method_names)
        @invoked_list ||= []
        method_names.each do |method_name|
          next if @invoked_list.include?(method_name)
          @invoked_list << method_name
          invoke(method_name)
        end
      end

      def setup(*method_names)
        @invoked_list = []
        method_name = if method_names.length > 1
          collection_sha1 = Digest::SHA1.hexdigest(method_names.map{|name| methods_hash[name].nil? ? not_defined!(name) : methods_hash[name].sha1}.join("\n"))
          m = "__#{method_names.join("_")}".to_sym
          define(m, :req => method_names, :source_sha1 => collection_sha1) {} unless methods_hash[m]
          m
        else
          method_names.first
        end

        req(method_name)
      end


      def define name, options = {}, &blk
        source_sha1 = options[:source_sha1]
        source_sha1 ||= begin
          source_path = blk.source_location[0].dup
          Digest::SHA1.hexdigest(source_path << File.read(source_path))
        end

        methods_hash[name] = Sha1Lambda.new(source_sha1) do |dependency_call|

          loaded = unless dependency_call
            self.driver.load(name, source_sha1)
          end

          unless loaded
            changed_data = self.changed(dependency_call) do
              ActiveRecord::Base.transaction do
                if options[:req]
                  [options[:req]].flatten.each do |req_name|
                    invoke(req_name, true)
                  end
                end
                blk.call
              end
            end
            self.driver.dump(name, source_sha1, changed_data) unless dependency_call
          end
          nil
        end
      end

      private

      def invoke(name, dependency_call = false)
        (sha1lambda = methods_hash[name]) ? sha1lambda.call(dependency_call) : not_defined!(name)
      end

      def not_defined!(name)
        raise("`#{name.inspect}' not defined.")
      end

      def methods_hash
        (@methods_hash ||= {})
      end
    end
  end

end
