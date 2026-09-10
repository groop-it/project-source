# 현대해상 To-Be 공통 후처리 서버 구성 검토안

## AA × TA 협의용 Architecture / Infrastructure / Risk / Operation Baseline

> **목적**: AS-IS에서 각 업무 서비스/Handler 내부에 분산되어 있던
> FAX·EDMS·Image·Remote 등 후처리를 To-Be의 **공통 후처리 서버(Common
> Post Processing Server)** 로 통합할 때 AA와 TA가 함께 결정해야 할 구성
> 방향, 서버/네트워크/스토리지/가용성, 장애·재처리·성능·운영 리스크를
> 정리한다.
>
> **상태**: 설계 후보(Candidate). 실제 서버 수, L4/VIP, Zone, Storage,
> Port, HA, 처리량, DB 구조는 IDC/TA/OZ/업무/연계 담당자 확인 후
> 확정한다.

------------------------------------------------------------------------

# 1. Architecture 변화의 의미

``` text
AS-IS
Service A → Handler A → FAX
Service B → Handler B → EDMS
Service C → Handler C → Image
Service D → Handler D → Remote

TO-BE
Business / OZ
      ↓
Common Post Processing
      ↓
Dispatcher / State / Retry / Trace
      ↓
FAX / EDMS / Image / Remote Adapter
```

단순 Handler 이전이 아니다. 기존에 서비스별로 분산되어 있던 **실행
책임과 장애 영향, 상태관리, 재처리, 외부연계, 운영 책임이 공통 서비스로
집중**되는 Architecture 변경이다.

핵심 원칙은 다음과 같다.

> **후처리 기능은 중앙화하되 장애는 중앙화하지 않는다.**

공통화 대상: - 요청 표준 - Routing - 상태 - Error Model - Retry
Framework - Logging/Trace - Monitoring - 운영 Governance

격리 대상: - FAX 장애 - EDMS 장애 - Image 고부하 - Remote 장애 -
Adapter별 Thread/Timeout - Retry 폭증 - 외부 시스템별 Resource 사용

------------------------------------------------------------------------

# 2. 권장 Logical Architecture

``` mermaid
flowchart LR
    APP["Business / CIS"]
    OZ["OZ / Report"]
    VIP["L4 / VIP<br/>Candidate"]

    subgraph POST["Common Post Processing Pool"]
        API["Post API / Receiver"]
        DISP["Dispatcher"]
        WORK["Processor / Worker"]
        STATE["State Management"]
        RETRY["Retry / Recovery"]
        TRACE["Log / Trace"]
    end

    FAX["FAX Adapter"]
    EDMS["EDMS Adapter"]
    IMG["Image Adapter"]
    REM["Remote Adapter"]

    APP --> OZ --> VIP --> API
    API --> DISP --> WORK
    WORK --> FAX
    WORK --> EDMS
    WORK --> IMG
    WORK --> REM
    WORK --> STATE
    RETRY --> WORK
    TRACE --- API
    TRACE --- WORK
```

`L4/VIP`는 권장 검토 대상이며 프로젝트 실제 인프라 정책 확인 전 확정하지
않는다.

------------------------------------------------------------------------

# 3. 서버 구성 방향

## 3.1 운영계 단일 Instance의 핵심 Risk

``` text
모든 업무
   ↓
Post Server #1
   ↓
FAX / EDMS / Image
```

-   SPOF
-   점검/배포 시 전체 후처리 중단
-   기존 Handler 구조보다 장애 영향범위 확대
-   Peak 부하 집중
-   Image Conversion 같은 고부하 작업이 다른 후처리에 영향
-   Process Down 시 처리중 상태 유실 가능

따라서 운영계는 **Multi Instance**를 우선 검토한다.

## 3.2 Production Candidate

