require "active_record"
module Scenariotest
  class Driver

    def self.start(app)
      new(app).start
    end

    def initialize(app)
      @app = app
    end

    def find_cmd(*commands)
      dirs_on_path = ENV['PATH'].to_s.split(File::PATH_SEPARATOR)
      commands += commands.map{|cmd| "#{cmd}.exe"} if RbConfig::CONFIG['host_os'] =~ /mswin|mingw/

      full_path_command = nil
      found = commands.detect do |cmd|
        dir = dirs_on_path.detect do |path|
          full_path_command = File.join(path, cmd)
          File.executable? full_path_command
        end
      end
      found ? full_path_command : abort("Couldn't find database client: #{commands.join(', ')}. Check your $PATH and try again.")
    end

    def config
      @config ||= begin
        database_config = @app.config.database_configuration
        unless c = database_config[Rails.env]
          abort "No database is configured for the environment '#{Rails.env}'"
        end
        c
      end
    end

    def run(type, file, options={})
      cmd = case config["adapter"]
      when /^mysql/
        args = {
          'host'      => '--host',
          'port'      => '--port',
          'socket'    => '--socket',
          'username'  => '--user',
          'encoding'  => '--default-character-set',
          'password'  => '--password'
        }.map { |opt, arg| "#{arg}=#{config[opt]}" if config[opt] }.compact

        args << (options.map do |name, value|
          if value.blank?
            " #{name}"
          else
            " #{name}=#{value}"
          end
        end).join("")

        args << config['database']

        commands, direct = if type == 'dump'
          [['mysqldump', 'mysqldump5'], ">>"]
        else
          [['mysql', 'mysql5'], "<"]
        end
        [find_cmd(*commands), args.join(" "), direct, file].join(" ")

      when "postgresql", "postgres"
        ENV['PGUSER']     = config["username"] if config["username"]
        ENV['PGHOST']     = config["host"] if config["host"]
        ENV['PGPORT']     = config["port"].to_s if config["port"]
        ENV['PGPASSWORD'] = config["password"].to_s if config["password"]

        commands, direct = if type == 'dump'
          [['psqldump'], ">>"]
        else
          [['psql'], "<"]
        end

        [find_cmd(*commands), config["database"], direct, file].join(" ")
      end

      Rails.logger.debug("  Scenariotest: #{cmd}")
      raise "failed running #{cmd}" unless system(cmd)
      true
    end

    def dump_file(name, source_sha1, type = "sql")
      f = "#{@app.root}/tmp/scenariotest_fixtures/#{name}_#{source_sha1}.#{type}"
      FileUtils.mkdir_p(File.dirname(f)) unless File.exist?(File.dirname(f))
      f
    end

    class << self
      def instance
        @instance ||= new(Rails.application)
      end
    end

    def setup(senario_klass, method_names)
      definations = senario_klass.definations

      method_name = if method_names.length > 1
        sha1s = method_names.map{|name| definations[name].nil? ? senario_klass.not_defined!(name) : definations[name].sha1}
        collection_sha1 = if sha1s.uniq.size == 1
          sha1s[0]
        else
          Digest::SHA1.hexdigest(sha1s.join("\n"))
        end
        m = "__#{method_names.join("_")}".to_sym
        senario_klass.define(m, :req => method_names, :source_sha1 => collection_sha1) {} unless definations[m]
        m
      else
        method_names[0]
      end

      ActiveSupport::Notifications.instrument('setup.scenariotest', :name => "%s" % [method_name]) do
        Rails.logger.info("\n\n* Scenariotest Setup Started: #{method_name}")
        senario_klass.invoke(method_name)
      end
    end


    def empty_data(source_sha1)
      f = dump_file("empty_data", source_sha1, "sql")
      unless File.exist?(f)
        truncate_sql = ActiveRecord::Base.connection.tables.map{|t| "TRUNCATE `#{t}`;"}.join("\n")
        File.write(f, "-- clear data\n" << truncate_sql)
        # run("dump", f, "--no-data" => nil, "--ignore-table"=>"#{config['database']}.schema_migration")
      end
      run("load", f)
    end

    def can_load?(name, source_sha1)
      f = dump_file(name, source_sha1, "sql")
      return false unless File.exist?(f)
      yml_file = dump_file(name, source_sha1, "objects.yml")
      return false unless File.exist?(yml_file)
      true
    end

    def load(name, source_sha1)
      f = dump_file(name, source_sha1, "sql")
      return false unless File.exist?(f)
      yml_file = dump_file(name, source_sha1, "objects.yml")
      return false unless File.exist?(yml_file)

      ActiveSupport::Notifications.instrument('load.scenariotest', :name => "%s (%s)" % [name, source_sha1]) do

      run("load", f)

      objs = YAML.load_file(yml_file)

      klass_ids_map = {}
      objs.each do |name, obj|
        (if !obj[0].is_a?(Array)
          [obj]
        else
          obj
        end).each{|klass, id| (klass_ids_map[klass] ||= []) << id}
      end

      objs_identity_map = {}
      klass_ids_map.each do |klass, ids|
        klass.constantize.find(ids).each do |obj|
          objs_identity_map["#{klass}_#{obj.id}"] = obj
        end
      end


      objs.each do |name, obj|
        loaded_obj = if obj[0].is_a?(Array)
          obj.map{|klass, id| objs_identity_map["#{klass}_#{id}"]}
        else
          objs_identity_map["#{obj[0]}_#{obj[1]}"]
        end
        Scenariotest::Scenario[name] = loaded_obj
      end

      end
      true
    end

    def dump(name, source_sha1, changed_data, truncate = true)
      ActiveSupport::Notifications.instrument('dump.scenariotest', :name => "%s (%s)" % [name, source_sha1]) do

      File.open(dump_file(name, source_sha1, "objects.yml"), 'wb') do |f|
        YAML.dump(changed_data, f)
      end

      if truncate
        File.open(dump_file(name, source_sha1, "sql"), 'wb') do |f|
          truncate_sql = ActiveRecord::Base.connection.tables.map{|t| "TRUNCATE `#{t}`;"}.join("\n")
          f.write("-- clear data start\n" << truncate_sql << "\n-- clear data end\n\n")
        end
      end

      run("dump", dump_file(name, source_sha1, "sql"),
        "--no-create-info" => nil,
        "--skip-add-locks" => nil,
        "--skip-triggers" => nil)

      end
    end

  end
end


