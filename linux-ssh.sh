#!/bin/bash

echo "🔧 إعداد مستخدم SSH جديد..."
sudo useradd -m "$LINUX_USERNAME"
echo "$LINUX_USERNAME:$LINUX_USER_PASSWORD" | sudo chpasswd
sudo usermod -aG sudo "$LINUX_USERNAME"
sudo hostnamectl set-hostname "$LINUX_MACHINE_NAME"

echo "🧹 إزالة ngrok القديم إن وُجد..."
sudo rm -f /usr/local/bin/ngrok /usr/bin/ngrok ./ngrok ./ngrok-stable-linux-amd64.zip

echo "⬇️ تحميل ngrok الجديد (v3)..."
curl -sLo ngrok.zip https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.zip
unzip ngrok.zip
chmod +x ngrok
NGROK_PATH=$(realpath ./ngrok)

echo "🔐 تسجيل التوكن في ngrok..."
$NGROK_PATH config add-authtoken "$NGROK_AUTH_TOKEN"

echo "🛠️ إعداد كلمة مرور للمستخدم الحالي..."
echo -e "$LINUX_USER_PASSWORD\n$LINUX_USER_PASSWORD" | sudo passwd "$USER"

echo "🚀 بدء نغروك على بورت SSH 22..."
rm -f .ngrok.log
$NGROK_PATH tcp 22 --log=stdout > .ngrok.log &

sleep 10

# استخراج الرابط أو عرض الخطأ
HAS_ERRORS=$(grep "ERR_NGROK" .ngrok.log)

if [[ -z "$HAS_ERRORS" ]]; then
  echo ""
  echo "✅ SSH جاهز:"
  grep -o -E "tcp://(.+)" .ngrok.log | sed "s/tcp:\/\//ssh $LINUX_USERNAME@/" | sed "s/:/ -p /"
  echo ""
else
  echo "❌ حصل خطأ من ngrok:"
  echo "$HAS_ERRORS"
  exit 4
fi
