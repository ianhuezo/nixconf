.PHONY: update
update:
	sudo nixos-rebuild switch
update-flake:
	home-manager switch --flake .#joyboy
clean:
	nix-collect-garbage -d
