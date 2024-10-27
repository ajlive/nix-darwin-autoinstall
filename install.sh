#!/usr/bin/env bash
set -euo pipefail

usage() {
	cat <<EOF
Usage: $0 [--help] [--repo <repo>] <task>
EOF
}

TASK_INSTALL="install"
TASK_REINSTALL="reinstall"
TASK_UNINSTALL="uninstall"

help() {
	cat <<EOF
$(usage)

Install nix-darwin with a single command.

Args:
  <task>  The task to run: ${TASK_INSTALL}, ${TASK_REINSTALL}, or ${TASK_UNINSTALL}. (default: ${TASK_INSTALL})

Flags:
  --help         Show this help message.
  --repo <repo>  Your nix-darwin config repo on GitHub, ie, "username/reponame" (required for install/reinstall).
EOF
}

error() {
	message="$1"
	printf '\033[1;31m%s\033[0m\n' "${message}"
}

run() {
	cmd="$1"
	printf '\033[1m%s\033[0m\n' "${cmd}" >&2
	eval "${cmd}"
}

task="${1:-${TASK_INSTALL}}"
repo="${2:-}"

args=$(getopt --long help,repo: -n "$0" -- "$@")
eval set -- "$args"
while :; do
	case "${1}" in
	--help) help; exit 0 ;;
	--repo) repo="${2}"; shift 2 ;;
	--) shift; break ;;
	*) error "error parsing arguments"; exit 1 ;;
	esac
done

if ([ "${task}" != "${TASK_INSTALL}" ] \
	&& [ "${task}" != "${TASK_REINSTALL}" ] \
	&& [ "${task}" != "${TASK_UNINSTALL}" ]); then \
	error "invalid task: ${task}"
	help
	exit 1
fi

tmp_dir='/tmp/nix-darwin-autoinstall'
[ -d "${tmp_dir}" ] || run "mkdir -p '${tmp_dir}'"

just="$(which just || echo -n -s '')"
just_tmp="${tmp_dir}/just"
if [ -f "$just" ]; then
	echo "using just from ${just}"
else
	echo "temporarily installing just to ${just_tmp}: just will be installed from Homebrew later by installer"
	[ -f "${just_tmp}" ] && run "rm '${just_tmp}'"
	run "curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to $'{just_tmp}'"
	just="${just_tmp}"
fi

justfile_tmp="${tmp_dir}/justfile"
[ -f "${justfile_tmp}" ] && run "rm '${justfile_tmp}'"
run "curl --proto '=https' --tlsv1.2 -sSf -L https://raw.githubusercontent.com/ajlive/nix-darwin-autoinstall/main/justfile > '${justfile_tmp}'"

if [ -n "${repo}" ]; then
	run "${just} --justfile '${justfile_tmp}' repo='${repo}' ${task}"
else
	run "${just} --justfile '${justfile_tmp}' ${task}"
fi
[ -d "${tmp_dir}" ] && rm -rf "${tmp_dir}"
