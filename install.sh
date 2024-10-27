#!/usr/bin/env bash
set -euo pipefail

usage() {
	cat <<EOF
Usage: $0 [-h] <task> <repo>
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
  <repo>  Your nix-darwin configuration repository on GitHub, ie, username/reponame (required for install/reinstall).

Flags:
  -h         Show this help message.
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

task="${1:-}"
repo="${2:-}"

while getopts 'h' opt; do
	case $opt in
	h)
		help
		exit 0
		;;
	\?)
		error "Invalid option: -$OPTARG"
		usage
		exit 1
		;;
	esac
done

if [ -z "${task}" ] \
	|| ([ "${task}" != "${TASK_INSTALL}" ] && [ "${task}" != "${TASK_REINSTALL}" ] && [ "${task}" != "${TASK_UNINSTALL}" ]) \
	|| ([ "${task}" != "${TASK_UNINSTALL}" ] && [ -z "${repo}" ]); then
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

run "${just} --justfile '${justfile_tmp}' ${task} repo=${repo}"
[ -d "${tmp_dir}" ] && rm -rf "${tmp_dir}"
