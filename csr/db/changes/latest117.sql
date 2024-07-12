-- Please update version.sql too -- this keeps clean builds in sync
define version=117
@update_header

VARIABLE version NUMBER
BEGIN :version := 117; END; -- CHANGE THIS TO MATCH VERSION NUMBER
/

WHENEVER SQLERROR EXIT SQL.SQLCODE
DECLARE
	v_version	version.db_version%TYPE;
BEGIN
	SELECT db_version INTO v_version FROM version;
	IF v_version >= :version THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||:version||' HAS ALREADY BEEN APPLIED =======');
	END IF;
	IF v_version + 1 <> :version THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||:version||' CANNOT BE APPLIED TO A DATABASE OF VERSION '||v_version||' =======');
	END IF;
END;
/


alter table customer add (lock_start_dtm DATE DEFAULT '1 Jan 1980' NOT NULL, lock_end_dtm DATE DEFAULT '1 Jan 1980' NOT NULL);
-- update with period_lock data
begin
	for r in (
		select csr_root_sid, MIN(start_dtm) start_dtm, MAX(end_dtm) end_dtm from period_lock group by csr_root_sid 
	)
	loop
		update customer set locK_start_dtm = r.start_dtm, lock_end_dtm = r.end_dtm where csr_root_sid = r.csr_root_sid;
	end loop;
end;
/
commit;

drop table period_lock purge;

UPDATE csr.version SET db_version = :version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT



@update_tail