``` mermaid
flowchart LR
    SRC["Business / OZ"] --> VIP["L4 / VIP"]

    subgraph POOL["Post Processing Pool"]
        P1["Post #1<br/>Stateless"]
        P2["Post #2<br/>Stateless"]
    end

    DB[("Status / Result Store")]
    FS[("Shared Accessible Storage")]

    VIP --> P1
    VIP --> P2
    P1 --> DB
    P2 --> DB
    P1 --> FS
    P2 --> FS

    P1 --> F["FAX"]
    P1 --> E["EDMS"]
    P1 --> I["Image"]
    P2 --> F
    P2 --> E
    P2 --> I
```

권장 검토 방향: - Post Server Multi Instance - Stateless API 우선 - 상태
외부화 - 공통 접근 가능한 파일 영역 - L4/VIP 및 Health Check - Adapter별
장애 격리 - Monitoring/Alert

단, DB와 Storage 자체가 새로운 SPOF가 되지 않도록 TA가
HA/Backup/Recovery를 함께 설계해야 한다.

------------------------------------------------------------------------

# 4. Active-Active / Active-Standby

  구분              Active-Active   Active-Standby
  ----------------- --------------- -----------------
  가용성            높음            높음
  자원 활용         높음            낮음
  Scale-out         용이            제한
  구현 복잡도       높음            상대적으로 낮음
  중복 Claim 방지   필수            상대적으로 단순
  Failover          빠름            전환시간 필요

후처리가 전사 공통 Dependency가 되고 처리량이 충분히 크다면
**Stateless + Active-Active**를 우선 검토하되, 실제 Framework/운영
정책과 외부 연계 특성을 보고 결정한다.

------------------------------------------------------------------------

# 5. Stateless와 상태 영속화

서버 Local Memory에만 다음 정보를 두지 않는 방향을 권장한다.

-   처리상태
-   Retry Count
-   Request Context
-   외부 응답
-   재처리 대상
-   최종 결과

``` text
Post #1 ─┐
         ├── Shared State / Result Store
Post #2 ─┘
```

Node가 Down되어도 다른 Node 또는 Recovery Process가 작업상태를 판단할 수
있어야 한다.

------------------------------------------------------------------------

# 6. 상태 모델

권장 후보:

``` text
READY
PROCESSING
SUCCESS
FAIL
RETRYABLE
UNKNOWN
PARTIAL_SUCCESS
```

``` mermaid
stateDiagram-v2
    [*] --> READY
    READY --> PROCESSING
    PROCESSING --> SUCCESS
    PROCESSING --> FAIL
    PROCESSING --> UNKNOWN
    FAIL --> RETRYABLE
    RETRYABLE --> PROCESSING
    UNKNOWN --> RECONCILE
    RECONCILE --> SUCCESS
    RECONCILE --> RETRYABLE
```

특히 Timeout은 곧 FAIL이 아니다. 외부 시스템이 실제 처리했지만 응답만
유실됐을 수 있으므로 `UNKNOWN`이 필요할 수 있다.

------------------------------------------------------------------------

# 7. Report와 Post 상태 분리

가장 중요한 AA 의사결정이다.

``` text
OZ Report Generation = SUCCESS
Post Processing       = FAIL
```

권장 모델:

``` text
reportStatus
postStatus
finalBusinessStatus
```

  Report    Post          Final 후보     의미
  --------- ------------- -------------- ----------------
  SUCCESS   SUCCESS       SUCCESS        전체 정상
  SUCCESS   FAIL          PARTIAL/FAIL   업무정책 필요
  SUCCESS   UNKNOWN       PENDING        결과 확인 필요
  FAIL      NOT_STARTED   FAIL           발행 자체 실패

이를 ADR로 확정한다.

------------------------------------------------------------------------

# 8. Retry / 중복처리 / Idempotency

``` mermaid
sequenceDiagram
    participant P as Post Server
    participant E as External
    P->>E: FAX/EDMS Request
    E-->>P: External 처리 완료
    Note over P,E: 응답 중 Network Timeout
    P->>P: UNKNOWN
    P->>E: 무조건 Retry?
    Note over E: 중복 FAX/등록 위험
```

반드시 정의: - Retry Owner - Retry Condition - Count / Interval -
Backoff - Idempotency Key - Duplicate Check - UNKNOWN 처리 - Manual
Retry - External Transaction 조회 가능 여부

