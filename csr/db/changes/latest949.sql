-- Please update version.sql too -- this keeps clean builds in sync
define version=949
@update_header

BEGIN

	FOR r IN (SELECT host, oracle_schema FROM csr.customer WHERE app_sid IN (SELECT DISTINCT app_sid FROM csr.axis))
	LOOP
		dbms_output.put_line('fixing ' || r.host || ' ' || r.oracle_schema);
		security.user_pkg.logonadmin(r.host);
		
		-- PRIMARY table
		-- update constraints (we don't want ON DELETE CASCADE)
		BEGIN
			EXECUTE IMMEDIATE
				'ALTER TABLE '||r.oracle_schema||'.C$IND_PAGE_PRIMARY_AXIS_MEMBER DROP CONSTRAINT FK_AXIS_MEM_PRI_MEM';
			EXCEPTION 
				WHEN OTHERS THEN 
					NULL;
		END;
		
		BEGIN
			EXECUTE IMMEDIATE
				'ALTER TABLE '||r.oracle_schema||'.C$IND_PAGE_PRIMARY_AXIS_MEMBER ADD CONSTRAINT FK_AXIS_MEM_PRI_MEM'
				|| ' FOREIGN KEY (APP_SID, AXIS_MEMBER_ID)'
				|| ' REFERENCES CSR.AXIS_MEMBER(APP_SID, AXIS_MEMBER_ID)';
			EXCEPTION 
				WHEN OTHERS THEN 
					NULL;
		END;
		
		-- RELATED table
		-- update constraints (we don't want ON DELETE CASCADE)
		BEGIN
			EXECUTE IMMEDIATE
				'ALTER TABLE '||r.oracle_schema||'.C$IND_PAGE_RELATED_AXIS_MEMBER DROP CONSTRAINT FK_AXIS_MEM_REL_MEM';
			EXCEPTION 
				WHEN OTHERS THEN 
					NULL;
		END;
		
		BEGIN
			EXECUTE IMMEDIATE
			'ALTER TABLE '||r.oracle_schema||'.C$IND_PAGE_RELATED_AXIS_MEMBER ADD CONSTRAINT FK_AXIS_MEM_REL_MEM'
			|| ' FOREIGN KEY (APP_SID, AXIS_MEMBER_ID)'
			|| ' REFERENCES CSR.AXIS_MEMBER(APP_SID, AXIS_MEMBER_ID)';
			EXCEPTION 
				WHEN OTHERS THEN 
					NULL;
		END;
		
		
		-- need this to delete axis_member 
		EXECUTE IMMEDIATE
			'GRANT DELETE ON '||r.oracle_schema||'.C$IND_PAGE_PRIMARY_AXIS_MEMBER TO csr';
		EXECUTE IMMEDIATE
			'GRANT DELETE ON '||r.oracle_schema||'.L$IND_PAGE_PRIMARY_AXIS_MEMBER TO csr';
		EXECUTE IMMEDIATE
			'GRANT DELETE ON '||r.oracle_schema||'.C$IND_PAGE_RELATED_AXIS_MEMBER TO csr';
		EXECUTE IMMEDIATE
			'GRANT DELETE ON '||r.oracle_schema||'.L$IND_PAGE_RELATED_AXIS_MEMBER TO csr';
		
		dbms_output.put_line('done with ' || r.host || ' ' || r.oracle_schema);
	END LOOP;
END;
/

@../strategy_pkg
@../strategy_body

@update_tail
