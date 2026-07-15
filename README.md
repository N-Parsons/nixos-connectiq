# ConnectIQ SDK and Development on NixOS

This repo provides a package and shells for using the ConnectIQ SDK Manager and SDKs on NixOS.

**Note:** Both the SDK Manager and SDKs depend on outdated packages, including two that are marked as insecure (`webkitgtk_4_0` and `libsoup` 2.4) which are automatically configured to be permitted in this context. This repo automatically uses `nixos-24.11` to provide these old packages.


## SDK Manager

You need to accept the terms and download the SDK Manager yourself: https://developer.garmin.com/connect-iq/sdk/

### Installing the SDK Manager

You can install the SDK Manager in your system (including a .desktop file).

- Copy the `connectiq-sdkmanager` folder to your NixOS configuration folder (e.g. `/etc/nixos/pkgs/connectiq-sdkmanager`).
- Copy your downloaded zip file into that folder.
- Add it as a system package (and rebuild):

```
  environment.systemPackages = with pkgs; [
    (callPackage /etc/nixos/pkgs/connectiq-sdkmanager {})
  ];
```

You can then launch `Garmin ConnectIQ SDK Manager` or run `sdkmanager` from the terminal.

### Running in a shell

Alternatively, you can run the SDK Manager from a temporary shell without installing it - you only need the SDK Manager for downloading/updating SDKs and devices, so this is still a reasonable approach.

- Copy `connectiq-sdkmanager/shell.nix` to your preferred location (or leave it where it is).
- Unpack the zip file in the same location.
- Start the shell: `nix-shell`
- Run the SDK Manager: `bin/sdkmanager`

The shell is also an excellent method for troubleshooting bugs that can occur when using old/mismatched packages (e.g. EGL_BAD_PARAMETER errors), since it saves rebuilding your system repeatedly.


## Using the SDK

A development shell is provided in `connectiq-development/shell.nix`.

The shell automatically checks which SDK is selected and configures the `PATH` to use the appropriate SDK so that you can run commands (e.g. `monkeyc`, `monkeydo`, `connectiq`).

Codium is installed within the environment, and you will almost certainly want to install the [Garmin Monkey C](https://marketplace.visualstudio.com/items?itemName=garmin.monkey-c) extension and may want [Prettier Monkey C](https://marketplace.visualstudio.com/items?itemName=markw65.prettier-extension-monkeyc).

Most SDK commands/actions are available in Codium via the extension (`Ctrl+Shift+P`, commands prefixed with `Monkey C:`), except for the simulator, which needs to be run from the terminal.

### Basic usage

- Start the simulator: `connectiq`.
- Build your package: `monkeyc -d <device> -f monkey.jungle -o <package> -y <developer_key>`.
- Load the package into the simulator: `monkeydo <package> <device>`.
- Build a release version: `monkeyc -d <device> -f monkey.jungle -o <package> -y <developer_key> --release -O 3z`.

**Example arguments:**

- `<device>`: `fenix7s`
- `<package>`: `bin/test.prg`
- `<developer_key>`: `~/.Garmin/developer_key`

### A note on compatibility

The shell has been tested with SDK versions 8.1.0 to 9.2.0 on NixOS 26.05. Older SDK versions and later NixOS releases may require using a specific `nixpkgs` version.

A utility script is provided in `bin/check_sdk_deps` that will scan all installed SDKs identify missing dependencies. By default it scans `~/.Garmin/ConnectIQ/Sdks` but an alternative path can be provided as an argument.
