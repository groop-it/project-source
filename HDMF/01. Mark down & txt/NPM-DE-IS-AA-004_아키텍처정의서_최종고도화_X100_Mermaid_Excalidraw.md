# NPM-DE-IS-AA-004 아키텍처 정의서 최종 고도화 보완안

## 현대해상 차세대 통합 발행물 · OZ · EDMS/FAX · MCMS · 배포/운영 · Migration · Governance

### Mermaid + Excalidraw 설계 명세 포함

> **문서 성격**: 기존
> `NPM-DE-IS-AA-004-아키텍처정의서-재구성초안-v0.2(2).pptx`의 내용을
> 폐기하거나 축약하지 않고, AA 관점에서 최종 설계문서로 발전시키기 위한
> 고도화 보완안이다.\
> **기준 상태**: 설계단계 / Draft\
> **핵심 원칙**: 기존 상세자료 유지 + Architecture Hierarchy 강화 + OZ
> 중심 공통구조 정립 + 특수/예외 흐름 분리 +
> Migration/Verification/Governance 연결\
> **주의**: 본 문서에서 `TBD`, `Candidate`, `확인 필요`로 표시한 내용은
> 현대해상 IDC/TA/OZ/업무/연계 담당자 또는 실제 소스·설정·솔루션 가이드
> 확인 전까지 확정 아키텍처로 간주하지 않는다.

------------------------------------------------------------------------

# 0. Executive Summary

현재 재구성 초안의 문제는 기술 내용이 부족한 것이 아니다. 이미 문서에는
차세대 통합 발행물, OZ Viewer, OZ eForm, Scheduler, Async, Post
Processing, EDMS/FAX, MCMS, Deployment, NAS/OZR, Migration, Requirement
Traceability, ADR/Risk/TBD까지 주요 영역이 포함되어 있다.

최종 고도화에서 필요한 것은 **각 기술 요소를 더 많이 추가하는 것보다,
다음 다섯 관계를 명확히 만드는 것**이다.

``` mermaid
flowchart LR
    R["Requirement"] --> A["Architecture"]
    A --> D["Architecture Decision"]
    D --> M["Migration / Detail Design"]
    M --> V["Verification"]
    V --> E["Evidence / Operation"]
    E -. "Feedback" .-> A
```

즉 이 문서는 단순한 구성도 모음이 아니라 다음 질문에 답할 수 있어야
한다.

1.  왜 이 구조를 선택했는가?
2.  AS-IS에서 무엇이 바뀌는가?
3.  공통 구조와 시스템별 예외는 무엇인가?
4.  OZ Viewer, Scheduler, Async, 후처리는 각각 어떤 책임을 갖는가?
5.  장애·Timeout·Retry·부분성공은 어떻게 정의되는가?
6.  RD/MRD/XML/JSP/NAS 등 Legacy 요소가 어디에 남아 있는가?
7.  어떤 요구사항이 어느 Architecture와 ADR에 반영되었는가?
8.  무엇을 테스트해야 전환 완료라고 할 수 있는가?
9.  AA와 TA, 업무, OZ 공통, 연계 담당자의 책임 경계는 어디인가?
10. 아직 결정되지 않은 것은 무엇이며 누가 언제 확정해야 하는가?

최종 문서의 중심 메시지는 다음과 같이 정리한다.

> **현대해상 차세대 통합 발행물 Architecture는 업무 채널이 OZ를 직접
> 이해하도록 만드는 구조가 아니라, Application/Common Layer가 발행
> 요청을 표준화하고 OZ Viewer/eForm/Scheduler/후처리 영역을 공통화하며
> FAX·EDMS·Image·MCMS·Remote 등 외부 연계를 책임 경계에 따라 분리하는
> 구조로 정의한다.**

------------------------------------------------------------------------

# 1. 문서 목적과 범위

## 1.1 목적

본 Architecture Definition은 현대해상 차세대 통합 발행물 및 관련 연계
영역의 To-Be Application Architecture를 정의하고, 다음 이해관계자 간
공통 기준을 제공하는 것을 목적으로 한다.

-   AA
-   업무 개발팀
-   OZ 공통/솔루션 담당
-   TA/IDC
-   EDMS/FAX/Image/MCMS 연계 담당
-   테스트/품질 담당
-   감리/검토 담당

## 1.2 Architecture 범위

### 포함

-   업무/CIS와 통합 발행물 간 논리 관계
-   Application/Gateway/Framework 역할
-   OZ Viewer/eForm/Scheduler/전처리/처리/후처리
-   Preview/Print/Export/Async/Remote 처리
-   EDMS/FAX/Image/MCMS/EMS 연계
-   WEB/WAS/OZ/L4/VIP/NAS 논리 배치
-   MRD→OZR, RD→OZ Migration
-   XML→JSON 및 Parameter/Endpoint Migration
-   Requirement Traceability
-   ADR/Risk/TBD
-   Verification 및 운영 관점

### TA 상세로 분리

-   물리 서버 상세 Spec
-   CPU/MEM sizing 확정
-   Network 장비 상세
-   실제 Firewall/Port 정책
-   Storage 물리 구성
-   HA 제품/장비 상세
-   Backup 제품/정책 상세

------------------------------------------------------------------------

# 2. Architecture 표현 체계 --- L0\~L5

Architecture Diagram을 모두 같은 수준에서 표현하지 않는다.

  -----------------------------------------------------------------------
  Level             명칭              핵심 질문         주요 독자
  ----------------- ----------------- ----------------- -----------------
  L0                System Context    누가 누구와       전체
                                      연결되는가?       

  L1                Application       Application       AA/개발
                    Logical           영역의 책임은     
                                      무엇인가?         

  L2                Solution/Domain   OZ 영역은 어떤    AA/OZ
                                      기능으로          
                                      구성되는가?       

  L3                Component         각 Component가    개발/OZ
                                      무엇을            
                                      책임지는가?       

  L4                Processing Flow   요청이 실제로     개발/테스트
                                      어떤 순서로       
                                      처리되는가?       

  L5                Deployment        어느 논리         AA/TA/IDC
                                      노드/Zone에       
                                      배치되는가?       
  -----------------------------------------------------------------------

## 2.1 Diagram 작성 규칙

모든 Architecture 장표에 다음 메타정보를 표시한다.

``` text
Architecture Level : L0 ~ L5
Architecture Status: AS-IS / TO-BE / Candidate / TBD
Scope              : Common / System Specific
Owner              : AA / TA / OZ / Business / Integration
Related Requirement: AA-REQ-xxx
Related ADR        : ADR-OZ-xxx
Verification       : TEST-xxx
```

## 2.2 상태 표기

  표기        의미
  ----------- ------------------------
  CONFIRMED   근거 확인 및 합의 완료
  CANDIDATE   설계 후보
  TBD         확인 필요
  LEGACY      AS-IS 잔존
  NEW         To-Be 신규
  CHANGED     기존 대비 변경
  RETAINED    기존 유지

------------------------------------------------------------------------

# 3. Architecture Principle

기존 초안의 Application, Interface, Report, Operation 원칙을 단순
기술목록이 아니라 Architecture 판단기준으로 연결한다.

## 3.1 Application Principle

-   Java/OpenJDK 21 이상을 기준으로 한다.
-   Hi2 Framework(BXM) 적용 방향을 유지한다.
-   MVC + JSP/JSTL 기반 구조는 실제 프로젝트 표준에 따라 적용한다.
-   Legacy Java API 및 `javax.*` 의존성은 Java 21 전환 시 별도 영향분석
    대상으로 관리한다.
-   공통 발행 기능은 업무화면에 중복 구현하지 않고 공통
    Component/Adapter를 우선한다.

## 3.2 Interface Principle

-   JSON을 기본 데이터 교환 형식으로 사용하고 XML은 필요 시 유지한다.
-   EAI를 기본 연계 방식으로 두되 실제 시스템별 Direct/API/기타
    Protocol은 Mapping한다.
