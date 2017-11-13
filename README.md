# mulle-sourcetree, cross platform sourcetree
 compositor

![Last version](https://img.shields.io/github/tag/mulle-nat/mulle-sourcetree.svg)

... for Linux, OS X, FreeBSD, Windows


Add archives and repositories to your project and place them freely whereever
you want.

In the most simple example, this will download `zlib` and unpack it in the
desired location `external/expat`:

```
mulle-sourcetree add https://github.com/madler/zlib/archive/v1.2.11.tar.gz external/expat
mulle-sourcetree update
```


## A walkthrough through some of the options

Add two external projects to your sourcetree:

```
mulle-sourcetree add https://github.com/madler/zlib.git external/zlib
```

See what you added with `mulle-sourcetree list`:

```
url                                                    address     branch  tag  marks
---                                                    -------         ------  ---  -----
https://github.com/madler/zlib/archive/v1.2.11.tar.gz  external/expat
https://github.com/madler/zlib.git                     external/zlib   master
```

See what will happen with:

```
mulle-sourcetree dotdump > pic.dot
open pic.dot # view it with Graphviz (http://graphviz.org/)
```

![Picture](pic.png)


Now download the external resources, then check the status of your sourcetree:

```
mulle-sourcetree update
mulle-sourcetree status
```


```
address     status
-----------     ------
.               ok
external/expat  ok
external/zlib   ok
```

Move stuff around:

```
mulle-sourcetree set -d external/old/expat3
mulle-sourcetree update
mulle-sourcetree dotdump > pic.dot
```

Or do it manually with fixup


```
mv external/old/expat3  external/old/whateve
mulle-sourcetree fix
```



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


