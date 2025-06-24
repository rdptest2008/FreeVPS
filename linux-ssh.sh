#!/bin/bash

# إنشاء المستخدم وتحديث كلمة المرور بصلاحيات sudo
sudo useradd -m "$LINUX_USERNAME"
sudo adduser "$LINUX_USERNAME" sudo
echo "$LINUX_USERNAME:$LINUX_USER_PASSWORD" | sudo chpasswd
sudo sed -i 's/\/bin\/sh/\/bin\/bash/g' /etc/passwd
sudo hostname "$LINUX_MACHINE_NAME"

# تحقق من المتغيرات
if [[ -z "$NGROK_AUTH_TOKEN" ]]; then
  echo "Please set NGROK_AUTH_TOKEN"
  exit 2
fi

if [[ -z "$LINUX_USER_PASSWORD" ]]; then
  echo "Please set LINUX_USER_PASSWORD"
  exit 3
fi

echo "Installing latest ngrok..."

# حذف النسخة القديمة إن وجدت
sudo rm -f /usr/local/bin/ngrok
sudo rm -f /usr/bin/ngrok

# تنزيل ngrok v3 (amd64)
curl -sLO https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip
unzip -o ngrok-stable-linux-amd64.zip
sudo mv ngrok /usr/local/bin/ngrok
rm ngrok-stable-linux-amd64.zip

echo "Updating password for $USER..."
echo -e "$LINUX_USER_PASSWORD\n$LINUX_USER_PASSWORD" | sudo passwd "$USER"

echo "Starting ngrok tunnel on port 22..."

rm -f .ngrok.log

# تكوين ngrok مع التوكن الخاص بك
ngrok config add-authtoken "$NGROK_AUTH_TOKEN"

# تشغيل نغروك مع تسجيل الخروج
ngrok tcp 22 --log=stdout > .ngrok.log &

sleep 10

HAS_ERRORS=$(grep "ERR_NGROK" < .ngrok.log)

if [[ -z "$HAS_ERRORS" ]]; then
  echo "SSH connection details:"
  grep -o -E "tcp://(.+)" < .ngrok.log | sed "s/tcp:\/\//ssh $LINUX_USERNAME@/" | sed "s/:/ -p /"
else
  echo "ngrok error:"
  cat .ngrok.log
  exit 4
fi
