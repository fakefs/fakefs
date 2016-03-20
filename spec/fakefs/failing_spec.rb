require 'fakefs/safe'

describe 'failing test', fakefs: true do
  before(:each) do
    wd = '/tmp'
    Dir.mkdir wd
    Dir.chdir wd
  end

  it ' should be able to expect output to stdout' do
    expect{ $stdout.puts 'Output to stdout' }.to output(/to stdout/).to_stdout
  end

  it ' should be able to expect output to stderr' do
    expect{ $stderr.puts 'Output to stderr' }.to output(/to stderr/).to_stderr
  end

  # When run with 'bundle exec rspec' this test outputs
  # TypeError: can't convert Tempfile to IO (Tempfile#to_io gives FakeFS::File)
  # ./spec/fakefs/failing_spec.rb:19:in `block (2 levels) in <top (required)>'
  # -e:1:in `load'
  # -e:1:in `<main>'
  #
  # When run with rspec alone it outputs
  # ArgumentError:
  #    could not find a temporary directory
  it ' should be able to expect output to stderr' do
    expect{ $stderr.puts 'Output to stderr' }.to output(/to stderr/).to_stderr_from_any_process
  end
end