Trace Key 후보:
`Request ID / GID / IFID / Post Processing ID / External Transaction ID`

------------------------------------------------------------------------

# 9. Transaction Boundary

외부 호출 동안 DB Transaction을 장시간 유지하지 않는 방향을 검토한다.

``` text
TX-1
READY → PROCESSING
COMMIT

External FAX / EDMS / Image Call

TX-2
PROCESSING → SUCCESS / FAIL / UNKNOWN
COMMIT
```

DB Lock/Connection 장기점유와 장애 전파를 줄이는 목적이다.

------------------------------------------------------------------------

# 10. Sync / Async 분류

  후처리             방향 후보         검토 이유
  ------------------ ----------------- -----------------
  단순 Metadata      Sync 가능         짧은 처리
  FAX                Async 우선 검토   외부 처리/Retry
  EDMS               Async 검토        파일/외부연계
  Image Conversion   Async 검토        CPU/File 부하
  Remote             별도 검토         특수 연계
  대량 후처리        Async             처리량

MQ 제품이 확인되지 않았다면 문서에서 `Queue`를 제품 Architecture로
단정하지 않고 `Post Request Store`, `Async Processing Mechanism`처럼
중립적으로 표현한다.

------------------------------------------------------------------------

# 11. 파일 전달 / Storage

공통 서버화에서 TA와 반드시 결정해야 한다.

### A. NAS/Shared Path

`OZ → NAS → Post`

장점: 대용량 파일에 유리.\
Risk: Mount, Permission, Zone, NAS 장애, Path 일관성, Lifecycle.

### B. Binary API

`OZ → HTTP Binary → Post`

Risk: Memory, Timeout, Network, Max Request Size.

### C. Base64

구현은 쉬울 수 있으나 대용량 공통 전달방식으로는 데이터 크기/CPU/Memory
증가를 고려해야 한다.

  기준        NAS       Binary        Base64
  ----------- --------- ------------- ----------------
  대용량      유리      보통          불리
  Memory      유리      주의          주의
  Zone        주의      상대적 유리   상대적 유리
  주요 의존   Storage   Network       Network/Memory

------------------------------------------------------------------------

# 12. Temp / Disk Risk

정의할 항목: - Temp Directory - Max File Size - Disk Threshold -
Retention - Cleanup Schedule - File Naming - Permission - Encryption -
Disk Full Alert - 비정상 종료 시 잔여파일 Cleanup

``` text
Image 대량 처리
 → Temp 누적
 → Disk 100%
 → 공통 Post 전체 장애
```

따라서 Disk Usage는 필수 Monitoring 대상이다.

------------------------------------------------------------------------

# 13. Image Conversion Resource 격리

Image 변환이 CPU/Memory를 많이 사용하면 FAX/EDMS와 동일 Worker Pool을
공유하지 않는 방향을 검토한다.

``` mermaid
flowchart LR
    D["Dispatcher"] --> F["FAX Worker Pool"]
    D --> E["EDMS Worker Pool"]
    D --> I["Image Worker Pool"]
    D --> R["Remote Worker Pool"]
```

필요 시 Image Worker 자체를 별도 Server Pool로 분리한다.

이 구조는 특정 외부 시스템 장애/고부하가 다른 후처리에 전파되지 않게
하는 **Bulkhead** 관점이다.

------------------------------------------------------------------------

# 14. Timeout 계층

Timeout을 하나의 값으로 관리하지 않는다.

``` text
Business/Application Timeout
Post API Timeout
Worker Timeout
External Connect Timeout
External Read Timeout
Image Conversion Timeout
```

AA는 Timeout의 논리 관계와 실패상태를 정의하고 실제 값은
성능시험/TA/외부 시스템 SLA와 함께 확정한다.

------------------------------------------------------------------------

# 15. Capacity Planning

TA와 반드시 확보할 데이터:

