# NPM-DE-IS-AA-004 아키텍처 정의서 고도화 보완안

## Mermaid · Excalidraw 표현 포함

> 기준 문서: `NPM-DE-IS-AA-004-아키텍처정의서-재구성초안-v0.2(2).pptx`\
> 목적: 기존 재구성 초안의 내용과 구조는 유지하면서, AA 관점에서 부족한
> **계층성, 흐름, 책임 경계, 전환 기준, 감리 추적성, 의사결정 관리**를
> 보강한다.\
> 본 문서의 Mermaid/Excalidraw 예시는 **설계 논의용 초안**이며, 실제
> 현대해상 IDC/TA/OZ/업무 담당 확인이 필요한 항목은 `TBD`로 관리한다.

------------------------------------------------------------------------

## 1. 문서 분석 요약

현재 재구성 초안은 기존 문서의 문제를 "내용 부족"이 아니라 **전체
그림·OZ 상세·배포·운영·감리 추적성이 동일 계층에 혼재된 문제**로
정의하고 있으며, L0\~L5 수준의 계층 분리, OZ 기능별 상세화, Deployment
분리, Traceability/ADR/Risk 추가 방향을 제시하고 있다.

특히 다음 내용은 이미 방향이 잘 잡혀 있으므로 유지한다.

-   AS-IS / TO-BE 변화 요약
-   L0 System Context
-   L1 Application Logical Architecture
-   L2 OZ Application Architecture
-   Viewer / Preview
-   Report Issuance / Print
-   Scheduler
-   Async
-   Post Processing
-   EDMS / FAX
-   MCMS
-   Deployment / NAS / OZR 배포
-   Migration Architecture
-   Requirement Traceability
-   ADR / Risk / TBD
-   작업 분배안

보완의 핵심은 **새로운 기술을 임의로 추가하는 것이 아니라, 이미 존재하는
장표 사이의 관계를 더 명확하게 만드는 것**이다.

------------------------------------------------------------------------

# 2. 가장 먼저 보완할 사항

## 2.1 Architecture Level을 문서 전체에 적용

현재 초안에는 L0, L1, L2가 일부 표현되어 있으나, 문서 전체에 동일한 레벨
체계를 적용하면 각 장표의 목적이 더 명확해진다.

  --------------------------------------------------------------------------
  Level             명칭              목적              대표 산출물
  ----------------- ----------------- ----------------- --------------------
  L0                Concept / System  시스템 간 관계    CIS → 통합발행 →
                    Context                             외부연계

  L1                Application       Application Layer Client / Gateway /
                    Logical           역할              I/F / Biz

  L2                Domain / Solution OZ 영역 논리구조  Viewer / eForm /
                                                        Scheduler

  L3                Component         컴포넌트 책임     PreProcessor /
                                                        Processor / Post

  L4                Processing Flow   업무·기술         Preview / Print /
                                      처리순서          Fax / Async

  L5                Deployment        물리·운영 배치    WEB/WAS/L4/VIP/NAS
  --------------------------------------------------------------------------

### 보완 원칙

각 장표 우측 상단에 다음과 같이 레벨을 표시한다.

`[L0 System Context]`, `[L2 OZ Architecture]`, `[L4 Processing Flow]`

이를 통해 감리·IDC·TA·개발자가 "이 그림이 논리구조인지 물리구조인지"
혼동하지 않도록 한다.

------------------------------------------------------------------------

# 3. L0 --- 차세대 통합발행 System Context 보완

현재 L0 장표는 채널/CIS → 통합 발행물 영역 → 외부/공통 시스템의 관계를
설명한다. 여기에 **통합 발행물 영역을 현대해상 AA의 중심 경계(System
Boundary)** 로 더 명확하게 표시하는 것이 좋다.

## Mermaid Output