-   Endpoint, Parameter, Timeout, Retry, Error Code를 Interface
    Definition의 필수 속성으로 관리한다.
-   단순 문법 변환이 아니라 **의미 보존(Semantic Preservation)** 을
    Migration 원칙으로 한다.

## 3.3 Report Principle

-   OZ Viewer는 HTML5 기반 Viewer 방향으로 정의한다.
-   서버 측 데이터 바인딩을 기준으로 실제 호출 순서를 검증한다.
-   Preview와 Print/Export는 동일 Flow로 뭉치지 않고 별도 시나리오로
    검증한다.
-   대량/장시간 발행은 Scheduler/Async 영역을 분리한다.
-   후처리는 발행 성공 여부와 별도의 결과상태를 가질 수 있도록 설계한다.

## 3.4 Operation Principle

-   GID/IFID 등 추적키를 이용한 End-to-End Logging 기준을 둔다.
-   Timeout은 Client/Application/OZ/Scheduler/External Integration별로
    분리한다.
-   Retry는 "누가 Retry하는가"를 명시한다.
-   동일 요청 중복발행 가능성이 있는 Retry는 Idempotency/Request ID
    관점으로 관리한다.
-   장애 시 UNKNOWN 상태가 발생할 수 있는 외부 호출은 자동 재시도 전에
    실제 처리 여부를 확인할 수 있어야 한다.

------------------------------------------------------------------------

# 4. AS-IS → TO-BE 변화 모델

  ----------------------------------------------------------------------------------
  영역              AS-IS                        TO-BE 방향        Architecture 보완
  ----------------- ---------------------------- ----------------- -----------------
  Report            RD / MRD / Crownix           OZ / OZR / eForm  Migration Matrix

  Viewer            PDF/Base64/PDF.js 혼재 가능  OZ HTML5 Viewer   실제 사용화면
                                                                   확인

  Scheduler         개별/직접 호출 가능성        L4/VIP →          Health/Failover
                                                 Scheduler Pool    TBD

  Data              XML/Legacy 전문              JSON 기본, XML    Semantic Mapping
                                                 가능              

  Source            ReportingServerInvoker/JSP   OZ Adapter/API    Source Conversion

  Endpoint          분산 JSP/Domain              표준 Gateway/VIP  Endpoint Mapping

  Storage           NAS/API/Local 혼재           OZR Local/NAS/API Distribution
                                                 정책              Matrix

  Post              FAX/EDMS/Image 등            후처리 표준화     Result/Retry 표준

  Verification      수동 비교                    Diff/E2E          Evidence 관리
  ----------------------------------------------------------------------------------

------------------------------------------------------------------------

# 5. L0 --- System Context

## 5.1 목적

26개 To-Be 대상 시스템을 한 장에 모두 상세하게 그리지 않는다. L0에서는
**업무 채널 → 통합 발행물 → 외부/공통 시스템**의 경계만 보여준다.

## 5.2 대상 시스템 Inventory

1.  하이포탈+
2.  영업포탈
3.  보상포탈
4.  (보상)PRM 포탈
5.  (보상)출동포탈
6.  (보상)현출포탈
7.  (보상)모바일 하이유피
8.  (보상)모바일사고조회
9.  일반손사포탈
10. 장기손사포탈
11. 일반손사포탈PRM
12. 장기손사포탈PRM
13. MDS
14. TM영업포탈
15. 기업보험(B2B)홈페이지
16. 다이렉트 모바일
17. 다이렉트 홈페이지
18. 대표홈페이지
19. 디지털창구
20. 상담원관리
21. 여신시스템
22. 퇴직연금시스템
23. 하이콜 / 하이콜모바일
24. 보상원격발행
25. 보이는TM
26. 종합감사시스템

## 5.3 Mermaid --- System Context

``` mermaid
flowchart LR
    subgraph CIS["Channels / CIS"]
        PORTAL["업무 포탈군"]
        CLAIM["보상/손사 계열"]
        SALES["영업/TM 계열"]
        DIGITAL["홈페이지/모바일/디지털창구"]
        MDS["MDS"]
        SPECIAL["원격발행/보이는TM/기타 특수"]
    end

    subgraph REPORT["Integrated Report Boundary"]
        APP["Application / Gateway"]
        COMMON["Report Common Layer"]
        OZV["OZ Viewer"]
        OZE["OZ eForm"]
        SCH["OZ Scheduler"]
        ASYNC["Async"]
        POST["Post Processing"]
    end

    subgraph EXT["External / Common"]
        FAX["FAX"]
        EDMS["EDMS"]
        IMG["Image Convert"]
        MCMS["MCMS"]
        EMS["EMS"]
        REMOTE["Remote"]
        STORAGE["NAS / OZR"]
    end

    CIS --> APP
    APP --> COMMON
    COMMON --> OZV
    COMMON --> OZE
    OZE --> SCH
    COMMON --> ASYNC
    SCH --> POST
    ASYNC --> POST
    POST --> FAX
    POST --> EDMS
    POST --> IMG
    POST --> EMS
    POST --> REMOTE
    EDMS --> MCMS
    OZE --> STORAGE
```

## 5.4 Excalidraw 명세

``` text
CANVAS: 1600 x 900

[ZONE-01] x=40 y=80 w=350 h=720
Title: Channels / CIS
Children:
- 업무 포탈군
- 보상/손사 계열
- 영업/TM 계열
- 홈페이지/모바일
- MDS
- 특수/원격

[ZONE-02] x=450 y=80 w=650 h=720
Title: Integrated Report Boundary
Children:
- Application/Gateway
- Report Common
- OZ Viewer
- OZ eForm
- Scheduler
- Async
- Post Processor

[ZONE-03] x=1160 y=80 w=380 h=720
Title: External / Common
Children:
- FAX
- EDMS
- Image
- MCMS
- EMS
- Remote
- NAS/OZR

PRIMARY FLOW:
CIS → Application → Common → OZ
POST FLOW:
OZ → Post → FAX/EDMS/Image/EMS/Remote
STORAGE FLOW:
OZ → NAS/OZR
```

------------------------------------------------------------------------

# 6. 시스템 유형화 --- Common Architecture와 Exception 분리

26개 시스템별로 Architecture를 26장 만드는 대신 공통 Capability 기준으로
유형화한다.

  Type   의미          Capability
  ------ ------------- ----------------------------
  A      Standard OZ   Viewer / Print / Export
  B      Async         Standard + 장시간/대량
  C      FAX           Standard + FAX
  D      Image/EDMS    Standard + Image/EDMS
  E      Remote        원격발행
  F      Special       MCMS/특수 Viewer/특수 연계

> 실제 각 시스템이 어느 Type에 속하는지는 업무/소스 분석 후 확정한다.

## 6.1 Capability Matrix 권장

  ----------------------------------------------------------------------------------------------------------
  System      Viewer   Print   Export   Scheduler   Async   FAX   EDMS   Image   Remote   Special   Status
  ----------- -------- ------- -------- ----------- ------- ----- ------ ------- -------- --------- --------
  하이포탈+   TBD      TBD     TBD      TBD         TBD     TBD   TBD    TBD     \-       \-        분석중

  보상포탈    TBD      TBD     TBD      TBD         TBD     TBD   TBD    TBD     TBD      TBD       분석중

  MDS         TBD      TBD     TBD      TBD         TBD     TBD   TBD    TBD     TBD      TBD       분석중

  ...                                                                                               
  ----------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------

# 7. L1 --- Application Logical Architecture

``` mermaid
flowchart TB
    C["Client Tier<br/>UI / OZ Viewer / Client Agent"]
    A["Application Tier<br/>WEB/WAS / Gateway / Dispatcher / Framework"]
    I["Internal I/F Tier<br/>EAI / Direct / Protocol"]
    B["Biz Service Tier<br/>Endpoint / Executor / Main/Sub Service"]
    X["Integration Tier<br/>DBIO / Rule / EDMS / FAX / External"]

    C -->|"JSON / Request"| A
    A -->|"VO / Standard Message"| I
    I -->|"Internal Message"| B
    B -->|"DB / API / Integration"| X
    X -->|"Result"| B
    B -->|"Business Response"| A
    A -->|"JSON / Viewer Response"| C
```

