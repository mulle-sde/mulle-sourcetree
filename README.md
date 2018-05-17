# mulle-sourcetree, 🌲 Project composition and maintenance with build support

![Last version](https://img.shields.io/github/tag/mulle-nat/mulle-sourcetree.svg)

... for Linux, OS X, FreeBSD, Windows

![Overview](mulle-sourcetree-overview.png)

Organize your projects freely with multiple archives and repositories.
It is not meant to manage individual source files.


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

Install the pre-requisite [mulle-fetch](https://github.com/mulle-nat/mulle-bashfunctions)
and it's pre-requisites.

Install into `/usr` with sudo:

```
curl -L 'https://github.com/mulle-sde/mulle-fetch/archive/latest.tar.gz' \
 | tar xfz - && cd 'mulle-fetch-latest' && sudo ./install /usr
```

### Packages

OS          | Command
------------|------------------------------------
macos       | `brew install mulle-kybernetik/software/mulle-fetch`


## Sourcetree Nodes

A local sourcetree is a list of nodes. A node typically has a representation
in the filesystem. An easy example is a node called `zlib`, that is present
in the project as a folder called `zlib`.

A node consists of a of nine different fields. The most important fields are

* the address, which is its place in the project filesystem
* the nodetype, which distinguishes between local subprojects, remote repositories, operating system libraries and the like
* the url, which is used to identify and possibly retrieve a repository or archive for this node.

A node can also be decorated with various "marks" (see below) and can carry
a user-defined "userinfo" payload.

These are the fields of a node:

Field          | Required | Description
---------------|----------|---------------------------------------------
`address`      | YES      | name of the node and relative position in the project
`branch`       | NO       | repository branch (git)
`fetchoptions` | NO       | The node is not shareable with other sourcetrees
`marks`        | NO       | marks of the node
`nodetype`     | YES      | type of node
`tag`          | NO       | repository tag (git)
`url`          | NO       | URL of node.
`userinfo`     | NO       | userinfo of node. can be binary.
`uuid`         | NO       | internal node identifier. Don't touch.


## Sourcetree Nodetypes

These are the known nodetypes. In addition to `address` and `nodetype` some
of the other fields may be used or ignored, depending on the nodetype.

Nodetype  | Url | Branch | Tag | Fetchoptions | Description
----------|-----|--------|-----|--------------|------------------------
`git`     | YES | YES    | YES | YES          | git repository
`local`   | NO  | NO     | NO  | NO           | used for subprojects
`svn`     | YES | YES    | NO  | YES          | svn repository
`symlink` | YES | NO     | NO  | NO           | symbolic link
`tar`     | YES | NO     | NO  | YES          | tar archive. fetchoptions enable check shasum integrity
`zip`     | YES | NO     | NO  | YES          | zip archive. fetchoptions enable check shasum integrity


## Sourcetree Marks

A node of a sourcetree can have a variety of pre-defined and user-defined
"marks". These are a list of marks that are interpreted by mulle-sourcetree.
By default a node has all possible marks. You can selectively remove marks.

Mark       | Description
-----------|---------------------------------------------
`delete`   | Will be deleted in a `mulle-sourcetree clean`
`fs`       | The node has/should have a corresponding  file or folder
`recurse`  | An inferior sourcetree within this node will be used
`require`  | Failure to fetch this node is an error.
`set`      | The node itself can be modified.
`share`    | The node is shareable with other sourcetrees
`update`   | The node will be updated after an initial fetch.

These are some marks, that are used by mulle-sde tools:


Mark         | Description
-------------|---------------------------------------------
`build`      | Will be built.
`dependency` | This is a dependency
`header`     | Will be used for header generation (_dependencies.h)
`link`       | Will be linked against


#### Sourcetree Modes

Mode         | Description
-------------|---------------------------------------------
`--flat`     | Only the local sourcetree nodes are updated
`--recurse`  | Subtrees of nodes are also updated
`--share`    | Like recurse, but nodes with identical URLs are only fetched once


## Commands

#### `mulle-sourcetree add` : add nodes with

```
$ mulle-sourcetree -e add --url https://github.com/libexpat/libexpat/archive/R_2_2_5.tar.gz external/expat
```

You can specify your URL with environment variables, to make them more portable:

```
$ mulle-sourcetree -e add --url '${ZLIB_URL:-https://github.com/madler/zlib.git}' external/zlib
```


#### `mulle-sourcetree update` : fetch and update nodes

After changing the sourcetree, run *update* to reflect the changes back
into your project:



```
$ mulle-sourcetree -e update
```


#### `mulle-sourcetree list` : stay in control

See your sourcetree with **list**:

```
$ mulle-sourcetree -e list --output-header --output-eval
address         nodetype  marks  userinfo  url
-------         --------  -----  --------  ---
external/expat  tar                        https://github.com/libexpat/libexpat/archive/R_2_2_5.tar.gz
external/zlib   git                        https://github.com/madler/zlib.git
```

#### `mulle-sourcetree dotdump` : picture your sourcetree

Get a graphical overview with **dotdump**:

```
$ mulle-sourcetree -e dotdump > pic.dot
open pic.dot # view it with Graphviz (http://graphviz.org/)
```

![Picture](pic.png)


#### `mulle-sourcetree buildorder` : retrieve projects to build

```
$ mulle-sourcetree -e buildorder
/private/tmp/a/external/expat
/private/tmp/a/external/zlib
```



## GitHub and Mulle kybernetiK

The development is done on
[Mulle kybernetiK](https://www.mulle-kybernetik.com/software/git/mulle-sourcetree/master).
Releases and bug-tracking are on
[GitHub](https://github.com/{{PUBLISHER}}/mulle-sourcetree).
