# SQLite-Async
SQLite-Async prefetches the corresponding leaf pages identified by the
Final Interior Node, enabling non-blocking and parallel processing of I/O requests to
maximize system throughput and resource utilization. SQLite-Async fur-
ther optimizes data access by enabling concurrent prefetching, thereby
maximizing cache utilization and reducing query latency.

## Features
- **Asynchronous operation**:  
  Vanilla, which was originally synchronous, was modified to perform asynchronously.
  
- **Optimize Read operation**:  
  We optimized SQLite's read operation to achieve better read performance.

- **Seamless Integration with SQLite**:
  The project is designed to work directly with SQLite, enabling transparent and efficient integration without modifying the core database engine.  


- **Parallelism**:  
Maximized parallelism through the utilization of multithreading.


## Getting Started

### Prerequisites
- **SQLite** (latest version from [SQLite GitHub Repository](https://github.com/sqlite/sqlite))
- **Python** (Python 3.8.10 [Python Download Link](https://www.python.org/downloads/release/python-3810/))
- **Linux Kernel** (Working environment requires a recent Linux Kernel with fully implemented $\text{IO\_uring}$ functionality, version 5.1 or later is recommended.)

### Build

1. If the database already exists before switching the current engine, you must first construct the $\text{bitmap}$ table using $\text{init_construct_fin_table_src}$.


2. Clone this repository and navigate to the project directory:
```
cd 
```

2. Configure
```
mkdir bld && cd bld
../src/configure
```

