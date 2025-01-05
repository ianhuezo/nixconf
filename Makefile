PW?=PW
CONN?=Huezonet-Google
PROV?=PROV

.PHONY: update
update:
	sudo nixos-rebuild switch
update-flake:
	sudo nixos-rebuild switch --flake .#joyboy
clean:
	nix-collect-garbage -d
wifi:
	nmcli d wifi connect $(CONN) password '$(PW)' ifname $(PROV)
ssh:
	ssh-keygen -t ed25519 -C "ianhuezo@gmail.com"
