#!/bin/sh
###############################################################################
# prepare-offline.sh - Download all assets for offline AdGuardHome installation
# Usage: sh prepare-offline.sh [output_directory]
#   Default output directory: ./offline-bundle
#
# Run this script on a machine WITH internet access BEFORE going offline.
# Then copy the output directory to your Asuswrt-Merlin router and run:
#   AGH_OFFLINE_DIR=/path/to/offline-bundle sh installer
###############################################################################

export LC_ALL=C
export PATH="/sbin:/bin:/usr/sbin:/usr/bin:${PATH}"

OUTPUT_DIR="${1:-./offline-bundle}"
BRANCH="${BRANCH:-master}"
BASE_URL="https://raw.githubusercontent.com/jumpsmm7/Asuswrt-Merlin-AdGuardHome-Installer/${BRANCH}"

ai_have_cmd() { which "$1" >/dev/null 2>&1; }
PTXT() { while [ $# -gt 0 ]; do printf "%s\n" "$1"; shift; done; }

mkdir -p "${OUTPUT_DIR}" || { PTXT "Error: Cannot create ${OUTPUT_DIR}"; exit 1; }

# Determine target architecture(s)
detect_arch() {
	case "$(uname -m)" in
		aarch64|arm64) echo "arm64" ;;
		armv7l) echo "armv7" ;;
		armv7) echo "armv5" ;;
		x86_64) echo "amd64" ;;
		i*86) echo "386" ;;
		*) echo "unknown" ;;
	esac
}

download_if_missing() {
	local url dest desc
	url="$1"
	dest="$2"
	desc="$3"
	if [ -f "${dest}" ]; then
		PTXT "  [SKIP] ${desc} already exists"
		return 0
	fi
	PTXT "  [FETCH] ${desc}..."
	if ai_have_cmd curl; then
		curl -f -sL "${url}" -o "${dest}" || return 1
	elif ai_have_cmd wget; then
		wget -q -O "${dest}" "${url}" || return 1
	else
		PTXT "  [ERROR] No curl or wget available!"
		return 1
	fi
	return 0
}

PTXT "==============================================================================="
PTXT "  AdGuardHome Offline Bundle Preparer"
PTXT "  Output directory: ${OUTPUT_DIR}"
PTXT "==============================================================================="
PTXT ""

# 1. Download installer helper scripts
PTXT "[1/5] Downloading installer helper scripts..."
for script in AdGuardHome.sh S99AdGuardHome rc.func.AdGuardHome; do
	download_if_missing "${BASE_URL}/${script}" "${OUTPUT_DIR}/${script}" "${script}" || {
		PTXT "  [ERROR] Failed to download ${script}"
		PTXT "  URL: ${BASE_URL}/${script}"
	}
done

# 2. Download tzdata (timezone data)
PTXT ""
PTXT "[2/5] Downloading timezone data..."
for arch in aarch64 arm; do
	tzfile="tzdata-2021e-1-${arch}.pkg.tar.bz2"
	download_if_missing "${BASE_URL}/${tzfile}" "${OUTPUT_DIR}/${tzfile}" "${tzfile}" || true
done

# 3. Download AdGuardHome binaries for all architectures
PTXT ""
PTXT "[3/5] Downloading AdGuardHome binaries..."
ADGUARD_RELEASE_URL="https://api.github.com/repos/AdguardTeam/AdGuardHome/releases/latest"
LATEST_JSON=""
if ai_have_cmd curl; then
	LATEST_JSON="$(curl -f -sL "${ADGUARD_RELEASE_URL}" 2>/dev/null)"
fi
if [ -z "${LATEST_JSON}" ] && ai_have_cmd wget; then
	LATEST_JSON="$(wget -q -O - "${ADGUARD_RELEASE_URL}" 2>/dev/null)"
fi

