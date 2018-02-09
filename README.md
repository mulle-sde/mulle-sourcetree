# mulle-sourcetree, 🌲 Project composition and maintenance with build support

![Last version](https://img.shields.io/github/tag/mulle-nat/mulle-sourcetree.svg)

... for Linux, OS X, FreeBSD, Windows

![Overview](mulle-sourcetree-overview.png)

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
macos | `brew install mulle-kybernetik/software/mulle-sourcetree`
other | ./install.sh  (Requires: [mulle-fetch](https://github.com/mulle-nat/mulle-sourcetree))


## Sourcetree Modes

Mode       | Description
-----------|---------------------------------------------
--flat     | Only the local sourcetree nodes are updated
--recurse  | Subtrees of nodes are also updated
--share    | Like recurse, but nodes with identical URLS are only fetched once

## Sourcetree Marks

A node of a sourcetree can have a variety of "marks".

Mark          | Description
--------------|---------------------------------------------
no-build      | Will not be built.
no-delete     | Will not be deleted in a `mulle-sourcetree clean`
no-dependency | This is not a dependency. (e.g. OS libraries)
no-fs         | There is no equivalent in the project filesystem (e.g. OS libraries)
no-include    | This does not participate in the cmake dependency include scheme
no-link       | Will not be linked against
no-recurse    | A sourcetree within this node will be ignored
no-require    | Failure to fetch this node, is not an error.
no-set        | Protected node from modification.
no-share      | The node is not shareable with other sourcetrees
no-update     | The node will never be updated after an initial fetch.



## Commands

#### `add` : add dependencies with

```
$ mulle-sourcetree -e add --url https://github.com/libexpat/libexpat/archive/R_2_2_5.tar.gz external/expat
$ mulle-sourcetree -e add --url https://github.com/madler/zlib.git external/zlib
```

#### `update` : fetch and update dependencies

```
$ mulle-sourcetree -e update
```


#### `list` : stay in control

See your sourcetree with **list**:

```
$ mulle-sourcetree -e list --output-header
address         nodetype  marks  userinfo  url
-------         --------  -----  --------  ---
external/expat  tar                        https://github.com/libexpat/libexpat/archive/R_2_2_5.tar.gz
external/zlib   git                        https://github.com/madler/zlib.git
```

#### `dotdump` : picture your sourcetree

Get a graphical overview with **dotdump**:

```
$ mulle-sourcetree -e dotdump > pic.dot
open pic.dot # view it with Graphviz (http://graphviz.org/)
```

![Picture](pic.png)


#### `buildorder` : retrieve projects to build

```
$ mulle-sourcetree -e buildorder
/private/tmp/a/external/expat
/private/tmp/a/external/zlib
```



## GitHub and Mulle kybernetiK

The development is done on [Mulle kybernetiK](https://www.mulle-kybernetik.com/software/git/mulle-sourcetree/master). Releases and bug-tracking are on [GitHub](https://github.com/{{PUBLISHER}}/mulle-sourcetree).


