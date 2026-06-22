# French localization, applied to every node via hive.nix `defaults`.
# Sets the system locale, all per-category LC_* settings, the timezone and the
# console/X11 keyboard layout to French.
{ ... }:
{
  # Generate and use the French UTF-8 locale as the system default.
  i18n.defaultLocale = "fr_FR.UTF-8";

  # Make sure both the C and French locales are built into the system.
  i18n.supportedLocales = [
    "C.UTF-8/UTF-8"
    "fr_FR.UTF-8/UTF-8"
  ];

  # Localise every LC_* category (numbers, dates, currency, sorting, ...).
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "fr_FR.UTF-8";
    LC_IDENTIFICATION = "fr_FR.UTF-8";
    LC_MEASUREMENT = "fr_FR.UTF-8";
    LC_MONETARY = "fr_FR.UTF-8";
    LC_NAME = "fr_FR.UTF-8";
    LC_NUMERIC = "fr_FR.UTF-8";
    LC_PAPER = "fr_FR.UTF-8";
    LC_TELEPHONE = "fr_FR.UTF-8";
    LC_TIME = "fr_FR.UTF-8";
  };

  # Timezone (Bangkok, Thailand).
  time.timeZone = "Asia/Bangkok";

  # French keyboard for the virtual consoles (TTYs).
  # console.keyMap = "fr";

  # French keyboard for X11 / Wayland sessions (no-op on headless hosts, but
  # ensures any graphical session is localised as well).
  services.xserver.xkb = {
    layout = "fr";
    variant = "";
  };
}