``` mermaid
flowchart LR
    subgraph CIS["Channels / CIS"]
        HP["하이포탈+"]
        BP["보상포탈"]
        SP["일반/장기 손사포탈"]
        EP["영업/TM 영업포탈"]
        MDS["MDS"]
        WEB["홈페이지 / 모바일 / 디지털창구"]
        ETC["기타 대상 시스템"]
    end

    subgraph REPORT["차세대 통합 발행물 영역"]
        GW["Application / Gateway"]
        OZV["OZ Viewer"]
        EFORM["OZ eForm Server"]
        SCH["OZ Scheduler Pool"]
        ASYNC["Async Processing"]
        POST["Post Processing"]
    end

    subgraph EXT["External / Common Systems"]
        FAX["FAX"]
        EDMS["EDMS"]
        IMG["Image Conversion"]
        MCMS["MCMS"]
        EMS["Email / EMS"]
        REMOTE["Remote Issuance"]
    end

    CIS --> GW
    GW --> OZV
    GW --> EFORM
    EFORM --> SCH
    EFORM --> ASYNC
    SCH --> POST
    ASYNC --> POST

    POST --> FAX
    POST --> EDMS
    POST --> IMG
    POST --> EMS
    POST --> REMOTE
    EDMS --> MCMS
```

## Excalidraw Output 설계

Excalidraw에서는 Mermaid보다 **영역과 책임 경계**를 강조한다.

``` text
┌──────────────────────── Channels / CIS ────────────────────────┐
│ 하이포탈+ │ 보상포탈 │ 손사포탈 │ 영업포탈 │ MDS │ 홈페이지   │
└──────────────────────────────┬─────────────────────────────────┘
                               │ Report Request
                               ▼
┌──────────── 차세대 통합 발행물 Application Boundary ────────────┐
│                                                               │
│ [Gateway / F/W]                                               │
│        │                                                      │
│        ├────→ [OZ Viewer]                                     │
│        │                                                      │
│        └────→ [OZ eForm Server]                               │
│                    │                                          │
│             ┌──────┴─────────┐                                │
│             ▼                ▼                                │
│      [Scheduler Pool]   [Async Processing]                    │
│             └──────┬─────────┘                                │
│                    ▼                                          │
│             [Post Processor]                                  │
└────────────────────┬──────────────────────────────────────────┘
                     │
       ┌─────────────┼───────────────┐
       ▼             ▼               ▼
     [FAX]         [EDMS]        [Image Convert]
                     │
                     ▼
                   [MCMS]

             + [EMS] + [Remote]
```

### Excalidraw 시각 규칙

-   파란 영역: 현대해상 To-Be 통합발행 영역
-   회색 영역: 기존 업무/CIS
-   주황 영역: 외부 또는 공통 연계 시스템
-   실선: 확정된 주요 호출 방향
-   점선: TBD 또는 상세 인터페이스 확인 필요
-   빨간 테두리: Migration Risk 또는 Legacy Dependency

------------------------------------------------------------------------

# 4. L1 --- Application Logical Architecture 보완

기존 초안의 Client Tier / Application Tier / Internal I/F Tier / Biz
Service Tier / Integration 구조는 유지한다.

보완할 점은 **"데이터가 어떤 형태로 이동하는가"**를 같이 표시하는
것이다.

``` mermaid
flowchart TB
    CLIENT["Client Tier<br/>UI / OZ Viewer / Client Agent"]
    APP["Application Tier<br/>Dispatcher / Gateway / Framework"]
    IIF["Internal I/F Tier<br/>EAI / Direct / Protocol"]
    BIZ["Biz Service Tier<br/>Endpoint / Executor / Main/Sub Service"]
    INT["Integration Layer<br/>DBIO / Rule / EDMS / FAX / External"]

    CLIENT -->|"JSON / Request"| APP
    APP -->|"VO / 표준 전문"| IIF
    IIF -->|"내부 전문"| BIZ
    BIZ -->|"DB/API/연계 요청"| INT
    INT -->|"Result"| BIZ
    BIZ -->|"Response"| APP
    APP -->|"JSON / Viewer Response"| CLIENT
```

### 추가 표시 권장

각 화살표에 다음 중 하나를 명시한다.

-   JSON
-   XML
-   VO
-   Binary
-   PDF/TIFF
-   File Path
-   API/HTTPS
-   EAI 전문