## 7.1 반드시 보완할 것

화살표마다 가능한 경우 다음 메타정보를 붙인다.

-   Protocol
-   Data Format
-   Endpoint
-   Timeout
-   Retry
-   Owner
-   Security
-   Logging Key
-   Sync/Async

------------------------------------------------------------------------

# 8. L2/L3 --- OZ Application Architecture

## 8.1 논리 구성

``` mermaid
flowchart LR
    REQ["Report Request"]
    PRE["PreProcessor<br/>Validation / Request Build"]
    EF["OZ eForm Server<br/>Form / Data Binding"]
    VIEW["OZ Viewer<br/>HTML5 Preview"]
    PROC["Processor<br/>Issue / Export"]
    VIP["L4 / VIP"]
    SCH["Scheduler Pool"]
    POST["Post Processor<br/>Routing / Result"]

    REQ --> PRE
    PRE --> EF
    EF --> VIEW
    EF --> PROC
    EF --> VIP
    VIP --> SCH
    PROC --> POST
    SCH --> POST
```

## 8.2 Component Responsibility Matrix

  -----------------------------------------------------------------------------------------------------
  Component      주요 책임        입력             출력            Failure        Owner      상태
  -------------- ---------------- ---------------- --------------- -------------- ---------- ----------
  Viewer         Preview          Viewer Request   HTML5           Viewer Error   OZ         확인

  eForm          Form/Data        Form/Parameter   Bound Report    Form/Data      OZ         확인
                 Binding                                           Error                     

  Scheduler      분산/예약/대량   Job              Result          Timeout/Node   OZ/TA      상세 TBD
                 처리                                              Error                     

  PreProcessor   요청 전처리      Raw Request      Normalized      Validation     TBD        구현확인
                                                   Request                                   

  Processor      발행/변환        Form/Data        PDF/TIFF/etc.   Generation     TBD        구현확인
                                                                   Error                     

  Post Processor 후처리 Routing   Report Result    Integration     Partial/Fail   TBD        구현확인
                                                   Result                                    
  -----------------------------------------------------------------------------------------------------

------------------------------------------------------------------------

# 9. L4 --- Viewer / Preview Flow

## 9.1 AS-IS Candidate

``` mermaid
flowchart LR
    UI["업무화면"] --> RD["RD 호출"]
    RD --> PDF["PDF Binary"]
    PDF --> B64["Base64"]
    B64 --> V["PDF.js / Viewer"]
```

## 9.2 TO-BE Candidate

``` mermaid
flowchart LR
    UI["업무화면"] --> VR["OZ Viewer Request"]
    VR --> EF["OZ eForm Server"]
    EF --> DB["Server Data Binding"]
    DB --> H["HTML5 Rendering"]
```

## 9.3 확정 전 확인

-   실제 Base64 사용 화면
-   PDF.js 사용 화면
-   Viewer API/Parameter
-   서버 데이터 바인딩 실제 순서
-   Framework 조회전문 연계
-   Browser 호환
-   첫 화면 응답
-   전체 렌더링 시간
-   Network bytes
-   Client CPU
-   Server CPU

------------------------------------------------------------------------

# 10. L4 --- Report Issuance / Print / Export

``` mermaid
flowchart LR
    UI["업무화면"]
    REQ["Report Request"]
    GW["Gateway / Framework"]
    EF["OZ eForm"]
    PROC["Processor"]
    TYPE{"Output Type"}
    PRINT["Print"]
    PDF["PDF"]
    TIFF["TIFF"]
    XLS["Excel"]
    RESULT["Result"]

    UI --> REQ --> GW --> EF --> PROC --> TYPE
    TYPE --> PRINT --> RESULT
    TYPE --> PDF --> RESULT
    TYPE --> TIFF --> RESULT
    TYPE --> XLS --> RESULT
```

## 10.1 Verification

  Scenario   Input            Expected         Metric
  ---------- ---------------- ---------------- ---------------
  Preview    Form/Data        HTML5 Viewer     First Render
  Print      Print Option     Printer          Success/Agent
  PDF        Export Request   PDF              Binary Diff
  TIFF       Export Request   TIFF             Image Quality
  Excel      Export Request   Excel            Cell/Data
  Failure    Timeout/Error    Standard Error   Retry/Log

------------------------------------------------------------------------

# 11. L4 --- Scheduler Architecture

## 11.1 Logical Flow

``` mermaid
flowchart LR
    R["Report Request"] --> A["Application WAS"]
    A --> VIP["L4 / VIP"]

    subgraph P["OZ Scheduler Pool"]
        S1["Scheduler #1"]
        S2["Scheduler #2"]
        S3["Scheduler #3"]
    end

    VIP --> S1
    VIP --> S2
    VIP --> S3

    S1 --> EF["OZ eForm Server"]
    S2 --> EF
    S3 --> EF

    EF --> RES["Result / Status"]
```

## 11.2 Scheduler에서 문서에 반드시 남겨야 할 질문

  ID       질문                         담당      상태
  -------- ---------------------------- --------- ------
  SCH-01   Health Check 방식은?         TA/OZ     TBD
  SCH-02   Node 장애 시 처리중 Job은?   OZ        TBD
  SCH-03   Retry 주체는?                AA/OZ     TBD
  SCH-04   Retry 횟수/간격은?           OZ        TBD
  SCH-05   처리결과 Callback/Polling?   OZ/업무   TBD
  SCH-06   동시처리량 기준은?           OZ/성능   TBD
  SCH-07   대용량 기준은?               업무/OZ   TBD
  SCH-08   결과/Temp Storage 위치는?    TA/OZ     TBD
  SCH-09   운영 Monitoring 지표는?      운영      TBD
  SCH-10   VIP 장애/우회 정책은?        TA        TBD

------------------------------------------------------------------------

# 12. L4 --- Async Architecture

## 12.1 용어 보정

현재 자료의 `Queue / Spool`은 실제 MQ 제품 사용을 의미한다고 단정하지
않는다. 실제 구현 확인 전에는 다음과 같이 중립적으로 표현한다.

> Async Request Store / Processing Store

## 12.2 상태 모델

``` mermaid
stateDiagram-v2
    [*] --> READY
    READY --> PROCESSING
    PROCESSING --> SUCCESS
    PROCESSING --> FAIL
    PROCESSING --> UNKNOWN
    FAIL --> RETRYABLE
    RETRYABLE --> PROCESSING
    UNKNOWN --> MANUAL_CHECK
    MANUAL_CHECK --> PROCESSING
    SUCCESS --> [*]
```

## 12.3 처리 모델

``` mermaid
flowchart LR
    REQ["Business Request"] --> SAVE["Request / Status Save"]
    SAVE --> CLAIM["Claim Work"]
    CLAIM --> CALL["External OZ Call"]
    CALL --> RESULT{"Call Result"}
    RESULT -->|"Success"| OK["SUCCESS"]
    RESULT -->|"Known Failure"| FAIL["FAIL / RETRYABLE"]
    RESULT -->|"Timeout / Uncertain"| UNKNOWN["UNKNOWN"]
```

## 12.4 Transaction 원칙

``` text
TX-1
READY → PROCESSING
COMMIT

External OZ Call

TX-2
PROCESSING → SUCCESS / FAIL / UNKNOWN
COMMIT
```

외부 호출 중 DB Transaction을 장시간 유지하지 않는다.

## 12.5 중복발행 Risk

Timeout은 "실패"와 동일하지 않다.

``` text
Application Timeout
        │
        ├── OZ 실제 미처리 → Retry 가능
        │
        └── OZ 실제 처리완료 → Retry 시 중복발행 위험
```

따라서 Request ID, GID/IFID, Idempotency 또는 처리상태 확인 방법을 ADR로
결정해야 한다.

