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
#honestly, don't remember the steps to install nixos
setup:
	#if using a different comptuer need to follow these steps from rclone
	#https://rclone.org/drive/#making-your-own-client-id
	rclone config #to mount network drives
