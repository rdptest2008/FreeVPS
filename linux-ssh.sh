#!/bin/bash

echo "🔧 إعداد مستخدم SSH جديد..."
sudo useradd -m "$LINUX_USERNAME"
echo "$LINUX_USERNAME:$LINUX_USER_PASSWORD" | sudo chpasswd
sudo usermod -aG sudo "$LINUX_USERNAME"
sudo hostnamectl set-hostname "$LINUX_MACHINE_NAME"

echo "🧹 إزالة ngrok القديم إن وُجد..."
sudo rm -f /usr/local/bin/ngrok /usr/bin/ngrok ./ngrok ./ngrok.zip

echo "⬇️ تحميل ngrok v3 حديث..."
curl -sSL https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz -o ngrok.tgz
tar -xvzf ngrok.tgz
chmod +x ./ngrok

echo "🔑 تسجيل التوكن في ngrok..."
./ngrok config add-authtoken "$NGROK_AUTH_TOKEN"

echo "🔐 تغيير باسورد المستخدم الحالي..."
echo -e "$LINUX_USER_PASSWORD\n$LINUX_USER_PASSWORD" | sudo passwd "$USER"

echo "🚀 بدء ngrok TCP على المنفذ 22..."
rm -f .ngrok.log
./ngrok tcp 22 --log ".ngrok.log" &

sleep 10
HAS_ERRORS=$(grep "command failed" .ngrok.log)

if [[ -z "$HAS_ERRORS" ]]; then
  echo "✅ الاتصال جاهز!"
  echo "=========================================="
  echo "To connect:"
  echo "$(grep -o -E "tcp://(.+)" < .ngrok.log | sed "s/tcp:\/\//ssh $LINUX_USERNAME@/" | sed "s/:/ -p /")"
  echo "=========================================="
else
  echo "$HAS_ERRORS"
  exit 4
fi
