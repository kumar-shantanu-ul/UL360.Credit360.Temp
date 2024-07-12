-- Please update version.sql too -- this keeps clean builds in sync
define version=3310
define minor_version=8
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
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

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../compliance_body
@../compliance_library_report_body
@../compliance_register_report_body
@../schema_body
@../csrimp/imp_body

@update_tail