------------------------------------------------------------------------

# 13. L4 --- Post Processing

``` mermaid
flowchart TB
    OZ["OZ Report Generation"]
    GEN{"Generation Success?"}
    POST["Post Processor"]
    ROUTE{"Post Type"}

    FAX["FAX"]
    EDMS["EDMS"]
    IMG["Image Convert"]
    MARK["MarkAny"]
    EMS["Email / EMS"]
    REMOTE["Remote"]

    AGG["Result Aggregation"]
    OK["SUCCESS"]
    PART["PARTIAL SUCCESS"]
    FAIL["FAIL"]
    UNK["UNKNOWN"]

    OZ --> GEN
    GEN -->|"NO"| FAIL
    GEN -->|"YES"| POST
    POST --> ROUTE
    ROUTE --> FAX
    ROUTE --> EDMS
    ROUTE --> IMG
    ROUTE --> MARK
    ROUTE --> EMS
    ROUTE --> REMOTE
    FAX --> AGG
    EDMS --> AGG
    IMG --> AGG
    MARK --> AGG
    EMS --> AGG
    REMOTE --> AGG
    AGG --> OK
    AGG --> PART
    AGG --> UNK
```

## 13.1 핵심 ADR

### ADR-OZ-003 --- OZ 성공 + 후처리 실패

결정해야 할 후보:

1.  전체 FAIL
2.  PARTIAL SUCCESS
3.  Report SUCCESS + Post FAIL 별도 상태
4.  Report SUCCESS 유지 + Post Retry

권장 문서 모델:

``` text
ReportStatus
PostStatus
FinalBusinessStatus
```

세 상태를 분리하고 최종 업무상태 계산 규칙을 별도 정의한다.

------------------------------------------------------------------------

# 14. EDMS / FAX Integration

``` mermaid
flowchart LR
    RESULT["OZ Result<br/>PDF/TIFF/Image"]
    POST["Post Processor"]
    GW["Image / FAX Gateway"]

    IMG["Image Service"]
    OUT["Outbound"]
    EAG["EDMS Gateway Agent"]
    FAG["FAX Gateway Agent"]

    EDMS["EDMS"]
    FAX["FAX"]
    NAS["NAS / DB"]

    RESULT --> POST --> GW
    GW --> IMG --> EAG --> EDMS
    GW --> OUT --> FAG --> FAX
    IMG --> NAS
    OUT --> NAS
```

## 14.1 Interface Contract 필수 항목

-   Request ID
-   GID
-   IFID
-   User ID
-   Document/Form ID
-   File Format
-   File Path 또는 Binary 전달방식
-   Destination
-   Timeout
-   Retry
-   Result Code
-   Result Message
-   Log Location
-   Owner
-   Reconciliation 방법

------------------------------------------------------------------------

# 15. Remote FAX / Legacy RD Migration

현재 실제 Legacy Source에서 다음 형태가 확인되는 영역은 별도 Migration
Pattern으로 관리한다.

``` text
ReportingServerInvoker
mrd_path
mrd_param
mrd_data
opcode
export_type
rcv_fax_no
userid
client_type
GID
ifId
```

## 15.1 권장 Migration Layer

``` mermaid
flowchart LR
    UI["WebSquare / Client"]
    JSON["JSON Request"]
    DTO["RemoteFaxRequest DTO"]
    SVC["RemoteFaxService"]
    ROUTE{"Migration Route"}
    RD["Legacy RD Adapter"]
    OZ["OZ Adapter"]
    RDI["ReportingServerInvoker"]
    OZI["To-Be OZ Common Interface"]
    FAX["FAX"]

    UI --> JSON --> DTO --> SVC --> ROUTE
    ROUTE -->|"Legacy"| RD --> RDI --> FAX
    ROUTE -->|"To-Be"| OZ --> OZI --> FAX
```

## 15.2 Migration 원칙

XML→JSON과 RD→OZ를 한 번에 섞지 않는다.

``` text
Phase 1: XML → JSON / DTO
Phase 2: XPath 제거
Phase 3: Legacy RD Adapter 격리
Phase 4: RD → OZ Adapter 전환
Phase 5: E2E 비교
Phase 6: Legacy 제거
```

------------------------------------------------------------------------

# 16. XML → JSON Semantic Conversion

단순 문자열 치환이 아니라 XPath 의미를 보존한다.

## 16.1 Index 변환

XPath는 1-based, JSON/Java Array/List는 0-based다.

``` text
/root/data/id[1]/text()
            │
            ▼
JSON Array: data.id[0]
            │
            ▼
Java DTO: requestData.data().id().get(0)
```

  XPath         JSON           Java
  ------------- -------------- -----------------
  `id[1]`       `id[0]`        `.get(0)`
  `id[2]`       `id[1]`        `.get(1)`
  `id[i]`       `id[i-1]`      `.get(i - 1)`
  `count(id)`   `id.length`    `.size()`
  `text()`      scalar value   accessor/asText

## 16.2 중요한 예외

XML Schema상 `id`가 단일값으로 확정되어 JSON Schema에서 String으로
정규화한 경우:

``` text
XPath: /root/data/id[1]/text()
JSON : data.id
Java : requestData.data().id()
```

이 경우 `[1]`을 단순 삭제한 것이 아니라 **Schema 변환으로 cardinality를
단일값으로 확정한 것**임을 Migration Rule에 기록해야 한다.

## 16.3 Parallel Node 구조 개선

Legacy:

``` text
mrdData[1]   mrdParams[1]   mrdPath[1]
mrdData[2]   mrdParams[2]   mrdPath[2]
```

To-Be 권장:

``` json
{
  "reports": [
    {
      "mrdData": "...",
      "mrdParams": "...",
      "mrdPath": "..."
    }
  ]
}
```

이렇게 하면 3개 Node Count를 별도로 비교하는 구조를 제거할 수 있다.

------------------------------------------------------------------------

# 17. MCMS Architecture

MCMS는 통합발행 Core와 특수 연계를 분리한다.

``` mermaid
flowchart LR
    C["Client Agent"]
    F["EdmsVideoRoutingFilter"]
    D{"Video?"}
    EDMS["EDMS"]
    CHUNK["Chunk Upload"]
    TEMP["Temp Storage"]
    TRANS["Transcoding"]
    ORG["Original Storage"]
    STREAM["Streaming"]

    C --> F --> D
    D -->|"NO"| EDMS
    D -->|"YES"| CHUNK
    CHUNK --> TEMP --> TRANS
    TRANS --> ORG
    TRANS --> STREAM
```

등록/조회/다운로드/삭제/편집 상세 Flow는 기존 상세자료를 유지하고
L0/L1에서는 `MCMS 연계`로만 표현한다.

------------------------------------------------------------------------

# 18. L5 --- Deployment Architecture

## 18.1 Logical Deployment

``` mermaid
flowchart LR
    subgraph IZ["Internal Zone"]
        IWEB["Internal WEB"]
        IWAS["Internal WAS"]
        OZ["OZ eForm"]
        SCH["OZ Scheduler"]
        IC["Image Convert WAS"]
    end

    subgraph EZ["External Zone"]
        EWEB["External WEB"]
        EWAS["External WAS"]
        MDS["MDS WAS"]
    end

    VIP["L4 / VIP"]
    NAS["NAS / OZR Storage"]
    EXT["FAX / EDMS / EMS"]

    IWEB --> IWAS
    IWAS --> VIP
    VIP --> SCH
    SCH --> OZ
    OZ --> NAS
    IC --> NAS

    EWEB --> EWAS
    EWAS --> VIP
    MDS --> VIP

    OZ --> EXT
```

## 18.2 WEB/WAS Baseline

프로젝트에서 별도로 확인된 논리 기준은 다음과 같이 관리한다.

``` text
WEB : Apache 2.4.68
WAS : Tomcat 11.0.24
JVM : OpenJDK 21
```

