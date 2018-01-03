FakeFS [![build status](https://travis-ci.org/fakefs/fakefs.svg?branch=master)](https://travis-ci.org/fakefs/fakefs)
======

Mocking calls to FileUtils or File means tightly coupling tests with the implementation.

``` ruby
it "creates a directory" do
  FileUtils.expects(:mkdir).with("directory").once
  Library.add "directory"
end
```

The above test will break if `mkdir_p` is used instead.
Refactoring code should not necessitate refactoring tests.

A better approach is to use a temp directory if you are working with relative directories.

```Ruby
require 'tmpdir'

it "creates a directory" do
  Dir.mktmpdir do |dir|
    Dir.chdir dir do
      Library.add "directory"
      assert File.directory?("directory")
    end
  end
end
```

But if you are working with absolute directories or do not want to use temporary directories, use FakeFS instead:

``` ruby
it "creates a directory" do
  FakeFS do
    Library.add "directory"
    assert File.directory?("directory")
  end
end
```

Installation
------------

```Bash
gem install fakefs
```

Usage
-----

To fake out the FS:

``` ruby
require 'fakefs'
```

Temporarily faking the FS
-------------------------

``` ruby
require 'fakefs/safe'

FakeFS.activate!
# your code
FakeFS.deactivate!

# or
FakeFS do
  # your code
end
```

Rails
-----

In rails projects, add this to your Gemfile:

``` ruby
gem "fakefs", require: "fakefs/safe"
```

RSpec
-----


Include FakeFS::SpecHelpers to turn FakeFS on and off in an example group:

``` ruby
require 'fakefs/spec_helpers'

describe "my spec" do
  include FakeFS::SpecHelpers
end
```

See `lib/fakefs/spec_helpers.rb` for more info.

To use FakeFS within a single test and be guaranteed a fresh fake filesystem:
``` ruby
require 'fakefs/safe'

describe "my spec" do
  context "my context" do
    it "does something to the filesystem"
      FakeFS.with_fresh do
        # whatever it does
      end
    end
  end
end
```


FakeFs --- `TypeError: superclass mismatch for class File`
--------------

`pp` and `fakefs` may collide, even if you're not actually explicitly using `pp`.  Adding `require 'pp'` before `require 'fakefs'` should fix the problem locally.  For a module-level fix, try adding it to the `Gemfile`:

```ruby
source "https://rubygems.org"

require 'pp'
# list of gems
```

The problem may not be limited to `pp`; any gems that add to `File` may be affected.

Working with existing files
---------------------------

Clone existing directories or files to reuse them during tests, they are safe to modify.

```ruby
FakeFS do
  config = File.expand_path('../../config', __FILE__)

  FakeFS::FileSystem.clone(config)
  expect(File.read("#{config}/foo.yml")).to include("original-content-of-foo")

  File.write("#{config}/foo.yml"), "NEW")
  expect(File.read("#{config}/foo.yml")).to eq "NEW"
end
```

Integrating with other filesystem libraries
--------------------------------------------
Third-party libraries may add methods to filesystem-related classes. FakeFS
doesn't support these methods out of the box, but you can define fake versions
yourself on the equivalent FakeFS classes. For example,
[FileMagic](https://rubygems.org/gems/ruby-filemagic) adds `File#content_type`.
A fake version can be provided as follows:

``` ruby
FakeFS::File.class_eval do
  def content_type
    'fake/file'
  end
end
```

[MockFS](http://mockfs.rubyforge.org/) comparison
----------------------------------

FakeFS provides a test suite and works with symlinks. It's also strictly a
test-time dependency: your actual library does not need to use or know about
FakeFS.


Caveats
-------

FakeFS internally uses the `Pathname` and `FileUtils` constants. If you use
these in your app, be certain you're properly requiring them and not counting
on FakeFS' own require.

As of v0.5.0, FakeFS's current working directory (i.e. `Dir.pwd`) is
independent of the real working directory. Previously if the real working
directory were, for example, `/Users/donovan/Desktop`, then FakeFS would use
that as the fake working directory too, even though it most likely didn't
exist. This caused all kinds of subtle bugs. Now the default working directory
is the only thing that is guaranteed to exist, namely the root (i.e. `/`). This
may be important when upgrading from v0.4.x to v0.5.x, especially if you depend
on the real working directory while using FakeFS.

FakeFS replaces File and FileUtils, but is not a filesystem replacement, so gems
that use strange commands or C might circumvent it.  For example, the `sqlite3`
gem will completely ignore any faked filesystem.

Speed?
------

<http://gist.github.com/156091>


Contributing
------------

Once you've made your great commits:

1. [Fork][0] FakeFS
2. Create a topic branch - `git checkout -b my_branch`
3. Push to your branch - `git push origin my_branch`
5. Open a [Pull Request][1]
5. That's it!

Meta
----

* Code: `git clone git://github.com/fakefs/fakefs.git`
* Home: <https://github.com/fakefs/fakefs>
* Bugs: <https://github.com/fakefs/fakefs/issues>
* Test: <https://travis-ci.org/fakefs/fakefs>
* Gems: <https://rubygems.org/gems/fakefs>

[0]: https://help.github.com/forking/
[1]: https://help.github.com/send-pull-requests/

Releasing
---------

1. `bundle exec rake bump:patch` or minor/major
2. `bundle exec rake release`
