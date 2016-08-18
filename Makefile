include /usr/share/templar/make/Makefile

##############
# parameters #
##############
# do you want to see the commands executed ?
DO_MKDBG:=0
# do you want to check the javascript code?
DO_CHECKJS:=1
# do you want to validate html?
DO_CHECKHTML:=0
# do you want to validate css?
DO_CHECKCSS:=0
# Do you want to do tools?
DO_TOOLS:=1
# do you want dependency on the makefile itself ?
DO_ALL_DEPS:=1

#########
# tools #
#########
TOOL_COMPILER:=~/install/closure/compiler.jar
TOOL_JSMIN:=~/install/jsmin/jsmin
TOOL_JSDOC:=~/install/jsdoc/jsdoc
TOOL_JSL:=tools/jsl/jsl
TOOL_JSLINT:=~/install/node_modules/jslint/bin/jslint.js
TOOL_CSS_VALIDATOR:=~/install/css-validator/css-validator.jar
TOOL_GJSLINT:=gjslint
TOOL_YUICOMPRESSOR:=yui-compressor

JSCHECK:=jscheck.stamp
HTMLCHECK:=html.stamp
CSSCHECK:=css.stamp
# what is the stamp file for the tools?
TOOLS:=tools.stamp

########
# code #
########
CLEAN:=

ifeq ($(DO_CHECKJS),1)
ALL+=$(JSCHECK)
all: $(ALL)
CLEAN+=$(JSCHECK)
endif # DO_CHECKJS

ifeq ($(DO_CHECKHTML),1)
ALL+=$(HTMLCHECK)
all: $(ALL)
CLEAN+=$(HTMLCHECK)
endif # DO_CHECKHTML

ifeq ($(DO_CHECKCSS),1)
ALL+=$(CSSCHECK)
all: $(ALL)
CLEAN+=$(CSSCHECK)
endif # DO_CHECKCSS

# silent stuff
ifeq ($(DO_MKDBG),1)
Q:=
# we are not silent in this branch
else # DO_MKDBG
Q:=@
#.SILENT:
endif # DO_MKDBG

SOURCES_JS:=$(shell find js -name "*.js")
SOURCES_HTML:=php/index.php
#SOURCE_HTML:=$(shell find html -name "*.html")
SOURCES_CSS:=$(shell find css -name "*.css")

# dependency on the makefile itself
ifeq ($(DO_ALL_DEPS),1)
ALL_DEPS:=Makefile
else
ALL_DEPS:=
endif

# all variables between the snapshot of BUILT_IN_VARS and this place in the code
DEFINED_VARS:=$(filter-out $(BUILT_IN_VARS) BUILT_IN_VARS, $(.VARIABLES))
###########
# targets #
###########

$(TOOLS): scripts/tools.py
	$(info doing [$@])
	$(Q)scripts/tools.py
	$(Q)make_helper touch-mkdir $@

.PHONY: debug_me
debug_me:
	$(info doing [$@])
	$(foreach v, $(DEFINED_VARS), $(info $(v) = $($(v))))

# clean

.PHONY: clean_manual
clean_manual:
	$(info doing [$@])
	$(Q)-rm -f $(CLEAN)

# checks

.PHONY: checkjs
checkjs: $(JSCHECK)
	$(info doing [$@])

.PHONY: checkhtml
checkhtml: $(HTMLCHECK)
	$(info doing [$@])

.PHONY: checkcss
checkcss: $(CSSCHECK)
	$(info doing [$@])

$(JSCHECK): $(SOURCES_JS) $(TOOLS) $(ALL_DEP)
	$(info doing [$@])
	$(Q)$(TOOL_JSL) --conf=support/jsl.conf --quiet --nologo --nosummary --nofilelisting $(SOURCES_JS)
	$(Q)make_helper wrapper-silent $(TOOL_GJSLINT) --flagfile support/gjslint.cfg $(SOURCES_JS)
	$(Q)mkdir -p $(dir $@)
	$(Q)touch $(JSCHECK)

$(HTMLCHECK): $(SOURCES_HTML) $(TOOLS) $(ALL_DEP)
	$(info doing [$@])
	$(Q)tidy -errors -q -utf8 $(SOURCES_HTML)
	$(Q)mkdir -p $(dir $@)
	$(Q)touch $(HTMLCHECK)

$(CSSCHECK): $(SOURCES_CSS) $(TOOLS) $(ALL_DEP)
	$(info doing [$@])
	$(Q)make_helper wrapper-css-validator java -jar $(TOOL_CSS_VALIDATOR) --profile=css3 --output=text -vextwarning=true --warning=0 $(addprefix file:,$(SOURCES_CSS))
	$(Q)mkdir -p $(dir $@)
	$(Q)touch $(CSSCHECK)

# deploy

.PHONY: deploy_local_code
deploy_local_code: all
	$(info doing [$@])
	$(Q)rm -rf $(tdefs.nikuda_local_root)
	$(Q)mkdir $(tdefs.nikuda_local_root)
	$(Q)cp -r css js js_tp images php php/index.php $(tdefs.nikuda_local_root)
	$(Q)cp -f out/config_local.php $(tdefs.nikuda_local_root)/php/config.php

