# -----------------------

# Installers of build utilities

.PHONY: install-github-cli
.PHONY: install-zip
.PHONY: install-powershell
.PHONY: install-shellcheck

ifdef COMSPEC
include os-windows.mk
else
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
include os-darwin.mk
else
ifeq ($(UNAME_S),Linux)
include os-linux.mk
else
$(error We currently do not support doing contributions on '$(UNAME_S)')
endif
endif
endif

# -----------------------

ifdef DiskuvOCamlHome
CMAKE = '$(DiskuvOCamlHome)'/tools/cmake/bin/cmake.exe
else
CMAKE = cmake
endif

PUBLISHDOCS_WORKDIR  = _build/.publishdocs
ARCHIVE_MEMBERS = LICENSE.txt README.md etc buildtime installtime runtime .dkmlroot .gitattributes .gitignore

.PHONY: clean
clean:
	$(CMAKE) -E remove_directory _build || $(CMAKE) -E rm -rf _build

.PHONY: install-release-script-dependencies
install-release-script-dependencies:
	@PATH="$$PATH:/usr/bin:/bin"; \
	if which pacman >/dev/null 2>&1 && which cygpath >/dev/null 2>&1; then \
		pacman --sync --needed --noconfirm zip; \
	fi

.PHONY: auth-github-cli
auth-github-cli: install-github-cli
	@PATH="/usr/bin:/bin:/mingw64/bin:$$PATH" ; if which gh.exe >/dev/null 2>&1; then GH=gh.exe; else GH=gh; fi; \
	$$GH auth status || $$GH auth login

NEW_CHANGE_HEADER = (@@YYYYMMDD@@)\n\n

.PHONY: release-start-major
release-start-major:
	@PATH="/usr/local/bin:/usr/bin:/bin:/mingw64/bin:$$PATH" ; \
	if which pacman >/dev/null 2>&1 && which cygpath >/dev/null 2>&1; then HOME="$$USERPROFILE"; fi; \
	cd .. && bump2version major --config-file .bumpversion.prerelease.cfg --no-tag --message 'Start v{new_version} release' --verbose && \
	NEW_VERSION=`awk '$$1=="current_version"{print $$NF; exit 0}' .bumpversion.prerelease.cfg` && \
	printf '## %s $(NEW_CHANGE_HEADER)' $$NEW_VERSION > contributors/changes/v$$NEW_VERSION.md

.PHONY: release-start-minor
release-start-minor:
	@PATH="/usr/local/bin:/usr/bin:/bin:/mingw64/bin:$$PATH" ; \
	if which pacman >/dev/null 2>&1 && which cygpath >/dev/null 2>&1; then HOME="$$USERPROFILE"; fi; \
	cd .. && bump2version minor --config-file .bumpversion.prerelease.cfg --no-tag --message 'Start v{new_version} release' --verbose && \
	NEW_VERSION=`awk '$$1=="current_version"{print $$NF; exit 0}' .bumpversion.prerelease.cfg` && \
	printf '## %s $(NEW_CHANGE_HEADER)' $$NEW_VERSION > contributors/changes/v$$NEW_VERSION.md

.PHONY: release-start-patch
release-start-patch:
	@PATH="/usr/local/bin:/usr/bin:/bin:/mingw64/bin:$$PATH" ; \
	if which pacman >/dev/null 2>&1 && which cygpath >/dev/null 2>&1; then HOME="$$USERPROFILE"; fi; \
	cd .. && bump2version patch --config-file .bumpversion.prerelease.cfg --no-tag --message 'Start v{new_version} release' --verbose && \
	NEW_VERSION=`awk '$$1=="current_version"{print $$NF; exit 0}' .bumpversion.prerelease.cfg` && \
	printf '## %s $(NEW_CHANGE_HEADER)' $$NEW_VERSION > contributors/changes/v$$NEW_VERSION.md

.PHONY: release-prerelease
release-prerelease: auth-github-cli install-release-script-dependencies
	@export PATH="/usr/local/bin:/usr/bin:/bin:/mingw64/bin:$$PATH"; \
	BVDIR=`which bump2version` && BVDIR=`dirname "$$BVDIR"` && export PATH="$$BVDIR:$$PATH" && bash -x release.sh -p

.PHONY: release-complete
release-complete: auth-github-cli install-release-script-dependencies
	@export PATH="/usr/local/bin:/usr/bin:/bin:/mingw64/bin:$$PATH"; \
	BVDIR=`which bump2version` && BVDIR=`dirname "$$BVDIR"` && export PATH="$$BVDIR:$$PATH" && bash -x release.sh

# ----------------------------------------------------------
# BEGIN Documentation

# You can set these variables from the command line, and also
# from the environment for the first two.
SPHINXOPTS    ?=
SPHINXBUILD   ?= sphinx-build
SOURCEDIR     = .
BUILDDIR      = _build

sphinx-help:
	@$(SPHINXBUILD) -M help "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

.PHONY: sphinx-help Makefile html

# $(O) is meant as a shortcut for $(SPHINXOPTS).
html: Makefile
	@$(SPHINXBUILD) -M $@ "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

.PHONY: publish-prepare-docs
publish-prepare-docs:
	@if test -n "$$(git status --porcelain)"; then echo "FATAL: The working directory must be clean! All changes have to be committed to git or removed."; exit 1; fi
	@$(MAKE) clean

	@$(CMAKE) -E echo Building Sphinx html twice so that Sphinx cross-references work ...
	@$(MAKE) html
	@$(MAKE) html O="-W"

.PHONY: view-docs
view-docs: publish-prepare-docs
	@$(CMAKE) -E echo Trying to open a web browser so you can review the final result ...
	@$(CMAKE) -E echo "Once you are finished the review, commit in the main branch to publish the changes"
	@wslview _build/html/index.html || open _build/html/index.html || explorer '_build\html\index.html' || \
		$(CMAKE) -E echo "Cannot find a browser. Please review the web site at _build/html/index.html"

# END Documentation
# ----------------------------------------------------------
