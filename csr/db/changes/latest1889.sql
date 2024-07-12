-- Please update version.sql too -- this keeps clean builds in sync
define version=1889
@update_header
DECLARE
	v_count			NUMBER(10);
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_users
	 WHERE username = UPPER('donations');
	
	IF v_count > 0 THEN
		EXECUTE IMMEDIATE 'GRANT EXECUTE ON csr.indicator_pkg	TO donations';
		EXECUTE IMMEDIATE 'GRANT SELECT  ON csr.val				TO donations';
		EXECUTE IMMEDIATE 'GRANT SELECT  ON csr.val_change		TO donations';
		EXECUTE IMMEDIATE 'GRANT SELECT  ON csr.ind				TO donations';
	END IF;
END;
/

@update_tail