.PHONY: deploy_local_db
deploy_local_db:
	$(info doing [$@])
	$(Q)-mysqladmin --host=$(tdefs.nikuda_local_db_host) --user=$(tdefs.nikuda_local_db_user) --password=$(tdefs.nikuda_local_db_password) -f drop $(tdefs.nikuda_local_db_name) > /dev/null
	$(Q)mysqladmin --host=$(tdefs.nikuda_local_db_host) --user=$(tdefs.nikuda_local_db_user) --password=$(tdefs.nikuda_local_db_password) create $(tdefs.nikuda_local_db_name)
	$(Q)mysql --host=$(tdefs.nikuda_local_db_host) --user=$(tdefs.nikuda_local_db_user) --password=$(tdefs.nikuda_local_db_password) $(tdefs.nikuda_local_db_name) < db/nikuda.mysqldump

# notes about deploy:
# we are not allowed to drop the database and create it so we don't
# instead we just load the new data.
# As far as existing table data is concerned this is ok since the mysql
# dump removes the tables and recreates them with the data.
# This is somewhat unclean since db tables which were in the old version
# and are not in the new will remain there and will need to be removed
# by hand...
.PHONY: deploy_remote
deploy_remote: deploy_remote_code deploy_remote_db
	$(info doing [$@])

.PHONY: deploy_remote_db
deploy_remote_db:
	$(info doing [$@])
	$(Q)mysql $(tdefs.nikuda_remote_db_name) --host=$(tdefs.nikuda_remote_db_host) --user=$(tdefs.nikuda_remote_db_user) --password=$(tdefs.nikuda_remote_db_password) < db/nikuda.mysqldump

.PHONY: deploy_remote_code
deploy_remote_code:
	$(info doing [$@])
	$(Q)scripts/ftp_rmdir.py $(tdefs.nikuda_remote_ftp_host) $(tdefs.nikuda_remote_ftp_user) $(tdefs.nikuda_remote_ftp_password) .
	$(Q)ncftpput -R -u $(tdefs.nikuda_remote_ftp_user) -p $(tdefs.nikuda_remote_ftp_password) $(tdefs.nikuda_remote_ftp_host) $(tdefs.nikuda_remote_ftp_dir) css js js_tp images php
	$(Q)ncftpput -C -u $(tdefs.nikuda_remote_ftp_user) -p $(tdefs.nikuda_remote_ftp_password) $(tdefs.nikuda_remote_ftp_host) out/config_remote.php $(tdefs.nikuda_remote_ftp_dir)php/config.php
	$(Q)ncftpput -C -u $(tdefs.nikuda_remote_ftp_user) -p $(tdefs.nikuda_remote_ftp_password) $(tdefs.nikuda_remote_ftp_host) php/index.php $(tdefs.nikuda_remote_ftp_dir)index.php

.PHONY: deploy_remote_config
deploy_remote_config: out/config_remote.php
	$(info doing [$@])
	$(Q)ncftpput -C -u $(tdefs.nikuda_remote_ftp_user) -p $(tdefs.nikuda_remote_ftp_password) $(tdefs.nikuda_remote_ftp_host) out/config_remote.php $(tdefs.nikuda_remote_ftp_dir)config.php

.PHONY: deploy_under_construction
deploy_under_construction:
	$(info doing [$@])
	$(Q)ncftpput -R -u $(tdefs.nikuda_remote_ftp_user) -p $(tdefs.nikuda_remote_ftp_password) $(tdefs.nikuda_remote_ftp_host) $(tdefs.nikuda_remote_ftp_dir) under_construction/index.php

.PHONY: undeploy_under_construction
undeploy_under_construction:
	$(info doing [$@])
	$(Q)ncftpput -R -u $(tdefs.nikuda_remote_ftp_user) -p $(tdefs.nikuda_remote_ftp_password) $(tdefs.nikuda_remote_ftp_host) $(tdefs.nikuda_remote_ftp_dir) php/index.php

# remote stuff

.PHONY: remote-backup
remote-backup:
	$(info doing [$@])
	$(Q)wget -r ftp://$(tdefs.nikuda_remote_ftp_host) --ftp-user=$(tdefs.nikuda_remote_ftp_user) --ftp-password=$(tdefs.nikuda_remote_ftp_password)

.PHONY: remote-mysql
remote-mysql:
	$(info doing [$@])
	$(Q)mysql --host=$(tdefs.nikuda_remote_db_host) --user=$(tdefs.nikuda_remote_db_user) --password=$(tdefs.nikuda_remote_db_password) $(tdefs.nikuda_remote_db_name)

.PHONY: remote-ftp
remote-ftp:
	$(info doing [$@])
	$(info put remote user as $(tdefs.nikuda_remote_ftp_user))
	$(info put remote password as $(tdefs.nikuda_remote_ftp_password))
	#$(Q)ftp $(tdefs.nikuda_remote_ftp_host)
	$(Q)lftp $(tdefs.nikuda_remote_ftp_host) -u $(tdefs.nikuda_remote_ftp_user),$(tdefs.nikuda_remote_ftp_password)

.PHONY: remote-errorlog
remote-errorlog:
	$(info doing [$@])
	$(Q)rm -f error_log phperrors.txt
	$(Q)ncftpget -C -u $(tdefs.nikuda_remote_ftp_user) -p $(tdefs.nikuda_remote_ftp_password) $(tdefs.nikuda_remote_ftp_host) /php/error_log error_log
	$(Q)ncftpget -C -u $(tdefs.nikuda_remote_ftp_user) -p $(tdefs.nikuda_remote_ftp_password) $(tdefs.nikuda_remote_ftp_host) /php/phperrors.txt phperrors.txt
