#!/bin/bash

# Farben für die Ausgabe
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Überprüfen, ob das Skript als Root ausgeführt wird
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Bitte führen Sie dieses Skript als Root aus (sudo).${NC}"
  exit
fi

clear
echo -e "${GREEN}====================================================${NC}"
echo -e "${GREEN}   LINUX MINT GAMING OPTIMIZER   ${NC}"
echo -e "${GREEN}====================================================${NC}"
echo -e "${RED}UNBEDINGT EMPFOHLEN: Nutzen Sie Timeshift (in Mint enthalten), um ein Backup zu erstellen!${NC}"
echo ""
echo "Dieses Skript führt folgende Schritte aus:"
echo "1. System Update"
echo "2. Kernel-Installation (XanMod - Optimiert für Gaming)"
echo "3. GPU-Treiber Update"
echo "4. Installation von Gaming-Tools (Alles Optional wählbar)"
echo "5. System-Tweaks (Swappiness=10, THP=madvise, CPU=Performance)"
echo ""
read -p "Möchten Sie fortfahren? (j/n): " choice
if [[ "$choice" != "j" && "$choice" != "J" ]]; then
    echo "Abbruch."
    exit 1
fi

# ---------------------------------------------------------
# 1. SYSTEM UPDATE
# ---------------------------------------------------------
echo -e "\n${GREEN}[1/5] Führe System-Update durch...${NC}"
apt update && apt upgrade -y

# ---------------------------------------------------------
# 2. XANMOD KERNEL (Gaming Kernel)
# ---------------------------------------------------------
echo -e "\n${GREEN}[2/5] Installiere XanMod Gaming Kernel...${NC}"
echo -e "${YELLOW}Hinweis: Secure Boot muss im BIOS ggf. deaktiviert sein.${NC}"

# Key und Repo hinzufügen
wget -qO - https://dl.xanmod.org/gpg.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes
echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | tee /etc/apt/sources.list.d/xanmod-release.list
apt update

echo "=========================================================="
echo "Bitte wählen Sie die optimale XanMod Kernel-Version für Ihre CPU:"
echo " "
echo "1) x64v3 (Standard & Sicher): Für die meisten Gaming-CPUs (z.B. AMD Ryzen 1000-5000, Intel 4. bis 11. Gen). ${GREEN}<-- SICHERE WAHL${NC}"
echo "2) x64v4 (Modern & Schnell): Nur für NEUESTE CPUs (z.B. AMD Ryzen 7000+, Intel 12. Gen+). ${RED}RISIKO BEI ALTER HARDWARE!${NC}"
echo "3) Edge (Neueste Version): Enthält die neuesten, manchmal weniger stabilen Features."
echo "4) ABBRUCH: Kernel-Installation überspringen."
read -p "Auswahl (1-4): " kernel_choice

case $kernel_choice in
    1)
        KERNEL_PACKAGE="linux-xanmod-x64v3"
        ;;
    2)
        KERNEL_PACKAGE="linux-xanmod-x64v4"
        echo -e "${RED}WARNUNG: x64v4 funktioniert NICHT mit AMD Zen 3 (Ryzen 5000). Systemstart kann fehlschlagen!${NC}"
        ;;
    3)
        KERNEL_PACKAGE="linux-xanmod-edge"
        echo -e "${RED}WARNUNG: Edge-Kernel können zu Instabilität führen!${NC}"
        ;;
    4)
        echo "Kernel-Installation übersprungen."
        KERNEL_PACKAGE="" 
        ;;
    *)
        echo -e "${RED}Ungültige Eingabe. Setze auf die sicherste Standardwahl: x64v3.${NC}"
        KERNEL_PACKAGE="linux-xanmod-x64v3"
        ;;
esac

if [ ! -z "$KERNEL_PACKAGE" ]; then
    echo "Installiere Paket: $KERNEL_PACKAGE"
    apt install "$KERNEL_PACKAGE" -y
fi

