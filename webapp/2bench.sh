#!/bin/bash


echo "[4] コンテナ内のaccess.logをクリアします"

docker exec webapp-nginx-1 bash -c "echo -n '' > /var/log/nginx/access.log"

echo "[4] コンテナ内のmysql-slow.logをクリアします"

docker exec webapp-mysql-1 bash -c "echo -n '' > /var/log/mysql/mysql-slow.log"

MSYS_NO_PATHCONV=1 docker run --network host -i private-isu-benchmarker /opt/go/bin/benchmarker -t http://host.docker.internal -u /opt/go/userdata