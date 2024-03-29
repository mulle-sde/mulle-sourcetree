SCRIPTS=./bin/installer \
src/mulle-sourcetree-action.sh \
src/mulle-sourcetree-bash-completion.sh \
src/mulle-sourcetree-callback.sh \
src/mulle-sourcetree-cfg.sh \
src/mulle-sourcetree-clean.sh \
src/mulle-sourcetree-commands.sh \
src/mulle-sourcetree-config.sh \
src/mulle-sourcetree-craftorder.sh \
src/mulle-sourcetree-db.sh \
src/mulle-sourcetree-dbstatus.sh \
src/mulle-sourcetree-diff.sh \
src/mulle-sourcetree-dotdump.sh \
src/mulle-sourcetree-environment.sh \
src/mulle-sourcetree-eval-add.sh \
src/mulle-sourcetree-fetch.sh \
src/mulle-sourcetree-filter.sh \
src/mulle-sourcetree-fix.sh \
src/mulle-sourcetree-list.sh \
src/mulle-sourcetree-node.sh \
src/mulle-sourcetree-nodeline.sh \
src/mulle-sourcetree-nodemarks.sh \
src/mulle-sourcetree-reset.sh \
src/mulle-sourcetree-reuuid.sh \
src/mulle-sourcetree-rewrite.sh \
src/mulle-sourcetree-status.sh \
src/mulle-sourcetree-sync.sh \
src/mulle-sourcetree-test.sh \
src/mulle-sourcetree-update.sh \
src/mulle-sourcetree-walk.sh \
src/mulle-sourcetree-wrap.sh

CHECKSTAMPS=$(SCRIPTS:.sh=.chk)

#
# catch some more glaring problems, the rest is done with sublime
#
SHELLFLAGS=-x -e SC2016,SC2034,SC2086,SC2164,SC2166,SC2006,SC1091,SC2039,SC2181,SC2059,SC2196,SC2197 -s sh

.PHONY: all
.PHONY: clean
.PHONY: shellcheck_check

%.chk:	%.sh
	- shellcheck $(SHELLFLAGS) $<
	(shellcheck -f json $(SHELLFLAGS) $< | jq '.[].level' | grep -w error > /dev/null ) && exit 1 || touch $@

all:	$(CHECKSTAMPS) mulle-sourcetree.chk shellcheck_check jq_check

mulle-sourcetree.chk:	mulle-sourcetree
	- shellcheck $(SHELLFLAGS) $<
	(shellcheck -f json $(SHELLFLAGS) $< | jq '.[].level' | grep -w error > /dev/null ) && exit 1 || touch $@

installer:
	@ ./bin/installer

clean:
	@- rm src/*.chk
	@- rm *.chk

shellcheck_check:
	which shellcheck || brew install shellcheck

jq_check:
	which shellcheck || brew install shellcheck
