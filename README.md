# mulle-sourcetree, cross platform sourcetree compositor

![Last version](https://img.shields.io/github/tag/mulle-nat/mulle-sourcetree.svg)

... for Linux, OS X, FreeBSD, Windows

#### Capabilities

* maintains local (file, folder) or external tree nodes (archive, repository)
* can decorate tree nodes with marks (flags), which can be queried later
* can store an arbitrary binary blob with each node as userinfo
* can deal with sourcetrees within sourcetrees (recursive operation)
* can walk the sourcetree with qualifiers
* support the repair of the sourcetree after filesystem changes

#### What this enables you to do

* build sub-projects in the correct order
* build platform specifica without #ifdef or complicated Makefiles
* acquire required sub-projects dependent on the platform


<script type="text/javascript" src="https://asciinema.org/a/147241.js" id="asciicast-147241" async></script>

Organize your projects my adding archives and repositories to your project and placing them freely.


## Decorate your source tree with marks

You can decorate the nodes in the sourcetree with marks. Those you can query later on
```
mulle-sourcetree add --url https://github.com/madler/zlib.git external/zlib
mulle-sourcetree mark external/zlib nobuild
mulle-sourcetree add --url https://github.com/noone/noexist.git external/noexist
mulle-sourcetree mark external/zlib norequire
mulle-sourcetree list
mulle-sourcetree update
mulle-sourcetree buildorder
```

## Have sourcetrees within sourcetrees



## Stay in control with dotump

Have a graphical overview of your sourcetree with **dotdump**

```
url                                                    address     branch  tag  marks
---                                                    -------         ------  ---  -----
https://github.com/madler/zlib/archive/v1.2.11.tar.gz  external/expat
https://github.com/madler/zlib.git                     external/zlib   master
```

```
mulle-sourcetree dotdump > pic.dot
open pic.dot # view it with Graphviz (http://graphviz.org/)
```

![Picture](pic.png)



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


