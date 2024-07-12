-- Please update version.sql too -- this keeps clean builds in sync
define version=513
@update_header


CREATE SEQUENCE AXIS_ID_SEQ 
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 5
    NOORDER
;

CREATE SEQUENCE AXIS_MEMBER_ID_SEQ 
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 5
    NOORDER
;

@update_tail