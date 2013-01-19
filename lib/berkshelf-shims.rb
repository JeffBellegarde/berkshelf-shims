module BerkshelfShims

  def self.berkshelf_path
    File.absolute_path(ENV['BERKSHELF_PATH'] || "#{ENV['HOME']}/.berkshelf/")
  end

  class BerksLockFile
    class << self
      def from_file(path)
        content = File.read(path)
        object = new
        object.load(content)
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

    def cookbook(name, options)
      cookbooks[name] = options
    end

    def create_links(cookbook_dir, berkshelf_path)
      FileUtils.mkdir_p(cookbook_dir)
      cookbooks.each do |name, options|
        if options[:path]
          target = options[:path]
        elsif options[:locked_version]
          target = "#{berkshelf_path}/cookbooks/#{name}-#{options[:locked_version]}"
        end
        if target
          FileUtils.ln_s(target, "#{cookbook_dir}/#{name}", :force => true)
        else
          puts "unknown cookbook reference #{name} #{options}"
        end
      end
    end
  end

  def self.create_shims(root, path=nil)
    BerksLockFile::from_file("#{root}/Berksfile.lock").create_links("#{root}/cookbooks", path ? path : berkshelf_path)
  end

end
