import re
import sys
def parse_log_and_calc_bandwidth(file_path):
    issue_pattern = re.compile(
        r"(?P<timestamp>\d+\.\d+): block_rq_issue: \d+,\d+ \w+ \d+ \(\) \d+ \+ (?P<sectors>\d+)"
    )

    total_bytes = 0
    timestamps = []

    with open(file_path, 'r') as f:
        for line in f:
            match = issue_pattern.search(line)
            if match:
                time = float(match.group("timestamp"))
                sectors = int(match.group("sectors"))
                timestamps.append(time)
                total_bytes += sectors * 512  # sector 크기는 512 byte

    if not timestamps:
        print("block_rq_issue 이벤트가 없습니다.")
        return

    duration = max(timestamps) - min(timestamps)
    if duration == 0:
        print("시간 간격이 0입니다.")
        return

    bandwidth_MBps =(total_bytes / duration) / (1024 * 1024)
    print(f"총 전송 바이트: {total_bytes} bytes")
    print(f"시간 구간: {duration:.6f} 초")
    print(f"Bandwidth: {bandwidth_MBps:.2f} MB/s")

# 사용 예시
if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(f"Usage: python {sys.argv[0]} <logfile>")
        sys.exit(1)

    logfile = sys.argv[1]
    parse_log_and_calc_bandwidth(logfile)