이렇게 해야 향후 **XML → JSON**, **RD → OZ**, **Endpoint 변경**이 어느
구간에서 발생하는지 바로 확인할 수 있다.

------------------------------------------------------------------------

# 5. L2 --- OZ Application Architecture 보완

현재 초안의 OZ Common Layer는 다음 역할을 가진다.

-   OZ Viewer
-   OZ eForm Server
-   OZ Scheduler Pool
-   OZ PreProcessor
-   OZ Processor
-   Post Processor

이 구조에서 중요한 보완점은 **컴포넌트명만 보여주는 것이 아니라
책임(Responsibility)을 분리하는 것**이다.

``` mermaid
flowchart LR
    REQ["Report Request"]

    PRE["OZ PreProcessor<br/>요청 검증 / Parameter 조립"]
    EF["OZ eForm Server<br/>서식 / Data Binding"]
    PROC["OZ Processor<br/>발행 / Export"]
    VIEW["OZ Viewer<br/>HTML5 Preview"]
    SCH["OZ Scheduler Pool<br/>분산 / 대량 발행"]
    POST["Post Processor<br/>후처리 Routing"]

    REQ --> PRE
    PRE --> EF

    EF --> VIEW
    EF --> PROC
    EF --> SCH

    PROC --> POST
    SCH --> POST
```

## 보완할 책임표

  --------------------------------------------------------------------------------
  Component      책임             입력             출력           확인 필요
  -------------- ---------------- ---------------- -------------- ----------------
  Viewer         미리보기         Viewer Request   HTML5 화면     Rendering/성능

  eForm          서식·데이터 처리 Form/Parameter   Report Data    실제 역할범위

  Scheduler      대량/예약/분산   Job Request      Job Result     VIP/Health Check

  PreProcessor   전처리           Request          Normalized     구현주체
                                                   Request        

  Processor      발행/Export      Form/Data        PDF/TIFF 등    구현주체

  Post Processor 후처리           Result           FAX/EDMS 등    성공상태 기준
  --------------------------------------------------------------------------------

> `PreProcessor`, `Processor`, `Post Processor`의 실제 현대해상 구현
> 책임은 상세 소스/솔루션 구성 확인 후 확정한다.

------------------------------------------------------------------------

# 6. Viewer / Preview Flow 보완

초안은 AS-IS Candidate와 TO-BE Candidate를 분리하고 있다. 이 방향은
유지하되 **Candidate / Confirmed 상태를 명확하게 표시**해야 한다.

``` mermaid
flowchart LR
    subgraph ASIS["AS-IS Candidate"]
        A1["업무 화면"]
        A2["RD 호출"]
        A3["PDF Binary"]
        A4["Base64"]
        A5["PDF.js / Viewer"]

        A1 --> A2 --> A3 --> A4 --> A5
    end

    subgraph TOBE["TO-BE"]
        T1["업무 화면"]
        T2["OZ Viewer Request"]
        T3["OZ eForm Server"]
        T4["Server Data Binding"]
        T5["HTML5 Rendering"]

        T1 --> T2 --> T3 --> T4 --> T5
    end
```

### 추가해야 할 확인 포인트

1.  기존 Base64/PDF 경로를 사용하는 실제 화면 목록
2.  PDF.js 제거 가능 여부
3.  OZ Viewer Parameter Mapping
4.  Viewer 첫 페이지 응답시간
5.  전체 보고서 완료시간
6.  Browser Compatibility
7.  Client CPU / Server CPU
8.  Network Payload

------------------------------------------------------------------------

# 7. Scheduler Architecture 보완

현재 초안은 `Report Request → L4 VIP → Scheduler Pool → OZ eForm Server`
구조를 제시한다.

이 부분은 **가용성·Retry·결과 관리**를 추가해야 한다.

