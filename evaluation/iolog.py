import sys
import re
import numpy as np

def calculate_io_latency(file_path):
    """
    로그 파일에서 'block_rq_issue'와 'block_rq_complete' 이벤트의 시간 차이를 계산하여
    평균 I/O 지연 시간(latency)을 반환합니다.
    """
    issue_requests = {}
    latencies = []

    # 정규식 패턴: block_rq_issue
    issue_pattern = re.compile(r"(\S+-\d+)\s+\[\d+\]\s+\S+\s+(\d+\.\d+): block_rq_issue: \d+,\d+ \S+ \d+ \(\) (\d+) \+ \d+")
    
    # 정규식 패턴: block_rq_complete
    complete_pattern = re.compile(r"(\S+-\d+)\s+\[\d+\]\s+\S+\s+(\d+\.\d+): block_rq_complete: \d+,\d+ \S+ \(\) (\d+) \+ \d+")
    #cdk: sample 20 elements
    #num_samp=20
    num_com=200

    try:
        with open(file_path, 'r') as file:
            for line in file:
                issue_match = issue_pattern.search(line)
                complete_match = complete_pattern.search(line)
                
                if issue_match:
                    #cdk ; modified
                    process_id, timestamp_str, blk_number = issue_match.groups()
                    #if num_samp > 0:
                    #    print(f"{issue_match}")
                    #   num_samp= num_samp -1 
                    #cdk : print timestamp_str
                    #if num_samp > 0:
                    #    print(f"timestamp+str {timestamp_str}")
                    #    num_samp=num_samp - 1
                    issue_requests[blk_number] = float(timestamp_str), process_id
                    #cdk : print process_id
                    ##if num_samp > 0:
                    #   print(f"Process requested : {process_id} at block {int(blk_number)} , timestamp {float(timestamp_str):.2f}")
                    #   num_samp = num_samp - 1

                elif complete_match:
                    process_id, timestamp_str, blk_number = complete_match.groups()
                #cdk print complet_id
                    #if num_com > 0:
                     #  print(f"Process completed : {process_id} at block {int(blk_number)}, timestamp {float(timestamp_str):.2f}")
                    #  num_com = num_com - 1

                    if blk_number in issue_requests:
                        #cdk : pop with log shown
                        #if num_samp > 0:
                         #   print(f"Finished process: {process_id}")
                          #  num_samp = num_samp - 1

                        issue_timestamp, process_id = issue_requests.pop(blk_number)
                        complete_timestamp = float(timestamp_str)
                        latency = complete_timestamp - issue_timestamp
                        latencies.append(latency)
    
        if not latencies:
            return 0, "계산할 데이터가 충분하지 않습니다."

        average_latency = sum(latencies) / len(latencies)
        print(f"I/O 요청 (max, ms): {max(latencies)}")
        print(f"I/O 요청 (Q1, ms): {np.percentile(latencies, 25)*1000:.3f}")
        print(f"I/O 요청 (Q2, ms): {np.percentile(latencies, 50)*1000:.3f}")
        print(f"I/O 요청 (Q3, ms): {np.percentile(latencies, 75)*1000:.3f}")
        print(f"총 I/O 요청 처리 시간 (s) : {len(latencies) * average_latency:.1f}")
        return average_latency, f"측정된 I/O 요청 수: {len(latencies)}건"
        
    except FileNotFoundError:
        return None, f"오류: '{file_path}' 파일을 찾을 수 없습니다."
    except Exception as e:
        return None, f"오류가 발생했습니다: {e}"

# --- 스크립트 실행 부분 ---
if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(f"사용법: python3 {sys.argv[0]} <로그_파일_이름>")
        sys.exit(1)

    log_file_path = sys.argv[1]
    avg_latency, info = calculate_io_latency(log_file_path)

    if avg_latency is not None:
        print(f"평균 I/O 지연 시간: {avg_latency * 1000:.3f} ms") # 초(s) -> 밀리초(ms) 변환
        print(info)
    else:
        print(info)
