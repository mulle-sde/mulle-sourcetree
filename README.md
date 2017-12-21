# mulle-sourcetree,  🌲 Project composition and maintainance with build support 

![Last version](https://img.shields.io/github/tag/mulle-nat/mulle-sourcetree.svg)

... for Linux, OS X, FreeBSD, Windows

Organize your projects freely with multiple archives and repositories.

#### Capabilities

* maintains local (file, folder) or external tree nodes (archive, repository)
* can decorate tree nodes with marks (flags), which can be queried later
* can store an arbitrary binary blob with each node as userinfo
* can deal with sourcetrees within sourcetrees (recursive operation)
* can share common dependendies of sourcetrees (share operation)
* can walk the sourcetree with qualifiers
* supports the repair of the sourcetree after manual filesystem changes
* can symlink other local projects

#### What this enables you to do

* build sub-projects in the correct order
* build platform specifica without #ifdef or complicated Makefiles
* acquire dependencies unique to each platform
* avoid duplicate edits in shared projects


Executable                      | Description
--------------------------------|--------------------------------
`mulle-sourcetree`              | Maintain sources and dependencies
`mulle-bootstrap-to-sourcetree` | Migration tool for mulle-bootstrap projects


## Install


OS    | Command
------|------------------------------------
macos | `brew install mulle-kybernetik/software/mulle-fetch`
other | ./install.sh  (Requires: [mulle-fetch](https://github.com/mulle-nat/mulle-fetch), [mulle-bashfunctions](https://github.com/mulle-nat/mulle-bashfunctions))

## Commands

#### Add dependencies with *add*

```
$ mulle-sourcetree add https://github.com/libexpat/libexpat/archive/R_2_2_5.tar.gz external/expat
$ mulle-sourcetree add https://github.com/madler/zlib.git external/zlib
```

#### Fetch dependencies with *update*

```
$ mulle-sourcetree update
```


#### Stay in control with *list* and *dotdump*

See your sourcetree with **list**:

```
$ mulle-sourcetree list
url                                                    address     branch  tag  marks
---                                                    -------         ------  ---  -----
https://github.com/libexpat/libexpat/archive/R_2_2_5.tar.gz  external/expat
https://github.com/madler/zlib.git                     external/zlib   master
```

Get a graphical overview with **dotdump**:

```
mulle-sourcetree dotdump > pic.dot
open pic.dot # view it with Graphviz (http://graphviz.org/)
```

![Picture](pic.png)


## GitHub and Mulle kybernetiK

The development is done on [Mulle kybernetiK](https://www.mulle-kybernetik.com/software/git/mulle-sourcetree/master). Releases and bug-tracking are on [GitHub](https://github.com/{{PUBLISHER}}/mulle-sourcetree).


