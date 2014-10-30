require 'spec_helper'

# FakeFs module for tests
module FakeFS
  RSpec.describe SpecHelpers do
    before do
      @rspec_example_group = Class.new do
        def self.before(_sym = :each)
          yield if block_given?
        end

        def self.after(_sym = :each)
          yield if block_given?
        end
      end
    end

    describe 'when extending' do
      context 'before each' do
        it 'should call it' do
          expect(@rspec_example_group).to receive(:before).with(:each)
          @rspec_example_group.extend FakeFS::SpecHelpers
        end

        it 'should call FakeFS.activate!' do
          expect(FakeFS).to receive(:activate!)
          @rspec_example_group.extend FakeFS::SpecHelpers
        end
      end

      context 'after each' do
        it 'should call it' do
          expect(@rspec_example_group).to receive(:after).with(:each)
          @rspec_example_group.extend FakeFS::SpecHelpers
        end

        it 'should deactivate fakefs' do
          expect(FakeFS).to receive(:deactivate!)
          @rspec_example_group.extend FakeFS::SpecHelpers
        end

        it 'should clear the fakefs filesystem for the next run' do
          expect(FakeFS::FileSystem).to receive(:clear)
          @rspec_example_group.extend FakeFS::SpecHelpers
        end
      end
    end

    describe 'when including' do
      it 'should call before :each' do
        expect(@rspec_example_group).to receive(:before)
        @rspec_example_group.class_eval do
          include FakeFS::SpecHelpers
        end
      end
    end

    describe SpecHelpers::All do
      describe 'when extending' do
        context 'before :all' do
          it 'should call it' do
            expect(@rspec_example_group).to receive(:before).with(:all)
            @rspec_example_group.extend FakeFS::SpecHelpers::All
          end

          it 'should call FakeFS.activate!' do
            expect(FakeFS).to receive(:activate!)
            @rspec_example_group.extend FakeFS::SpecHelpers::All
          end
        end

        context 'after :all' do
          it 'should call it' do
            expect(@rspec_example_group).to receive(:after).with(:all)
            @rspec_example_group.extend FakeFS::SpecHelpers::All
          end

          it 'should call FakeFS.deactivate!' do
            expect(FakeFS).to receive(:deactivate!)
            @rspec_example_group.extend FakeFS::SpecHelpers::All
          end

          it 'should not call FakeFS::FileSystem.clear' do
            expect(FakeFS::FileSystem).to_not receive(:clear)
            @rspec_example_group.extend FakeFS::SpecHelpers::All
          end
        end
      end

      describe 'when including' do
        context 'before :all' do
          it 'should call it' do
            expect(@rspec_example_group).to receive(:before)
            @rspec_example_group.class_eval do
              include FakeFS::SpecHelpers::All
            end
          end
        end
      end
    end
  end
end
