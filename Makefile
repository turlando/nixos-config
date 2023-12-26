# -*- mode: GNUmakefile; tab-width: 4; -*-

###############################################################################

HOSTNAME ?= $(shell hostname)

###############################################################################

.PHONY: help
help:
	@echo

###############################################################################

.PHONY: generate-hardware-config
generate-hardware-config: hosts/$(HOSTNAME)/hardware.nix

.PHONY: build-vm
build-vm:
	nix \
		--experimental-features 'nix-command flakes' \
		build .#nixosConfigurations.$(HOSTNAME).config.system.build.vm

###############################################################################

hosts/$(HOSTNAME)/hardware.nix: .FORCE
	nixos-generate-config --no-filesystems --show-hardware-config > $@

###############################################################################

.PHONY: .FORCE
.FORCE:

###############################################################################
