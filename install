#!/usr/bin/env sh
set -eu

XDG_DIR="${XDG_CONFIG_HOME:-}"
if [ -z "${XDG_DIR}" ]; then XDG_DIR="${HOME}/.config"; fi
NIX_DARWIN_DIR="${NIX_DARWIN_CONFIG_DIR:-}"
if [ -z "${NIX_DARWIN_DIR}" ]; then NIX_DARWIN_DIR="${XDG_DIR}/nix-darwin"; fi
TMP_DIR="/tmp/nix-darwin-autoinstall"
NIX="/nix/var/nix/profiles/default/bin/nix"
NIX_INSTALLER="/nix/nix-installer"

TASK_INSTALL="install"
TASK_REINSTALL="reinstall"
TASK_UNINSTALL="uninstall"
TASK_DEFAULT="${TASK_INSTALL}"

usage() {
	cat <<EOF
Usage: $0 [-hv] [-t <task>] [-r <repo>]
EOF
}

help() {
	cat <<EOF
$(usage)

Install nix-darwin with a single command.

Args:

Flags:
  -r <repo>  Your nix-darwin config repo on GitHub, ie, "username/reponame".
  -t <task>  The task to run: ${TASK_INSTALL}, ${TASK_REINSTALL}, or ${TASK_UNINSTALL}. (default: ${TASK_DEFAULT})
  -h         Show this help message.
  -v         Enable verbose output.
EOF
}

info() {
	printf '\033[1;32mINFO:\033[0m %s\n' "${1}"
}

warning() {
	printf '\033[1;33mWARNING:\033[0m %s\n' "${1}"
}

error() {
	printf '\033[1;31mERROR:\033[0m %s\n' "${1}"
}

task() {
	printf '\033[1;95mTASK:\033[0m %s\n' "${1}"
}

subtask() {
	printf '\033[1;94mSUBTASK:\033[0m %s\n' "${1}"
}

success() {
	printf '\033[1;32m%s\033[0m\n' "${1}"
}

task="${TASK_DEFAULT}"
repo=""
verbose=false
while getopts "hr:t:v" opt; do
	case "${opt}" in
	r) repo="${OPTARG}";;
	t) task="${OPTARG}";;
	v) verbose=true;;
	h) help; exit 0;;
	?) usage; exit 1;;
	esac
done

info "settings: task=${task}, repo=${repo}, verbose=${verbose}"

if ([ "${task}" != "${TASK_INSTALL}" ] \
	&& [ "${task}" != "${TASK_REINSTALL}" ] \
	&& [ "${task}" != "${TASK_UNINSTALL}" ]); then \
	error "invalid task: ${task}"
	help
	exit 1
fi

quote_spaced() {
	cmd=""
	for arg in $@; do
		chars=$(echo "${arg}" | sed -e 's/\(.\)/\1\n/g')
		has_space=false
		for c in $chars; do
			if [ "${c}" = " " ]; then
				has_space=true
				break
			fi
		done
		if $has_space; then
			cmd="${cmd} \"${arg}\""
		else
			cmd="${cmd} ${arg}"
		fi
	done
	echo "${cmd}"
}

run() {
	cmd="$(quote_spaced $@)"
	printf '\033[1m%s\033[0m\n' "${cmd}" >&2
	eval "${cmd}"
}

runcompl() {
	cmd="$(quote_spaced $1)"
	printf '\033[1m%s\033[0m\n' "${cmd}" >&2
	eval "${cmd}"
}

runv() {
	cmd="$(quote_spaced $@)"
	$verbose && printf '\033[1m%s\033[0m\n' "${cmd}" >&2
	eval "${cmd}"
}

runvcompl() {
	cmd="$(quote_spaced $1)"
	$verbose && printf '\033[1m%s\033[0m\n' "${cmd}" >&2
	eval "${cmd}"
}

subtask_cleanup() {
	no_deps_found=true
	brewlist="${TMP_DIR}/brewlist.txt"
	runvcompl "brew list > ${brewlist}"
	bundlelist="${TMP_DIR}/bundlelist.txt"
	runvcompl "brew bundle list > ${bundlelist}"
	deps="gh git"
	for dep in $deps; do
		dep_path=$(which "$dep")
		if [ -z "${dep_path}" ]; then
			continue
		fi
		dep_in_list=$(cat "${brewlist}" | grep -E "^${dep}$")
		dep_in_brewfile=$(cat "${bundlelist}" | grep -E "^${dep}$")
		if [ -n "${dep_path}" ] && [ -z "${dep_in_list}" ]; then
			no_deps_found=false
			warning "${dep_path} is installed, but not by homebrew: you may or may not want to clean it up"
		elif [ -n "${dep_in_list}" ] && [ -z "${dep_in_brewfile}" ]; then
			no_deps_found=false
			warning "${dep_path} is installed but not in global Brewfile: you may want to run\n  brew uninstall ${dep}"
		fi
	done
	if $no_deps_found; then
		info "no dependencies found outside of global Brewfile"
	fi
}

