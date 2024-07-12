DECLARE
	OBJECT_NOT_IN_BIN EXCEPTION;
	PRAGMA EXCEPTION_INIT(OBJECT_NOT_IN_BIN, -38307);
BEGIN
	FOR r IN (
		SELECT original_name
		  FROM dba_recyclebin
		 WHERE owner = 'RAG'
	)
	LOOP
		BEGIN
			EXECUTE IMMEDIATE 'PURGE TABLE rag.'||r.original_name;
		EXCEPTION 
			WHEN OBJECT_NOT_IN_BIN THEN 
				NULL;
		END;
	END LOOP;
END;
/

BEGIN
	FOR r IN (
		SELECT * FROM user_objects WHERE LOWER(object_name) = 'test_common_pkg' AND object_type = 'PACKAGE'
	) LOOP
		EXECUTE IMMEDIATE 'DROP PACKAGE csr.test_common_pkg';
	END LOOP;
END;
/
