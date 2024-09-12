.PHONY: update
update:
	sudo nixos-rebuild switch
update-flake:
	home-manager switch --flake .#ianh
clean:
	nix-collect-garbage -d
