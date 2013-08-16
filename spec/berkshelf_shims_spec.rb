require 'json'

describe BerkshelfShims do
  describe '#berkshelf_path' do
    subject {BerkshelfShims.berkshelf_path}
    it 'defaults to the user\'s home directory' do
      should == "#{ENV['HOME']}/.berkshelf"
    end
    context 'with a BERKSHELF_PATH environment variable' do
      before do
        @first_env = ENV['BERKSHELF_PATH']
        ENV['BERKSHELF_PATH']='/some-path'
      end
      after do
        ENV['BERKSHELF_PATH'] = @first_env
      end
      it 'should respect teh environment variable' do
        should == '/some-path'
      end
    end
  end

  shared_examples 'berkshelf examples' do
    let(:test_dir) {File.expand_path(File.join(File.dirname(__FILE__), '../tmp'))}
    let(:lock_file) {"#{test_dir}/Berksfile.lock"}
    let(:cookbooks_dir) {"#{test_dir}/cookbooks"}
    let(:relative_target_dir) {File.expand_path("#{test_dir}/relative")}
    before do
      Dir.mkdir(relative_target_dir)
      File.open(File.join(relative_target_dir, "metadata.rb"), 'w') do |f|
        f.write('name "relative"')
      end
    end

    context 'with a normal input' do
      let(:cookbook_entries) {[
                               "cookbook 'relative', :path => '#{relative_target_dir}'",
                               "cookbook 'versioned', :locked_version => '0.0.1'",
                               "cookbook 'somegitrepo', :git => 'http://github.com/someuser/somegitrepo.git', :ref => '6ffb9cf5ddee65b8c208dec5c7b1ca9a4259b86a'"
                              ]}
      let(:v2_cookbook_entries) {{
          #Still converting these entries 2.0 format.
          'relative' => {:path => "#{relative_target_dir}"},
          'versioned' => {:locked_version => '0.0.1'},
          'somegitrepo' => {:git => 'http://github.com/someuser/somegitrepo.git', :ref => '6ffb9cf5ddee65b8c208dec5c7b1ca9a4259b86a'}
        }}

      context 'with the default berkshelf path' do
        before do
          BerkshelfShims::create_shims(test_dir)
        end
        it 'creates the links' do
          Dir.exists?(cookbooks_dir).should == true
          Dir["#{cookbooks_dir}/*"].sort.should == ["#{cookbooks_dir}/relative", "#{cookbooks_dir}/somegitrepo", "#{cookbooks_dir}/versioned"]
          File.readlink("#{cookbooks_dir}/relative").should == relative_target_dir
          File.readlink("#{cookbooks_dir}/versioned").should == "#{BerkshelfShims.berkshelf_path}/cookbooks/versioned-0.0.1"
          File.readlink("#{cookbooks_dir}/somegitrepo").should == "#{BerkshelfShims.berkshelf_path}/cookbooks/somegitrepo-6ffb9cf5ddee65b8c208dec5c7b1ca9a4259b86a"
        end
        context 'run a second time' do
          before do
            BerkshelfShims::create_shims(test_dir)
          end
          it 'creates the links' do
            Dir.exists?(cookbooks_dir).should == true
            Dir["#{cookbooks_dir}/*"].sort.should == ["#{cookbooks_dir}/relative", "#{cookbooks_dir}/somegitrepo", "#{cookbooks_dir}/versioned"]
            File.readlink("#{cookbooks_dir}/relative").should == relative_target_dir
            File.readlink("#{cookbooks_dir}/versioned").should == "#{BerkshelfShims.berkshelf_path}/cookbooks/versioned-0.0.1"
            File.readlink("#{cookbooks_dir}/somegitrepo").should == "#{BerkshelfShims.berkshelf_path}/cookbooks/somegitrepo-6ffb9cf5ddee65b8c208dec5c7b1ca9a4259b86a"
          end
      end
      end

      context 'with an explicit berkshelf path' do
        before do
          BerkshelfShims::create_shims(test_dir, 'berkshelf')
        end
        it 'creates the links' do
          Dir.exists?(cookbooks_dir).should == true
          Dir["#{cookbooks_dir}/*"].sort.should == ["#{cookbooks_dir}/relative", "#{cookbooks_dir}/somegitrepo", "#{cookbooks_dir}/versioned"]
          File.readlink("#{cookbooks_dir}/relative").should == relative_target_dir
          File.readlink("#{cookbooks_dir}/versioned").should == "berkshelf/cookbooks/versioned-0.0.1"
          File.readlink("#{cookbooks_dir}/somegitrepo").should == "berkshelf/cookbooks/somegitrepo-6ffb9cf5ddee65b8c208dec5c7b1ca9a4259b86a"
        end
      end

      context 'with an environent variable' do
        before do
          ENV[BerkshelfShims::BERKSHELF_PATH_ENV] = '/berkshelf_env'
          BerkshelfShims::create_shims(test_dir)
        end
        it 'creates the links' do
          Dir.exists?(cookbooks_dir).should == true
          Dir["#{cookbooks_dir}/*"].sort.should == ["#{cookbooks_dir}/relative", "#{cookbooks_dir}/somegitrepo", "#{cookbooks_dir}/versioned"]
          File.readlink("#{cookbooks_dir}/relative").should == relative_target_dir
          File.readlink("#{cookbooks_dir}/versioned").should == "/berkshelf_env/cookbooks/versioned-0.0.1"
          File.readlink("#{cookbooks_dir}/somegitrepo").should == "/berkshelf_env/cookbooks/somegitrepo-6ffb9cf5ddee65b8c208dec5c7b1ca9a4259b86a"
        end
      end
    end

    context 'with an unknown cookbook reference' do
      let(:cookbook_entries) {[
                               "cookbook 'relative'"
                              ]}
      let(:v2_cookbook_entries) {{
          'relative' => {}
        }}
      it 'throws an error' do
        expect {BerkshelfShims::create_shims(test_dir)}.to raise_error BerkshelfShims::UnknownCookbookReferenceError
      end
    end
  end

  describe 'Berkshelf 1.0 format' do
    before do
      FileUtils.rm_rf(test_dir)
      FileUtils.mkdir(test_dir)
      File.open(lock_file, 'w') do |f|
        cookbook_entries.each do |line|
          f.puts line
        end
      end
    end
    include_examples 'berkshelf examples'
  end

  describe 'Berkshelf 2.0 format' do
    before do
      FileUtils.rm_rf(test_dir)
      FileUtils.mkdir(test_dir)
      File.open(lock_file, 'w') do |f|
        f.write(JSON.dump({:sources => v2_cookbook_entries}))
      end
    end
    include_examples 'berkshelf examples'
  end
end
