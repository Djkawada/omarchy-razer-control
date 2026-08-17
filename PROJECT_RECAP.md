# 🐍 Razer Control for Omarchy Linux — Récapitulatif du Projet

**Date :** 16 Août 2026  
**Auteur :** Pierre ([@Djkawada](https://github.com/Djkawada))  
**Dépôt GitHub public :** [https://github.com/Djkawada/omarchy-razer-control](https://github.com/Djkawada/omarchy-razer-control)

---

## 🎯 Vision du Projet
Offrir aux utilisateurs de claviers Razer sous **Omarchy Linux** (Hyprland / Quickshell) une solution **ultra-légère, autonome et sans aucun démon lourd en arrière-plan** (contrairement à OpenRazer, Polychromatic ou Synapse) :
- Communication directe matériel via `/dev/hidraw*` (protocole Razer 90 octets).
- **100 % natif Quickshell / Qt Quick** : Zéro latence, 0 Mo d'overhead Chromium, fluidité à 60/144/240 Hz.
- Prise en charge des claviers classiques et modernes (DeathStalker 2014, Expert, Chroma, BlackWidow, Huntsman...).

---

## 🛠️ Travail Accompli

1. **Widget de Barre Interactif ([`BarWidget.qml`](file:///home/pierre/Work/omarchy-razer-plugin/BarWidget.qml))** :
   - Icône Razer avec voyant vert pour le Mode Gaming.
   - Menu contextuel rapide : luminosité, effets, verrous (<kbd>Verr Maj</kbd>, <kbd>Verr Num</kbd>, <kbd>Arrêt Défil</kbd>), sélecteur de langue rapide et raccourci vers la grande fenêtre.
   - Clic droit direct sur l'icône de la barre pour ouvrir instantanément le grand Control Center.

2. **Grande Fenêtre Native de Diagnostic & Contrôle ([`ControlCenterWindow.qml`](file:///home/pierre/Work/omarchy-razer-plugin/ControlCenterWindow.qml))** :
   - Rétroéclairage adaptatif (se masque sur les claviers sans LED comme le DeathStalker Essential 2014).
   - Mode Gaming (<kbd>Fn</kbd> + <kbd>F10</kbd>) autonome matériel.
   - Guide pas-à-pas pour l'enregistrement de macros à la volée (OTF - <kbd>Fn</kbd> + <kbd>F9</kbd>).
   - HUD 5 LED réactif + contrôle des verrous + explication claire de la touche Scroll Lock.
   - Sélecteur de Polling Rate (125 Hz, 500 Hz, 1000 Hz).
   - **Testeur Anti-Ghosting & Matrice NKRO en direct** avec clavier visuel illuminé à la frappe et calcul du Max Rollover.
   - **Console de trames HID & logs système** en temps réel.

3. **Support Multilingue Intégral (i18n)** :
   - Français 🇫🇷, Anglais 🇬🇧, Japonais 🇯🇵.
   - Détection automatique sur la locale du système + boutons de changement manuel immédiat `[FR] [EN] [JA]`.

4. **Publication & Nettoyage** :
   - Code publié sur GitHub : [`Djkawada/omarchy-razer-control`](https://github.com/Djkawada/omarchy-razer-control).
   - Suppression du dossier webapp prototype obsolète (`deathstalker-web`).
   - Identifiant unique configuré : `com.github.djkawada.razer-control`.
   - Fichiers `manifest.json`, `LICENSE` (MIT), `README.md` avec captures et `preview.png` conformes aux règles du marketplace.

---

## 🚀 Procédure pour Demain Matin (Publication sur Omarchy Marketplace)

Dès que la restriction temporaire (Interaction Limit 24h) sera levée par les mainteneurs de HANCORE :

### Option 1 : Via l'interface web (1 clic)
1. Ouvrez le lien : 👉 **[Formulaire de soumission Omarchy Marketplace](https://github.com/HANCORE-linux/omarchy-plugin-marketplace/issues/new?template=submit-plugin.yml)**
2. Remplissez simplement :
   - **Repository URL** : `https://github.com/Djkawada/omarchy-razer-control`
   - **Category** : `Hardware`
   - **Tags** : `bar, quickshell, hyprland`
3. Cochez les cases de la checklist et validez en cliquant sur **Submit new issue**.

### Option 2 : En 1 seule ligne de commande dans votre terminal
```bash
gh issue create --repo HANCORE-linux/omarchy-plugin-marketplace --title "[Plugin]: Razer Control" --body-file /tmp/omarchy-plugin-submission.md
```

---

## 📦 Commandes Utiles

- **Emplacement du code source :** `/home/pierre/Work/omarchy-razer-plugin/`
- **Emplacement du plugin actif :** `~/.config/omarchy/plugins/com.github.djkawada.razer-control/`
- **Recharger la barre Omarchy à tout moment :** `omarchy restart shell`