실제 노드 수, CPU/MEM, HA, Zone, Port 등은 TA/IDC 확인 후 확정한다.

## 18.3 AA / TA R&R

  항목          AA                    TA
  ------------- --------------------- -------------------------
  Application   Logical Component     Runtime/Node
  WEB/WAS       Service Role          Physical Placement
  L4/VIP        Logical Routing       VIP/Health Check
  Scheduler     Pool/Processing       Process/Node/HA
  Storage       Usage/Data Flow       Mount/Backup/Permission
  Network       Interface Direction   Zone/Firewall/Port
  Monitoring    Required Metric       Tool/Agent/Collection

------------------------------------------------------------------------

# 19. NAS / OZR Distribution Architecture

``` mermaid
flowchart LR
    PMS["PMS / Distribution"]
    PKG["OZR Package"]
    PATH["/Appl/OZR/report"]
    IWAS["Internal Report WAS"]
    EWAS["External Report WAS"]
    LOCAL["Local FileSystem"]
    NAS["NAS"]
    API["API / HTTPS"]
    BACKUP["Fallback Path<br/>TBD"]

    PMS --> PKG --> PATH
    PATH --> IWAS
    PATH --> EWAS
    IWAS --> LOCAL
    EWAS --> API
    EWAS --> NAS
    LOCAL -. "Failure" .-> BACKUP
    NAS -. "Failure" .-> BACKUP
```

## 19.1 Distribution Matrix

  ------------------------------------------------------------------------------------
  System     AS-IS         TO-BE    Primary   Fallback   Version   Rollback   Owner
  ---------- ------------- -------- --------- ---------- --------- ---------- --------
  Internal   MRD/NAS       OZR      TBD       TBD        TBD       TBD        TBD

  External   MRD/NAS/API   OZR      TBD       TBD        TBD       TBD        TBD

  MDS        RD            OZ       TBD       TBD        TBD       TBD        TBD
  ------------------------------------------------------------------------------------

------------------------------------------------------------------------

# 20. Migration Architecture

## 20.1 End-to-End Migration Pipeline

``` mermaid
flowchart LR
    INV["Inventory"]
    SRC["Source Analyzer"]
    META["RD Metadata"]
    MAP["Endpoint / Parameter Mapping"]
    IMP["Impact & Risk"]
    CONV["Converter"]
    BUILD["To-Be Build"]
    DIFF["Diff Verification"]
    E2E["E2E"]
    CUT["Cutover"]
    EVID["Evidence"]

    INV --> SRC --> META --> MAP --> IMP --> CONV
    CONV --> BUILD --> DIFF --> E2E --> CUT --> EVID
```

## 20.2 Migration Object

  ----------------------------------------------------------------------------------
  대상              AS-IS                        TO-BE             관리 산출물
  ----------------- ---------------------------- ----------------- -----------------
  Report            RD/MRD                       OZ/OZR            Report Matrix

  Source            ReportingServerInvoker/JSP   OZ Adapter/API    Source Analysis

  Data              XML/String                   JSON/DTO/VO       Parameter Mapping

  Endpoint          JSP/Domain                   Gateway/VIP       Endpoint Mapping

  Storage           RD NAS                       OZR Local/NAS/API Distribution
                                                                   Matrix

  Verification      Manual                       Diff/E2E          Evidence Report
  ----------------------------------------------------------------------------------

------------------------------------------------------------------------

# 21. Endpoint Mapping

## 21.1 Endpoint Inventory 필드

``` text
System
Screen/Function
AS-IS Endpoint
AS-IS Method
AS-IS Protocol
Purpose
TO-BE Endpoint
TO-BE Protocol
Request Format
Response Format
Timeout
Retry
Owner
Migration Status
Evidence
```

## 21.2 대상 예시

-   Common JSP
-   FAX Agent JSP
-   Remote Report
-   Integrated Report Server
-   Async Server
-   Class/Method Invocation
-   Portal-specific Endpoint
-   EDMS/Image Conversion

------------------------------------------------------------------------

# 22. Parameter Mapping

## 22.1 Parameter Class

Parameter는 이름만 대응하지 않고 유형을 분리한다.

-   Viewer Parameter
-   Form Parameter
-   ODI/Data Parameter
-   Scheduler Parameter
-   Server Parameter
-   Business Parameter
-   Legacy RD Parameter

## 22.2 Mapping Matrix

  ------------------------------------------------------------------------------------------
  Legacy      Meaning     Source   Cardinality   To-Be    Type     Conversion   Validation
  ----------- ----------- -------- ------------- -------- -------- ------------ ------------
  mrd_path    Report Path XML/RD   N             TBD      Report   Rule         Required

  mrd_param   Report      XML/RD   N             TBD      Data     Rule         Required
              Params                                                            

  mrd_data    Report Data XML      N             TBD      Data     XML→JSON?    Required

  GID         Trace ID    Header   1             GID      Common   Direct       Required

  ifId        Interface   Header   1             ifId     Common   Direct       Required
              ID                                                                
  ------------------------------------------------------------------------------------------

> `mrd_*`의 OZ 1:1 Parameter Mapping은 실제 To-Be 공통 인터페이스 확인
> 전까지 확정하지 않는다.

------------------------------------------------------------------------

# 23. Performance Architecture

SVG/Canvas/PDF 등 특정 방식이 빠르다고 선결론을 내리지 않고 단계별
시간을 측정한다.

``` mermaid
flowchart LR
    DB["DB/Data"]
    APP["Application"]
    OZ["OZ Generation"]
    NET["Network"]
    CLIENT["Client Rendering"]

    DB --> APP --> OZ --> NET --> CLIENT
```

## 23.1 측정 지표

-   Data Retrieval Time
-   Application Processing Time
-   OZ Generation Time
-   Network Transfer Time
-   First Page Display
-   Full Rendering Time
-   Server CPU
-   Server Memory
-   Client CPU
-   Network Bytes
-   Concurrent User
-   Concurrent Scheduler Job

## 23.2 Benchmark Matrix

  Scenario    Small   Medium   Large   Concurrent
  ----------- ------- -------- ------- ------------
  Preview     O       O        O       O
  PDF         O       O        O       O
  TIFF        O       O        O       O
  Scheduler   \-      O        O       O
  Async       \-      O        O       O

------------------------------------------------------------------------

# 24. Reliability / Failure Architecture

## 24.1 Failure Domain

``` mermaid
flowchart TB
    C["Client"]
    A["Application"]
    S["Scheduler"]
    O["OZ"]
    P["Post"]
    E["External"]

    C --> A --> S --> O --> P --> E

    C -. "Client Timeout" .-> C1["Retry Risk"]
    A -. "App Error" .-> A1["Transaction"]
    S -. "Node Failure" .-> S1["Failover"]
    O -. "Generation Error" .-> O1["Report Fail"]
    P -. "Post Fail" .-> P1["Partial"]
    E -. "Unknown Result" .-> E1["Reconciliation"]
```

## 24.2 Retry Rule

모든 Retry에는 다음을 기록한다.

``` text
Retry Owner
Retry Condition
Retry Count
Retry Interval
Idempotency Key
Duplicate Prevention
Final State
Manual Recovery
Evidence
```

------------------------------------------------------------------------

# 25. Security / Audit 관점

기존 Architecture Definition의 보안 상세 장표와 연결하되 통합발행
영역에서는 다음 항목을 최소 Architecture Requirement로 관리한다.

-   인증/인가 Context 전달
-   User ID 추적
-   GID/IFID 추적
-   개인정보 포함 Report Logging 제한
-   파일 임시저장 위치
-   NAS 권한
-   External Interface 암호화
-   Sensitive Parameter Masking
-   Report/Export 접근통제
-   Audit Log
-   운영자 조회 권한

------------------------------------------------------------------------

# 26. Requirement Traceability

``` mermaid
flowchart LR
    REQ["Requirement"]
    PRINCIPLE["Architecture Principle"]
    ARCH["Architecture"]
    ADR["ADR"]
    DETAIL["Detail Design"]
    TEST["Verification"]
    EVID["Evidence"]

    REQ --> PRINCIPLE --> ARCH --> ADR --> DETAIL --> TEST --> EVID
```

