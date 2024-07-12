-- Please update version.sql too -- this keeps clean builds in sync
define version=900
@update_header

declare
	v_version number;
begin
	select db_version
	  into v_version
	  from postcode.version;
	if v_version != 6 then
		raise_application_error(-20001, 'postcode must be version 6 first');
	end if;
	select db_version
	  into v_version
	  from aspen2.version;
	if v_version != 24 then
		raise_application_error(-20001, 'aspen2 must be version 24 first');
	end if;
end;
/

drop table postcode.version;
drop table aspen2.version;


DECLARE
	v_cnt	NUMBER(10);
BEGIN
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM all_tables
	 WHERE owner = 'POSTCODE'
	   AND table_name = 'POSTCODE';
	 IF v_cnt = 1 THEN 
		EXECUTE IMMEDIATE('drop table postcode.postcode purge');
	END IF;
END;
/



CREATE SEQUENCE POSTCODE.POSTCODE_PLACE_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER;


CREATE TABLE POSTCODE.POSTCODE(
    COUNTRY     VARCHAR2(2)     NOT NULL,
    POSTCODE    VARCHAR2(20)    NOT NULL,
    CONSTRAINT PK_POSTCODE PRIMARY KEY (COUNTRY, POSTCODE)
);



CREATE TABLE POSTCODE.POSTCODE_PLACE(
    COUNTRY              VARCHAR2(2)       NOT NULL,
    POSTCODE_PLACE_ID    NUMBER(10, 0)     NOT NULL,
    POSTCODE             VARCHAR2(20)      NOT NULL,
    PLACE_NAME           VARCHAR2(180),
    ADMIN_NAME_1         VARCHAR2(100),
    ADMIN_CODE_1         VARCHAR2(20),
    ADMIN_NAME_2         VARCHAR2(100),
    ADMIN_CODE_2         VARCHAR2(20),
    ADMIN_NAME_3         VARCHAR2(100),
    ADMIN_CODE_3         VARCHAR2(20),
    LAT                  NUMBER(20, 10)    NOT NULL,
    LNG                  NUMBER(20, 10)    NOT NULL,
    ACCURACY             NUMBER(1, 0),
    CONSTRAINT PK_POSTCODE_PLACE PRIMARY KEY (POSTCODE_PLACE_ID)
);



ALTER TABLE POSTCODE.POSTCODE ADD CONSTRAINT FK_POSTCODE_COUNTRY 
    FOREIGN KEY (COUNTRY)
    REFERENCES POSTCODE.COUNTRY(COUNTRY);

ALTER TABLE POSTCODE.POSTCODE_PLACE ADD CONSTRAINT FK_POSTCODE_PC_PLACE 
    FOREIGN KEY (COUNTRY, POSTCODE)
    REFERENCES POSTCODE.POSTCODE(COUNTRY, POSTCODE);


@update_tail
