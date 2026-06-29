#!/bin/bash
set -euo pipefail

API_KEY=$(aws ssm get-parameter --name "${api_key_ssm_path}" --with-decryption --query Parameter.Value --output text --region "${aws_region}")

# Install Typesense
curl -O https://dl.typesense.org/releases/27.0/typesense-server-27.0-linux-arm64.tar.gz
tar -xzf typesense-server-27.0-linux-arm64.tar.gz -C /opt
mv /opt/typesense-server /opt/typesense

mkdir -p /var/lib/typesense /etc/typesense
cat > /etc/typesense/typesense.ini <<EOF
[server]
api-key = $${API_KEY}
data-dir = /var/lib/typesense
api-port = 8108
enable-cors = true
EOF

cat > /etc/systemd/system/typesense.service <<'UNIT'
[Unit]
Description=Typesense search server
After=network.target

[Service]
Type=simple
ExecStart=/opt/typesense --config=/etc/typesense/typesense.ini
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable typesense
systemctl start typesense

# Wait for Typesense to accept connections, then ensure the routines collection exists.
for i in $(seq 1 30); do
  if curl -sf "http://localhost:8108/health" >/dev/null; then
    break
  fi
  sleep 2
done

curl -sf "http://localhost:8108/collections/routines" -H "X-TYPESENSE-API-KEY: $${API_KEY}" >/dev/null 2>&1 || \
curl -sf "http://localhost:8108/collections" \
  -H "X-TYPESENSE-API-KEY: $${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"name":"routines","fields":[{"name":"name","type":"string"},{"name":"description","type":"string"},{"name":"tags","type":"string[]","facet":true},{"name":"durationSeconds","type":"int32","facet":true},{"name":"authorName","type":"string"},{"name":"likeCount","type":"int32"},{"name":"importCount","type":"int32"},{"name":"publishedAt","type":"int64"}],"default_sorting_field":"publishedAt"}'

# Daily snapshot to S3 at 03:00 UTC
cat > /usr/local/bin/typesense-snapshot.sh <<SCRIPT
#!/bin/bash
set -euo pipefail
curl -s "http://localhost:8108/operations/snapshot?snapshot_path=/tmp/typesense-snapshot" -H "X-TYPESENSE-API-KEY: $${API_KEY}"
aws s3 sync /tmp/typesense-snapshot "s3://${backup_bucket}/\$(date +%Y-%m-%d)/" --region "${aws_region}"
SCRIPT
chmod +x /usr/local/bin/typesense-snapshot.sh

mkdir -p /etc/cron.d
echo "0 3 * * * root /usr/local/bin/typesense-snapshot.sh" > /etc/cron.d/typesense-snapshot