-   일 평균 건수
-   Peak TPS
-   Peak 동시처리
-   FAX/EDMS/Image별 비율
-   평균/최대 파일 크기
-   평균/P95/P99 처리시간
-   외부 시스템 최대 응답시간
-   Retry율
-   보관기간
-   예상 증가율

부하시험은 평균이 아니라 **Peak + 외부 시스템 지연 + 대용량 파일**
조건을 포함한다.

------------------------------------------------------------------------

# 16. L4/VIP / Health Check

TA 협의: 1. Post 앞 L4/VIP 필요 여부 2. Health Check URI/Port 3. TCP
Check vs Application Readiness 4. Drain 지원 5. Sticky Session 필요 여부
6. Node Down 시 처리중 Request 7. VIP HA 8. Connection Timeout 9.
Internal/External Routing

Health는 구분한다.

``` text
Liveness  : Process/JVM이 살아 있는가?
Readiness : 신규 요청을 받을 수 있는가?
Dependency: DB/Storage/FAX/EDMS 상태는?
```

FAX 장애 하나 때문에 Post Server 전체를 L4에서 제외할지 여부도 정책으로
정한다.

------------------------------------------------------------------------

# 17. Network / Firewall / Zone

공통화 전: `각 업무 WAS → 각 외부 시스템`

공통화 후: `Business/OZ → Post VIP → Post → FAX/EDMS/Image/DB/Storage`

따라서 Firewall Matrix가 변경된다.

  Source   Destination   Port   Protocol     Purpose        Status
  -------- ------------- ------ ------------ -------------- --------
  OZ/WAS   Post VIP      TBD    HTTP/S TBD   Post Request   TBD
  Post     FAX           TBD    TBD          FAX            TBD
  Post     EDMS          TBD    TBD          EDMS           TBD
  Post     NAS           TBD    FS TBD       File           TBD
  Post     DB            TBD    JDBC         State          TBD

외부 Zone에서 내부 Post Server 접근이 불가능하면 Gateway/Relay 또는
Zone별 Instance가 필요할 수 있다.

------------------------------------------------------------------------

# 18. Security / Audit

-   호출주체 인증/인가
-   User Context 전달
-   GID/IFID 추적
-   개인정보 포함 파일 보호
-   Sensitive Parameter/Log Masking
-   TLS
-   NAS/Temp Permission
-   관리자 재처리 권한
-   Audit Log
-   Credential 관리
-   파일 보존/삭제 정책

------------------------------------------------------------------------

# 19. Logging / Observability

권장 추적 체인:

``` text
GID
 └─ IFID
    └─ Report Request ID
       └─ Post Processing ID
          └─ Adapter Transaction ID
             └─ External Transaction ID
```

로그만으로 "OZ 생성 성공 후 FAX가 왜 실패했는가?"를 End-to-End로 추적할
수 있어야 한다.

Monitoring: - CPU/Memory/JVM/GC/Thread - Disk/Network -
READY/PROCESSING/SUCCESS/FAIL/UNKNOWN - Retry Count - Adapter별
Success/Fail - P95/P99 - Pending Count - External Timeout

Alert: - Node Down - Health Fail - DB/Storage Fail - Disk Threshold -
Pending 급증 - FAIL/UNKNOWN 증가 - Retry Storm - External Timeout 증가

------------------------------------------------------------------------

# 20. 배포 / Graceful Shutdown

Active-Active라면 Node Drain 기반 Rolling Deploy를 검토한다.

``` text
1. L4에서 Node Drain
2. 신규 Request 차단
3. Processing 완료 대기
4. 미완료 상태 영속화
5. Deploy/Restart
6. Health/Readiness 확인
7. L4 재투입
8. 다음 Node 반복
```

강제 종료만 허용하면 배포 때마다 `UNKNOWN` 작업이 발생할 수 있다.

------------------------------------------------------------------------

# 21. Recovery / DR

TA 협의: - State DB HA/Backup - Storage HA/Backup - Post Server
Recovery - DR 대상 여부 - RTO/RPO - 미완료 건 Recovery - External
Reconciliation - DR 전환 시 중복 방지 - 수동 재처리 기능