# ---------------------------------------------------------
# 3. GPU TREIBER AUSWAHL
# ---------------------------------------------------------
echo -e "\n${GREEN}[3/5] Grafikkarte konfigurieren${NC}"
echo "Welche Grafikkarte nutzen Sie?"
echo "1) AMD / Intel (Installiert Kisak Mesa PPA - Empfohlen)"
echo "2) NVIDIA (Installiert Treiber via ubuntu-drivers)"
echo "3) Überspringen"
read -p "Auswahl (1-3): " gpu_choice

case $gpu_choice in
    1)
        echo "Füge Kisak-Mesa PPA hinzu..."
        add-apt-repository ppa:kisak/kisak-mesa -y
        apt update
        apt full-upgrade -y
        ;;
    2)
        echo "Suche und installiere NVIDIA-Treiber..."
        ubuntu-drivers autoinstall
        ;;
    3)
        echo "Überspringe GPU-Treiber..."
        ;;
    *)
        echo "Ungültige Eingabe, überspringe..."
        ;;
esac

# ---------------------------------------------------------
# 4. GAMING TOOLS (Optional)
# ---------------------------------------------------------
echo -e "\n${GREEN}[4/5] Installiere Gaming-Tools...${NC}"

# Flatpak (Basis für ProtonUp-Qt)
echo "Installiere Flatpak (Voraussetzung für ProtonUp-Qt)..."
apt install flatpak -y
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Optional: GameMode
echo -e "\n${YELLOW}--- OPTIONALE INSTALLATION: GameMode ---${NC}"
echo "GameMode optimiert automatisch die CPU/GPU-Leistung, wenn ein Spiel läuft."
read -p "Möchten Sie GameMode installieren? (j/n): " gamemode_choice
if [[ "$gamemode_choice" == "j" || "$gamemode_choice" == "J" ]]; then
    apt install gamemode -y
else
    echo "GameMode übersprungen."
fi

# Optional: CPUFreqUtils
echo -e "\n${YELLOW}--- OPTIONALE INSTALLATION: CPU Frequenz Tools ---${NC}"
echo "Erforderlich, um den CPU Governor permanent auf 'Performance' zu setzen."
read -p "Möchten Sie CPU Frequenz Tools (cpufrequtils) installieren? (j/n): " cpufreq_choice
if [[ "$cpufreq_choice" == "j" || "$cpufreq_choice" == "J" ]]; then
    apt install cpufrequtils -y
else
    echo "CPU Tools übersprungen."
fi

# Optional: MangoHud
echo -e "\n${YELLOW}--- OPTIONALE INSTALLATION: MangoHud ---${NC}"
echo "FPS-Overlay (wie MSI Afterburner)."
read -p "Möchten Sie MangoHud installieren? (j/n): " mangohud_choice
if [[ "$mangohud_choice" == "j" || "$mangohud_choice" == "J" ]]; then
    apt install mangohud -y
    echo -e "${YELLOW}   NUTZUNG: 'mangohud %command%' in Steam-Startoptionen.${NC}"
else
    echo "MangoHud übersprungen."
fi

# Optional: Lutris
echo -e "\n${YELLOW}--- OPTIONALE INSTALLATION: LUTRIS ---${NC}"
echo "Launcher für Epic, GOG, Battle.net."
read -p "Möchten Sie Lutris installieren? (j/n): " lutris_choice
if [[ "$lutris_choice" == "j" || "$lutris_choice" == "J" ]]; then
    add-apt-repository ppa:lutris-team/lutris -y
    apt update
    apt install lutris -y
else
    echo "Lutris übersprungen."
fi

# Optional: Steam
echo -e "\n${YELLOW}--- OPTIONALE INSTALLATION: Steam ---${NC}"
read -p "Möchten Sie Steam installieren? (j/n): " steam_choice
if [[ "$steam_choice" == "j" || "$steam_choice" == "J" ]]; then
    apt install steam-installer -y
else
    echo "Steam übersprungen."
fi

# OBLIGATORISCH: ProtonUp-Qt
echo -e "\n${GREEN}Installiere ProtonUp-Qt via Flatpak (obligatorisch)...${NC}"
flatpak install flathub net.davidotek.GtkSharpInstaller -y

