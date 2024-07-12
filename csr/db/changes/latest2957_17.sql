-- Please update version.sql too -- this keeps clean builds in sync
define version=2957
define minor_version=17
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
DECLARE
	v_count							NUMBER;	
	FUNCTION IndexColumnsExist (
		in_oracle_schema				IN  VARCHAR2,
		in_oracle_table					IN  VARCHAR2,
		in_index_columns				IN  VARCHAR2
	) RETURN BOOLEAN
	AS
		v_count							NUMBER;
	BEGIN
		SELECT COUNT(*)
		  INTO v_count
		  FROM (
			SELECT LISTAGG(aic.column_name, ', ') WITHIN GROUP (ORDER BY aic.column_position) index_columns
			  FROM all_ind_columns aic
			 WHERE aic.table_name = in_oracle_table
			   AND aic.table_owner = in_oracle_schema 
			 GROUP BY aic.index_owner, aic.index_name
		  ) ic
		 WHERE ic.index_columns = in_index_columns;
		 
		IF v_count = 0 THEN
			RETURN FALSE;
		END IF;		
		RETURN TRUE;
	END;
	PROCEDURE TryCreateIndex (
		in_oracle_schema				IN  VARCHAR2,
		in_oracle_table					IN  VARCHAR2,
		in_full_table_name				IN  VARCHAR2,
		in_index_columns				IN  VARCHAR2,
		in_index_suffix					IN  VARCHAR2
	)
	AS
	BEGIN
		IF in_index_columns IS NOT NULL AND NOT IndexColumnsExist(in_oracle_schema, in_full_table_name, in_index_columns) THEN
			BEGIN
				EXECUTE IMMEDIATE 'CREATE INDEX '||in_oracle_schema||'.IX_'||UPPER(SUBSTR(in_oracle_table, 1, 26-LENGTH(in_index_suffix)))||
					'_'||in_index_suffix||' ON '||in_oracle_schema||'.'||in_full_table_name||' ('||in_index_columns||')';
			EXCEPTION
				WHEN others THEN
					NULL; -- don't care if tables exist/permissions are deniend
			END;
		END IF;
	END;
BEGIN
	security.user_pkg.LogonAdmin;
	
	FOR r IN (
		SELECT *
		  FROM (
			SELECT t.oracle_schema, t.oracle_table, pkc.pk_column, tc.column_sid flow_column_sid, sfkc.securable_fk_columns,
				   CASE WHEN managed = 1 THEN 'C$'||t.oracle_table ELSE t.oracle_table END full_table_name,
				   CASE WHEN managed = 1 
					THEN 'FLOW_ITEM_ID'||NVL2(r.region_columns, ', ', '')||r.region_columns||', RETIRED_DTM, VERS, CONTEXT_ID' 
					ELSE 'FLOW_ITEM_ID'||NVL2(r.region_columns, ', ', '')||r.region_columns 
				   END flow_index_columns,
				   NVL2(r.region_columns, r.region_columns||NVL2(pkc.pk_column, ', '||pkc.pk_column, ''), NULL) region_index_columns
			  FROM cms.tab t
			  LEFT JOIN (
				SELECT app_sid, tab_sid, LISTAGG(oracle_column, ', ') WITHIN GROUP (ORDER BY oracle_column) region_columns
				  FROM cms.tab_column tc
				 WHERE col_type = 24
				 GROUP BY app_sid, tab_sid
			  ) r ON t.app_sid = r.app_sid AND t.tab_sid = r.tab_sid
			  LEFT JOIN (
				SELECT ucc.app_sid, ucc.uk_cons_id, MIN(tc.oracle_column) pk_column
				  FROM cms.tab_column tc
				  JOIN cms.uk_cons_col ucc ON tc.app_sid = ucc.app_sid AND tc.column_sid = ucc.column_sid
				 GROUP BY ucc.app_sid, ucc.uk_cons_id
				HAVING COUNT(*) = 1
			  ) pkc ON t.managed = 1 AND t.app_sid = pkc.app_sid AND t.pk_cons_id = pkc.uk_cons_id
			  LEFT JOIN (
				SELECT t.app_sid, t.tab_sid, LISTAGG(tc.oracle_column) WITHIN GROUP (ORDER BY fcc.pos) securable_fk_columns
				  FROM cms.tab t
				  JOIN cms.fk_cons_col fcc ON t.app_sid = fcc.app_sid AND t.securable_fk_cons_id = fcc.fk_cons_id
				  JOIN cms.tab_column tc ON fcc.app_sid = tc.app_sid AND fcc.column_sid = tc.column_sid
				 WHERE t.securable_fk_cons_id IS NOT NULL
				 GROUP BY t.app_sid, t.tab_sid
			  ) sfkc ON t.app_sid = sfkc.app_sid AND t.tab_sid = sfkc.tab_sid
			  LEFT JOIN cms.tab_column tc ON t.app_sid = tc.app_sid AND t.tab_sid = tc.tab_sid AND tc.col_type = 23 AND tc.oracle_column = 'FLOW_ITEM_ID'
			 WHERE is_view = 0
			 ORDER BY t.oracle_schema, t.oracle_table
		  )
		 WHERE pk_column IS NOT NULL 
		    OR flow_column_sid IS NOT NULL
			OR securable_fk_columns IS NOT NULL
	) LOOP
		IF r.flow_column_sid IS NOT NULL THEN
			TryCreateIndex(r.oracle_schema, r.oracle_table, r.full_table_name, r.flow_index_columns, 'FLOW');
			TryCreateIndex(r.oracle_schema, r.oracle_table, r.full_table_name, r.region_index_columns, 'REG');
		END IF;
		
		TryCreateIndex(r.oracle_schema, r.oracle_table, r.full_table_name, r.pk_column, 'PK');
		TryCreateIndex(r.oracle_schema, r.oracle_table, r.full_table_name, r.securable_fk_columns, 'SFK');
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../../../aspen2/cms/db/tab_body

@update_tail
