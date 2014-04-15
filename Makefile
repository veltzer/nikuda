##############
# PARAMETERS # 
##############
# remember all build in vars (must be before parameter definitions)
BUILT_IN_VARS:=$(.VARIABLES)

include ~/.nikudarc

# do you want dependency on the makefile itself ?
DO_MAKEDEPS:=1
# do you want to see the commands executed ?
DO_MKDBG:=0
# do you want to check the javascript code?
DO_CHECKJS:=1
# do you want to validate html?
DO_CHECKHTML:=1
# do you want to validate css?
DO_CHECKCSS:=1

# tools
TOOL_COMPILER:=~/install/closure/compiler.jar
TOOL_JSMIN:=~/install/jsmin/jsmin
TOOL_JSDOC:=~/install/jsdoc/jsdoc
TOOL_JSL:=~/install/jsl/jsl
TOOL_GJSLINT:=~/install/gjslint/gjslint
TOOL_YUICOMPRESSOR:=yui-compressor
TOOL_JSLINT:=jslint
TOOL_CSS_VALIDATOR:=~/install/css-validator/css-validator.jar

JSCHECK:=jscheck.stamp
HTMLCHECK:=html.stamp
CSSCHECK:=css.stamp

GPP_DIR_SOURCE:=gpp
GPP_DIR_TARGET:=gpp_out

# create a gpp command line of all vars (must be last after paramter definitions)
DEFINED_VARS:=$(filter-out $(BUILT_IN_VARS) BUILT_IN_VARS, $(.VARIABLES))
GPP_PARAMS:=$(foreach v, $(DEFINED_VARS), -D$(v)="$($(v))")
########
# CODE #
########
ALL:=
CLEAN:=

ifeq ($(DO_CHECKJS),1)
ALL:=$(ALL) $(JSCHECK)
CLEAN:=$(CLEAN) $(JSCHECK)
endif # DO_CHECKJS

ifeq ($(DO_CHECKHTML),1)
ALL:=$(ALL) $(HTMLCHECK)
CLEAN:=$(CLEAN) $(HTMLCHECK)
endif # DO_CHECKHTML

ifeq ($(DO_CHECKCSS),1)
ALL:=$(ALL) $(CSSCHECK)
CLEAN:=$(CLEAN) $(CSSCHECK)
endif # DO_CHECKCSS

# silent stuff
ifeq ($(DO_MKDBG),1)
Q:=
# we are not silent in this branch
else # DO_MKDBG
Q:=@
#.SILENT:
endif # DO_MKDBG

# handle dependency on the makefile itself...
ALL_DEP:=
ifeq ($(DO_MAKEDEPS),1)
	ALL_DEP:=$(ALL_DEP) Makefile ~/.nikudarc
endif

SOURCES_JS:=$(shell find js -name "*.js")
SOURCES_HTML:=php/index.php
#SOURCE_HTML:=$(shell find html -name "*.html")
SOURCES_CSS:=$(shell find css -name "*.css")

GPP_SOURCES:=$(shell find $(GPP_DIR_SOURCE) -name "*.gpp")
GPP_TARGETS:=$(addprefix $(GPP_DIR_TARGET)/,$(notdir $(basename $(GPP_SOURCES))))

ALL:=$(ALL) $(GPP_TARGETS)

#########
# RULES #
#########

.PHONY: all
all: $(ALL)

.PHONY: checkjs
checkjs: $(JSCHECK)
	$(info doing [$@])

.PHONY: checkhtml
checkhtml: $(HTMLCHECK)
	$(info doing [$@])

.PHONY: checkcss
checkcss: $(CSSCHECK)
	$(info doing [$@])