# ---------------------------------------------------------
# 5. SYSTEM TWEAKS (Optimiert)
# ---------------------------------------------------------
echo -e "\n${GREEN}[5/5] Wende System-Tweaks an...${NC}"

# Backup
cp /etc/sysctl.conf /etc/sysctl.conf.bak

# 1. VM Max Map Count
if ! grep -q "vm.max_map_count" /etc/sysctl.conf; then
    echo "vm.max_map_count=2147483647" >> /etc/sysctl.conf
else
    sed -i 's/^vm.max_map_count.*/vm.max_map_count=2147483647/' /etc/sysctl.conf
fi

# 2. VM Swappiness (Wert 10 = Optimiert für Gaming)
if ! grep -q "vm.swappiness" /etc/sysctl.conf; then
    echo "vm.swappiness=10" >> /etc/sysctl.conf
    echo "Swappiness auf 10 gesetzt."
else
    sed -i 's/^vm.swappiness.*/vm.swappiness=10/' /etc/sysctl.conf
    echo "Swappiness auf 10 aktualisiert."
fi

sysctl -p

# 3. Optional: THP (Transparent Huge Pages) Optimierung
echo -e "\n${YELLOW}--- OPTIONAL: Transparent Huge Pages (THP) auf 'madvise' setzen ---${NC}"
echo "Dies ist die Standard-Einstellung von Nobara OS."
echo "Es verhindert Ruckler, erlaubt aber optimierten Apps (z.B. Emulatoren) den Zugriff."
read -p "Möchten Sie THP auf 'madvise' (empfohlen) setzen? (j/n): " thp_choice
if [[ "$thp_choice" == "j" || "$thp_choice" == "J" ]]; then
    cp /etc/default/grub /etc/default/grub.bak
    # Prüft, ob der Eintrag schon existiert
    if ! grep -q "transparent_hugepage=madvise" /etc/default/grub; then
        # Falls 'never' gesetzt war, ersetze es, sonst füge 'madvise' hinzu
        sed -i 's/transparent_hugepage=never/transparent_hugepage=madvise/g' /etc/default/grub
        if ! grep -q "transparent_hugepage=madvise" /etc/default/grub; then
             sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 transparent_hugepage=madvise"/' /etc/default/grub
        fi
        update-grub
        echo "THP auf 'madvise' gesetzt (wirksam nach Neustart)."
    else
        echo "THP war bereits auf 'madvise'."
    fi
else
    echo "THP-Einstellung unverändert."
fi

# 4. CPU Governor (Performance)
if [ -f /etc/default/cpufrequtils ] || [ "$cpufreq_choice" == "j" ] || [ "$cpufreq_choice" == "J" ]; then
    if [ -f /etc/default/cpufrequtils ]; then
        sed -i 's/^GOVERNOR.*/GOVERNOR="performance"/' /etc/default/cpufrequtils
    else
        echo 'GOVERNOR="performance"' > /etc/default/cpufrequtils
    fi
    systemctl restart cpufrequtils 2>/dev/null || true
    echo "CPU Governor auf 'performance' gesetzt."
fi

# ---------------------------------------------------------
# ABSCHLUSS
# ---------------------------------------------------------
echo -e "\n${GREEN}====================================================${NC}"
echo -e "${GREEN}   OPTIMIERUNG ABGESCHLOSSEN!   ${NC}"
echo -e "${GREEN}====================================================${NC}"
echo "Bitte führen Sie jetzt einen NEUSTART durch."
echo ""
echo -e "${YELLOW}Letzter manueller Schritt:${NC}"
echo "Falls Sie Cinnamon nutzen: Gehen Sie in die Systemeinstellungen -> Allgemein"
echo "und aktivieren Sie 'Compositing für Vollbild-Fenster deaktivieren'."
echo ""
read -p "Jetzt neu starten? (j/n): " reboot_choice
if [[ "$reboot_choice" == "j" || "$reboot_choice" == "J" ]]; then
    reboot
fi