------------------------------------------------------------------------

# 22. 주요 장애 시나리오

### Node 1 Down

신규 요청은 다른 Node로 우회하고 미완료 작업 Recovery 기준 필요.

### DB Down

신규 요청을 받을지 Fail-fast할지 결정.

### NAS Down

신규 파일 후처리 중단/Retry/Fallback 정책 결정.

### FAX Down

FAX만 격리하고 EDMS/Image는 정상 동작하도록 설계 검토.

### External Timeout

즉시 재시도하지 않고 UNKNOWN/Reconciliation 정책 적용.

### Disk Full

파일 기반 작업 차단 + Alert + Cleanup.

### Retry Storm

외부 복구 직후 실패 건이 동시에 재처리되지 않도록 Backoff/Concurrency
Limit 검토.

------------------------------------------------------------------------

# 23. Risk Register

  --------------------------------------------------------------------------------
  ID             Risk           영향           대응 방향            협의
  -------------- -------------- -------------- -------------------- --------------
  POST-R01       Post SPOF      전체 후처리    Multi Instance/L4    TA
                                중단                                

  POST-R02       State DB SPOF  상태관리 중단  HA/Recovery          TA/DB

  POST-R03       Storage SPOF   파일 처리 중단 HA/Fallback          TA

  POST-R04       Retry 중복     FAX/EDMS 중복  Idempotency          AA/업무

  POST-R05       Handler 로직   업무오류       AS-IS Inventory      AA/업무
                 누락                                               

  POST-R06       Image CPU 폭증 전체 지연      Worker 격리          AA/TA

  POST-R07       Temp Disk Full 서버 장애      Cleanup/Alert        TA

  POST-R08       외부 장애 전파 전체 영향      Bulkhead             AA

  POST-R09       Timeout        중복/누락      UNKNOWN/Reconcile    AA
                 결과불명                                           

  POST-R10       ACL/Port 누락  연계 실패      Network Matrix       TA

  POST-R11       Zone 제약      접근 불가      Gateway/분리         TA

  POST-R12       배포중         데이터 누락    Graceful Shutdown    AA/TA
                 처리유실                                           

  POST-R13       개인정보 파일  보안 Risk      권한/암호화          보안

  POST-R14       Peak 과부하    지연/장애      Capacity/Scale       TA

  POST-R15       공통 변경 영향 다수 시스템    Version/Regression   AA/QA
                                장애                                
  --------------------------------------------------------------------------------

------------------------------------------------------------------------

# 24. AS-IS Handler → To-Be Mapping

공통 서버 개발 전에 반드시 작성한다.

  --------------------------------------------------------------------------------------------------------------------
  System   Service   Handler        기능    Input   Output   External   File   Retry   Error   To-Be Adapter  Status
  -------- --------- -------------- ------- ------- -------- ---------- ------ ------- ------- -------------- --------
  TBD      TBD       FaxHandler     FAX     TBD     TBD      FAX        TBD    TBD     TBD     FaxAdapter     분석

  TBD      TBD       EdmsHandler    EDMS    TBD     TBD      EDMS       TBD    TBD     TBD     EdmsAdapter    분석

  TBD      TBD       ImageHandler   Image   TBD     TBD      Image      TBD    TBD     TBD     ImageAdapter   분석
  --------------------------------------------------------------------------------------------------------------------

숨은 로직 확인: - 업무 조건/채널 예외 - 파일명/Path - Encoding -
Header/User ID 보정 - Timeout/Retry - 결과코드 변환 - DB 상태 Update -
특정 Parameter - 로그/보정 로직

------------------------------------------------------------------------

# 25. 공통 Post API 논리 모델

``` json
{
  "requestId": "REQ-...",
  "gid": "...",
  "ifId": "...",
  "systemId": "...",
  "userId": "...",
  "reportId": "...",
  "postType": "FAX",
  "file": {
    "type": "PATH",
    "format": "TIFF",
    "location": "..."
  },
  "destination": {},
  "options": {}
}
```

