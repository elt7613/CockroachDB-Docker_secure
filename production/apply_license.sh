#!/bin/bash

# Apply License key for production cluster. Add your License Key
echo "Applying CockroachDB Enterprise License..."

docker exec roach-0 /cockroach/cockroach sql --certs-dir=/certs --host=34.46.203.113:26257 --execute "SET CLUSTER SETTING enterprise.license = '<YOUR-LICENSE-KEY>';"

echo "Checking if license key is applied..."

# Check the license key is applied or not
docker exec roach-0 /cockroach/cockroach sql --certs-dir=/certs --host=34.46.203.113:26257 --execute "SELECT * FROM crdb_internal.cluster_settings WHERE variable = 'enterprise.license';"

echo "License application completed!" 