#!/bin/bash

OPTS=`getopt -o D:t:s:w:c:d:k:v:s:b:n:m:h --long db_dir:,threads:,sync:,concurrent_mem_table_writes:,num_column_families:,num_multi_db:,key_size:,value_size:,duration_secs:,write_buffer_size:,max_write_buffer_number:,min_write_buffer_number_to_merge:,help -n 'write_bench.sh' -- "$@"`

print_help()
{
  echo "Usage:"
  echo "        --db_dir                                The directory where the database files will be created"
  echo "        --threads                               The number of threads that will be used to run the workload concurrently"
  echo "        --sync                                  Whether all writes should be synced to disk"
  echo "        --concurrent_mem_table_writes           Are concurrent writes to memtable allowed"
  echo "        --num_column_families                   The number of column families to use store the dataset"
  echo "        --num_multi_db                          The number of RocksDB database instances to use to store the dataset"
  echo "        --key_size                              The size of each key in bytes"
  echo "        --value_size                            The size of each value in bytes"
  echo "        --duration_secs                         The duration in seconds of the benchmark run"
  echo "        --write_buffer_size                     This sets the size of a single memtable"
  echo "        --max_write_buffer_number               This sets the maximum number of memtables"
  echo "        --min_write_buffer_number_to_merge      This is the minimum number of memtables to be merged before flushing to storage"
  echo "        --help                                  Print this help message"

  exit 1
}

print_options()
{
  echo "dbdir=$dbdir"
  echo "threads=$threads"
  echo "sync=$sync"
  echo "concurrent_mem=$concurrent_mem"
  echo "num_column_families=$num_column_families"
  echo "num_multi_db=$num_multi_db"
  echo "key_size=$key_size"
  echo "value_size=$value_size"
  echo "write_buffer_size=$write_buffer_size"
  echo "max_write_buffer_number=$max_write_buffer_number"
  echo "min_write_buffer_number_to_merge=$min_write_buffer_number_to_merge"
  echo "level0_file_num_compaction_trigger=$level0_file_num_compaction_trigger"
  echo "max_bytes_for_level_base=$max_bytes_for_level_base"
  echo "duration_secs=$duration_secs"
  echo
}

if [ $? != 0 ] ; then
  print_help
fi

eval set -- "$OPTS"

# Variables to control benchmark workload and RocksDB options
dbdir=/var/lib/rocksdb
threads=4
sync=0
concurrent_mem=0
num_column_families=1
num_multi_db=0
key_size=8
value_size=32
write_buffer_size=134217728
max_write_buffer_number=16
min_write_buffer_number_to_merge=2
level0_file_num_compaction_trigger=4
max_bytes_for_level_base=$(( $write_buffer_size * $min_write_buffer_number_to_merge * $level0_file_num_compaction_trigger  ))
duration_secs=60

while true; do
  case "$1" in
    --db_dir )                          dbdir=$2;
                                        shift; shift
                                        ;;
    --threads )                         threads=$2;
                                        shift; shift
                                        ;;
    --sync )                            sync=$2;
                                        shift; shift
                                        ;;
    --concurrent_mem_table_writes )     concurrent_mem=$2;
                                        shift; shift
                                        ;;
    --num_column_families )             num_column_families=$2;
                                        shift; shift
                                        ;;
    --num_multi_db )                    num_multi_db=$2;
                                        shift; shift
                                        ;;
    --key_size )                        key_size=$2;
                                        shift; shift
                                        ;;
    --value_size )                      value_size=$2;
                                        shift; shift
                                        ;;
    --write_buffer_size )               write_buffer_size=$2;
                                        shift; shift
                                        ;;
    --max_write_buffer_number )         max_write_buffer_number=$2;
                                        shift; shift
                                        ;;
    --min_write_buffer_number_to_merge ) min_write_buffer_number_to_merge=$2;
                                        shift; shift
                                        ;;
    --duration_secs )                   duration_secs=$2;
                                        shift; shift
                                        ;;
    --help )                            print_help >&2
                                        exit 1
                                        ;;
    -- )                                shift; break
                                        ;;
    * )                                 print_help >&2
                                        exit 1
                                        ;;
  esac
done

# Reset --max_bytes_for_level_base based on the updated config parameters
max_bytes_for_level_base=$(( $write_buffer_size * $min_write_buffer_number_to_merge * $level0_file_num_compaction_trigger  ))

bench_dt=$(date +%Y-%m-%d-%H%M%S)
dbdir=${dbdir}/${bench_dt}

rm -rf $dbdir; mkdir $dbdir

echo "## Running benchmark with the following options set"
print_options | tee ${dbdir}/BENCHMARK_OPTIONS

echo "Cleaning the page cache"
echo
sync && echo 3 > /proc/sys/vm/drop_caches

echo "Starting the benchmark now"
echo

./rocksdb/db_bench --benchmarks=overwrite --use_existing_db=0 \
  --db=$dbdir --wal_dir=$dbdir \
  --sync=$sync \
  --bytes_per_sync=8388608 \
  --cache_size=201326592 --cache_numshardbits=6 \
  --open_files=-1 \
  --block_size=4096 \
  --use_direct_io_for_flush_and_compaction=true \
  --compaction_pri=kMinOverlappingRatio \
  --write_buffer_size=$write_buffer_size --max_write_buffer_number=$max_write_buffer_number --min_write_buffer_number_to_merge=$min_write_buffer_number_to_merge \
  --level0_file_num_compaction_trigger=$level0_file_num_compaction_trigger \
  --max_bytes_for_level_base=$max_bytes_for_level_base --max_bytes_for_level_multiplier=8 \
  --target_file_size_base=33554432 \
  --level0_slowdown_writes_trigger=12 \
  --level0_stop_writes_trigger=20 \
  --delayed_write_rate=16777216 \
  --num_levels=6 \
  --max_background_compactions=16 \
  --level_compaction_dynamic_level_bytes=false \
  --max_background_flushes=7 \
  --memtablerep=skip_list \
  --allow_concurrent_memtable_write=$concurrent_mem \
  --enable_write_thread_adaptive_yield=$concurrent_mem \
  --compression_type=snappy --min_level_to_compress=3 --compression_ratio=0.5 \
  --cache_index_and_filter_blocks=0 \
  --bloom_bits=10 \
  --num=104857600  --key_size=$key_size --value_size=$value_size \
  --benchmark_write_rate_limit=0 \
  --num_column_families=$num_column_families \
  --num_hot_column_families=$num_column_families \
  --num_multi_db=$num_multi_db \
  --enable_numa=true \
  --hard_rate_limit=3 \
  --rate_limit_delay_max_milliseconds=1000000 \
   --verify_checksum=1 \
  --duration=$duration_secs \
  --threads=$threads \
  --merge_operator="put" \
  --seed=1454699926 \
  --batch_size=4 \
  --statistics=0 \
  --stats_per_interval=1 --stats_interval_seconds=30 \
  --report_interval_seconds=10 --report_file=${dbdir}/report.csv \
  --report_bg_io_stats=true \
  --histogram=1 > ${dbdir}/BENCHMARK_SUMMARY 2>&1

echo "Benchmark summary available in ${dbdir}/BENCHMARK_SUMMARY"
