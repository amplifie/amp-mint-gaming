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
echo -e "${GREEN}   LINUX MINT GAMING OPTIMIZER     ${NC}"
echo -e "${GREEN}====================================================${NC}"
echo -e "${RED}EMPFOHLEN: Nutzen Sie Timeshift (in Mint enthalten), um ein Backup zu erstellen!${NC}"
echo ""

echo "Dieses Skript führt folgende Schritte aus:"
echo "1. System Update"
echo "2. Kernel-Installation (XanMod LTS empfohlen für NVIDIA)"
echo "3. GPU-Treiber Update"
echo "4. Installation von Gaming-Tools (Optional)"
echo "5. System-Tweaks (Performance & Anti-Stutter)"
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
# Installiere wichtige Abhängigkeiten für Treiber-Kompilierung vorab
apt install build-essential dkms -y

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
echo "Bitte wählen Sie die optimale XanMod Kernel-Version:"
echo " "
echo "1) XanMod LTS (6.12) - [EMPFOHLEN FÜR NVIDIA] ${GREEN}<-- STABIL & SCHNELL${NC}"
echo "   Bietet Gaming-Performance (FSYNC) bei maximaler Treiber-Kompatibilität."
echo " "
echo "2) XanMod Mainline (v3/Edge) - [NUR FÜR AMD/INTEL] ${RED}RISIKO!${NC}"
echo "   Der neuste Kernel (6.17+). Mit den neusten NV Treibern NICHT kompatibel!"
echo " "
echo "3) Überspringen (Standard Mint Kernel behalten)"
read -p "Auswahl (1-3): " kernel_choice

case $kernel_choice in
    1)
        # LTS Version (Safe for NVIDIA)
        KERNEL_PACKAGE="linux-xanmod-lts-x64v3"
        echo -e "${GREEN}Gute Wahl! LTS ist perfekt für Gaming.${NC}"
        ;;
    2)
        # Edge Version (Risk for NVIDIA)
        KERNEL_PACKAGE="linux-xanmod-x64v3"
        echo -e "${RED}WARNUNG: Wenn Sie eine NVIDIA-Karte haben, wird die Treiber-Installation fehlschlagen!${NC}"
        read -p "Wirklich fortfahren? (j/n): " risk_choice
        if [[ "$risk_choice" != "j" ]]; then KERNEL_PACKAGE="linux-xanmod-lts-x64v3"; fi
        ;;
    3)
        echo "Kernel-Installation übersprungen."
        KERNEL_PACKAGE="" 
        ;;
    *)
        echo -e "${YELLOW}Ungültige Eingabe. Wähle sicheren LTS Kernel.${NC}"
        KERNEL_PACKAGE="linux-xanmod-lts-x64v3"
        ;;
esac

if [ ! -z "$KERNEL_PACKAGE" ]; then
    echo "Installiere Paket: $KERNEL_PACKAGE"
    apt install "$KERNEL_PACKAGE" -y
fi

# ---------------------------------------------------------
# 3. GPU TREIBER AUSWAHL (MIT DYNAMISCHER SUCHE)
# ---------------------------------------------------------
echo -e "\n${GREEN}[3/5] Grafikkarte konfigurieren${NC}"
echo "Welche Grafikkarte nutzen Sie?"
echo "1) AMD / Intel (Installiert Kisak Mesa PPA - Empfohlen)"
echo "2) NVIDIA"
echo "3) Überspringen"
read -p "Auswahl (1-3): " gpu_choice

NVIDIA_SELECTED=0

case $gpu_choice in
    1)
        echo "Füge Kisak-Mesa PPA hinzu..."
        add-apt-repository ppa:kisak/kisak-mesa -y
        apt update
        apt full-upgrade -y
        ;;
    2)
        echo -e "\n${YELLOW}Welchen NVIDIA-Treiber möchten Sie installieren?${NC}"
        echo "1) Stabil (Auto-Install) - Wählt automatisch den stabilsten Treiber."
        echo "2) Performance / Neu (Bleeding Edge) - Installiert die absolut neuste verfügbare Version."
        echo "   (Benötigt XanMod LTS aus Schritt 2)"
        read -p "Auswahl (1-2): " nv_ver_choice
        
        if [[ "$nv_ver_choice" == "2" ]]; then
            # Automatische Suche nach dem neusten Paket, das auf -open endet
            LATEST_NV=$(apt-cache search '^nvidia-driver-[0-9]+-open$' | sort -V | tail -n 1 | awk '{print $1}')
            
            if [ -z "$LATEST_NV" ]; then
                echo -e "${RED}Keinen Open-Treiber gefunden. Falle auf Autoinstall zurück.${NC}"
                ubuntu-drivers autoinstall
            else
                echo -e "Erkannte neueste Version: ${GREEN}$LATEST_NV${NC}"
                apt install "$LATEST_NV" -y
            fi
        else
            echo "Suche stabilen Treiber via autoinstall..."
            ubuntu-drivers autoinstall
        fi
        
        NVIDIA_SELECTED=1
        ;;
    3)
        echo "Überspringe GPU-Treiber..."
        ;;
    *)
        echo "Ungültige Eingabe, überspringe..."
        ;;
esac

# ZUSÄTZLICHER SCHRITT: DKMS FIX (NUR FÜR NVIDIA)
if [ "$NVIDIA_SELECTED" -eq 1 ]; then
    echo -e "\n${YELLOW}Führe DKMS Autoinstall/Rebuild für den XanMod Kernel aus... (WICHTIG)${NC}"
    # Erzwingt das Bauen der Module für ALLE Kernel (auch den neuen XanMod)
    dkms autoinstall
    echo -e "${GREEN}NVIDIA-Modul-Kompilierung beendet. Bitte beim Neustart auf Fehler achten.${NC}"
fi

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

# Optional: PulseAudio Volume Control (pavucontrol)
echo -e "\n${YELLOW}--- OPTIONALE INSTALLATION: PulseAudio Volume Control (pavucontrol) ---${NC}"
echo "Dies ist ein **grafischer Mixer** zur Verwaltung von Audio-Ein-/Ausgängen, Streams und Soundkarten-Profilen."
read -p "Möchten Sie pavucontrol installieren? (j/n): " pavucontrol_choice
if [[ "$pavucontrol_choice" == "j" || "$pavucontrol_choice" == "J" ]]; then
    apt install pavucontrol -y
    echo "pavucontrol installiert."
else
    echo "pavucontrol übersprungen."
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
if [ -f /etc/default/cpufrequtils ] || ([ -n "$cpufreq_choice" ] && [[ "$cpufreq_choice" == "j" || "$cpufreq_choice" == "J" ]]); then
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
echo -e "${YELLOW}WICHTIG: Wählen Sie im Boot-Menü den 'XanMod LTS' Kernel!${NC}"
echo ""
read -p "Jetzt neu starten? (j/n): " reboot_choice
if [[ "$reboot_choice" == "j" || "$reboot_choice" == "J" ]]; then
    reboot
fi
