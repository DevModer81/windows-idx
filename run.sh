#!/usr/bin/env bash
set -e

### CONFIG ###
ISO_URL="https://crustywindo.ws/collection/Windows%2011/Windows%2011%2022H2%20Build%2022621.2134%20Gamer%20OS%20en-US%20ESD%20August%202023.iso"
ISO_FILE="win11-gamer.iso"

DISK_FILE="win11.qcow2"
DISK_SIZE="64G"

RAM="8G"
CORES="4"
THREADS="2"

VNC_DISPLAY=":0"      # => port 5900
RDP_PORT="3389"

### CHECK KVM ###
if [ ! -e /dev/kvm ]; then
  echo "❌ /dev/kvm không tồn tại → KHÔNG PHẢI KVM"
  exit 1
fi

### CHECK QEMU ###
command -v qemu-system-x86_64 >/dev/null || {
  echo "❌ Chưa có qemu-system-x86_64"
  exit 1
}

### CHECK ISO ###
if [ ! -f "${ISO_FILE}" ]; then
  echo "⬇️  ISO chưa có → đang tải..."
  wget -O "${ISO_FILE}" "${ISO_URL}"
else
  echo "✅ ISO đã tồn tại"
fi

### CHECK DISK ###
if [ ! -f "${DISK_FILE}" ]; then
  echo "💽 Tạo disk ${DISK_SIZE}"
  qemu-img create -f qcow2 "${DISK_FILE}" "${DISK_SIZE}"
else
  echo "✅ Disk đã tồn tại"
fi

### RUN QEMU (BIOS + KVM + IDE) ###
echo "🚀 Windows 11 (BIOS legacy + KVM)"
echo "🖥️  VNC : localhost:5900"
echo "🖧  RDP : localhost:${RDP_PORT}"

qemu-system-x86_64 \
  -enable-kvm \
  -machine pc,accel=kvm \
  -cpu host,hv-relaxed,hv-vapic,hv-spinlocks=0x1fff \
  -smp sockets=1,cores=${CORES},threads=${THREADS} \
  -m ${RAM} \
  -mem-prealloc \
  -rtc base=localtime \
  -boot menu=on \
  \
  -drive file=${DISK_FILE},if=ide,format=qcow2 \
  -cdrom ${ISO_FILE} \
  \
  -netdev user,id=n0,hostfwd=tcp::${RDP_PORT}-:3389 \
  -device e1000,netdev=n0 \
  \
  -vnc ${VNC_DISPLAY} \
  -usb -device usb-tablet
