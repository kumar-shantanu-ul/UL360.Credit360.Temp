-- Please update version.sql too -- this keeps clean builds in sync
define version=458
@update_header

CREATE SEQUENCE STD_MEASURE_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

CREATE SEQUENCE STD_MEASURE_CONVERSION_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

@update_tail