## 26.1 Traceability Matrix

  --------------------------------------------------------------------------------------------------------------------
  REQ ID       Requirement   Architecture       ADR          Detail   Verification   Evidence   Owner         Status
  ------------ ------------- ------------------ ------------ -------- -------------- ---------- ------------- --------
  AA-REQ-001   통합 발행물   L0/L1/L2           TBD          TBD      E2E            TBD        AA            OPEN
               전환                                                                                           

  AA-REQ-002   HTML5 Viewer  Viewer             ADR-OZ-001   TBD      Browser/Perf   TBD        AA/OZ         OPEN

  AA-REQ-003   대량/비동기   Scheduler/Async    ADR-OZ-002   TBD      Load/Retry     TBD        AA/OZ         OPEN

  AA-REQ-004   EDMS/FAX      Post/Integration   ADR-OZ-003   TBD      E2E            TBD        Integration   OPEN

  AA-REQ-005   운영 안정성   Deployment         ADR-OZ-004   TBD      Failover       TBD        TA            OPEN
  --------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------

# 27. ADR Catalogue

## ADR-OZ-001 Viewer Strategy

**Question**: Legacy PDF/Base64/PDF.js를 어디까지 유지할 것인가?

결정 요소: - 실제 사용화면 - OZ Viewer 기능 - Browser - 성능 -
다운로드/저장 요구 - 외부 시스템 의존

## ADR-OZ-002 Scheduler Routing

**Question**: Scheduler 호출을 어떤 접속점과 Pool 정책으로 운영할
것인가?

결정 요소: - L4/VIP - Health Check - Failover - Result - Retry -
Monitoring

## ADR-OZ-003 Post Processing Status

**Question**: OZ 성공 + 후처리 실패를 어떻게 정의할 것인가?

## ADR-OZ-004 OZR Distribution

**Question**: Local/NAS/API 중 시스템별 Primary/Fallback은 무엇인가?

## ADR-OZ-005 Parallel Run

**Question**: RD/OZ 병행기간의 Domain/Routing은 어떻게 구성할 것인가?

## ADR-OZ-006 Async Retry

**Question**: Timeout/UNKNOWN 상태에서 자동 Retry를 허용할 것인가?

## ADR-OZ-007 Parameter Compatibility

**Question**: Legacy mrd\_\* 및 XML 구조를 Adapter에서 얼마 동안 유지할
것인가?

------------------------------------------------------------------------

# 28. Risk Register

  ---------------------------------------------------------------------------------------
  Risk ID     Risk         Impact      Detection        Mitigation          Owner
  ----------- ------------ ----------- ---------------- ------------------- -------------
  R-001       Base64       Viewer 전환 Source Analyzer  화면별 분류         AA/업무
              Legacy       실패                                             
              Dependency                                                    

  R-002       Scheduler    중복발행    Job Trace        Idempotency         AA/OZ
              Retry 중복                                                    

  R-003       Async        결과불명    Status           UNKNOWN/Reconcile   AA
              Timeout                                                       

  R-004       Parameter    보고서 오류 Diff             Matrix              개발
              Mapping 누락                                                  

  R-005       Endpoint     호출 실패   Inventory        Endpoint Map        AA
              누락                                                          

  R-006       EDMS/Image   후처리 실패 E2E              Contract            Integration
              정합성                                                        

  R-007       NAS/OZR 권한 배포/조회   Deploy Test      TA Matrix           TA
                           실패                                             

  R-008       Java21       Runtime     Analyzer/Build   Library Upgrade     개발
              Legacy       Error                                            

  R-009       Encoding     문자 깨짐   Test             Encoding Rule       개발
              EUC-KR                                                        

  R-010       Parallel     오라우팅    E2E              Routing ADR         AA/TA
              Domain                                                        
  ---------------------------------------------------------------------------------------

------------------------------------------------------------------------

# 29. Architecture Risk Mindmap

``` mermaid
mindmap
  root((Integrated Report Risk))
    Viewer
      Base64
      PDF.js
      Browser
      Performance
    OZ
      Parameter
      Form
      Generation
    Scheduler
      VIP
      Health
      Failover
      Retry
    Async
      Timeout
      Duplicate
      Unknown
    Post
      FAX
      EDMS
      Image
      PartialSuccess
    Migration
      RD
      MRD
      XML
      JSP
      Endpoint
    Deployment
      NAS
      OZR
      Domain
    Runtime
      Java21
      Encoding
      Library
```

------------------------------------------------------------------------

# 30. Verification Architecture

## 30.1 Verification Layer

``` mermaid
flowchart LR
    UNIT["Unit"]
    INT["Interface"]
    REPORT["Report Diff"]
    E2E["E2E"]
    PERF["Performance"]
    FAIL["Failure/Recovery"]
    CUT["Cutover"]

    UNIT --> INT --> REPORT --> E2E --> PERF --> FAIL --> CUT
```

## 30.2 E2E Scenario

최소 다음을 독립 시나리오로 관리한다.

1.  Preview
2.  Print
3.  PDF Export
4.  TIFF Export
5.  FAX
6.  EDMS
7.  Image Convert
8.  Async
9.  Scheduler
10. Remote
11. Timeout
12. Retry
13. Partial Success
14. Failover
15. OZR Deployment/Rollback

------------------------------------------------------------------------

# 31. Parallel Run / Cutover Architecture

``` mermaid
flowchart LR
    USER["Business"]
    ROUTE{"Routing"}
    RD["AS-IS RD"]
    OZ["TO-BE OZ"]
    COMP["Result Compare"]
    DEC["Cutover Decision"]

    USER --> ROUTE
    ROUTE -->|"Legacy"| RD
    ROUTE -->|"To-Be"| OZ
    RD --> COMP
    OZ --> COMP
    COMP --> DEC
```

## 31.1 검토 대안

-   A: Domain 일괄 Cutover
-   B: To-Be 별도 Domain
-   C: 동일 Domain 내부 Routing

실제 인프라/VIP/보안 제약을 확인한 후 ADR-OZ-005에서 결정한다.

------------------------------------------------------------------------

# 32. Monitoring / Observability

## 32.1 Correlation Model

``` text
User Request
  └─ GID
      └─ IFID
          └─ Report Request ID
              └─ Scheduler Job ID
                  └─ Post Processing ID
```

가능한 범위에서 이 관계를 유지하여 장애 분석 시 Client → Application →
OZ → Scheduler → External까지 추적한다.

## 32.2 Metric

-   Request Count
-   Success/Fail/Partial/Unknown
-   Generation Time
-   Scheduler Waiting/Processing
-   Timeout
-   Retry
-   Post Fail
-   FAX/EDMS Fail
-   OZR Load Error
-   Concurrent Processing

------------------------------------------------------------------------

# 33. R&R

  업무                 Business   AA    OZ Common   TA/IDC   Integration   QA
  -------------------- ---------- ----- ----------- -------- ------------- -----
  Legacy 사용처 발굴   R          A/C   C           \-       C             \-
  Architecture         C          A/R   C           C        C             C
  Parameter Standard   C          A     R/C         \-       C             C
  OZ 구현              C          C     A/R         C        \-            C
  L4/VIP               \-         C     C           A/R      \-            C
  FAX/EDMS             C          C     C           C        A/R           C
  E2E                  R          A     R           C        R             A/R
  Cutover              C          A     C           R        C             C

A=Accountable, R=Responsible, C=Consulted

------------------------------------------------------------------------

# 34. IDC / TA 협의 Agenda

1.  내부/외부 WEB/WAS 실제 노드 구성
2.  OZ eForm 실제 배치
3.  Scheduler Process/Node 배치
4.  L4/VIP 접속 구조
5.  Health Check
6.  Scheduler 장애 처리
7.  NAS/OZR Storage
8.  OZR 배포/권한
9.  Internal/External Zone
10. FAX/EDMS Network
11. Production HA
12. Monitoring
13. Backup/Restore
14. Parallel Domain
15. Cutover/Rollback

