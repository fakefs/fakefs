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
  #
  # If you remove the before(:each) above, then it fails with this message:
  # Errno::ENOENT: No such file or directory - /tmp/stderr20160320--9vv9lq
  #                                                                      ./lib/fakefs/file.rb:649:in `create_missing_file'
  # ./lib/fakefs/file.rb:405:in `initialize'
  # ./lib/fakefs/dir.rb:188:in `create'
  #                                                                                                                                              ./spec/fakefs/failing_spec.rb:25:in `block (2 levels) in <top (required)>'
  # -e:1:in `load'
  # -e:1:in `<main>'

  it ' should be able to expect output to stderr' do
    expect{ $stderr.puts 'Output to stderr' }.to output(/to stderr/).to_stderr_from_any_process
  end
end