$(JSCHECK): $(SOURCES_JS) $(ALL_DEP)
	$(info doing [$@])
	$(Q)$(TOOL_JSL) --conf=support/jsl.conf --quiet --nologo --nosummary --nofilelisting $(SOURCES_JS)
	$(Q)#scripts/wrapper.py $(TOOL_GJSLINT) --flagfile support/gjslint.cfg $(SOURCES_JS)
	$(Q)#jslint $(SOURCES_JS)
	$(Q)mkdir -p $(dir $@)
	$(Q)touch $(JSCHECK)

$(HTMLCHECK): $(SOURCES_HTML) $(ALL_DEP)
	$(info doing [$@])
	$(Q)tidy -errors -q -utf8 $(SOURCES_HTML) 
	$(Q)mkdir -p $(dir $@)
	$(Q)touch $(HTMLCHECK)

$(CSSCHECK): $(SOURCES_CSS) $(ALL_DEP)
	$(info doing [$@])
	$(Q)scripts/css-validator-wrapper.py java -jar $(TOOL_CSS_VALIDATOR) --vextwarning=true --output=text $(addprefix file:,$(SOURCES_CSS))
	$(Q)mkdir -p $(dir $@)
	$(Q)touch $(CSSCHECK)

.PHONY: deploy_local_code
deploy_local_code: all
	$(info doing [$@])
	$(Q)rm -rf $(LOCAL_ROOT)
	$(Q)mkdir $(LOCAL_ROOT)
	$(Q)cp -r css js js_tp images php php/index.php $(LOCAL_ROOT)
	$(Q)cp gpp_out/config_local.php $(LOCAL_ROOT)/php/config.php

.PHONY: deploy_local_db
deploy_local_db:
	$(info doing [$@])
	$(Q)-mysqladmin --host=$(LOCAL_DB_HOST) --user=$(LOCAL_DB_USER) --password=$(LOCAL_DB_PASS) -f drop $(LOCAL_DB_NAME) > /dev/null
	$(Q)mysqladmin --host=$(LOCAL_DB_HOST) --user=$(LOCAL_DB_USER) --password=$(LOCAL_DB_PASS) create $(LOCAL_DB_NAME)
	$(Q)mysql --host=$(LOCAL_DB_HOST) --user=$(LOCAL_DB_USER) --password=$(LOCAL_DB_PASS) $(LOCAL_DB_NAME) < db/nikuda.mysqldump

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
	$(Q)mysql $(REMOTE_DB_NAME) --host=$(REMOTE_DB_HOST) --user=$(REMOTE_DB_USER) --password=$(REMOTE_DB_PASS) < db/nikuda.mysqldump
.PHONY: deploy_remote_code
deploy_remote_code:
	$(info doing [$@])
	$(Q)ncftpput -R -u $(REMOTE_FTP_USER) -p $(REMOTE_FTP_PASS) $(REMOTE_FTP_HOST) $(REMOTE_FTP_DIR) css js js_tp images php php/index.php
	$(Q)ncftpput -C -u $(REMOTE_FTP_USER) -p $(REMOTE_FTP_PASS) $(REMOTE_FTP_HOST) gpp_out/config_remote.php $(REMOTE_FTP_DIR)php/config.php
.PHONY: deploy_hack
deploy_hack:
	$(info doing [$@])
	$(Q)ncftpput -R -u $(REMOTE_FTP_USER) -p $(REMOTE_FTP_PASS) $(REMOTE_FTP_HOST) $(REMOTE_FTP_DIR) php/test_02_connect.php
.PHONY: deploy_remote_config
deploy_remote_config:
	$(info doing [$@])
	$(Q)ncftpput -C -u $(REMOTE_FTP_USER) -p $(REMOTE_FTP_PASS) $(REMOTE_FTP_HOST) gpp_out/config_remote.php $(REMOTE_FTP_DIR)php/config.php
.PHONY: deploy_under_construction
deploy_under_construction:
	$(info doing [$@])
	$(Q)ncftpput -R -u $(REMOTE_FTP_USER) -p $(REMOTE_FTP_PASS) $(REMOTE_FTP_HOST) $(REMOTE_FTP_DIR) under_construction/index.php

