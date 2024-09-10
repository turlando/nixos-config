# -*- mode: GNUmakefile; tab-width: 4; -*-

###############################################################################

HOSTNAME ?= $(shell hostname)
USER ?= $(shell whoami)
PERIOD ?= 30d

###############################################################################

NIX := nix
HM  := home-manager

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
	$(HM) switch --flake .#$(USER)@$(HOSTNAME)

.PHONY: generate-hardware-config
generate-hardware-config: hosts/$(HOSTNAME)/hardware.nix

.PHONY: build-nixos
build-nixos:
	$(NIX) build .#nixosConfigurations.$(HOSTNAME).config.system.build.toplevel

.PHONY: build-home
build-home:
	$(HM) build --flake .#$(USER)@$(HOSTNAME)

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
	nix-collect-garbage --delete-older-than $(PERIOD)

.PHONY: clean-all
clean-all:
	nix-collect-garbage --delete-old

###############################################################################

hosts/$(HOSTNAME)/hardware.nix: .FORCE
	nixos-generate-config --no-filesystems --show-hardware-config > $@

###############################################################################

.PHONY: .FORCE
.FORCE:

###############################################################################
