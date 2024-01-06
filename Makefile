# -*- mode: GNUmakefile; tab-width: 4; -*-

###############################################################################

HOSTNAME ?= $(shell hostname)
USER ?= $(shell whoami)
TRACE ?=
PERIOD ?= 30d
DRY ?=

###############################################################################

_NIX := nix --experimental-features 'nix-command flakes repl-flake'
HN := $(_NIX) run home-manager/release-23.11 --

ifneq ($(TRACE),)
	NIX = $(_NIX) --show-trace
else
	NIX = $(_NIX)
endif

ifneq ($(DRY),)
	_DRY := --dry-run
endif

###############################################################################

.PHONY: help
help:
	@echo

###############################################################################

.PHONY: update
update:
	$(NIX) flake update

.PHONY: switch-nixos
switch-nixos:
	nixos-rebuild switch --flake .#$(HOSTNAME)

.PHONY: switch-home
switch-home:
	$(HN) switch --flake .#$(USER)@$(HOSTNAME)

.PHONY: generate-hardware-config
generate-hardware-config: hosts/$(HOSTNAME)/hardware.nix

.PHONY: build-nixos
build-nixos:
	$(NIX) build .#nixosConfigurations.$(HOSTNAME).config.system.build.toplevel

.PHONY: build-home
build-home:
	$(HN) build --flake .#$(USER)@$(HOSTNAME)

.PHONY: build
build: build-nixos build-home

.PHONY: build-vm
build-vm:
	$(NIX) build .#nixosConfigurations.$(HOSTNAME).config.system.build.vm

.PHONY: repl
repl:
	$(NIX) repl .#nixosConfigurations.$(HOSTNAME)

.PHONY: clean
clean:
	nix-collect-garbage --delete-older-than $(PERIOD) $(_DRY)

###############################################################################

hosts/$(HOSTNAME)/hardware.nix: .FORCE
	nixos-generate-config --no-filesystems --show-hardware-config > $@

###############################################################################

.PHONY: .FORCE
.FORCE:

###############################################################################