회의 결과는 다음 형식으로 기록한다.

``` text
Decision:
Status: DECIDED / TBD
Owner:
Listener:
Due:
Evidence:
Related ADR:
Affected Diagram:
```

------------------------------------------------------------------------

# 35. Excalidraw 최종 Architecture Output 명세

Mermaid는 자동생성/버전관리용으로 사용하고, Excalidraw는 설계회의와 최종
Architecture 설명용으로 사용한다.

## 35.1 Master Canvas

``` text
Canvas Size: 1920 x 1080
Grid: 20
Primary Direction: Left → Right
Secondary Flow: Top → Bottom
```

### Zone A --- Channels/CIS

``` text
x: 40
y: 100
w: 320
h: 780
```

### Zone B --- Application/Common

``` text
x: 400
y: 100
w: 400
h: 780
```

### Zone C --- OZ Domain

``` text
x: 840
y: 100
w: 520
h: 780
```

### Zone D --- External/Common

``` text
x: 1400
y: 100
w: 460
h: 780
```

## 35.2 Node Metadata

각 Excalidraw Node는 논리적으로 다음 Metadata를 가진다.

``` json
{
  "id": "oz-scheduler-pool",
  "label": "OZ Scheduler Pool",
  "type": "architecture-node",
  "level": "L3",
  "domain": "OZ",
  "status": "TO-BE",
  "scope": "COMMON",
  "owner": "TBD",
  "listener": [],
  "requirements": ["AA-REQ-003"],
  "adrs": ["ADR-OZ-002"],
  "risks": ["R-002"],
  "verification": ["Scheduler Load", "Failover", "Retry"],
  "source": "Architecture Definition"
}
```

## 35.3 Edge Metadata

``` json
{
  "id": "edge-app-scheduler",
  "from": "application-was",
  "to": "oz-scheduler-pool",
  "protocol": "TBD",
  "via": "L4/VIP",
  "dataFormat": "TBD",
  "syncType": "TBD",
  "timeout": "TBD",
  "retry": "TBD",
  "status": "TO-BE"
}
```

## 35.4 Excalidraw 시각 규칙

  표현              의미
  ----------------- -----------------
  Solid Arrow       확정/주요 Flow
  Dashed Arrow      TBD/Candidate
  Double Border     External System
  Red Badge         Risk
  `ADR` Badge       Decision 필요
  `LEGACY` Badge    제거/호환 대상
  `NEW` Badge       To-Be 신규
  `COMMON` Badge    공통 기능
  `SPECIAL` Badge   시스템별 예외

------------------------------------------------------------------------

# 36. Mermaid / Excalidraw / PPT 역할

  Output            역할
  ----------------- -------------------------------
  Mermaid           Git/Diff/자동생성/기술문서
  Excalidraw        Architecture 설계/회의/시각화
  PPT               공식 보고/감리/의사결정
  GCE Graph Model   공통 원천 데이터

``` mermaid
flowchart LR
    SRC["Source / Requirement / Config"]
    ANA["GCE Analyzer"]
    MODEL["GCE Architecture Graph Model"]
    M["Mermaid Renderer"]
    E["Excalidraw Renderer"]
    P["PPT Architecture"]
    V["Verification"]

    SRC --> ANA --> MODEL
    MODEL --> M
    MODEL --> E
    E --> P
    MODEL --> V
```

------------------------------------------------------------------------

# 37. GCE 연계 방향

본 Architecture Definition은 장기적으로 GCE의 다음 Module과 연결할 수
있다.

``` text
GCE Analyzer
 ├─ Source Analyzer
 ├─ RD Metadata Extractor
 ├─ Endpoint Analyzer
 └─ Impact/Risk Analyzer

GCE Converter
 ├─ XML → JSON → Java
 ├─ RD → OZ
 ├─ Java Legacy → Java 21
 └─ SQL/DB

GCE Quality
 ├─ Diff
 ├─ E2E
 ├─ Risk
 └─ Evidence

GCE Architecture Graph
 ├─ Mermaid
 └─ Excalidraw
```

## 37.1 Architecture ↔ Source 연결

장기적으로는 Architecture Node를 실제 Source Evidence와 연결한다.

``` mermaid
flowchart LR
    ARCH["Architecture Node<br/>Remote FAX"]
    SRC["Source Evidence<br/>RemoteFaxUtilCfg"]
    LEG["Legacy Dependency<br/>ReportingServerInvoker"]
    RULE["Migration Rule"]
    TOBE["OZ Adapter"]
    TEST["Verification"]

    ARCH --> SRC --> LEG --> RULE --> TOBE --> TEST
```

------------------------------------------------------------------------

# 38. 문서 내 Source Evidence 관리

Architecture가 추정으로 변하지 않도록 각 중요한 결정에 Evidence를
붙인다.

``` text
Evidence Type:
- Source
- Configuration
- Official Solution Guide
- Meeting
- Requirement
- Test Result
- IDC/TA Confirmation
```

예:

``` text
Architecture Claim:
Scheduler는 L4/VIP를 통해 Pool 형태로 접근한다.

Evidence:
- Architecture Definition
- OZ/TA 확인 결과

Status:
TBD → CONFIRMED
```

------------------------------------------------------------------------

# 39. 최종 문서 목차 권장안

``` text
1. 개요
   1.1 목적
   1.2 범위
   1.3 관련문서
   1.4 용어
   1.5 Requirement Mapping

2. Architecture Overview
   2.1 Architecture Principle
   2.2 Architecture Level
   2.3 AS-IS / TO-BE
   2.4 L0 System Context
   2.5 System Capability Matrix
   2.6 L1 Application Logical

3. Integrated Report Architecture
   3.1 L2 OZ Application
   3.2 Component Responsibility
   3.3 Viewer / Preview
   3.4 Report Issuance
   3.5 Print / Export
   3.6 Scheduler
   3.7 Async
   3.8 Post Processing
   3.9 Remote

4. External Integration
   4.1 FAX
   4.2 EDMS
   4.3 Image Conversion
   4.4 MCMS
   4.5 EMS

5. Deployment
   5.1 WEB/WAS
   5.2 OZ/eForm
   5.3 Scheduler
   5.4 L4/VIP
   5.5 NAS/Storage
   5.6 OZR Distribution
   5.7 Internal/External Zone

6. Migration
   6.1 Migration Strategy
   6.2 RD → OZ
   6.3 MRD → OZR
   6.4 XML → JSON
   6.5 Java Legacy → Java21
   6.6 Endpoint Mapping
   6.7 Parameter Mapping
   6.8 Parallel Run
   6.9 Cutover/Rollback

7. Quality / Reliability
   7.1 Performance
   7.2 Failure
   7.3 Retry
   7.4 Monitoring
   7.5 E2E
   7.6 Diff Verification

8. Architecture Governance
   8.1 Requirement Traceability
   8.2 ADR
   8.3 Risk
   8.4 TBD
   8.5 Owner/Listener
   8.6 Evidence

9. Appendix
   9.1 System Inventory
   9.2 Interface Inventory
   9.3 Parameter Matrix
   9.4 Architecture Legend
   9.5 Mermaid Source
   9.6 Excalidraw Metadata
```

------------------------------------------------------------------------

