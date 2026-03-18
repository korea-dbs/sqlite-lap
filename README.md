# SQLite-LAP
SQLite-LAP prefetches the corresponding leaf pages identified by the
Final Interior Node, enabling non-blocking and parallel processing of I/O requests to
maximize system throughput and resource utilization. SQLite-LAP fur-
ther optimizes data access by enabling concurrent prefetching, thereby
maximizing cache utilization and reducing query latency.

## Features
- **Asynchronous operation**:  
  Vanilla, which was originally synchronous, was modified to perform asynchronously.
  
- **Optimize Read operation**:  
  We optimized SQLite's read operation to achieve better read performance.

- **Seamless Integration with SQLite**:
  The project is designed to work directly with SQLite and libSQL enabling transparent and efficient integration without modifying the core database engine.  


- **Parallelism**:  
Maximized parallelism through the utilization of multithreading in FIN-leaf level.


## Getting Started

### Prerequisites
- **SQLite** (latest version from [SQLite GitHub Repository](https://github.com/sqlite/sqlite))
- **libSQL** (latest version from [libSQL GitHub Repository](https://github.com/tursodatabase/libsql)) 
- **Python** (Python 3.8.10 [Python Download Link](https://www.python.org/downloads/release/python-3810/))
- **Linux Kernel** (Working environment requires a recent Linux Kernel with fully implemented IO\_uring functionality, version 5.1 or later is recommended.)

### Build

1. If the database already exists before switching the current engine, you must first construct the $\text{bitmap}$ table using `init\_construct\_fin\_table\_src`.
Please perform a full scan query on all tables within the DB file.
```
CREATE TABLE bitmap_table (
    fippgno INTEGER,
    childpg INTEGER,
    PRIMARY KEY (fippgno,childpg)
);
SELECT * FROM table_name;
```

   


2. Clone this repository and navigate to the project directory:
```
cd SQLite_LAP
```

3. Configure
```
mkdir bld && cd bld
../src/configure
```

4. Select Mode
```
vi Makefile
```
Change  Makefile.

```
CC = gcc
CFLAGS = -g -O2 -pthread -I/usr/include
LIBS += -luring -pthread
```

6. Compile
```
cd ../../bld
make clean && make -j
sudo make install -j
```


## Run

Run the SQLite-LAP
```
cd bld
./sqlite3
```


