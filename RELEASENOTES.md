### 0.14.5

* improve usage info a bit

### 0.14.4

* fix local address getting mangled

### 0.14.3

* recognize some no-os- variant marks

### 0.14.2

* fix for mingw

### 0.14.1

* fix a bug when burying zombies experimentally add fetch-`<uname>` mark
* buildorder is now more clever about producing `MULLE_SOURCETREE_STASH_DIR` prefixed paths

### 0.13.1

* fix update flag and erroneous error message when cleaning

## 0.13.0

* add knownmarks command, renamed --extended-marks to --extended-mark


### 0.12.2

* make no-public known

### 0.12.1

* touch parent configs when config changed

## 0.12.0

* rewrote update, to enable sharing of symlinked repositories


## 0.11.0

* add --qualifier option to filter marks more cleverly, you can still use --marks though in limited cases
* add --callback option to buildorder


### 0.10.1

* fix subprojects dependencies not being properly shared

## 0.10.0

* improved symlink handling in the walker a lot, which has positive implications through out mulle-sourcetree
* local nodes are not silently augmented with required marks, but instead an error is thrown


### 0.9.10

* simplified code a little, improved add command semantics

### 0.9.9

* use `LC_ALL=C` for sort

### 0.9.8

* remove file from git

### 0.9.7

* simplify README

### 0.9.6

* improved brew formula defintion

### 0.9.5

* need bsdmainutils on debian for column

### 0.9.4

* fix package dependencies more

### 0.9.3

* fix homebrew install ruby script

### 0.9.2

* rename option --marks to --output-marks for buildorder

### 0.9.1

* rename install to installer, because of name conflict

## 0.9.0

* Allow output-no- as well as no-output- for list options
* Fix problem with share inside no-share


### 0.8.5

* remove filename from status output

### 0.8.4

* fix dox and install

### 0.8.3

* rename install.sh to install, fix trace bug

### 0.8.2

* CMakeLists.txt CMakePackage.txt LICENSE Makefile README.md RELEASENOTES.md TODO.md benchmark bin build install.sh movies mulle-column mulle-project mulle-sourcetree mulle-sourcetree-overview.dot mulle-sourcetree-overview.png mulle-sourcetree.sublime-project mulle-sourcetree.sublime-workspace pic.png research src test tmp.62MuALC5 tmp.8TihBMhs tmp.8meNZ6Gb tmp.EaPl8Kw5 tmp.FJzuDhTS tmp.JBcS0N48 tmp.LX05Aq2p tmp.LfE1PWHv tmp.Me6QNGhI tmp.TNU1AnKf tmp.dxYEPghb tmp.gHlgWdiP tmp.mz667t1s tmp.qbWLdiJX tmp.rXe64Rrl tmp.ruRELjzu tmp.tqRbdouz tmp.ueLGLOck tmp.ytNCkWea simplified CMakeLists.txt, simplify printf stuff

### 0.8.1

* fix some bugs

## 0.8.0

* add dbstatus command


### 0.7.15

* considerable speed improvements

### 0.7.14

* fix test

### 0.7.13

* fix README

### 0.7.12

* address prefixed with . is not allowed, as the mulle tools depend on that

### 0.7.11

* fix CMakeLists.txt

### 0.7.10

* support no-all-load

### 0.7.9

* add move command

### 0.7.8

* fix bug with only-share

### 0.7.7

* fix two harmless bugs

### 0.7.6

* share is the new default now

### 0.7.5

* a bit faster marks checking

### 0.7.4

* store marks sorted, don't update sourcetrees of symlinked projects

### 0.7.3

* up the version
* lose outdated and unmaintained migration tool for now, improve fix code, make db local to host

### 0.7.2

* fix column output
* fix column output
* fix listing bug

### 0.7.1

* fix column output


## 0.7.0

* change format to use % like other tools
* nodemarks are now always stored sorted
* don't produce .bak files anymore


### 0.6.2

* don't produce .bak files anymore

## 0.6.0

* new -if-missing option


## 0.5.0

* Various small improvements


## 0.4.0

* adapt to new mulle-bashfunctions 1.3


### 0.3.3

* add no-fs mark

### 0.3.2

* add some more nodemarks for mulle-sde

### 0.3.1

* changes for mulle-sde

## 0.3.0

* use no- instead of no, allow only- markers too


### 0.2.1

* fix stuff for linux

## 0.2.0

* use evaled url to unique sharable nodes


### 0.1.1

* Various small improvements

## 0.1.0

* reorganize support files into own .mulle-sourcetree subdirectory
* callback environment scheme redone
* fix code improved
* run-test without .sh extension now
* forked off from mulle-bootstrap
* rename "scm" to "source", because it fits better.
* added mulle-bootstrap shared to remove .build folders from .bootstrap
* added a convenience interface to edit repositories and embedded_repositories


# 1.0.0

* forked off from mulle-bootstrap
