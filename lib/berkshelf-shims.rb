require 'json'

module BerkshelfShims

  class UnknownCookbookReferenceError < StandardError
    def initialize(cookbook_name, options)
      super("Unknown cookbook reference #{cookbook_name} #{options}")
    end
  end

  BERKSHELF_PATH_ENV = 'BERKSHELF_PATH'
  def self.berkshelf_path
    File.absolute_path(ENV[BERKSHELF_PATH_ENV] || "#{ENV['HOME']}/.berkshelf/")
  end

  class BerksLockFile
    class << self
      def from_file(path)
        content = File.read(path)
        object = new
        object.load(content)
      end

      def from_lockfile(lockfile)
        object = new
        lockfile.load!
        lockfile.sources.each do |source|
          description = {}
          description[:locked_version] = source.locked_version
          if source.location
            location = source.location
            if location.class.location_key == :git
              description[:git] = location.uri
              description[:ref] = location.ref
            elsif location.class.location_key == :path
              description[:path] = location.path
            else
              raise "unknown location type #{location.class.location_key}"
            end
          end
          object.cookbooks[source.name] = description
        end
        object
      end
    end

    attr_reader :cookbooks

    def initialize
      @cookbooks = {}
    end

    def load(content)
      instance_eval(content)
      self
    end

    def cookbook(name, options = {})
      cookbooks[name] = options
    end

    def create_links(cookbook_dir, berkshelf_path)
      FileUtils.mkdir_p(cookbook_dir)
      Dir["#{cookbook_dir}/*"].each do |f|
        File.delete(f)
      end
      cookbooks.each do |name, options|
        if options[:path]
          target = options[:path]
        elsif options[:locked_version]
          target = "#{berkshelf_path}/cookbooks/#{name}-#{options[:locked_version]}"
        elsif options[:git] && options[:ref]
          target = "#{berkshelf_path}/cookbooks/#{name}-#{options[:ref]}"
        end
        if target
          FileUtils.ln_s(target, "#{cookbook_dir}/#{name}")
        else
          raise UnknownCookbookReferenceError.new(name, options)
        end
      end
    end
  end

  def self.create_shims(root, path=nil)
    path ||= berkshelf_path

    if running_berkshelf2? && b2_berksfile?(root)
      berksfile = Berkshelf::Berksfile.new("#{root}/Berksfile")
      berks_lockfile = Berkshelf::Lockfile.new(berksfile)
      lockfile = BerksLockFile::from_lockfile(berks_lockfile)
    else
      lockfile = BerksLockFile::from_file("#{root}/Berksfile.lock")
    end
    lockfile.create_links("#{root}/cookbooks", path)
  end

  def self.running_berkshelf2?
    require 'berkshelf'
    Berkshelf::VERSION.split('.').first > '1'
  end

  def self.b2_berksfile? path
    begin
      h = JSON.parse(File.read("#{path}/Berksfile.lock"))
      true
    rescue Exception => e
      false
    end
  end
end