실제 필드는 업무/보안/OZ/연계 분석 후 확정한다.

Error Model 후보:

``` json
{
  "requestId": "...",
  "postProcessingId": "...",
  "status": "FAIL",
  "error": {
    "category": "EXTERNAL_TIMEOUT",
    "code": "...",
    "message": "...",
    "retryable": true
  }
}
```

------------------------------------------------------------------------

# 26. 성능 / Failure Test

필수 시나리오: - Normal - Peak - Burst - Large File - Image Heavy -
External Slow - External Timeout - Node Down - DB Slow/Down - NAS
Slow/Down - Retry Storm - Rolling Deploy

측정:
`TPS / Throughput / P95 / P99 / CPU / Memory / Thread / DB Connection / File I/O / Pending / Error / Recovery Time`

------------------------------------------------------------------------

# 27. R&R

  항목                   AA    TA    업무   연계   QA
  ---------------------- ----- ----- ------ ------ -----
  Logical Architecture   A/R   C     C      C      C
  Server/Node            C     A/R   \-     \-     C
  L4/VIP                 C     A/R   \-     \-     C
  Handler Inventory      A     \-    R      C      C
  Post API               A/R   C     C      C      C
  Adapter                C     \-    C      A/R    C
  Status/Retry           A     C     C      C      R
  Storage/Network        C     A/R   \-     C      C
  Capacity               C     A/R   C      C      R
  E2E                    A     C     R      R      A/R

------------------------------------------------------------------------

# 28. TA 회의 체크리스트

## Server / HA

-   [ ] 운영 Instance 수
-   [ ] Active-Active / Standby
-   [ ] CPU/MEM/JVM
-   [ ] Process/Worker 분리
-   [ ] Scale-out 기준

## L4

-   [ ] VIP
-   [ ] Liveness/Readiness
-   [ ] Drain
-   [ ] Failover
-   [ ] Sticky Session 필요 여부

## Network / Zone

-   [ ] Internal/External Zone
-   [ ] Firewall/Port
-   [ ] Routing
-   [ ] Gateway/Relay 필요 여부

## Storage

-   [ ] NAS/API/Binary 방식
-   [ ] Temp
-   [ ] Permission
-   [ ] Capacity
-   [ ] HA/Backup

## Operation

-   [ ] Monitoring/Alert
-   [ ] Rolling Deploy
-   [ ] Graceful Shutdown
-   [ ] Recovery
-   [ ] DR/RTO/RPO

------------------------------------------------------------------------

# 29. AA 체크리스트

-   [ ] AS-IS Handler Inventory
-   [ ] Handler→Adapter Mapping
-   [ ] Post Type
-   [ ] API Contract
-   [ ] Status/Error Model
-   [ ] Report/Post/Final Status
-   [ ] Retry/UNKNOWN
-   [ ] Idempotency
-   [ ] Transaction Boundary
-   [ ] Sync/Async
-   [ ] Trace ID
-   [ ] API Versioning
-   [ ] Manual Reprocessing
-   [ ] Regression/E2E

------------------------------------------------------------------------

# 30. 주요 ADR

``` text
ADR-POST-001  Post Server HA
ADR-POST-002  L4/VIP
ADR-POST-003  State Storage
ADR-POST-004  File 전달 방식
ADR-POST-005  Sync/Async 기준
ADR-POST-006  Retry/UNKNOWN
ADR-POST-007  Report/Post Final Status
ADR-POST-008  Image Worker 분리
ADR-POST-009  Internal/External Zone
ADR-POST-010  Graceful Shutdown/Recovery
ADR-POST-011  Idempotency
ADR-POST-012  Manual Reprocessing
```

------------------------------------------------------------------------

# 31. 단계별 추진

``` mermaid
flowchart LR
    D["1. Discovery<br/>Handler/Volume/Interface"]
    A["2. Architecture<br/>API/State/HA/Storage"]
    P["3. Prototype<br/>FAX or EDMS 1종"]
    T["4. Failure/Load Test"]
    M["5. Migration<br/>Handler별 순차전환"]
    O["6. Operation<br/>Monitor/Recovery"]

    D --> A --> P --> T --> M --> O
```