``` mermaid
flowchart LR
    REQ["Report Request"]
    APP["Application WAS"]
    VIP["L4 / VIP"]

    subgraph POOL["OZ Scheduler Pool"]
        S1["Scheduler #1"]
        S2["Scheduler #2"]
        S3["Scheduler #3"]
    end

    EF["OZ eForm Server"]
    RESULT["Result / Status"]

    REQ --> APP
    APP --> VIP

    VIP --> S1
    VIP --> S2
    VIP --> S3

    S1 --> EF
    S2 --> EF
    S3 --> EF

    EF --> RESULT
```

### 반드시 별도 TBD로 관리할 항목

-   Scheduler Health Check
-   Scheduler 장애 시 Job 재분배
-   Retry 주체
-   Timeout 기준
-   Scheduler 처리 결과 조회 방식
-   Callback / Polling 여부
-   Scheduler별 동시 처리량
-   대용량 Report 처리 기준
-   운영 모니터링 지표
-   Scheduler Storage

------------------------------------------------------------------------

# 8. Async Architecture 보완

초안의 Async 장표에는 `Queue / Spool`이라는 표현이 있다. 그러나 실제
현대해상 구현이 메시지 큐 제품을 사용한다는 근거는 문서만으로 확정되지
않으므로, AA 문서에서는 더 중립적인 표현이 안전하다.

### 권장 용어

`Queue / Spool` → `Async Request Store / Processing Store`

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

### 처리 Flow

``` mermaid
flowchart LR
    REQ["업무 요청"]
    SAVE["요청 접수 / 상태 저장"]
    WORK["Async Processor"]
    OZ["OZ 발행"]
    RESULT["결과 저장"]
    RESP["상태 조회 / 회신"]

    REQ --> SAVE
    SAVE --> WORK
    WORK --> OZ
    OZ --> RESULT
    RESULT --> RESP
```

### 중요한 AA 원칙

외부 OZ 호출 전후의 DB Transaction을 길게 유지하지 않는다.

``` text
[Transaction 1]
READY → PROCESSING
COMMIT

        ↓

External OZ Call

        ↓

[Transaction 2]
PROCESSING → SUCCESS / FAIL / UNKNOWN
COMMIT
```

Timeout 발생 시 실제 OZ 처리가 완료되었는지 알 수 없는 경우 `UNKNOWN`
상태를 고려해야 한다.

------------------------------------------------------------------------

# 9. Post Processing Architecture 보완

현재 초안에서 후처리는 FAX / EDMS / Image / MarkAny / Email / Remote
등으로 분기한다.

가장 중요한 보완은 **OZ 발행 결과와 후처리 결과를 분리하는 것**이다.

``` mermaid
flowchart TB
    OZ["OZ Report Generation"]
    CHECK{"OZ 성공?"}

    POST["Post Processor"]
    FAX["FAX"]
    EDMS["EDMS"]
    IMG["Image Convert"]
    MARK["MarkAny"]
    EMS["Email / EMS"]
    REMOTE["Remote"]

    SUCCESS["SUCCESS"]
    PARTIAL["PARTIAL SUCCESS"]
    FAIL["FAIL"]

    OZ --> CHECK
    CHECK -->|"NO"| FAIL
    CHECK -->|"YES"| POST

    POST --> FAX
    POST --> EDMS
    POST --> IMG
    POST --> MARK
    POST --> EMS
    POST --> REMOTE

    FAX --> PARTIAL
    EDMS --> PARTIAL
    IMG --> PARTIAL
```

## 반드시 ADR로 결정할 질문

> **OZ Report Generation = SUCCESS 이지만 FAX/EDMS 등의 Post Processing
> = FAIL인 경우 최종 업무 상태를 무엇으로 볼 것인가?**

후보:

-   SUCCESS
-   FAIL
-   PARTIAL SUCCESS
-   SUCCESS + Post Retry

권장하는 AA 문서 방식은 이 결정을 `ADR`로 남기는 것이다.

------------------------------------------------------------------------

# 10. EDMS / FAX 연계 보완

기존 EDMS/FAX 장표는 상세도가 높으므로 새로 만들기보다 **OZ Post
Processor에서 어느 지점으로 진입하는지**만 명확하게 연결한다.