if [ -n "${LATEST_JSON}" ]; then
	for platform_arch in "linux_arm64" "linux_armv7" "linux_armv5" "linux_amd64"; do
		archive="AdGuardHome_${platform_arch}.tar.gz"
		# Try to find download URL from GitHub API
		DL_URL="$(printf "%s" "${LATEST_JSON}" | awk -v name="${archive}" '
			/browser_download_url/ {
				url = $2
				gsub(/[" ,]/, "", url)
				if (url ~ name) { print url; exit }
			}
		')"
		if [ -z "${DL_URL}" ]; then
			DL_URL="https://github.com/AdguardTeam/AdGuardHome/releases/latest/download/${archive}"
		fi
		download_if_missing "${DL_URL}" "${OUTPUT_DIR}/${archive}" "${archive} (${platform_arch})" || {
			PTXT "  [WARN] Could not download ${archive} for ${platform_arch}"
		}
	done
else
	PTXT "  [WARN] Could not fetch latest release info from GitHub API."
	PTXT "  Falling back to hardcoded URLs for common architectures..."
	for platform_arch in "linux_arm64" "linux_armv7" "linux_armv5" "linux_amd64"; do
		archive="AdGuardHome_${platform_arch}.tar.gz"
		download_if_missing "https://github.com/AdguardTeam/AdGuardHome/releases/latest/download/${archive}" \
			"${OUTPUT_DIR}/${archive}" "${archive}" || true
	done
fi

# 4. Copy the installer itself (if not already in output directory)
PTXT ""
PTXT "[4/5] Copying installer script..."
SCRIPT_SRC="$(readlink -f "$0" 2>/dev/null || readlink -f "$0" 2>/dev/null || echo "$0")"
if [ -f "${SCRIPT_SRC}" ] && [ "$(basename "${SCRIPT_SRC}")" != "prepare-offline.sh" ]; then
	SCRIPT_SRC_DIR="$(dirname "${SCRIPT_SRC}")"
	cp -f "${SCRIPT_SRC_DIR}/installer" "${OUTPUT_DIR}/installer" 2>/dev/null || {
		PTXT "  [WARN] Copying installer from current directory"
		cp -f "./installer" "${OUTPUT_DIR}/installer" 2>/dev/null || {
			PTXT "  [WARN] Please manually copy the installer script to the output directory"
		}
	}
fi

# 5. Create a README
PTXT ""
PTXT "[5/5] Creating bundle info..."
PTXT "AdGuardHome Offline Bundle" > "${OUTPUT_DIR}/README.txt"
PTXT "Prepared on: $(date)" >> "${OUTPUT_DIR}/README.txt"
PTXT "Branch: ${BRANCH}" >> "${OUTPUT_DIR}/README.txt"
PTXT "" >> "${OUTPUT_DIR}/README.txt"
PTXT "Installation:" >> "${OUTPUT_DIR}/README.txt"
PTXT "  1. Copy this entire directory to your Asuswrt-Merlin router" >> "${OUTPUT_DIR}/README.txt"
PTXT "  2. Run: AGH_OFFLINE_DIR=/path/to/this/dir sh installer" >> "${OUTPUT_DIR}/README.txt"
PTXT "" >> "${OUTPUT_DIR}/README.txt"
PTXT "Prerequisites on router:" >> "${OUTPUT_DIR}/README.txt"
PTXT "  - Entware must be installed" >> "${OUTPUT_DIR}/README.txt"
PTXT "  - python3-bcrypt or bcrypt-tool must be pre-installed for password hashing" >> "${OUTPUT_DIR}/README.txt"
PTXT "  - opkg packages: python3, python3-bcrypt, column" >> "${OUTPUT_DIR}/README.txt"

PTXT ""
PTXT "==============================================================================="
PTXT "  Offline bundle prepared at: ${OUTPUT_DIR}"
PTXT "  Total size: $(du -sh "${OUTPUT_DIR}" 2>/dev/null | cut -f1)"
PTXT "  Files:"
ls -la "${OUTPUT_DIR}/"
PTXT "==============================================================================="
PTXT ""
PTXT "Next steps:"
PTXT "  1. Copy '${OUTPUT_DIR}' to your Asuswrt-Merlin router (e.g., to /tmp/mnt/USB/agh-offline)"
PTXT "  2. On the router, make sure Entware packages are pre-installed:"
PTXT "       opkg install python3 python3-bcrypt column"
PTXT "  3. Run offline installer:"
PTXT "       AGH_OFFLINE_DIR=/path/to/offline-bundle sh installer"
PTXT ""
