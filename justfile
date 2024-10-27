config_dir := home_directory()+"/.config"
nix_darwin_dir := config_dir+"/nix-darwin" # local nix-darwin config directory
repo := "" # "username/repo" for a nix-darwin config repo on GitHub
tmp_dir := "/tmp/nix-darwin-autoinstall"

nix := "/nix/var/nix/profiles/default/bin/nix"
nix_installer := "/nix/nix-installer"
tmp_nix_installer := "/tmp/nix-installer"

deps_to_check := "gh git"
brewfile_deps := shell("brew bundle list | /usr/bin/grep -E '^(gh|git)$'")

TASK := "\\033[1;95mTASK:\\033[0m"
SUBTASK := "\\033[1;94mSUBTASK:\\033[0m"
INFO := "\\033[1;32mINFO:\\033[0m"
WARNING := "\\033[1;33mWARNING:\\033[0m"
ERROR := "\\033[1;31mERROR:\\033[0m"

_default:
	{{ just_executable() }} --list

# install dependencies: Nix, Homebrew, git, and gh (GitHub CLI)
install: _install _cleanup
	@[ -n '{{ repo }}' ] \
		&& echo "\033[1;32mNix and dependencies installed and {{ repo }} cloned to {{ nix_darwin_dir }}\033[0m" \
		|| echo "\033[1;32mNix and dependencies installed\033[0m"

# uninstall and freshly install dependencies
reinstall: _uninstall _install _cleanup
	@[ -n '{{ repo }}' ] \
		&& echo "\033[1;32mNix and dependencies reinstalled and {{ repo }} cloned to {{ nix_darwin_dir }}\033[0m" \
		|| echo "\033[1;32mNix and dependencies reinstalled\033[0m"

# uninstall Nix
uninstall: _uninstall _cleanup
	@echo "\033[1;32mNix and dependencies uninstalled and {{ nix_darwin_dir }} removed\033[0m"

_cleanup:
	#!/bin/sh
	no_deps_found=true
	mkdir -p '{{ tmp_dir }}'
	brewlist='{{ tmp_dir }}/brewlist.txt'
	brew list > "${brewlist}"
	bundlelist='{{ tmp_dir }}/bundlelist.txt'
	brew bundle list > "${bundlelist}"
	for dep in {{ deps_to_check }}; do
		dep_path=$(which "$dep")
		if [ -z "${dep_path}" ]; then
			continue
		fi
		dep_in_list=$(cat "${brewlist}" | grep -E "^${dep}$")
		dep_in_brewfile=$(cat "${bundlelist}" | grep -E "^${dep}$")
		if [ -n "$dep_path" ] && [ -z "$dep_in_list" ]; then
			no_deps_found=false
			echo "{{ WARNING }} $dep_path is installed, but not by homebrew: you may or may not want to clean up"
		elif [ -n "$dep_in_list" ] && [ -z "$dep_in_brewfile" ]; then
			no_deps_found=false
			echo "{{ WARNING }} $dep_path is installed but not in global Brewfile: you may want to run\n  brew uninstall $dep"
		fi
	done
	if $no_deps_found; then
		echo "{{ INFO }} no dependencies found outside of global Brewfile"
	fi
	rm -rf '{{ tmp_dir }}'

_install:
	@echo '{{ TASK }} install:'
	@echo '  1. install Nix'
	@echo '  2. install dependencies: Homebrew, git, and gh (GitHub CLI) if GITHUB_TOKEN env var is not defined'
	@[ -n '{{ repo }}' ] \
		& echo "  3. clone {{ repo }} to {{ nix_darwin_dir }}"
	@[ ! -f '{{ nix }}' ] \
		&& echo "{{ SUBTASK }} installing Nix" \
		&& curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm \
		|| echo "{{ INFO }} Nix is already installed"
	@[ -z "$(which brew)" ] \
		&& echo "{{ SUBTASK }} installing Homebrew" \
		&& /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
		|| echo "{{ INFO }} Homebrew is already installed"
	@[ -n '{{ repo }}' ] \
		&& ([ -z "$(which git)" ] \
			&& echo "{{ SUBTASK }} installing git" \
			&& brew update && brew install git \
			|| echo "{{ INFO }} git is already installed") \
		|| echo '{{ INFO }} no repo name given, skipping git installation'
	@[ -n '{{ repo }}' ] \
		&& ([ -z "$GITHUB_TOKEN" ] && [ -z $(which gh) ] \
			&& echo "{{ SUBTASK }} installing gh because GITHUB_TOKEN is undefined" \
			&& brew update && brew install gh \
			|| echo "{{ INFO }} GITHUB_TOKEN is defined or gh already installed") \
		|| echo '{{ INFO }} no repo name given, skipping gh installation'
	@[ -n '{{ repo }}' ] && [ ! -d '{{ nix_darwin_dir }}' ] \
		&& (echo "{{ SUBTASK }} cloning {{ repo }} to {{ nix_darwin_dir }}" \
			&& ( \
				([ -n "$GITHUB_TOKEN" ] && git clone https://$GITHUB_TOKEN@github.com/{{ repo }}.git '{{ nix_darwin_dir }}') \
				|| ([ -z "$(gh auth token)" ] && gh auth login && gh repo clone {{ repo }} '{{ nix_darwin_dir }}') \
				|| (gh repo clone {{ repo }} '{{ nix_darwin_dir }}') \
			) \
			|| echo "{{ INFO }} {{ nix_darwin_dir }} already exists") \
		|| echo '{{ INFO }} no repo name given, skipping repo cloning'

_uninstall:
	@echo '{{ TASK }} uninstall:'
	@echo '  1. uninstall Nix'
	@echo '  2. remove ~/.config/nix-darwin'
	@[ -f "{{ nix_installer }}" ] \
		&& echo "{{ SUBTASK }} uninstalling Nix" \
		&& {{ nix_installer }} uninstall --no-confirm \
		|| echo "{{ INFO }} Nix not installed"
	@[ -d '{{ nix_darwin_dir }}' ] \
		&& echo "{{ SUBTASK }} removing {{ nix_darwin_dir }}" \
		&& rm -rf '{{ nix_darwin_dir }}' \
		|| echo "{{ INFO }} {{ nix_darwin_dir }} does not exist"