.PHONY: backup_remote
backup_remote:
	$(info doing [$@])
	$(Q)wget -r ftp://$(REMOTE_FTP_HOST) --ftp-user=$(REMOTE_FTP_USER) --ftp-password=$(REMOTE_FTP_PASS)

.PHONY: clean
clean:
	$(info doing [$@])
	$(Q)git clean -fxd > /dev/null

.PHONY: clean_manual
clean_manual:
	$(info doing [$@])
	$(Q)-rm -f $(CLEAN)

.PHONY: mysql_remote
mysql_remote:
	$(info doing [$@])
	$(Q)mysql --host=$(REMOTE_DB_HOST) --user=$(REMOTE_DB_USER) --password=$(REMOTE_DB_PASS) $(REMOTE_DB_NAME)

.PHONY: ftp_remote
ftp_remote:
	$(info doing [$@])
	$(info put remote user as $(REMOTE_FTP_USER))
	$(info put remote password as $(REMOTE_FTP_PASS))
	$(Q)ftp $(REMOTE_FTP_HOST)

.PHONY: get_error_log
get_error_log:
	$(info doing [$@])
	$(Q)rm -f error_log phperrors.txt
	$(Q)ncftpget -C -u $(REMOTE_FTP_USER) -p $(REMOTE_FTP_PASS) $(REMOTE_FTP_HOST) /php/error_log error_log
	$(Q)ncftpget -C -u $(REMOTE_FTP_USER) -p $(REMOTE_FTP_PASS) $(REMOTE_FTP_HOST) /php/phperrors.txt phperrors.txt

.PHONY: debug
debug:
	$(info ALL is $(ALL))
	$(info CLEAN is $(CLEAN))
	$(info LOCAL_ROOT is $(LOCAL_ROOT))
	$(info REMOTE_FTP_USER is $(REMOTE_FTP_USER))
	$(info REMOTE_FTP_PASS is $(REMOTE_FTP_PASS))
	$(info REMOTE_FTP_HOST is $(REMOTE_FTP_HOST))
	$(info REMOTE_FTP_DIR is $(REMOTE_FTP_DIR))
	$(info REMOTE_DB_HOST is $(REMOTE_DB_HOST))
	$(info REMOTE_DB_USER is $(REMOTE_DB_USER))
	$(info REMOTE_DB_PASS is $(REMOTE_DB_PASS))
	$(info REMOTE_DB_NAME is $(REMOTE_DB_NAME))
	$(info REMOTE_DB_HOST is $(REMOTE_DB_HOST))
	$(info REMOTE_DB_USER is $(REMOTE_DB_USER))
	$(info REMOTE_DB_PASS is $(REMOTE_DB_PASS))
	$(info REMOTE_DB_NAME is $(REMOTE_DB_NAME))
	$(info SOURCES_JS is $(SOURCES_JS))
	$(info SOURCES_HTML is $(SOURCES_HTML))
	$(info SOURCES_CSS is $(SOURCES_CSS))
	$(info LOCAL_DB_HOST is $(LOCAL_DB_HOST))
	$(info LOCAL_DB_NAME is $(LOCAL_DB_NAME))
	$(info LOCAL_DB_USER is $(LOCAL_DB_USER))
	$(info LOCAL_DB_PASS is $(LOCAL_DB_PASS))
	$(info LOCAL_ROOT is $(LOCAL_ROOT))
	$(info GPP_SOURCES is $(GPP_SOURCES))
	$(info GPP_TARGETS is $(GPP_TARGETS))
	$(info GPP_PARAMS is $(GPP_PARAMS))

#########
# rules #
#########

$(GPP_TARGETS): $(GPP_DIR_TARGET)%: $(GPP_DIR_SOURCE)%.gpp $(ALL_DEP)
	$(info doing [$@])
	$(Q)-mkdir $(dir $@) 2> /dev/null || exit 0
	$(Q)gpp $(GPP_PARAMS) $< > $@
