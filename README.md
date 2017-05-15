# RocksDB benchmark scripts and tools
RocksDB benchmark tools and scripts

The main benchmark script is `bench.sh`. The benchmark scripts and tools use `db_bench` tool that is distributed as part of RocksDB. Before the benchmark scripts can be used, RocksDB must be built. The section below lists the steps needed for building RocksDB with the `db_bench` tool.

## Usage

```bash
./bench.sh --help
Usage:
        --db_dir                                The directory where the database files will be created
        --threads                               The number of threads that will be used to run the workload concurrently
        --sync                                  Whether all writes should be synced to disk
        --concurrent_mem_table_writes           Are concurrent writes to memtable allowed
        --num_column_families                   The number of column families to use store the dataset
        --num_multi_db                          The number of RocksDB database instances to use to store the dataset
        --key_size                              The size of each key in bytes
        --value_size                            The size of each value in bytes
        --duration_secs                         The duration in seconds of the benchmark run
        --write_buffer_size                     This sets the size of a single memtable
        --max_write_buffer_number               This sets the maximum number of memtables
        --min_write_buffer_number_to_merge      This is the minimum number of memtables to be merged before flushing to storage
        --help                                  Print this help message
```

## Building RocksDB
RocksDB can be built by following the command below

```bash
apt-get install libjemalloc-dev
git clone https://github.com/facebook/rocksdb.git
cd rocksdb
git checkout v5.3.4
JEMALLOC=1 make release
```

## Examples

### Write Benchmarks with sync enabled
The example below assume that you want to restrict the memory used by memtables to 2GB.

#### 1 RocksDB and 1 Column Family
```bash
./bench.sh --threads=16 --db_dir=/var/lib/rocksdb --sync=1 --concurrent_mem_table_writes=1  --key_size=64 --value_size=1024 --write_buffer_size=134217728 --max_write_buffer_number=16 --min_write_buffer_number_to_merge=2 --num_column_families=1 --num_multi_db=0 --duration_secs=3600
```

#### 1 RocksDB and 32 Column Families
```bash
./bench.sh --threads=16 --db_dir=/var/lib/rocksdb --sync=1 --concurrent_mem_table_writes=1  --key_size=64 --value_size=1024 --write_buffer_size=16777216 --max_write_buffer_number=4 --min_write_buffer_number_to_merge=4 --num_column_families=32 --num_multi_db=0 --duration_secs=3600
```

#### 1 RocksDB and 128 Column Families
```bash
./bench.sh --threads=16 --db_dir=/var/lib/rocksdb --sync=1 --concurrent_mem_table_writes=1  --key_size=64 --value_size=1024 --write_buffer_size=4194304 --max_write_buffer_number=4 --min_write_buffer_number_to_merge=4 --num_column_families=128 --num_multi_db=0 --duration_secs=3600
```

#### 1 RocksDB and 1024 Column Families
```bash
./bench.sh --threads=16 --db_dir=/var/lib/rocksdb --sync=1 --concurrent_mem_table_writes=1  --key_size=64 --value_size=1024 --write_buffer_size=524288 --max_write_buffer_number=4 --min_write_buffer_number_to_merge=4 --num_column_families=1024 --num_multi_db=0 --duration_secs=3600
```

#### 32 RocksDB and 1 Column Family
```bash
./bench.sh --threads=16 --db_dir=/var/lib/rocksdb --sync=1 --concurrent_mem_table_writes=1  --key_size=64 --value_size=1024 --write_buffer_size=16777216 --max_write_buffer_number=4 --min_write_buffer_number_to_merge=4 --num_column_families=1 --num_multi_db=32 --duration_secs=3600
```

#### 128 RocksDB and 1 Column Family
```bash
./bench.sh --threads=16 --db_dir=/var/lib/rocksdb --sync=1 --concurrent_mem_table_writes=1  --key_size=64 --value_size=1024 --write_buffer_size=4194304 --max_write_buffer_number=4 --min_write_buffer_number_to_merge=4 --num_column_families=1 --num_multi_db=128 --duration_secs=3600
```

#### 1024 RocksDB and 1 Column Family
```bash
./bench.sh --threads=16 --db_dir=/var/lib/rocksdb --sync=1 --concurrent_mem_table_writes=1  --key_size=64 --value_size=1024 --write_buffer_size=524288 --max_write_buffer_number=4 --min_write_buffer_number_to_merge=4 --num_column_families=1 --num_multi_db=1024 --duration_secs=3600
```
