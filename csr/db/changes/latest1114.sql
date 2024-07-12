-- Please update version.sql too -- this keeps clean builds in sync
define version=1114
@update_header

CREATE SEQUENCE CT.EC_QUESTIONNAIRE_ANS_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    nocycle
    CACHE 20
    noorder;

CREATE SEQUENCE CT.EC_QUESTIONNAIRE_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    nocycle
    CACHE 20
    noorder;

@update_tail
