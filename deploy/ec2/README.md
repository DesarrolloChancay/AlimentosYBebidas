# Despliegue EC2 Ubuntu 24.04

Objetivo:

- EC2 Ubuntu `24.04.4 LTS`
- Python `3.12.3`
- Proyecto en `/home/ubuntu/AlimentosYBebidas`
- Dominio `ayb.clubcastillodechancay.com`
- `nginx` + `gunicorn` + `systemd` + `certbot`

## Arquitectura prevista

- `nginx` escucha en `80/443`
- `gunicorn` escucha solo en `127.0.0.1:5060`
- `systemd` mantiene viva la app
- `certbot --nginx` instala y renueva HTTPS

Importante:

- Esta app usa `Flask-SocketIO` y estado en memoria para tiempo real.
- Por eso `gunicorn` debe quedarse en `1 worker`.
- Si luego quieres varios workers o varias instancias, necesitas sticky sessions y `SOCKETIO_MESSAGE_QUEUE` con Redis.

## 1. Requisitos previos

- El registro DNS `A` de `ayb.clubcastillodechancay.com` debe apuntar al IP público de la EC2.
- El Security Group debe permitir:
  - `22/tcp`
  - `80/tcp`
  - `443/tcp`
- La base de datos debe aceptar conexiones desde la EC2 o su Security Group.

## 2. Bootstrap del servidor

En la EC2:

```bash
cd /home/ubuntu/AlimentosYBebidas
chmod +x deploy/ec2/bootstrap_ubuntu_24.sh
./deploy/ec2/bootstrap_ubuntu_24.sh
```

## 3. Variables de entorno de producción

Copia el ejemplo y complétalo:

```bash
sudo cp /home/ubuntu/AlimentosYBebidas/deploy/ec2/alimentosybebidas.env.example /etc/alimentosybebidas.env
sudo nano /etc/alimentosybebidas.env
```

Variables mínimas:

- `SECRET_KEY`
- `DB_USER`
- `DB_PASSWORD`
- `DB_HOST`
- `DB_PORT`
- `DB_NAME`

Valores recomendados ya preparados:

- `FLASK_ENV=production`
- `SOCKETIO_CORS_ALLOWED_ORIGINS=https://ayb.clubcastillodechancay.com`
- `GUNICORN_WORKERS=1`
- `GUNICORN_THREADS=100`

## 4. systemd

Instala el servicio:

```bash
sudo cp /home/ubuntu/AlimentosYBebidas/deploy/ec2/systemd/alimentosybebidas.service /etc/systemd/system/alimentosybebidas.service
sudo systemctl daemon-reload
sudo systemctl enable --now alimentosybebidas
sudo systemctl status alimentosybebidas
```

Ver logs:

```bash
journalctl -u alimentosybebidas -f
```

## 5. nginx

Instala la configuración:

```bash
sudo cp /home/ubuntu/AlimentosYBebidas/deploy/ec2/nginx/ayb.clubcastillodechancay.com.conf /etc/nginx/sites-available/ayb.clubcastillodechancay.com.conf
sudo ln -sfn /etc/nginx/sites-available/ayb.clubcastillodechancay.com.conf /etc/nginx/sites-enabled/ayb.clubcastillodechancay.com.conf
sudo nginx -t
sudo systemctl reload nginx
```

Si existe el sitio por defecto y estorba:

```bash
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx
```

## 6. Probar por HTTP antes de HTTPS

Confirma:

```bash
curl -I http://ayb.clubcastillodechancay.com/healthz
```

Debes obtener `200 OK`.

## 7. HTTPS con Certbot

Cuando HTTP ya responda:

```bash
sudo certbot --nginx -d ayb.clubcastillodechancay.com
```

Luego prueba la renovación automática:

```bash
sudo certbot renew --dry-run
```

## 8. Comandos de operación

Reiniciar la app:

```bash
sudo systemctl restart alimentosybebidas
```

Recargar nginx:

```bash
sudo systemctl reload nginx
```

Ver logs de nginx:

```bash
sudo tail -f /var/log/nginx/ayb_access.log /var/log/nginx/ayb_error.log
```

Ver logs de la app:

```bash
journalctl -u alimentosybebidas -f
```

## 9. Deploy de nuevas versiones

```bash
cd /home/ubuntu/AlimentosYBebidas
git pull
source .venv/bin/activate
pip install -r requirements.txt
sudo systemctl restart alimentosybebidas
```

## 10. Verificaciones rápidas

- App:

```bash
curl -I http://127.0.0.1:5060/healthz
```

- Dominio:

```bash
curl -I https://ayb.clubcastillodechancay.com/healthz
```

- Servicio:

```bash
systemctl is-active alimentosybebidas
```

## Notas de seguridad y operación

- No expongas `gunicorn` en `0.0.0.0`; se deja solo en `127.0.0.1:5060`.
- No subas `/etc/alimentosybebidas.env` al repositorio.
- Si cambias el dominio, actualiza:
  - `/etc/alimentosybebidas.env`
  - `/etc/nginx/sites-available/ayb.clubcastillodechancay.com.conf`
  - el certificado de Certbot
- Si en el futuro quieres varios workers o varias instancias:
  - no basta con subir `GUNICORN_WORKERS`
  - necesitas Redis y sticky sessions para Socket.IO
