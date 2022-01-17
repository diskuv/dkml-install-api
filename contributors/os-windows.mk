install-github-cli:
	@PATH="$$PATH:/usr/bin:/bin"; \
	if which pacman >/dev/null 2>&1 && which cygpath >/dev/null 2>&1; then \
		pacman --sync --needed --noconfirm mingw64/mingw-w64-x86_64-github-cli; \
	fi
	@PATH="/usr/bin:/bin:/mingw64/bin:$$PATH"; if ! which gh >/dev/null 2>&1; then \
		echo "FATAL: GitHub CLI was not installed, and the Makefile does not know how to install it." >&2; exit 1; \
	fi

install-zip:
	@PATH="$$PATH:/usr/bin:/bin"; \
	if which pacman >/dev/null 2>&1 && which cygpath >/dev/null 2>&1; then \
		pacman --sync --needed --noconfirm zip; \
	fi
	@PATH="/usr/bin:/bin:/mingw64/bin:$$PATH"; if ! which zip >/dev/null 2>&1; then \
		echo "FATAL: 'zip' was not installed, and the Makefile does not know how to install it." >&2; exit 1; \
	fi

install-powershell:

/usr/local/bin/shellcheck.exe:
	@PATH="/usr/local/bin:/usr/bin:/bin:/mingw64/bin:$$PATH"; \
	if ! which shellcheck >/dev/null 2>&1; then \
		curl -L https://github.com/koalaman/shellcheck/releases/download/stable/shellcheck-stable.zip -o /tmp/shellcheck-stable.zip; \
		rm -rf /tmp/shellcheck && \
		unzip -d /tmp/shellcheck /tmp/shellcheck-stable.zip && install -d /usr/local/bin && install /tmp/shellcheck/shellcheck.exe /usr/local/bin; \
	fi

install-shellcheck: /usr/local/bin/shellcheck.exe
