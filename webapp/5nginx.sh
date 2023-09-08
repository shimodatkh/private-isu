#!/bin/bash

# 現在の日時を変数に格納
current_time=$(date '+%Y-%m-%d_%H-%M-%S')
mysql_log_dir=log/nginx/$current_time
# explain結果を保存するファイル
result_file=$mysql_log_dir/3_alp_result.log

# フォルダを作成
mkdir -p $mysql_log_dir

# フォルダをlsで表示
ls -l  $mysql_log_dir


echo "[1] コンテナ内のaccess.logを表示します"

docker exec webapp-nginx-1 ls -l /var/log/nginx/access.log

echo "[2] access.logをコピーします"

docker cp webapp-nginx-1:/var/log/nginx/access.log $mysql_log_dir/access.log

# go-mysql-query-digest $mysql_log_dir/access.log > $mysql_log_dir/mysql-slow-analyze.log

echo "[3] access.logを解析します"

# $mysql_log_dir/access.log のサイズが1バイト以下だったら終了する
if [ $(wc -c < $mysql_log_dir/access.log) -le 1 ]; then
  echo "access.log is empty"
  exit 0
fi

./alp.exe json --file $mysql_log_dir/access.log  -r --sort=sum  --show-footers -m "/image/\d+.(jpg|png|gif), @[a-zA-Z]+, /posts/\d+"  > $result_file

  # $mysql_log_dir/mysql-slow-analyze.log

echo "[4] コンテナ内のaccess.logをクリアします"

docker exec webapp-nginx-1 bash -c "echo -n '' > /var/log/nginx/access.log"

echo "[5] コンテナ内のaccess.logを表示します"

docker exec webapp-nginx-1 ls -l /var/log/nginx/access.log

### 解析パート