공통 서버를 한 번에 전 업무로 전환하기보다 후처리 한 종류를 Pilot으로
검증하고 확대하는 것이 리스크를 낮춘다.

------------------------------------------------------------------------

# 32. 최종 권장 방향

현재 AA 관점의 설계 후보:

``` text
Business / OZ
      ↓
L4 / VIP
      ↓
Post Processing Pool
 ├─ Post #1 (Stateless)
 └─ Post #2 (Stateless)
      ↓
Shared State / Result
      ↓
Accessible File Storage
      ↓
Adapter / Worker
 ├─ FAX
 ├─ EDMS
 ├─ Image
 └─ Remote
      ↓
Monitoring / Alert / Recovery
```

### Architecture 핵심

**Centralize** - API - Routing - State - Logging - Monitoring -
Governance

**Isolate** - External Failure - Heavy Workload - Retry -
Thread/Resource - Adapter Failure

즉 To-Be 공통 후처리 서버를 단순 `Handler Server`가 아니라 다음과 같은
**Post Processing Platform**으로 정의하는 것이 적절하다.

``` text
Post Processing Platform
=
Standard Request
+ Dispatcher
+ Adapter
+ State
+ Retry
+ Recovery
+ Trace
+ Monitoring
+ HA
```

------------------------------------------------------------------------

# 33. TA 회의에서 바로 사용할 핵심 질문

> **서버/HA**\
> 공통 후처리가 전 업무의 공통 Dependency가 되므로 운영계 단일 서버인지
> Multi Instance인지, L4/VIP 기반 Active-Active 구성이 가능한지 확인이
> 필요합니다.

> **Storage**\
> OZ 결과파일을 Post Server가 NAS/Local/API 중 어떤 방식으로 접근할지와
> Internal/External Zone에서 동일 경로 접근이 가능한지 확인이
> 필요합니다.

> **Recovery**\
> 처리 도중 Node가 Down될 경우 다른 Node가 미완료 작업을 판단하고
> 재처리할 수 있도록 상태를 어디에 영속화할지 결정해야 합니다.

> **Capacity**\
> FAX·EDMS·Image를 같은 서버군에서 처리할 경우 Image 변환 부하가 다른
> 후처리에 영향을 줄 수 있으므로 Peak TPS/파일크기/CPU/MEM 및 Worker
> 분리 기준이 필요합니다.

> **Network**\
> 기존 업무 WAS별 외부 연계가 Post Server로 집중되므로
> Source/Destination/Port/Firewall Matrix를 다시 확인해야 합니다.

> **운영**\
> 배포와 재기동 시 처리중 건을 보호하기 위한 Drain, Graceful Shutdown,
> Recovery, Manual Reprocessing 기준이 필요합니다.

------------------------------------------------------------------------

# 34. Definition of Done

-   [ ] AS-IS Handler Inventory 완료
-   [ ] Handler→Adapter Mapping 완료
-   [ ] Post API 정의
-   [ ] Status/Error Model 정의
-   [ ] Report/Post/Final Status 결정
-   [ ] Retry/UNKNOWN/Idempotency 결정
-   [ ] Sync/Async 결정
-   [ ] File 전달방식 결정
-   [ ] Temp/Cleanup 결정
-   [ ] Multi Instance/HA 결정
-   [ ] L4/VIP/Health 결정
-   [ ] State DB/Storage HA 결정
-   [ ] Network/Firewall Matrix 완료
-   [ ] Zone Routing 확정
-   [ ] Capacity 산정
-   [ ] Image Worker 분리 여부 결정
-   [ ] Monitoring/Alert 정의
-   [ ] Graceful Shutdown/Recovery 정의
-   [ ] Manual Reprocessing 정의
-   [ ] Load/Failure/E2E Test 완료
-   [ ] Cutover/Rollback 계획 완료
-   [ ] ADR 확정
-   [ ] AA/TA/업무/연계 R&R 확정
