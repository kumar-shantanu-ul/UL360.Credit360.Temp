-- Please update version.sql too -- this keeps clean builds in sync
define version=1543
@update_header

BEGIN
	FOR r IN (
		SELECT * FROM all_indexes WHERE OWNER ='CSR' AND index_name = 'PK_ISSUE_USER'
	)
	LOOP
		EXECUTE IMMEDIATE 'DROP INDEX CSR.PK_ISSUE_USER';
	END LOOP;
	
	FOR r IN (
		SELECT * FROM all_indexes WHERE OWNER ='CSRIMP' AND index_name = 'PK_ISSUE_USER'
	)
	LOOP
		EXECUTE IMMEDIATE 'DROP INDEX CSRIMP.PK_ISSUE_USER';
	END LOOP;
END;
/


@update_tail