# 40. 기존 21페이지 초안 보완 Mapping

    기존 Page 현재 주제      최종 보완
  ----------- -------------- ------------------------------------
            1 표지           유지
            2 재구성 방향    Architecture Level/목표 추가
            3 목차           최종 목차로 확장
            4 설계 원칙      Principle→ADR/Verification 연결
            5 AS-IS/TO-BE    Migration Object 추가
            6 L0             26시스템 유형/경계 추가
            7 L1             Data/Protocol Edge 추가
            8 L2 OZ          Component Responsibility 추가
            9 Viewer         Candidate/Confirmed + 성능 추가
           10 Issuance       Output별 검증 추가
           11 Scheduler      Failure/Retry/Monitoring 추가
           12 Async          상태/Transaction/UNKNOWN 추가
           13 Post           Report/Post/Final Status 분리
           14 EDMS/FAX       Interface Contract 추가
           15 MCMS           Core/Special 경계 명확화
           16 Deployment     AA/TA R&R 강화
           17 NAS/OZR        Distribution/Rollback Matrix
           18 Migration      GCE Pipeline + Semantic Conversion
           19 Traceability   Evidence까지 연결
           20 ADR/Risk/TBD   ADR Catalogue/Risk Register 확장
           21 작업분배       RACI/IDC Agenda 추가

------------------------------------------------------------------------

# 41. 최종 작성 원칙

## 해야 하는 것

-   기존 상세 장표를 Evidence/Detail Asset으로 재사용
-   공통 Architecture와 예외 Architecture 분리
-   모든 TBD에 Owner/Due 부여
-   모든 중요한 Architecture Decision을 ADR로 관리
-   Requirement→Architecture→Test 연결
-   AS-IS/TO-BE를 명확히 구분
-   Migration은 Source/Endpoint/Parameter/Storage까지 포함
-   Failure/Retry/Partial/Unknown을 정상 Flow만큼 중요하게 표현

## 피해야 하는 것

-   26개 시스템을 모두 같은 상세도로 그리는 것
-   Logical Architecture와 Physical Deployment를 한 그림에 과도하게 섞는
    것
-   "OZ가 알아서 처리" 같은 책임 불명확 표현
-   Timeout=실패로 단정
-   Retry 주체가 없는 설계
-   XML `[1]` 같은 의미를 단순 문자열 치환으로 제거
-   `mrd_*`를 근거 없이 OZ Parameter에 1:1 대응
-   실제 사용 여부를 확인하지 않은 Base64/PDF.js를 전 시스템 AS-IS로
    확정
-   Queue 제품이 확인되지 않았는데 MQ Architecture로 단정
-   Scheduler/Handler/Async의 프로젝트 실제 구현을 솔루션 일반론만으로
    확정

------------------------------------------------------------------------

# 42. Final Architecture Story

최종 발표/감리 시 문서는 다음 순서로 설명하면 된다.

``` mermaid
flowchart TB
    WHY["1. 왜 바꾸는가?<br/>Requirement / AS-IS"]
    WHAT["2. 무엇이 바뀌는가?<br/>AS-IS → TO-BE"]
    CONTEXT["3. 어디가 바뀌는가?<br/>L0 System Context"]
    LOGIC["4. 어떻게 구성되는가?<br/>L1/L2 Architecture"]
    FLOW["5. 어떻게 처리되는가?<br/>Viewer/Scheduler/Async/Post"]
    DEPLOY["6. 어디에 배치되는가?<br/>L5 Deployment"]
    MIG["7. 어떻게 전환하는가?<br/>RD/XML/Endpoint/OZR"]
    SAFE["8. 장애에 어떻게 대응하는가?<br/>Retry/Failover/Monitoring"]
    VERIFY["9. 어떻게 검증하는가?<br/>Diff/E2E/Performance"]
    GOV["10. 누가 결정하고 증명하는가?<br/>ADR/Risk/Evidence"]

    WHY --> WHAT --> CONTEXT --> LOGIC --> FLOW --> DEPLOY --> MIG --> SAFE --> VERIFY --> GOV
```

이 흐름으로 문서를 구성하면 기술 담당자에게는 설계 근거가, IDC/TA에는
협의 경계가, 업무 개발자에게는 호출/전환 기준이, 감리에는 Requirement
Traceability와 Evidence가 제공된다.

------------------------------------------------------------------------

# 43. 최종 결론

본 고도화안의 목적은 Architecture Definition을 "그림이 많은 문서"로
만드는 것이 아니다.

최종 목표는 다음 구조를 완성하는 것이다.

``` text
Requirement
   ↓
Architecture Principle
   ↓
System / Application / OZ Architecture
   ↓
Architecture Decision
   ↓
Migration Rule
   ↓
Implementation
   ↓
Verification
   ↓
Evidence
   ↓
Operation
```

그리고 현대해상 RD→OZ 전환에서는 다음 연결이 특히 중요하다.

``` text
Legacy Source
   ↓
Source Analyzer
   ↓
Legacy Dependency
   ↓
Endpoint / Parameter / XML Semantic Mapping
   ↓
OZ Adapter / Common Interface
   ↓
Diff / E2E
   ↓
Cutover
```

이를 통해 Architecture 문서가 실제 Source Conversion과 분리된 정적
산출물이 아니라, **실제 전환 근거와 검증 결과까지 연결되는 살아있는
Architecture Baseline**이 되도록 한다.

장기적으로 GCE를 적용할 경우 동일 Architecture Graph Model에서 Mermaid,
Excalidraw, PPT용 Architecture, Migration Matrix, Verification
Evidence를 파생시키는 구조가 가장 적합하다.

------------------------------------------------------------------------

## Appendix A. Architecture Object 공통 모델

``` json
{
  "architectureId": "AA-OZ-001",
  "name": "OZ Scheduler Pool",
  "level": "L3",
  "status": "TO-BE",
  "scope": "COMMON",
  "system": "Integrated Report",
  "owner": "TBD",
  "listeners": [],
  "requirements": [],
  "adrs": [],
  "risks": [],
  "interfaces": [],
  "sourceEvidence": [],
  "verification": [],
  "tbd": []
}
```

## Appendix B. Interface Object

``` json
{
  "interfaceId": "IF-TBD",
  "source": "Application WAS",
  "target": "OZ Scheduler",
  "via": "L4/VIP",
  "protocol": "TBD",
  "requestFormat": "TBD",
  "responseFormat": "TBD",
  "timeout": "TBD",
  "retry": "TBD",
  "traceKeys": ["GID", "IFID"],
  "owner": "TBD",
  "status": "TBD"
}
```

## Appendix C. Migration Rule Object

``` json
{
  "ruleId": "GCE-JAVA-XMLJSON-INDEX-001",
  "category": "XML_TO_JSON",
  "sourcePattern": "/root/data/id[1]/text()",
  "semantic": "first matched id node",
  "targetJson": "data.id[0]",
  "targetJava": "requestData.data().id().get(0)",
  "precondition": "id is represented as JSON array",
  "risk": "Do not drop XPath index without cardinality analysis",
  "verification": "Compare first XML node value with first JSON array value"
}
```

## Appendix D. Architecture Definition of Done

Architecture Definition을 완료로 판단하려면 최소 다음 조건을 만족해야
한다.

-   [ ] L0 System Context 확정
-   [ ] L1 Application Logical 확정
-   [ ] L2 OZ Architecture 확정
-   [ ] 26개 시스템 Capability 분류
-   [ ] Viewer Flow 확정
-   [ ] Print/Export Flow 확정
-   [ ] Scheduler Flow 및 Failure 정책 확정
-   [ ] Async 상태/Retry 정책 확정
-   [ ] Post Processing 결과상태 확정
-   [ ] FAX/EDMS/Image 진입점 확정
-   [ ] MCMS 경계 확정
-   [ ] WEB/WAS/OZ/L4/NAS 논리배치 확정
-   [ ] OZR Distribution Matrix 작성
-   [ ] RD→OZ Migration Matrix 작성
-   [ ] Endpoint Mapping 작성
-   [ ] Parameter Mapping 작성
-   [ ] XML→JSON Semantic Rule 정의
-   [ ] Java21 영향분석
-   [ ] Parallel Run/Cutover/Rollback 결정
-   [ ] Performance Benchmark 수행
-   [ ] Failure/Retry/E2E 수행
-   [ ] Requirement Traceability 완성
-   [ ] ADR Open 항목 종료 또는 승인된 TBD 처리
-   [ ] Risk Owner 지정
-   [ ] Evidence 연결