``` mermaid
flowchart LR
    OZ["OZ Result<br/>PDF/TIFF/Image"]
    POST["Post Processor"]
    GW["Image / FAX Gateway"]

    IMG["Image Service"]
    OUT["Outbound Service"]

    EDMSA["EDMS Gateway Agent"]
    FAXA["FAX Gateway Agent"]

    EDMS["EDMS"]
    FAX["FAX System"]
    NAS["NAS / DB"]

    OZ --> POST
    POST --> GW

    GW --> IMG
    GW --> OUT

    IMG --> EDMSA --> EDMS
    OUT --> FAXA --> FAX

    IMG --> NAS
    OUT --> NAS
```

### 추가해야 할 정보

-   요청 ID / GID / IFID
-   파일 저장 위치
-   결과 상태
-   Retry 가능 여부
-   연계 Timeout
-   장애 시 책임 시스템
-   로그 조회 위치

------------------------------------------------------------------------

# 11. MCMS 보완

MCMS는 통합 발행물 핵심 처리와 분리하여 **특수 연계 시스템**으로
유지한다.

``` mermaid
flowchart LR
    CLIENT["Client Agent"]
    ROUTE["EdmsVideoRoutingFilter"]
    TYPE{"Video?"}

    EDMS["EDMS 등록"]
    CHUNK["Chunk Upload"]
    TEMP["MCMS Temp"]
    TRANS["Transcoding"]
    ORG["Original Storage"]
    STREAM["Streaming"]

    CLIENT --> ROUTE
    ROUTE --> TYPE

    TYPE -->|"NO"| EDMS
    TYPE -->|"YES"| CHUNK
    CHUNK --> TEMP
    TEMP --> TRANS
    TRANS --> ORG
    TRANS --> STREAM
```

공통 Architecture에서는 `MCMS 연계`까지만 표시하고,
등록/조회/다운로드/삭제/편집은 기존 상세 Flow를 유지한다.

------------------------------------------------------------------------

# 12. Deployment Architecture 보완

AA 문서에서 WEB/WAS/L4/NAS를 표시하되, 물리 서버의 CPU/MEM/OS/HA 상세는
TA 책임으로 분리한다.

``` mermaid
flowchart LR
    subgraph INTERNAL["Internal Zone"]
        IWEB["Internal WEB"]
        IWAS["Internal WAS"]
        OZ["OZ eForm"]
        SCH["OZ Scheduler"]
        IMG["Image Convert WAS"]
    end

    subgraph EXTERNAL["External Zone"]
        EWEB["External WEB"]
        EWAS["External WAS"]
        MDS["MDS WAS"]
    end

    VIP["L4 / VIP"]
    NAS["NAS / Storage"]
    EXT["FAX / EDMS / EMS"]

    IWEB --> IWAS
    IWAS --> VIP
    VIP --> SCH
    SCH --> OZ

    OZ --> NAS
    IMG --> NAS

    EWEB --> EWAS
    EWAS --> VIP

    OZ --> EXT
```

## AA / TA 책임 경계

  항목        AA                   TA
  ----------- -------------------- ---------------------------
  WEB/WAS     논리 역할 / 서비스   노드 / CPU / MEM / OS
  L4/VIP      접속 및 분산 목적    VIP / Health Check / 장비
  Scheduler   Pool / 처리 관계     Process 배치 / HA
  NAS         사용 목적 / 데이터   Mount / 권한 / Backup
  Network     연계 방향            Zone / Firewall / Port

------------------------------------------------------------------------

# 13. NAS / OZR 배포 보완

현재 문서는 MRD → OZR 전환과 `/Appl/OZR/report` 등의 배포 방향을
포함한다.

보완해야 할 핵심은 **시스템별 배포방식을 Matrix화하는 것**이다.

  System          AS-IS          TO-BE     배포 방식          장애 대안   Owner
  --------------- -------------- --------- ------------------ ----------- -------
  내부 통합발행   MRD/NAS        OZR       Local Disk         TBD         TBD
  외부 통합발행   MRD/NAS/API    OZR       API/HTTPS or NAS   TBD         TBD
  MDS             기존 RD 연계   OZ 연계   TBD                TBD         TBD
  대량메일        NAS            OZ 연계   TBD                TBD         TBD

