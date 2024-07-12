-- Please update version.sql too -- this keeps clean builds in sync
define version=71
@update_header

VARIABLE version NUMBER
BEGIN :version := 71; END; -- CHANGE THIS TO MATCH VERSION NUMBER
/

WHENEVER SQLERROR EXIT SQL.SQLCODE
DECLARE
	v_version	version.db_version%TYPE;
BEGIN
	SELECT db_version INTO v_version FROM version;
	IF v_version >= :version THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||:version||' HAS ALREADY BEEN APPLIED =======');
	END IF;
END;
/	


WHENEVER SQLERROR CONTINUE


ALTER TABLE ALERT_TEMPLATE ADD (MAIL_TEMPLATE CLOB NULL);
ALTER TABLE ALERT_TEMPLATE ADD (MIME_TYPE VARCHAR2(255) DEFAULT 'text/plain' NOT NULL);
alter table trash modify (description varchar2(4000));

begin
INSERT INTO TEMPLATE_TYPE ( TEMPLATE_TYPE_ID, NAME, MIME_TYPE, DESCRIPTION, DEFAULT_DATA) VALUES ( 5, 'Approval Step export', 'application/vnd.ms-excel', 'A template for Approval Step exports', EMPTY_BLOB());
end;
/
commit;





UPDATE version SET db_version = :version;
COMMIT;
PROMPT
PROMPT ================== UPDATED OK ========================
PROMPT
EXIT



@update_tail
