define version=3311
define minor_version=0
define is_combined=1
@update_header

-- clean out junk in csrimp
BEGIN
	FOR r IN (
		SELECT table_name
		  FROM all_tables
		 WHERE owner='CSRIMP' AND table_name!='CSRIMP_SESSION'
		)
	LOOP
		EXECUTE IMMEDIATE 'TRUNCATE TABLE csrimp.'||r.table_name;
	END LOOP;
	DELETE FROM csrimp.csrimp_session;
	commit;
END;
/

-- clean out debug log
TRUNCATE TABLE security.debug_log;



ALTER TABLE csr.customer
ADD (
	marked_for_zap NUMBER(1) DEFAULT 0 NOT NULL,
	zap_after_dtm DATE,
	batch_jobs_disabled NUMBER(1) DEFAULT 0 NOT NULL,
	calc_jobs_disabled NUMBER(1) DEFAULT 0 NOT NULL,
	scheduled_tasks_disabled NUMBER(1) DEFAULT 0 NOT NULL,
	alerts_disabled NUMBER(1) DEFAULT 0 NOT NULL,
	prevent_logon NUMBER(1) DEFAULT 0 NOT NULL
);
ALTER TABLE csr.customer
ADD (
	CONSTRAINT CK_ALLOW_MARKED_FOR_ZAP CHECK (MARKED_FOR_ZAP IN (0,1)),
	CONSTRAINT CK_ALLOW_BATCH_JOBS_DISABLED CHECK (BATCH_JOBS_DISABLED IN (0,1)),
	CONSTRAINT CK_ALLOW_CALC_JOBS_DISABLED CHECK (CALC_JOBS_DISABLED IN (0,1)),
	CONSTRAINT CK_ALLOW_SCHEDULED_TASKS_DISABLED CHECK (SCHEDULED_TASKS_DISABLED IN (0,1)),
	CONSTRAINT CK_ALLOW_ALERTS_DISABLED CHECK (ALERTS_DISABLED IN (0,1)),
	CONSTRAINT CK_ALLOW_PREVENT_LOGON CHECK (PREVENT_LOGON IN (0,1))
);
ALTER TABLE csrimp.customer
ADD (
	marked_for_zap NUMBER(1) DEFAULT 0 NOT NULL,
	zap_after_dtm DATE,
	batch_jobs_disabled NUMBER(1) DEFAULT 0 NOT NULL,
	calc_jobs_disabled NUMBER(1) DEFAULT 0 NOT NULL,
	scheduled_tasks_disabled NUMBER(1) DEFAULT 0 NOT NULL,
	alerts_disabled NUMBER(1) DEFAULT 0 NOT NULL,
	prevent_logon NUMBER(1) DEFAULT 0 NOT NULL
);
ALTER TABLE csrimp.customer
ADD (
	CONSTRAINT CK_ALLOW_MARKED_FOR_ZAP CHECK (MARKED_FOR_ZAP IN (0,1)),
	CONSTRAINT CK_ALLOW_BATCH_JOBS_DISABLED CHECK (BATCH_JOBS_DISABLED IN (0,1)),
	CONSTRAINT CK_ALLOW_CALC_JOBS_DISABLED CHECK (CALC_JOBS_DISABLED IN (0,1)),
	CONSTRAINT CK_ALLOW_SCHEDULED_TASKS_DISABLED CHECK (SCHEDULED_TASKS_DISABLED IN (0,1)),
	CONSTRAINT CK_ALLOW_ALERTS_DISABLED CHECK (ALERTS_DISABLED IN (0,1)),
	CONSTRAINT CK_ALLOW_PREVENT_LOGON CHECK (PREVENT_LOGON IN (0,1))
);
GRANT CREATE TABLE TO csr;
BEGIN
	FOR R IN (
		SELECT owner, table_name FROM all_tab_columns 
		 WHERE owner in ('CSR', 'CSRIMP') AND table_name in ('COMPLIANCE_ITEM', 'COMPLIANCE_ITEM_DESCRIPTION', 'COMPLIANCE_AUDIT_LOG') AND column_name = 'SUMMARY' AND data_type = 'VARCHAR2'
	) LOOP
        IF r.owner = 'CSR' AND r.table_name = 'COMPLIANCE_ITEM_DESCRIPTION' THEN
            EXECUTE IMMEDIATE 'BEGIN DBMS_SCHEDULER.DISABLE(''csr.compliance_item_text''); END;';
            EXECUTE IMMEDIATE 'DROP INDEX csr.IX_CI_SUMMARY_SEARCH';
        END IF;
		EXECUTE IMMEDIATE 'ALTER TABLE '||r.owner||'.'||r.table_name||' ADD (temp_summary CLOB)'; 
		EXECUTE IMMEDIATE 'UPDATE '||r.owner||'.'||r.table_name||' SET temp_summary = summary';
		-- Reorders Columns.
		FOR C IN (
			SELECT column_name 
			  FROM all_tab_columns
			 WHERE owner = r.owner
			   AND table_name = r.table_name
			   AND column_id > (SELECT column_id FROM  all_tab_columns WHERE owner = r.owner AND table_name = r.table_name AND column_name = 'SUMMARY')
               AND column_name != 'TEMP_SUMMARY'
			 ORDER BY column_id ASC
		) LOOP
			EXECUTE IMMEDIATE 'ALTER TABLE '||r.owner||'.'||r.table_name||' MODIFY '||c.column_name||' INVISIBLE';
			EXECUTE IMMEDIATE 'ALTER TABLE '||r.owner||'.'||r.table_name||' MODIFY '||c.column_name||' VISIBLE';
		END LOOP;
		EXECUTE IMMEDIATE 'ALTER TABLE '||r.owner||'.'||r.table_name||' RENAME COLUMN summary TO drop_summary';
		EXECUTE IMMEDIATE 'ALTER TABLE '||r.owner||'.'||r.table_name||' RENAME COLUMN temp_summary TO summary'; 		  
		EXECUTE IMMEDIATE 'ALTER TABLE '||r.owner||'.'||r.table_name||' DROP COLUMN drop_summary';
        IF r.owner = 'CSR' AND r.table_name = 'COMPLIANCE_ITEM_DESCRIPTION' THEN
            EXECUTE IMMEDIATE 'CREATE INDEX csr.ix_ci_summary_search on csr.compliance_item_description(summary) indextype IS ctxsys.context PARAMETERS(''datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist'')';
            EXECUTE IMMEDIATE 'BEGIN DBMS_SCHEDULER.ENABLE(''csr.compliance_item_text''); END;';
        END IF;
	END LOOP;
END;
/
ALTER TABLE csr.compliance_item_desc_hist ADD (summary_clob CLOB);
ALTER TABLE csrimp.compliance_item_desc_hist ADD (summary_clob CLOB);


GRANT EXECUTE ON csr.site_name_management_pkg TO tool_user;








DELETE FROM csr.tag_group
 WHERE tag_group_id NOT IN (SELECT tag_group_id FROM csr.tag_group_description)
   AND tag_group_id NOT IN (SELECT tag_group_id FROM csr.tag_group_member);






@..\customer_pkg
@..\templated_report_pkg
@..\compliance_pkg


@..\indicator_body
@..\tag_body
@..\templated_report_schedule_body
@..\customer_body
@..\batch_job_body
@..\stored_calc_datasource_body
@..\schema_body
@..\csrimp\imp_body
@..\templated_report_body
@..\compliance_body
@..\deleg_plan_body
@..\..\..\aspen2\cms\db\tab_body
@..\compliance_library_report_body
@..\compliance_register_report_body
@..\chain\company_filter_body
@..\csr_user_body



@update_tail