`장애 시 예비용 OZR`처럼 문서에 남아 있는 확인 항목은 반드시 ADR/TBD
관리표로 이동시킨다.

------------------------------------------------------------------------

# 14. Migration Architecture 고도화

현재 초안의 Migration Architecture는 매우 중요한 장표다. 이를 단순 표가
아니라 **Migration Pipeline**으로 확장한다.

``` mermaid
flowchart LR
    SRC["Legacy Source / JSP"]
    ANA["Source Analyzer"]
    META["RD Metadata Extractor"]
    IMP["Migration Impact"]
    CONV["Converter"]
    OZ["OZ Adapter / API"]
    TEST["Diff / E2E"]
    DONE["Migration Complete"]

    SRC --> ANA
    ANA --> META
    META --> IMP
    IMP --> CONV
    CONV --> OZ
    OZ --> TEST
    TEST --> DONE
```

## 현대해상 주요 Conversion 범위

``` text
RD / MRD
   ↓
OZ / OZR

ReportingServerInvoker
   ↓
OZ Adapter / Common API

XML / XPath
   ↓
JSON / DTO

JSP Endpoint
   ↓
To-Be Endpoint

mrd_path / mrd_param / mrd_data
   ↓
OZ Parameter Mapping

NAS RD Resource
   ↓
OZR Distribution Policy
```

### Conversion Rule 예시

``` text
/root/data/id[1]/text()
        ↓
JSON Array 구조라면
data.id[0]
        ↓
Java
requestData.data().id().get(0)
```

`[1]`은 제거되는 것이 아니라 **XPath의 1-based index가 JSON/Java의
0-based index로 의미 변환**되어야 한다.

------------------------------------------------------------------------

# 15. Requirement Traceability 보완

현재 요구사항 → Architecture → ADR → Detail Design → Verification 방향은
유지한다.

``` mermaid
flowchart LR
    REQ["Requirement"]
    ARCH["Architecture"]
    ADR["ADR"]
    DETAIL["Detail Design"]
    TEST["Verification"]
    EVID["Evidence"]

    REQ --> ARCH
    ARCH --> ADR
    ADR --> DETAIL
    DETAIL --> TEST
    TEST --> EVID
```

## 권장 관리 필드

  필드                   설명
  ---------------------- -----------------------
  REQ ID                 요구사항 식별자
  Requirement            요구사항
  Architecture Section   반영 장표
  Component              관련 컴포넌트
  ADR                    관련 의사결정
  Owner                  책임자
  Status                 상태
  Verification           검증 시나리오
  Evidence               테스트/회의/결과 증거

------------------------------------------------------------------------

# 16. ADR / Risk / TBD 관리 고도화

현재 문서의 "확인 필요" 문구를 장표 안에 흩어두지 않고 중앙 관리한다.

## ADR 후보

### ADR-OZ-001 --- Viewer Rendering

-   AS-IS PDF/Base64 유지 여부
-   OZ HTML5 Viewer 전환 범위
-   호환성 영향
-   성능 영향

### ADR-OZ-002 --- Scheduler Routing

-   동일 WAS Scheduler 직접호출 여부
-   L4 VIP 경유 원칙
-   장애 시 Routing

### ADR-OZ-003 --- Post Processing Result

-   OZ 성공 + 후처리 실패의 최종 상태

### ADR-OZ-004 --- OZR Distribution

-   Local Disk
-   NAS
-   API
-   장애 예비 경로

### ADR-OZ-005 --- Parallel Run

-   AS-IS / TO-BE 병행 기간
-   Domain 분리
-   내부 Routing

------------------------------------------------------------------------

# 17. Architecture Risk Map

``` mermaid
mindmap
  root((AA Risk))
    Viewer
      Base64 Legacy
      Browser
      Performance
    Scheduler
      Health Check
      Retry
      Failover
    Migration
      Parameter Mapping
      Endpoint
      RD Dependency
    Integration
      FAX
      EDMS
      Image
      Remote
    Deployment
      NAS
      OZR Distribution
      Domain
    Java21
      javax-jakarta
      Legacy Library
      Encoding
```

