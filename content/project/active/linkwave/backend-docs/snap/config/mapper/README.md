---
created: 2025-12-26
---
# msghub customize 으로부터 변경된 점
## KV
1. 필드 명 변경
   1. MSG_BIZ_KEY -> KISA_ORIGCODE
   2. KV_JSON -> KV_DATA
   3. KV_JSON2 -> KV_DATA2
   4. FILE_LIST -> FILE_DATA
2. 필드 사이즈 변경
   1. FILE_DATA: 1000 -> 4000

## UMS
1. 필드 명 변경
    1. MSG_BIZ_KEY -> KISA_ORIGCODE
    2. REQ_PRODUCT -> REQ_CH
    3. FB_PRODUCT -> FB_CH
    4. FILE_LIST -> FILE_DATA
    5. KAKAO_SENDER_KEY -> KAKAO_CH_ID
2. 필드 사이즈 변경
    1. MERGE_DATA: 1000 -> 4000 
    2. FILE_DATA: 1000 -> 4000
    3. KAKAO_CH_ID: 40 -> 80 
3. 필드 값 ENUM 변경
    1. REQ_PRODUCT : ReqProd.class </br>
        REQ_CH : Channel.class
```java
@AllArgsConstructor
public enum Channel {
    SMS("sms"),
    GDS("국제sms"),
    MMS("mms"),
    RCS("rcs"),
    ALIMTALK("알림톡"),
    FRIENDTALK("친구톡"),
    PUSH("push"),
    UMS("ums 통합발송"),
    ;
    
    public final String description;
}
```
```java
@Getter
@AllArgsConstructor
public enum ReqProd {
    sms("sms", "sms"),
    sms_global("sms_global", "국제sms"),
    lms("lms", "lms"),
    mms("mms", "mms"),
    rcs("rcs", "rcs"),
    kko_noti("kko_noti", "알림톡"),
    kko_friend("kko_friend", "친구톡"),
    push("push", "push"),
    ;

    public final String key;
    public final String desc;

    @Override
    public String toString() {
        return key;
    }
}
```