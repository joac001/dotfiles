# dotfiles

Personal config for a CachyOS + Hyprland (caelestia rice) setup: shell (fish/bash/zsh),
Hyprland, the caelestia shell, terminal, prompt, and a handful of CLI tools.

Not included on purpose: app clients with heavy cache/session data (Discord and its
mods, Slack, Firefox/Mozilla profile, Spotify, Code - OSS state) and anything that's
auto-generated (`fish_variables`, logs, `~/.config/monitors.xml`).

## First time on a new machine

1. Install a CachyOS Hyprland setup (base Hyprland packages, fish, starship, foot,
   btop, cava, fuzzel, fastfetch, micro, nvtop, htop, uwsm) and the AUR packages this
   rice depends on:

   ```sh
   yay -S --needed - < packages/aur.txt
   ```

   (`slack-desktop`, `spotify`, `equibop-bin`, `spicetify-cli`, `spicetify-marketplace-bin`
   in that list are just apps I use, not required for the rice itself — skip them if
   you don't want them.)

2. Clone this repo and run the installer:

   ```sh
   git clone git@github.com:joac001/dotfiles.git ~/dotfiles
   cd ~/dotfiles
   ./install.sh
   ```

   `install.sh` symlinks every file under `home/` into the real `$HOME` at the same
   relative path (e.g. `home/.config/fish/config.fish` -> `~/.config/fish/config.fish`).
   Anything already there gets backed up to `~/.dotfiles-backup/<timestamp>/` first,
   it's never overwritten silently.

3. Log into Hyprland (`uwsm start hyprland-uwsm.desktop` or your login manager entry).

One thing that's machine-specific: `~/.config/caelestia/monitors/` has a per-output
config named after this machine's actual monitor ports (`DP-6`, `HDMI-A-2`, `DP-7`).
On another machine with different outputs, caelestia will just fall back to defaults
for unrecognized monitors — adjust/add entries there as needed.

## Making a change

Since everything is symlinked, editing a config normally (e.g. `micro ~/.config/hypr/variables.lua`)
edits the file inside this repo directly. To publish the change:

```sh
cd ~/dotfiles
git add -A
git commit -m "describe the change"
git push
```

## Pulling updates on another machine

```sh
cd ~/dotfiles
git pull
```

That's enough if you only edited files that already existed. If you added a **new**
file (a new app's config), also re-run `./install.sh` so it gets symlinked in.

## Layout

```
dotfiles/
  install.sh          # symlinks home/ into $HOME
  packages/aur.txt     # AUR packages this rice depends on (pacman -Qqm)
  home/                # mirrors $HOME; everything here is what gets symlinked
    .bashrc .bash_profile .zshrc
    .config/
      fish/ hypr/ caelestia/ foot/ starship.toml
      btop/ cava/ fuzzel/ fastfetch/ micro/ nvtop/ htop/ uwsm/ qtengine/
      mimeapps.list code-flags.conf cachyos-hello.json
```
