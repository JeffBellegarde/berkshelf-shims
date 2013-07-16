berkshelf-shims
===============

[![Build Status](https://travis-ci.org/JeffBellegarde/berkshelf-shims.png?branch=master)](https://travis-ci.org/JeffBellegarde/berkshelf-shims)

Provide shims functionality for berkshelf.

Until https://github.com/RiotGames/berkshelf/pull/120 Berkshelf supported a --shims options that would create a directory of soft links referencing versioned cookbooks installed in the Berkshelf. Under the new Vagrant plugin, this was no longer needed and thus removed.

However, under [chefspec](https://github.com/acrmp/chefspec), the functionality is still useful. The gem provides equivalent functionality.

Just like Berkshelf used to do, berkshelf-shims creates a 'cookbook' directory in the same directory as the Berksfile and populates it with soft links.

Usage
-----
Setup Berkshelf as normal and generate a Berskfile.lock. Without the .lock file berkshelf-gems has nothing to read and will fail.

Add the gem to your Gemfile.

```
gem 'berkshelf-shims'
```

Add an appropriate hook for your testing framework.

#### RSpec hook

Put the following into spec/spec_helper.rb.

```ruby
require 'berkshelf-shims'

RSpec.configure do |config|
  config.before(:suite) do
    BerkshelfShims::create_shims(File.join(File.dirname(__FILE__), '..'))
  end
end
```

When instantiating the chef runner, pass in path to the created cookbook directory.
```ruby
ChefSpec::ChefRunner.new(:cookbook_path => "#{root_dir}/cookbooks")
```

Please notice that create_shims takes the root directory of the project while, ChefRunner.new needs the created 'cookbooks' directory.


