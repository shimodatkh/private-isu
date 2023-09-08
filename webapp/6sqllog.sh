#!/bin/bash

# 現在の日時を変数に格納
current_time=$(date '+%Y-%m-%d_%H-%M-%S')
mysql_log_dir=log/mysql/$current_time
# explain結果を保存するファイル
result_file=$mysql_log_dir/3_explained_queries.log

# フォルダを作成
mkdir -p $mysql_log_dir

# フォルダをlsで表示
ls -l  $mysql_log_dir


echo "[1] コンテナ内のmysql-slow.logを表示します"

docker exec webapp-mysql-1 ls -l /var/log/mysql/mysql-slow.log

echo "[2] mysql-slow.logをコピーします"

docker cp webapp-mysql-1:/var/log/mysql/mysql-slow.log $mysql_log_dir/mysql-slow.log

# go-mysql-query-digest $mysql_log_dir/mysql-slow.log > $mysql_log_dir/mysql-slow-analyze.log

echo "[3] mysql-slow.logを解析します"

# $mysql_log_dir/mysql-slow.log のサイズが1バイト以下だったら終了する
if [ $(wc -c < $mysql_log_dir/mysql-slow.log) -le 1 ]; then
  echo "mysql-slow.log is empty"
  exit 0
fi

docker run -it --rm -v $(pwd)/$mysql_log_dir/mysql-slow.log:/tmp/mysql-slow.log perconalab/percona-toolkit /bin/bash -c "pt-query-digest /tmp/mysql-slow.log --limit 20" >  $mysql_log_dir/mysql-slow-analyze.log

echo "[4] コンテナ内のmysql-slow.logをクリアします"

docker exec webapp-mysql-1 bash -c "echo -n '' > /var/log/mysql/mysql-slow.log"

echo "[5] コンテナ内のmysql-slow.logを表示します"

docker exec webapp-mysql-1 ls -l /var/log/mysql/mysql-slow.log

### 解析パート

# $mysql_log_dir/mysql-slow-analyze.log のサイズが1バイト以下だったら終了する
if [ $(wc -c < $mysql_log_dir/mysql-slow-analyze.log) -le 1 ]; then
  echo "mysql-slow-analyze.log is empty"
  exit 0
fi

# 結果ファイルを初期化
echo "" > $result_file

# SELECT文の総数を計算
total_selects=$(grep -c "^SELECT" $mysql_log_dir/mysql-slow-analyze.log)

# カウンターの初期化
count=0

# mysql-slow-analyze.logからSELECT文を抜き出し、1行ずつ処理
grep "^SELECT" $mysql_log_dir/mysql-slow-analyze.log | while read -r line; do
  # カウンターをインクリメント
  ((count++))

  # [1/15]のような区切りを出力
  echo "[$count/$total_selects]" >> $result_file
  echo "" >> $result_file

    # 末尾の\Gを削除
  line=$(echo "$line" | sed 's/\\G$//')

  # SELECT文そのものを出力
  echo "$line" >> $result_file

  # 先頭にEXPLAINをつけ、実行計画を取得
  explain_result=$(docker exec webapp-mysql-1 mysql -uroot -proot isuconp -t -e "EXPLAIN $line ")

  # 実行計画を出力
  echo "$explain_result" >> $result_file

  # 改行を出力
  echo "" >> $result_file
done

