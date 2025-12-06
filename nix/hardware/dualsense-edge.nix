{ config, lib, pkgs, ... }:

{
  # PS5 DualSense Edge Controller Support
  # Fixes button and axis mapping issues on Linux
  # The Edge controller has swapped axes: triggers report as right stick and vice versa

  services.udev.packages = [
    (pkgs.writeTextFile {
      name = "dualsense-edge-udev-rules";
      destination = "/etc/udev/rules.d/70-dualsense-edge.rules";
      text = ''
        # Sony DualSense Edge Wireless Controller
        # USB connection (054c:0df2)
        KERNEL=="hidraw*", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="0df2", MODE="0660", TAG+="uaccess"
        KERNEL=="event*", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="0df2", ENV{ID_INPUT_JOYSTICK}="1"

        # Bluetooth connection
        KERNEL=="hidraw*", KERNELS=="*054C:0DF2*", MODE="0660", TAG+="uaccess"
        KERNEL=="event*", KERNELS=="*054C:0DF2*", ENV{ID_INPUT_JOYSTICK}="1"

        # Disable touchpad on DualSense Edge
        ACTION=="add|change", ATTRS{name}=="DualSense Edge Wireless Controller Touchpad", ENV{LIBINPUT_IGNORE_DEVICE}="1"
      '';
    })
  ];

  # SDL2 gamepad mapping for DualSense Edge (swaps axes correctly)
  environment.sessionVariables = {
    SDL_GAMECONTROLLERCONFIG = "054c0df2,Sony DualSense Edge,platform:Linux,a:b0,b:b1,x:b3,y:b2,back:b8,guide:b10,start:b9,leftstick:b11,rightstick:b12,leftshoulder:b4,rightshoulder:b5,dpup:h0.1,dpdown:h0.4,dpleft:h0.8,dpright:h0.2,leftx:a0,lefty:a1,rightx:a2,righty:a5,lefttrigger:a3,righttrigger:a4,";
  };
}
