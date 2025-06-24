#!/bin/bash

# إضافة المستخدم وتحديث الصلاحيات
sudo useradd -m "$LINUX_USERNAME"
sudo adduser "$LINUX_USERNAME" sudo
echo "$LINUX_USERNAME:$LINUX_USER_PASSWORD" | sudo chpasswd
sed -i 's/\/bin\/sh/\/bin\/bash/g' /etc/passwd
sudo hostname "$LINUX_MACHINE_NAME"

# التحقق من المتغيرات
if [[ -z "$NGROK_AUTH_TOKEN" ]]; then
  echo "❌ Please set 'NGROK_AUTH_TOKEN'"
  exit 2
fi

if [[ -z "$LINUX_USER_PASSWORD" ]]; then
  echo "❌ Please set 'LINUX_USER_PASSWORD' for user: $USER"
  exit 3
fi

echo "✅ Installing latest ngrok..."

# تثبيت ngrok v3
curl -sLO https://bin.ngrok.io/ngrok-v3-stable-linux-amd64.tgz
tar -xvzf ngrok-v3-stable-linux-amd64.tgz
sudo mv ngrok /usr/local/bin
rm -f ngrok-v3-stable-linux-amd64.tgz

# تحديث باسورد المستخدم الحالي
echo -e "$LINUX_USER_PASSWORD\n$LINUX_USER_PASSWORD" | sudo passwd "$USER"

echo "🚀 Starting ngrok tunnel for port 22 (SSH)..."

rm -f .ngrok.log
ngrok config add-authtoken "$NGROK_AUTH_TOKEN"
ngrok tcp 22 --log=stdout > .ngrok.log &

sleep 10

HAS_ERRORS=$(grep "ERR_NGROK" < .ngrok.log)

if [[ -z "$HAS_ERRORS" ]]; then
  echo ""
  echo "=========================================="
  echo "✅ SSH Command:"
  grep -o -E "tcp://(.+)" < .ngrok.log | sed "s/tcp:\/\//ssh $LINUX_USERNAME@/" | sed "s/:/ -p /"
  echo "=========================================="
else
  echo "❌ ngrok Error:"
  echo "$HAS_ERRORS"
  exit 4
fi
