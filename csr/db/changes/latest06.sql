-- Please update version.sql too -- this keeps clean builds in sync
define version=06
@update_header



alter table csr_user add (LAST_BUT_ONE_LOGON_DTM date);



alter table measure add (
    OPTION_SET_ID           NUMBER(10, 0));


CREATE TABLE OPTION_ITEM(
    OPTION_SET_ID    NUMBER(10, 0)    NOT NULL,
    POS              NUMBER(10, 0)    NOT NULL,
    VALUE            NUMBER(10, 0)    NOT NULL,
    DESCRIPTION      VARCHAR2(255)    NOT NULL,
    INFO_XML         CLOB              DEFAULT EMPTY_CLOB() NOT NULL,
    CONSTRAINT PK107 PRIMARY KEY (OPTION_SET_ID, POS)
)
;



-- 
-- TABLE: OPTION_SET 
--

CREATE TABLE OPTION_SET(
    OPTION_SET_ID    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK108 PRIMARY KEY (OPTION_SET_ID)
)
;


ALTER TABLE MEASURE ADD CONSTRAINT RefOPTION_SET182 
    FOREIGN KEY (OPTION_SET_ID)
    REFERENCES OPTION_SET(OPTION_SET_ID)
;


-- 
-- TABLE: OPTION 
--

ALTER TABLE OPTION_ITEM ADD CONSTRAINT RefOPTION_SET183 
    FOREIGN KEY (OPTION_SET_ID)
    REFERENCES OPTION_SET(OPTION_SET_ID)
;


CREATE SEQUENCE OPTION_SET_ID_SEQ 
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 5
    NOORDER
;



declare
	v_act varchar(38);	    
begin
	user_pkg.logonauthenticatedpath(0,'//builtin/administrator',500,v_act);
	FOR r IN (select sid_id,parent_sid_id from securable_object where lower(name) = 'csr' and class_id = 277895)
	 loop
		acl_pkg.PropogateACEs(v_act, r.sid_id);
    End Loop;
end;
/
commit;


@update_tail
