---
created: 2026-02-10
tags:
  - linkwave
  - architecture
  - system-design
---

> 이 문서는 linkwave-docs의 common/SYSTEM_ARCHITECTURE.md 원본입니다.

# LinkWave System Architecture

## 1. Overview

### 1.1 Purpose
Web interface for composing and sending messages (SMS, LMS, MMS, KakaoTalk, RCS).

### 1.2 Technology Stack
- **Frontend**: React 19+, TypeScript, Vite
- **Backend**: Spring Boot 4.0, Java 21
- **Database**: MySQL 8.0+ (expandable to Oracle, PostgreSQL)

### 1.3 Scope
The web application handles **request submission and DB storage only**. Actual message delivery is handled by a separate sending agent (Snap).

---

## 2. System Architecture

### 2.1 Overall Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                      Administrator (HQ)                          │
│  - Organization management                                       │
│  - User management                                               │
│  - Sender number management                                      │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                      User (Client Company)                       │
│                                                                  │
│  [React Web App]                                                 │
│        ↓                                                         │
│  [REST API (Spring Boot)]                                        │
│        ↓                                                         │
│  [Service Layer]                                                 │
│        ↓                                                         │
│  ┌──────────────────────────────────────────────┐               │
│  │            Web Service DB                     │               │
│  │  - Address book management                    │               │
│  │  - Sender number list                         │               │
│  │  - Message storage                            │               │
│  │  - Shared address book                        │               │
│  └──────────────────────────────────────────────┘               │
│        ↓                                                         │
│  [Data Synchronization Module]                                   │
│        ↓                                                         │
│  ┌──────────────────────────────────────────────┐               │
│  │           Message DB                          │               │
│  │  - ums_msg (sending request table)            │               │
│  │  - ums_log_{YYYYMM} (monthly sending history) │               │
│  └──────────────────────────────────────────────┘               │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                      Sending Agent (Snap)                        │
│                                                                  │
│  [Message DB Polling]                                            │
│        ↓                                                         │
│  [Real-time/Batch Traffic Separation]                            │
│    - TRAFFIC_TYPE: real (real-time/important)                    │
│    - TRAFFIC_TYPE: normal (general)                              │
│    - TRAFFIC_TYPE: batch (marketing/advertising)                 │
│        ↓                                                         │
│  [Relay Server Sending]                                          │
│        ↓                                                         │
│  [Sending Result Update]                                         │
│    - ums_msg status update                                       │
│    - ums_log record                                              │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 Data Flow

1. User composes message on web interface
2. Frontend sends request to Backend REST API
3. Backend validates and stores in Message DB
4. Sending Agent polls Message DB
5. Agent sends to relay server based on TRAFFIC_TYPE priority
6. Results are updated in ums_msg and ums_log tables

### 2.3 Duplicate Prevention

**Duplicate Condition**: `Phone Number + Message Content`
- Prevents resending identical content to the same number within a time window
- Implementation:
  - Store `(PHONE + MSG)` hash in `ums_msg` table
  - Validate duplicate requests within window (default: 10 minutes)
  - Provide duplicate sending option (user choice)

---

## 3. Key Business Concepts

### 3.1 CLIENT_KEY
Unique message identifier format: `{timestamp}_{userPrefix}_{randomString}`
- Example: `20251203140000_UserA_A3F8D2E1`

### 3.2 TRAFFIC_TYPE
Message priority classification:
- `real`: High priority, immediate sending (< 10 min delay)
- `normal`: Standard priority, general queue
- `batch`: Low priority, batch processing (> 100 recipients or > 10 min scheduled)

### 3.3 DEDUP_HASH
MD5 hash of `phone|content` for duplicate prevention (default 10 min window)

---

## 4. Database Schema Overview

### 4.1 Table Categories

| Category | Tables | DB Location |
|----------|--------|-------------|
| **Admin (HQ)** | organizations, users, admin_sender_numbers | Web DB |
| **User (Client)** | sender_numbers, personal_address_book, shared_address_book, message_storage | Web DB |
| **Message Processing** | ums_msg, ums_log_{YYYYMM} | Message DB |
| **Additional** | message_files, audit_logs, sync_queue | Web DB |

### 4.2 Hybrid Persistence Strategy

- **User Domain** → **JPA**: users, organizations, sender_numbers, address_book
- **Message Domain** → **MyBatis**: ums_msg, ums_log_{YYYYMM}, statistics

**Key Principle**: Never mix both technologies on the same table.

---

## 5. Security Considerations

- JWT-based authentication
- Spring Security integration
- Role-based access control (SUPER_ADMIN, ORGANIZATION_ADMIN, USER)
- HTTPS communication required
- SQL Injection prevention via prepared statements

---

## 6. Message Flow

```
1. User composes message on web page
   ↓
2. Controller receives and validates request
   - Required field validation
   - Byte count validation (SMS: 90 bytes, LMS: 2000 bytes)
   - File size validation (MMS: 10MB max)
   - Duplicate check (if enabled)
   ↓
3. MessageService processes business logic
   - Determine TRAFFIC_TYPE (real/normal/batch)
   - Generate CLIENT_KEY
   - Generate DEDUP_HASH
   ↓
4. Data Sync Module
   - Save to Message DB (ums_msg)
   - Set MSG_STATUS: 'ready'
   ↓
5. Return Response to user
   ↓
6. Sending Agent polls Message DB
   - Priority: real > normal > batch
   - Condition: MSG_STATUS = 'ready' AND REQ_DATE <= NOW()
   ↓
7. Agent processes and updates results
   - ums_msg: MSG_STATUS → 'complete'
   - ums_log_{YYYYMM}: Record sending history
```

---

## 7. Extension Points

### 7.1 Message Type Priority
1. **Phase 1**: SMS, LMS, MMS
2. **Phase 2**: KakaoTalk, RCS
3. **Phase 3**: Push notifications

### 7.2 Future Features
- Contact book management
- Message templates
- Statistics API
- Webhook callbacks

---

## Related Documents

- [[backend-architecture|Backend Architecture]]
- [[frontend-architecture|Frontend Architecture]]
- [[api-specifications|API Specifications]]
- [[initial-design|Initial Design Scratch]]
