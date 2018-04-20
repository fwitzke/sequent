require 'spec_helper'
require 'fileutils'

describe Sequent::Generator do
  let(:tmp_path) { 'tmp/sequent-generator-spec' }

  around do |example|
    FileUtils.rmtree(tmp_path)
    FileUtils.mkdir_p(tmp_path)
    Dir.chdir(tmp_path) { example.run }
    # FileUtils.rmtree(tmp_path)
  end

  subject(:execute) { Sequent::Generator.new('blog').execute }

  it 'creates a directory with the given name' do
    expect { subject }.to change { File.directory?('blog') }.from(false).to(true)
  end

  it 'copies the generator files' do
    execute
    expect(FileUtils.cmp('blog/Gemfile', '../../lib/sequent/generator/template_project/Gemfile')).to be_truthy
  end

  it 'has working example with specs' do
    execute

    Bundler.with_clean_env do
      system 'bash', '-ce', <<~SCRIPT
        cd blog
        export RACK_ENV=test
        source ~/.bash_profile
        rbenv shell $(cat ./.ruby-version)
        rbenv install --skip-existing
        gem install bundler
        bundle install
        bundle exec rake db:drop db:create db:migrate view_schema:build
        bundle exec rspec spec
      SCRIPT

      expect($?.to_i).to eq(0)
    end
  end
end