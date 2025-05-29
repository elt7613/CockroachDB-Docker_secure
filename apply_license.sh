# Apply License key. Add your License Key
docker exec roach-0 /cockroach/cockroach sql --certs-dir=/certs --host=roach-0.crdb.io:26257 --execute "SET CLUSTER SETTING enterprise.license = '<YOUR-LICENSE-KEY>';"

# Check the license key is applied or not
docker exec roach-0 /cockroach/cockroach sql --certs-dir=/certs --host=roach-0.crdb.io:26257 --execute "SELECT * FROM crdb_internal.cluster_settings WHERE variable = 'enterprise.license';"