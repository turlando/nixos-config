# -*- mode: GNUmakefile; tab-width: 4; -*-

###############################################################################

HOSTNAME ?= $(shell hostname)
TRACE ?=

###############################################################################

_NIX := nix --experimental-features 'nix-command flakes'

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

.PHONY: generate-hardware-config
generate-hardware-config: hosts/$(HOSTNAME)/hardware.nix

.PHONY: build
build:
	$(NIX) build .#nixosConfigurations.$(HOSTNAME).config.system.build.toplevel

.PHONY: build-vm
build-vm:
	$(NIX) build .#nixosConfigurations.$(HOSTNAME).config.system.build.vm

###############################################################################

hosts/$(HOSTNAME)/hardware.nix: .FORCE
	nixos-generate-config --no-filesystems --show-hardware-config > $@

###############################################################################

.PHONY: .FORCE
.FORCE:

###############################################################################
