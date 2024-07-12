DECLARE
	v_exists NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_exists
	  FROM all_users
	 WHERE username = UPPER('rag');
	 
	IF v_exists = 1 THEN
		FOR r IN (SELECT oracle_table FROM cms.tab WHERE oracle_schema = 'RAG')
		LOOP
			cms.tab_pkg.DropTable('RAG', UPPER(r.oracle_table), true);
		END LOOP;
		EXECUTE IMMEDIATE 'DROP USER rag CASCADE';
	END IF;
	EXECUTE IMMEDIATE 'CREATE USER rag IDENTIFIED BY rag TEMPORARY TABLESPACE TEMP DEFAULT TABLESPACE USERS QUOTA UNLIMITED ON USERS';
	EXECUTE IMMEDIATE 'GRANT EXECUTE ON security.security_pkg TO rag';
	EXECUTE IMMEDIATE 'GRANT SELECT ON cms.context TO rag';
	EXECUTE IMMEDIATE 'GRANT SELECT ON cms.fast_context TO rag';
	EXECUTE IMMEDIATE 'GRANT EXECUTE ON cms.tab_pkg TO rag';
END;
/
