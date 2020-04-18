require 'spec_helper'
require 'tempfile'

RSpec.describe 'fakefs' do
  it 'can create a Tempfile and read it using IO.foreach using a path' do
    FakeFS do
      FileUtils.mkdir_p(Dir.tmpdir)

      Tempfile.create('') do |f|
        f.write("Hello World!\nfoo\nbar\n")
        f.flush

        expect(File.exist?(f.path)).to be true
        expect(File.read(f.path)).to eq("Hello World!\nfoo\nbar\n")

        lines = []
        IO.foreach(f.path) do |line|
          lines << line
        end

        expect(lines).to match_array(["Hello World!\n", "foo\n", "bar\n"])
      end
    end
  end

  it 'can create a Tempfile and read it using IO.foreach using an object' do
    FakeFS do
      FileUtils.mkdir_p(Dir.tmpdir)

      Tempfile.create('') do |f|
        f.write("Hello World!\nfoo\nbar\n")
        f.flush

        expect(File.exist?(f.path)).to be true
        expect(File.read(f.path)).to eq("Hello World!\nfoo\nbar\n")

        lines = []
        IO.foreach(f) do |line|
          lines << line
        end

        expect(lines).to match_array(["Hello World!\n", "foo\n", "bar\n"])
      end
    end
  end
end
