-- Please update version.sql too -- this keeps clean builds in sync
define version=820
@update_header

BEGIN

	FOR r IN (SELECT host, oracle_schema FROM csr.customer WHERE app_sid IN (SELECT DISTINCT app_sid FROM csr.axis))
	LOOP
		dbms_output.put_line('fixing ' || r.host || ' ' || r.oracle_schema);
		security.user_pkg.logonadmin(r.host);
		
		-- create backup table to store
		EXECUTE IMMEDIATE
			'CREATE TABLE '||r.oracle_schema||'.backup_ip_primary_am as select * from '||r.oracle_schema||'.IND_PAGE_PRIMARY_AXIS_MEMBER';
		
		EXECUTE IMMEDIATE
			'CREATE TABLE '||r.oracle_schema||'.backup_ip_related_am as select * from '||r.oracle_schema||'.IND_PAGE_RELATED_AXIS_MEMBER';

		-- drop old tables (we gonna recreate it)
		EXECUTE IMMEDIATE
			'begin cms.tab_pkg.droptable('''||r.oracle_schema||''', ''IND_PAGE_PRIMARY_AXIS_MEMBER'', true); end; ';

		EXECUTE IMMEDIATE
			'begin cms.tab_pkg.droptable('''||r.oracle_schema||''', ''IND_PAGE_RELATED_AXIS_MEMBER'', true); end; ';
	
		-- recreate tables with new columns and PKs
		EXECUTE IMMEDIATE
			'CREATE TABLE '||r.oracle_schema||'.IND_PAGE_PRIMARY_AXIS_MEMBER('
			|| ' IND_PAGE_ID             NUMBER(10, 0)    NOT NULL,'
			|| ' AXIS_MEMBER_ID          NUMBER(10, 0)    NOT NULL,'
			|| ' APP_SID                 NUMBER(10, 0)    NOT NULL,'
			|| ' REPORTING_PERIOD_SID    NUMBER(10, 0)    NOT NULL,'
			|| ' SHOW_ON_DASHBOARD       NUMBER(1, 0)     DEFAULT 0 NOT NULL,'
			|| ' CONSTRAINT PK_IND_PAGE_PRIM_AXIS_MEMBER PRIMARY KEY (IND_PAGE_ID, AXIS_MEMBER_ID, APP_SID, REPORTING_PERIOD_SID))';
		
		EXECUTE IMMEDIATE
			'CREATE TABLE '||r.oracle_schema||'.IND_PAGE_RELATED_AXIS_MEMBER('
			|| ' IND_PAGE_ID             NUMBER(10, 0)    NOT NULL,'
			|| ' AXIS_MEMBER_ID          NUMBER(10, 0)    NOT NULL,'
			|| ' APP_SID                 NUMBER(10, 0)    NOT NULL,'
			|| ' REPORTING_PERIOD_SID    NUMBER(10, 0)    NOT NULL,'
			|| ' SHOW_ON_DASHBOARD       NUMBER(1, 0)     DEFAULT 0 NOT NULL,'
			|| ' CONSTRAINT PK_IND_PAGE_REL_AXIS_MEMBER PRIMARY KEY (IND_PAGE_ID, APP_SID, AXIS_MEMBER_ID, REPORTING_PERIOD_SID))';

		-- register tables new
		EXECUTE IMMEDIATE
			'begin cms.tab_pkg.registerTable('''||r.oracle_schema||''', ''ind_page_primary_axis_member,ind_page_related_axis_member''); end;';
		
		-- set grants
		EXECUTE IMMEDIATE
			'GRANT SELECT, INSERT, UPDATE, DELETE ON '||r.oracle_schema||'.ind_page_primary_axis_member TO csr';
		EXECUTE IMMEDIATE
			'GRANT SELECT, INSERT, UPDATE, DELETE ON '||r.oracle_schema||'.ind_page_related_axis_member TO csr';

		-- copy data from the backup table
		EXECUTE IMMEDIATE
			'BEGIN'
			|| '	user_pkg.logonadmin('''||r.host||''');'
			|| '	FOR r IN ( '
			|| '	SELECT ipam.ind_page_id, ipam.axis_member_id, ipam.app_sid, saip.reporting_period_sid '
			|| '	  FROM '||r.oracle_schema||'.backup_ip_primary_am ipam, '||r.oracle_schema||'.selected_axis_ind_page saip'
			|| '	 WHERE ipam.axis_member_id = saip.axis_member_id'
			|| '	   AND ipam.ind_page_id = saip.ind_page_id'
			|| ' )'
			|| '	LOOP'
			|| '		INSERT INTO '||r.oracle_schema||'.IND_PAGE_PRIMARY_AXIS_MEMBER '
			|| '			(ind_page_id, axis_member_id, app_sid, reporting_period_sid, show_on_dashboard)'
			|| '		VALUES'
			|| '			(r.ind_page_id, r.axis_member_id, r.app_sid, r.reporting_period_sid, 1);'
			|| ' END LOOP;'
			|| ' END;';
			
			dbms_output.put_line('done with ' || r.host || ' ' || r.oracle_schema);

--		EXECUTE IMMEDIATE
--			'DROP TABLE '||r.oracle_schema||'.backup_ip_primary_am';
--		EXECUTE IMMEDIATE
--			'DROP TABLE '||r.oracle_schema||'.backup_ip_related_am';
	
	END LOOP;
END;
/

@../strategy_pkg
@../strategy_body
@update_tail
