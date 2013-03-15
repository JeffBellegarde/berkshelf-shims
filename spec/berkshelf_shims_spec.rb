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

  describe '#create_shims' do
    let(:test_dir) {'tmp'}
    let(:lock_file) {"#{test_dir}/Berksfile.lock"}
    let(:cookbooks_dir) {"#{test_dir}/cookbooks"}
    let(:relative_target_dir) {'/Some/Directory'}

    before do
      FileUtils.rm_rf(test_dir)
      FileUtils.mkdir(test_dir)
      File.open(lock_file, 'w') do |f|
        cookbook_entries.each do |line|
          f.puts line
        end
      end
    end
    context 'with a normal input' do
      let(:cookbook_entries) {[
          "cookbook 'relative', :path => '#{relative_target_dir}'",
          "cookbook 'versioned', :locked_version => '0.0.1'"
        ]}

      context 'with the default berkshelf path' do
        before do
          BerkshelfShims::create_shims('tmp')
        end
        it 'creates the links' do
          Dir.exists?(cookbooks_dir).should == true
          Dir["#{cookbooks_dir}/*"].sort.should == ["#{cookbooks_dir}/relative", "#{cookbooks_dir}/versioned"]
          File.readlink("#{cookbooks_dir}/relative").should == '/Some/Directory'
          File.readlink("#{cookbooks_dir}/versioned").should == "#{BerkshelfShims.berkshelf_path}/cookbooks/versioned-0.0.1"
        end
      end

      context 'with an explicit berkshelf path' do
        before do
          BerkshelfShims::create_shims('tmp', 'berkshelf')
        end
        it 'creates the links' do
          Dir.exists?(cookbooks_dir).should == true
          Dir["#{cookbooks_dir}/*"].sort.should == ["#{cookbooks_dir}/relative", "#{cookbooks_dir}/versioned"]
          File.readlink("#{cookbooks_dir}/relative").should == '/Some/Directory'
          File.readlink("#{cookbooks_dir}/versioned").should == "berkshelf/cookbooks/versioned-0.0.1"
        end
      end

      context 'with an environent variable' do
        before do
          ENV[BerkshelfShims::BERKSHELF_PATH_ENV] = '/berkshelf_env'
          BerkshelfShims::create_shims('tmp')
        end
        it 'creates the links' do
          Dir.exists?(cookbooks_dir).should == true
          Dir["#{cookbooks_dir}/*"].sort.should == ["#{cookbooks_dir}/relative", "#{cookbooks_dir}/versioned"]
          File.readlink("#{cookbooks_dir}/relative").should == '/Some/Directory'
          File.readlink("#{cookbooks_dir}/versioned").should == "/berkshelf_env/cookbooks/versioned-0.0.1"
        end
      end
    end

    context 'with an unknown cookbook reference' do
      let(:cookbook_entries) {[
          "cookbook 'relative'"
        ]}
      it 'throws an error' do
        expect {BerkshelfShims::create_shims('tmp')}.to raise_error BerkshelfShims::UnknownCookbookReferenceError
      end
    end
  end
end
