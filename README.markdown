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
-----------------------------
The above approach works with RSpec as well. In addition to this you may use the
'use_fakefs' macro to turn FakeFS on and off in a given example group.  See
lib/spec_helpers for more details on it's usage.


How is this different than MockFS?
----------------------------------

FakeFS provides a test suite and works with symlinks. It's also strictly a
test-time dependency: your actual library does not need to use or know about
FakeFS.


Speed?
------
<http://gist.github.com/156091>


Installation
------------

### [Gemcutter](http://gemcutter.org/)

    $ gem install fakefs

### [Rip](http://hellorip.com)

    $ rip install git://github.com/defunkt/fakefs.git


Meta
----

* Code: `git clone git://github.com/defunkt/fakefs.git`
* Home: <http://github.com/defunkt/fakefs>
* Docs: <http://defunkt.github.com/fakefs>
* Bugs: <http://github.com/defunkt/fakefs/issues>
* List: <http://groups.google.com/group/fakefs>
* Test: <http://runcoderun.com/defunkt/fakefs>
* Gems: <http://gemcutter.org/gems/fakefs>
* Boss: Chris Wanstrath :: <http://github.com/defunkt>
