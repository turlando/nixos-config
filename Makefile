# -*- mode: GNUmakefile; tab-width: 4; -*-

###############################################################################

HOSTNAME ?= $(shell hostname)
TRACE ?=

###############################################################################

_NIX := nix --experimental-features 'nix-command flakes repl-flake'

###############################################################################

ifneq ($(TRACE),)
	NIX = $(_NIX) --show-trace
else
	NIX = $(_NIX)
endif

###############################################################################

.PHONY: help
help:
	@echo

###############################################################################

.PHONY: update
update:
	$(NIX) flake update

.PHONY: switch
switch:
	nixos-rebuild switch --flake .#$(HOSTNAME)

.PHONY: upgrade
upgrade: update switch

.PHONY: generate-hardware-config
generate-hardware-config: hosts/$(HOSTNAME)/hardware.nix

.PHONY: build
build:
	$(NIX) build .#nixosConfigurations.$(HOSTNAME).config.system.build.toplevel

.PHONY: build-vm
build-vm:
	$(NIX) build .#nixosConfigurations.$(HOSTNAME).config.system.build.vm

.PHONY: repl
repl:
	$(NIX) repl .#nixosConfigurations.$(HOSTNAME)

###############################################################################

hosts/$(HOSTNAME)/hardware.nix: .FORCE
	nixos-generate-config --no-filesystems --show-hardware-config > $@

###############################################################################

.PHONY: .FORCE
.FORCE:

###############################################################################