### 주요 Risk

1.  SVG / Canvas / PDF 실제 성능 불확실
2.  Base64/PDF Stream Legacy Dependency
3.  EDMS/Image Conversion To-Be 정합성
4.  Scheduler 장애·Retry 중복처리
5.  Async Timeout 후 중복발행
6.  Endpoint Mapping 누락
7.  XML→JSON Parameter 의미 손실
8.  Java 21 호환성
9.  NAS 권한/경로 변경
10. Parallel Run Domain/Routing

------------------------------------------------------------------------

# 18. Excalidraw 통합 Architecture 권장 Output

최종 AA 검토용 Excalidraw는 다음과 같은 형태가 가장 적합하다.

``` text
┌────────────────────────────────────────────────────────────────────┐
│                         CHANNEL / CIS                              │
│                                                                    │
│ [하이포탈+] [보상포탈] [손사] [영업] [MDS] [홈페이지] [모바일]     │
└─────────────────────────────┬──────────────────────────────────────┘
                              │ JSON / Report Request
                              ▼
┌──────────────────── APPLICATION / GATEWAY ─────────────────────────┐
│                                                                    │
│ [Dispatcher] → [Framework] → [Service Endpoint]                    │
│                         │                                          │
│                         ▼                                          │
│                    [Report Adapter]                                │
└─────────────────────────┬──────────────────────────────────────────┘
                          │
                          ▼
┌──────────────────────── OZ DOMAIN ─────────────────────────────────┐
│                                                                    │
│ [PreProcessor]                                                     │
│       │                                                            │
│       ▼                                                            │
│ [OZ eForm Server] ───────→ [OZ Viewer]                             │
│       │                                                            │
│       ├────────────→ [OZ Processor]                                │
│       │                                                            │
│       └→ [L4/VIP] → [Scheduler Pool]                               │
│                          │                                         │
│                          ▼                                         │
│                    [Post Processor]                                │
└──────────────────────────┬─────────────────────────────────────────┘
                           │
       ┌───────────────────┼─────────────────────────┐
       │                   │                         │
       ▼                   ▼                         ▼
┌────────────┐       ┌────────────┐           ┌────────────┐
│    FAX     │       │    EDMS    │           │Image Convert│
└────────────┘       └─────┬──────┘           └────────────┘
                           │
                           ▼
                      ┌──────────┐
                      │   MCMS   │
                      └──────────┘

         [EMS] [Remote] [NAS / OZR Distribution]
```

## Excalidraw 인터랙션/표현 규칙

실제 `.excalidraw` 파일로 생성할 경우 다음 메타데이터를 각 객체에
부여하는 것을 권장한다.

``` json
{
  "type": "architecture-node",
  "id": "oz-scheduler-pool",
  "label": "OZ Scheduler Pool",
  "architectureLevel": "L3",
  "domain": "OZ",
  "status": "TO-BE",
  "owner": "TBD",
  "risk": ["FAILOVER", "RETRY"],
  "sourceSlide": "OZ-03",
  "linkedAdr": ["ADR-OZ-002"]
}
```

이렇게 하면 향후 GCE Analyzer가 분석 결과를 Excalidraw로 Export할 때
단순 그림이 아니라 **추적 가능한 Architecture Object**로 만들 수 있다.

------------------------------------------------------------------------

# 19. Mermaid와 Excalidraw의 역할 분리

  구분                   Mermaid                  Excalidraw
  ---------------------- ------------------------ ------------------------
  목적                   자동생성 / 문서화        설계회의 / 시각적 설명
  강점                   Git 관리, Diff, 재생성   자유배치, 강조, 메모
  Source Analyzer 연계   매우 적합                적합
  Logic Flow             매우 적합                적합
  Data Lineage           적합                     매우 적합
  Call Graph             매우 적합                적합
  System Architecture    적합                     매우 적합
  감리 문서              보조                     주 Architecture 그림
  GCE Output             `.mmd` / Markdown        `.excalidraw`

