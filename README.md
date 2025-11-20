# 🎮 amp-mint-gaming – Linux Mint Gaming Optimizer

Linux Gaming Optimizer ist ein Bash-Skript, das eine frische Installation von Linux Mint automatisch für maximale Gaming-Performance optimiert. Ziel ist es, die "Out-of-the-Box"-Leistung und Features von Distributionen wie Nobara OS zu erreichen, ohne die Stabilität und den Komfort von Mint aufzugeben.

## 🚀 Features

Das Skript automatisiert folgende Schritte:

System-Update: Bringt das System auf den neuesten Stand.
Kernel-Upgrade: Installiert den XanMod Gaming Kernel (Wahlweise v3 Safe oder v4 Modern) für geringere Latenzen.
GPU-Treiber:
    AMD/Intel: Installiert das Kisak-PPA für die neuesten Mesa-Treiber.
    NVIDIA: Installiert die aktuellsten proprietären Treiber.
Gaming-Tools (Optional wählbar):**
    ProtonUp-Qt (via Flatpak) für Proton-GE (obligatorisch).
    GameMode (Feral Interactive).
    MangoHud (FPS-Overlay).
    Lutris (Launcher für Epic, GOG, etc.).
    Steam.
System-Tweaks:
    * Erhöht `vm.max_map_count` (Wichtig für Hogwarts Legacy, Star Citizen, etc.).
    * Setzt `vm.swappiness` auf 10 (Bevorzugt RAM statt Festplatte).
    * Setzt THP (Transparent Huge Pages) auf `madvise` (Nobara Standard) zur Vermeidung von Rucklern.
    * Setzt den CPU Governor permanent auf `performance`.

------

## ⚠️ WICHTIG: Vor der Nutzung

Dieses Skript greift tief in das System ein (Kernel, Bootloader).
**Erstelle UNBEDINGT ein Backup mit TIMESHIFT (in Mint vorinstalliert), bevor du das Skript startest!**

Nutzung auf eigene Gefahr.

------

## 📥 Installation

Öffne dein Terminal in Linux Mint und führe folgenden Befehl aus (kopieren & einfügen):

```bash
wget -O install.sh [https://raw.githubusercontent.com/amplifie/amp-mint-gaming/main/install.sh](https://raw.githubusercontent.com/amplifie/amp-mint-gaming/main/install.sh) && sudo bash install.sh