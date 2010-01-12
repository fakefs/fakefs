FakeFS
======

Mocha is great. But when your library is all about manipulating the
filesystem, you really want to test the behavior and not the implementation.

If you're mocking and stubbing every call to FileUtils or File, you're
tightly coupling your tests with the implementation.

    def test_creates_directory
      FileUtils.expects(:mkdir).with("directory").once
      Library.add "directory"
    end

The above test will break if we decide to use `mkdir_p` in our code. Refactoring
code shouldn't necessitate refactoring tests.

With FakeFS:

    def test_creates_directory
      Library.add "directory"
      assert File.directory?("directory")
    end

Woot.


Usage
-----

    require 'fakefs'

    # That's it.


Don't Fake the FS Immediately
-----------------------------

    require 'fakefs/safe'

    FakeFS.activate!
    # your code
    FakeFS.deactivate!

    # or
    FakeFS do
      # your code
    end


RSpec
-----

The above approach works with RSpec as well. In addition you may include
FakeFS::SpecHelpers to turn FakeFS on and off in a given example group:

    require 'fakefs/spec_helpers'

    describe "my spec" do
      include FakeFS::SpecHelpers
    end

See `lib/fakefs/spec_helpers.rb` for more info.


How is this different than MockFS?
----------------------------------

FakeFS provides a test suite and works with symlinks. It's also strictly a
test-time dependency: your actual library does not need to use or know about
FakeFS.


Caveats
-------

FakeFS internally uses the `Pathname` and `FileUtils` constants. If you use
these in your app, be certain you're properly requiring them and not counting
on FakeFS' own require.


Speed?
------

<http://gist.github.com/156091>


Installation
------------

### [Gemcutter](http://gemcutter.org/)

    $ gem install fakefs

### [Rip](http://hellorip.com)

    $ rip install git://github.com/defunkt/fakefs.git


Contributing
------------

Once you've made your great commits:

1. [Fork][0] FakeFS
2. Create a topic branch - `git checkout -b my_branch`
3. Push to your branch - `git push origin my_branch`
4. Create an [Issue][1] with a link to your branch
5. That's it!

Meta
----

* Code: `git clone git://github.com/defunkt/fakefs.git`
* Home: <http://github.com/defunkt/fakefs>
* Docs: <http://defunkt.github.com/fakefs>
* Bugs: <http://github.com/defunkt/fakefs/issues>
* List: <http://groups.google.com/group/fakefs>
* Test: <http://runcoderun.com/defunkt/fakefs>
* Gems: <http://gemcutter.org/gems/fakefs>

[0]: http://help.github.com/forking/
[1]: http://github.com/defunkt/fakefs/issues
