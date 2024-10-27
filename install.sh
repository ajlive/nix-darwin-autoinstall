#!/usr/bin/env bash
set -euo pipefail

usage() {
	cat <<EOF
Usage: $0 [--help] [--task <task>] [--repo <repo>] [--justfile <file>]
EOF
}

TASK_INSTALL="install"
TASK_REINSTALL="reinstall"
TASK_UNINSTALL="uninstall"

TASK_DEFAULT="${TASK_INSTALL}"
REPO_DEFAULT=''
JUSTFILE_DEFAULT='https://raw.githubusercontent.com/ajlive/nix-darwin-autoinstall/main/justfile'

help() {
	cat <<EOF
$(usage)

Install nix-darwin with a single command.

Args:

Flags:
  --task             The task to run: ${TASK_INSTALL}, ${TASK_REINSTALL}, or ${TASK_UNINSTALL}. (default: ${TASK_DEFAULT})
  --repo <repo>      Your nix-darwin config repo on GitHub, ie, "username/reponame".
  --justfile <file>  The justfile to use for installation. (default: ${JUSTFILE_DEFAULT})
  --help             Show this help message.
EOF
}

info() {
	printf '\033[1;32mINFO:\033[0m %s\n' "${1}"
}

error() {
	printf '\033[1;31mERROR:\033[0m %s\n' "${1}"
}

run() {
	cmd="$1"
	printf '\033[1m%s\033[0m\n' "${cmd}" >&2
	eval "${cmd}"
}

task="${TASK_DEFAULT}"
repo="${REPO_DEFAULT}"
justfile="${JUSTFILE_DEFAULT}"
set -- "$@"
while :; do
	opt="${1:---}"
	arg="${2:-}"
	case "${opt}" in
	--task)      task="${arg}";                      shift 2 ;;
	--repo)      repo="${arg}";                      shift 2 ;;
	--justfile)  justfile="${arg}";                  shift 2 ;;
	--help)      help;                               exit 0 ;;
	--)                	                         break ;;
	*)           error "unsupported option ${arg}";  exit 1 ;;
	esac
done

info "settings: task=${task}, repo=${repo}, justfile=${justfile}"

if ([ "${task}" != "${TASK_INSTALL}" ] \
	&& [ "${task}" != "${TASK_REINSTALL}" ] \
	&& [ "${task}" != "${TASK_UNINSTALL}" ]); then \
	error "invalid task: ${task}"
	help
	exit 1
fi

tmp_dir='/tmp/nix-darwin-autoinstall'
[ -d "${tmp_dir}" ] && rm -rf "${tmp_dir}"
mkdir -p "${tmp_dir}"

just="$(which just || echo -n -s '')"
just_tmp="${tmp_dir}/just"
if [ -f "$just" ]; then
	info "using just from ${just}"
else
	info "temporarily installing just to ${just_tmp}: just will be installed from Homebrew later by installer"
	run "curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to $'{just_tmp}'"
	just="${just_tmp}"
fi

if [ "${justfile}" == "${JUSTFILE_DEFAULT}" ]; then
	justfile_tmp="${tmp_dir}/justfile"
	run "curl --proto '=https' --tlsv1.2 -sSf -L https://raw.githubusercontent.com/ajlive/nix-darwin-autoinstall/main/justfile > '${justfile_tmp}'"
	justfile="${justfile_tmp}"
fi

if [ -n "${repo}" ]; then
	run "${just} --justfile '${justfile}' repo='${repo}' ${task}"
else
	run "${just} --justfile '${justfile}' ${task}"
fi
[ -d "${tmp_dir}" ] && rm -rf "${tmp_dir}"
