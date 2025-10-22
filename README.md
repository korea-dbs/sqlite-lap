# SQLite-Async
SQLite-Async prefetches the corresponding leaf pages identified by the
Final Interior Node, enabling non-blocking and parallel processing of I/O requests to
maximize system throughput and resource utilization. SQLite-Async fur-
ther optimizes data access by enabling concurrent prefetching, thereby
maximizing cache utilization and reducing query latency.

## Features
- **Asynchronous operation**:  
  The project uses IOuring to  changes in the WAL file and uploads the updated WAL file to a specified AWS S3 bucket.
  
- **Optimize Read operation**:  
  In addition to WAL file synchronization, this project also allows uploading SQL statements to an S3 bucket for further analysis or recovery purposes.

- **Seamless Integration with SQLite**:  


- **Parallelism**:  


- ****:  

