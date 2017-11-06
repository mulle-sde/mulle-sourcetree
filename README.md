# mulle-sourcetree, cross platform dependency manager using bash

![Last version](https://img.shields.io/github/tag/{{PUBLISHER}}/mulle-sourcetree.svg)

... for Linux, OS X, FreeBSD, Windows

... for C, C++, Objective-C

... certainly not a "minimal" or "lightweight" project with ca. 10000 lines of
  shell script code


## Why you may want it

* You program in C, C++ or in Objective-C, **mulle-sourcetree** is written for you
* If you need to link against a library, that clashes with an installed
library,  **mulle-sourcetree** could break this quandary
* If you feel that `apt-get install` pollutes your system with too many libraries,  **mulle-sourcetree** may be the solution
* If you don't like developing in virtual machines, **mulle-sourcetree** may
tickle your fancy
* If you like to decompose huge projects into reusable libraries,
**mulle-sourcetree** may enable you to do so
* If you do cross-platform development, **mulle-sourcetree** may be your best bet for a dependency manager


## Core principles

* Nothing gets installed outside of the project folder
* **mulle-sourcetree** manages your dependencies, it does not manage your
project
* It should be adaptable to a wide ranges of project styles. Almost anything
can be done with configuration settings or additional shell scripts.
* It should be scrutable. If things go wrong, it should be easy to figure
out what the problem is. It has extensive logging and tracing support built in.
* It should run everywhere. **mulle-sourcetree** is a collection of
shell scripts. If your system can run the bash, it can run **mulle-sourcetree**.


## What it does technically

* downloads [zip](http://eab.abime.net/showthread.php?t=5025) and [tar](http://www.grumpynerd.com/?p=132) archives
* fetches [git](//enux.pl/article/en/2014-01-21/why-git-sucks) repositories and it can also checkout [svn](//andreasjacobsen.com/2008/10/26/subversion-sucks-get-over-it/).
* builds [cmake](//blog.cppcms.com/post/54),
[xcodebuild](//devcodehack.com/xcode-sucks-and-heres-why/) and
[configure](//quetzalcoatal.blogspot.de/2011/06/why-autoconf-sucks.html)
projects and installs their output into a "dependencies" folder.
* installs [brew](//dzone.com/articles/why-osx-sucks-and-you-should) binaries and
libraries into an "addictions" folder (on participating platforms)
* alerts to the presence of shell scripts in fetched dependencies


## A first use

So you need a bunch of third party projects to build your own
project ? No problem. Use **mulle-sourcetree init** to do the initial setup of
a `.sourcetree` folder in your project directory. Then add the git repository
URLs:

```
mulle-sourcetree init
mulle-sourcetree setting -g -r -a "repositories" "https://github.com/madler/zlib.git"
mulle-sourcetree setting -g -r -a "repositories" "https://github.com/coapp-packages/expat.git"
mulle-sourcetree
```

**mulle-sourcetree** will check them out into a common directory `stashes`.

After cloning **mulle-sourcetree** looks for a `.sourcetree` folder in the freshly
checked out repositories. They might have dependencies too, if they do, those
dependencies are added and also fetched.

Everything should now be in place so **mulle-sourcetree** that can now build the
dependencies. It will place the headers and the produced
libraries into the `dependencies/lib`  and `dependencies/include` folders.


## Tell me more

* [How to install](dox/INSTALL.md)
* [How to use it](dox/COMMANDS.md)
* [What has changed ?](RELEASENOTES.md)
* [Tweak guide](dox/SETTINGS.md)
* [CMakeLists.txt.example](dox/CMakeLists.txt.example) shows how to access dependencies from **cmake**
* [FAQ](dox/FAQ.md)

* [mulle-sourcetree: A dependency management tool](https://www.mulle-kybernetik.com/weblog/2015/mulle_sourcetree_work_in_progr.html)
* [mulle-sourcetree: Understanding mulle-sourcetree (I)](https://www.mulle-kybernetik.com/weblog/2016/mulle_sourcetree_how_it_works.html)
* [mulle-sourcetree: Understanding mulle-sourcetree (II), Recursion](https://www.mulle-kybernetik.com/weblog/2016/mulle_sourcetree_recursion.html)

If you want to hack on mulle-sourcetree, I'd recommend to get
[Sublime Text](//www.sublimetext.com) and [install the linter plugin](//blog.codybunch.com/2016/01/25/Better-Bash-with-Sublime-Linter-and-ShellCheck/) to use [Shellcheck](//www.shellcheck.net). It
simplifies shell scripting by an order of magnitude.

## GitHub and Mulle kybernetiK

The development is done on [Mulle kybernetiK](https://www.mulle-kybernetik.com/software/git/mulle-sourcetree/master). Releases and bug-tracking are on [GitHub](https://github.com/{{PUBLISHER}}/mulle-sourcetree).


