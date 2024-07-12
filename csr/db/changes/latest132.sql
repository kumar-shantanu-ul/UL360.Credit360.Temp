-- Please update version.sql too -- this keeps clean builds in sync
define version=132
@update_header

VARIABLE version NUMBER
BEGIN :version := 132; END; -- CHANGE THIS TO MATCH VERSION NUMBER
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

-- temp table used by flash map mockup for mangroup 
CREATE GLOBAL TEMPORARY TABLE T_MAN_MAP_FILTERS
(
    key number(10), 
    val varchar2(255)
) ON COMMIT DELETE ROWS;

UPDATE version SET db_version = :version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT
 

@update_tail