subtask_install() {
	[ ! -f "${NIX}" ] \
		&& subtask "installing Nix" \
		&& runcompl "curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm" \
		|| info "Nix is already installed"
	[ -z "$(which brew)" ] \
		&& subtask "installing Homebrew" \
		&& run /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
		|| info "Homebrew is already installed"
	[ -n "${repo}" ] \
		&& ([ -z "$(which git)" ] \
			&& subtask "installing git" \
			&& run brew update && run brew install git \
			|| info "git is already installed") \
		|| info "no repo name given, skipping git installation"
	[ -n "${repo}" ] \
		&& ([ -z "${GITHUB_TOKEN}" ] && [ -z $(which gh) ] \
			&& subtask "installing gh because GITHUB_TOKEN is undefined" \
			&& run brew update && run brew install gh \
			|| info "GITHUB_TOKEN is defined or gh already installed") \
		|| info "no repo name given, skipping gh installation"
	[ -n "${repo}" ] \
		&& ([ ! -d "${NIX_DARWIN_DIR}" ] \
			&& subtask "cloning ${repo} to ${NIX_DARWIN_DIR}" \
			&& ( \
				([ -n "${GITHUB_TOKEN}" ] && run git clone "https://${GITHUB_TOKEN}@github.com/${repo}.git" "${NIX_DARWIN_DIR}") \
				|| ([ -z "$(gh auth token)" ] && run gh auth login && run gh repo clone "${repo}" "${NIX_DARWIN_DIR}") \
				|| (gh repo clone "${repo}" "${NIX_DARWIN_DIR}") \
			) \
			|| info "${NIX_DARWIN_DIR} already exists") \
		|| info "no repo name given, skipping repo cloning"
}

subtask_uninstall() {
	[ -f "${NIX_INSTALLER}" ] \
		&& subtask "uninstalling Nix" \
		&& run "${NIX_INSTALLER}" uninstall --no-confirm \
		|| info "Nix not installed"
	[ -d "${NIX_DARWIN_DIR}" ] \
		&& subtask "removing ${NIX_DARWIN_DIR}" \
		&& run rm -rf "${NIX_DARWIN_DIR}" \
		|| info "${NIX_DARWIN_DIR} does not exist"

}

install() {
	task "install:"
	echo "  1. install Nix"
	echo "  2. install dependencies: Homebrew, git, and gh (GitHub CLI) if GITHUB_TOKEN env var is not defined"
	[ -n "${repo}" ] \
		&& echo "  3. clone ${repo} to ${NIX_DARWIN_DIR}"
	subtask_install
	subtask_cleanup
	[ -d "${NIX_DARWIN_DIR}" ] \
		&& success "Nix and dependencies installed and ${NIX_DARWIN_DIR} exists" \
		|| success "Nix and dependencies installed"
}

reinstall() {
	task "reinstall:"
	echo "  1. uninstall Nix"
	echo "  2. remove ${NIX_DARWIN_DIR}"
	echo "  2. reinstall dependencies: Homebrew, git, and gh (GitHub CLI) if GITHUB_TOKEN env var is not defined"
	[ -n "${repo}" ] \
		&& echo "  3. clone ${repo} to ${NIX_DARWIN_DIR}"
	subtask_uninstall
	subtask_install
	subtask_cleanup
	[ -d "${NIX_DARWIN_DIR}" ] && [ -n "${repo}" ] \
		&& success "Nix and dependencies reinstalled and ${repo} cloned to ${NIX_DARWIN_DIR}" \
		|| success "Nix and dependencies reinstalled"
}

uninstall() {
	task "uninstall:"
	echo "  1. uninstall Nix"
	echo "  2. remove ~/.config/nix-darwin"
	subtask_uninstall
	subtask_cleanup
	success "Nix and dependencies uninstalled and ${NIX_DARWIN_DIR} removed"
}

[ -d "${TMP_DIR}" ] && runv rm -rf "${TMP_DIR}"
runv mkdir -p "${TMP_DIR}"

case "${task}" in
"${TASK_INSTALL}")   install;;
"${TASK_REINSTALL}") reinstall;;
"${TASK_UNINSTALL}") uninstall;;
*)                   error "invalid task: ${task}"; exit 1;;
esac

[ -d "${TMP_DIR}" ] && runv rm -rf "${TMP_DIR}"
