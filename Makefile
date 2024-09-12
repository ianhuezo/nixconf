.PHONY: update
update:
	home-manager switch --flake .#ianh
clean:
	nix-collect-garbage -d
