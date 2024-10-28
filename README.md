# nix-darwin-autoinstall

Setup script for automatically installing nix-darwin and dependencies.

- [nix-darwin-autoinstall](#nix-darwin-autoinstall)
  - [Install](#install)
  - [Install with user's nix-darwin config repo (on GitHub)](#install-with-users-nix-darwin-config-repo-on-github)
  - [Uninstall Nix](#uninstall-nix)
  - [Reinstall (uninstall Nix and then install)](#reinstall-uninstall-nix-and-then-install)

## Install

```shell
curl --proto '=https' --tlsv1.2 \
  --silent --show-error --fail \
  --location \
  https://raw.githubusercontent.com/ajlive/nix-darwin-autoinstall/refs/heads/main/install \
  | sh -s
```

## Install with user's nix-darwin config repo (on GitHub)

```shell
curl --proto '=https' --tlsv1.2 \
  --silent --show-error --fail \
  --location \
  https://raw.githubusercontent.com/ajlive/nix-darwin-autoinstall/refs/heads/main/install \
  | sh -s -- -r mygithubuser/mynixdarwinconfigrepo
```

## Uninstall Nix

```shell
curl --proto '=https' --tlsv1.2 \
  --silent --show-error --fail \
  --location \
  https://raw.githubusercontent.com/ajlive/nix-darwin-autoinstall/refs/heads/main/install \
  | sh -s -- -t uninstall
```

## Reinstall (uninstall Nix and then install)

```shell
curl --proto '=https' --tlsv1.2 \
  --silent --show-error --fail \
  --location \
  https://raw.githubusercontent.com/ajlive/nix-darwin-autoinstall/refs/heads/main/install \
  | sh -s -- -t reinstall
```