권장 구조:

``` mermaid
flowchart LR
    SOURCE["Source / Architecture Data"]
    MODEL["GCE Graph Model"]
    MERMAID["Mermaid Renderer"]
    EXCAL["Excalidraw Renderer"]

    SOURCE --> MODEL
    MODEL --> MERMAID
    MODEL --> EXCAL
```

즉 **Mermaid와 Excalidraw를 각각 따로 분석하는 구조가 아니라, 하나의
Architecture Graph Model을 두 Renderer가 표현**하는 구조가 적합하다.

------------------------------------------------------------------------

# 20. 최종 보완 우선순위

## P1 --- 즉시 보완

-   L0/L1/L2 Architecture Level 확정
-   OZ Viewer Flow
-   OZ Scheduler Flow
-   Post Processing 상태 정의
-   AA/TA 책임 경계
-   Requirement Traceability

## P2 --- 상세 설계 연계

-   Async 처리 상태
-   EDMS/FAX 진입점
-   OZR 배포 Matrix
-   Endpoint Mapping
-   Parameter Mapping
-   RD→OZ Migration Matrix

## P3 --- 운영/검증

-   Performance
-   Failover
-   Retry
-   Monitoring
-   E2E
-   Parallel Run
-   Rollback

------------------------------------------------------------------------

# 21. 권장 최종 문서 구조

``` text
1. 개요
   1.1 목적
   1.2 범위
   1.3 관련 문서
   1.4 Requirement Mapping

2. Architecture Overview
   2.1 설계 원칙
   2.2 AS-IS / TO-BE
   2.3 L0 System Context
   2.4 L1 Application Logical Architecture

3. Integrated Report Architecture
   3.1 L2 OZ Application Architecture
   3.2 Viewer / Preview
   3.3 Report Issuance / Print
   3.4 Scheduler
   3.5 Async
   3.6 Post Processing
   3.7 Remote Issuance

4. External Integration
   4.1 FAX
   4.2 EDMS
   4.3 Image Conversion
   4.4 MCMS
   4.5 EMS

5. Deployment Architecture
   5.1 WEB/WAS
   5.2 OZ / Scheduler
   5.3 L4 / VIP
   5.4 NAS / Storage
   5.5 OZR Distribution

6. Migration Architecture
   6.1 RD → OZ
   6.2 MRD → OZR
   6.3 XML → JSON
   6.4 Endpoint Mapping
   6.5 Parameter Mapping
   6.6 Parallel Run

7. Quality / Operation
   7.1 Performance
   7.2 Monitoring
   7.3 Failover
   7.4 Retry
   7.5 E2E Verification

8. Architecture Governance
   8.1 Requirement Traceability
   8.2 ADR
   8.3 Risk
   8.4 TBD
   8.5 Owner / Listener
```

------------------------------------------------------------------------

# 22. 결론

현재 재구성 초안은 **기존 자료를 버리지 않고 OZ 중심으로 문서를
재정렬하는 Baseline**으로 적절하다.

다음 단계의 핵심은 장표 수를 늘리는 것이 아니라 다음 네 가지를 연결하는
것이다.

``` mermaid
flowchart LR
    REQ["Requirement"]
    ARCH["Architecture"]
    MIG["Migration"]
    VERIFY["Verification"]

    REQ --> ARCH
    ARCH --> MIG
    MIG --> VERIFY
    VERIFY -. Evidence .-> REQ
```

그리고 Architecture 표현은 다음과 같이 역할을 분리한다.

-   **PPT / Excalidraw**: 사람 중심의 아키텍처 설명과 협의
-   **Mermaid**: 코드화된 구조, Git 관리, 자동생성
-   **GCE Graph Model**: 두 표현의 공통 원천
-   **GCE Analyzer / Converter**: 실제 Source와 Migration 근거 생성

따라서 최종적으로는 **"문서에 그려진 아키텍처"와 "실제 소스에서 분석된
아키텍처"를 GCE가 연결**할 수 있는 방향으로 확장하는 것이 가장
효과적이다.
