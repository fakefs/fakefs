Faked #require, #load and #autoload
===================================

Testing a library that loads ruby source files by configuration, I noticed that
defunkt's great FakeFS was lacking support for faking #require, #autoload, etc.


Installation
------------

    $ gem install fakefs-require


Usage
-----

    require "fakefs/safe"
    require "fakefs/require"

    FakeFS.activate!
    FakeFS::Require.activate!
    
    File.open("foo.rb", "w") {|f| f.write "puts 'hello world!'" }
    require "foo"
    
Files loaded by #require will be appended to $".


Gems, Standard Lib and Load Path
--------------------------------

FakeFS::Require provides a fallback for tests which use code (most likely gems)
that #require source files or gems at runtime (e.g. Usher). This will fail
because the required files don't exist in FakeFS. You can workaround this issue
by activating like this:

    FakeFS::Require.activate! :fallback => true

This will make the faked #require call the original #require if loading the
passed file in FakeFS fails.

FakeFS::Require uses $LOAD_PATH to find out in which paths to search (just like
the original...).


Autoloading
-----------

The autoloading mechanism ignores a monkey patched #require (see
http://blade.nagaokaut.ac.jp/cgi-bin/vframe.rb/ruby/ruby-core/20190?20046-21072+split-mode-vertical),
so we will have to fake #autoload itself to get this working. If you use gems or
other code that utilizes #autoload (e.g. Rack), pass the :autoload flag to
::activate!.

    FakeFS::Require.activate! :autoload => true

Note: This will only work for autoload calls made _after_ ::activate! has been
called.


Kernel#load
-----------

There is also support for Kernel#load, including loading the file within an
anonymous module.

    FakeFS::Require.activate! :load => true


Limitations
-----------

There are two known limitations to FakeFS::Require (besides ones to FakeFS).

1.  David Masover points this out:
        
        irb(main):001:0> autoload :CSV, 'csv'
        => nil
        irb(main):002:0> module CSV
        irb(main):003:1> end
        TypeError: CSV is not a module
                from (irb):2
    
    See http://www.ruby-forum.com/topic/205612#898211 for more information on
    this.

2.  If a class/module that calls #autoload defines #const_missing the faked
    autoload won't work. Maybe this is a WONTFIX, I don't know... any ideas?

3.  The faked #require does only work with .rb files. Binary files like .so and
    .dll will not be loaded.


Contributing
------------

Once you've made your great commits:

1. Fork fakefs-require
2. Create a topic branch - `git checkout -b my_branch`
3. Push to your branch - `git push origin my_branch`
4. Create an issue with a link to your branch
5. That's it!


License
-------

fakefs-require is subject to the MIT License (see LICENSE file)
