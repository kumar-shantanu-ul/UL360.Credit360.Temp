
ALTER TABLE CSR.METER_READING RENAME CONSTRAINT PK_METER_READING TO PK_METER_READING_OLD;
ALTER INDEX CSR.PK_METER_READING RENAME TO PK_METER_READING_OLD;

-- create new table
CREATE TABLE CSR.METER_READING_NEW(
    APP_SID                 NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    REGION_SID              NUMBER(10, 0)     NOT NULL,
    METER_READING_ID        NUMBER(10, 0)     NOT NULL,
    START_DTM               DATE              NOT NULL,
    END_DTM               	DATE,
    VAL_NUMBER              NUMBER(24, 10),
    ENTERED_BY_USER_SID     NUMBER(10, 0)     NOT NULL,
    ENTERED_DTM             DATE              DEFAULT SYSDATE NOT NULL,
    NOTE                    VARCHAR2(4000),
    REFERENCE               VARCHAR2(1024),
    COST                    NUMBER(24, 10),
    DEMAND                  NUMBER(24, 10),
    METER_DOCUMENT_ID       NUMBER(10, 0),
    CREATED_INVOICE_ID      NUMBER(10, 0),
    METER_SOURCE_TYPE_ID    NUMBER(10, 0)     NOT NULL,
    CONSTRAINT PK_METER_READING PRIMARY KEY (APP_SID, METER_READING_ID)
);

ALTER TABLE CSRIMP.METER_READING RENAME COLUMN READING_DTM TO START_DTM;
ALTER TABLE CSRIMP.METER_READING ADD END_DTM DATE;
DROP TABLE CSRIMP.METER_READING_PERIOD CASCADE CONSTRAINTS;

-- Process the data into the new table
BEGIN
	security.user_pkg.logonadmin;
	
	-- Point in time data
	FOR r IN (
		SELECT app_sid, meter_source_type_id
		  FROM csr.meter_source_type
		 WHERE arbitrary_period = 0
		 	ORDER BY app_sid
	) LOOP
		INSERT INTO csr.meter_reading_new
			(app_sid, region_sid, meter_reading_id, start_dtm, val_number, 
			entered_by_user_sid, entered_dtm, note, reference, cost, demand, 
			meter_document_id, created_invoice_id, meter_source_type_id)
		SELECT app_sid, region_sid, meter_reading_id, reading_dtm, val_number, 
			entered_by_user_sid, entered_dtm, note, reference, cost, demand, 
			meter_document_id, created_invoice_id, meter_source_type_id
		  FROM csr.meter_reading
		 WHERE app_sid = r.app_sid
		   AND meter_source_type_id = r.meter_source_type_id
		;
	END LOOP;
	
	-- Arbitrary period data
	FOR r IN (
		SELECT app_sid, meter_source_type_id
		  FROM csr.meter_source_type
		 WHERE arbitrary_period = 1
		 	ORDER BY app_sid
	) LOOP
		INSERT INTO csr.meter_reading_new
			(app_sid, region_sid, meter_reading_id, start_dtm, end_dtm, val_number, 
			entered_by_user_sid, entered_dtm, note, reference, cost, demand, 
			meter_document_id, created_invoice_id, meter_source_type_id)
		SELECT en.app_sid, en.region_sid, en.meter_reading_id, st.reading_dtm start_dtm, en.reading_dtm end_dtm, en.val_number - st.val_number consumption,
				en.entered_by_user_sid, en.entered_dtm, en.note, en.reference, en.cost, en.demand, 
				en.meter_document_id, en.created_invoice_id, en.meter_source_type_id
		  FROM csr.meter_reading st, csr.meter_reading en, csr.meter_reading_period mrp
		 WHERE st.app_sid = r.app_sid
		   AND en.app_sid = r.app_sid
		   AND st.meter_source_type_id = r.meter_source_type_id
		   AND en.meter_source_type_id = r.meter_source_type_id
		   AND st.region_sid = en.region_sid
		   AND st.meter_reading_id = mrp.start_id
		   AND en.meter_reading_id = mrp.end_id
		;
	END LOOP;
END;
/

-- switch out (rename) old/new tables
ALTER TABLE CSR.METER_READING RENAME TO METER_READING_OLD;
ALTER TABLE CSR.METER_READING_NEW RENAME TO METER_READING;

-- Hook-up constraints to new table
ALTER TABLE CSR.METER_READING ADD CONSTRAINT FK_ALL_METER_METER_READING 
    FOREIGN KEY (APP_SID, REGION_SID)
    REFERENCES CSR.ALL_METER(APP_SID, REGION_SID)
;

-- XXX: NO PK ON METER DOCUMENT!?
/*
ALTER TABLE CSR.METER_READING ADD CONSTRAINT FK_MTR_DOC_METER_READING 
    FOREIGN KEY (APP_SID, METER_DOCUMENT_ID)
    REFERENCES CSR.METER_DOCUMENT(APP_SID, METER_DOCUMENT_ID)
;
*/

ALTER TABLE CSR.METER_READING ADD CONSTRAINT FK_SRC_TYPE_METER_READING 
    FOREIGN KEY (APP_SID, METER_SOURCE_TYPE_ID)
    REFERENCES CSR.METER_SOURCE_TYPE(APP_SID, METER_SOURCE_TYPE_ID)
;

ALTER TABLE CSR.METER_READING ADD CONSTRAINT FK_USER_METER_READING 
    FOREIGN KEY (APP_SID, ENTERED_BY_USER_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;

ALTER TABLE CSR.METER_READING ADD CONSTRAINT FK_UTIL_CONT_METER_READING 
    FOREIGN KEY (APP_SID, CREATED_INVOICE_ID)
    REFERENCES CSR.UTILITY_INVOICE(APP_SID, UTILITY_INVOICE_ID)
;

CREATE INDEX CSR.IX_ALL_METER_METER_READING ON CSR.METER_READING (APP_SID, REGION_SID);
--CREATE INDEX CSR.IX_MTR_DOC_METER_READING ON CSR.METER_READING (APP_SID, METER_DOCUMENT_ID);
CREATE INDEX CSR.IX_SRC_TYPE_METER_READING ON CSR.METER_READING (APP_SID, METER_SOURCE_TYPE_ID);
CREATE INDEX CSR.IX_USER_METER_READING ON CSR.METER_READING (APP_SID, ENTERED_BY_USER_SID);
CREATE INDEX CSR.IX_UTIL_CONT_METER_READING ON CSR.METER_READING (APP_SID, CREATED_INVOICE_ID);


-- remove constraints from old table
BEGIN
	FOR c IN (
		SELECT constraint_name
		  FROM all_constraints
		 WHERE owner = 'CSR'
		   AND table_name = 'METER_READING_OLD'
		   AND constraint_type = 'R'
	) LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.METER_READING_OLD DROP CONSTRAINT ' || c.constraint_name;
	END LOOP;
END;
/

-- v$meter_reading
CREATE OR REPLACE VIEW csr.v$meter_reading AS
	SELECT mr.app_sid, mr.meter_reading_id, mr.region_sid, mr.start_dtm, mr.end_dtm, mr.val_number, mr.entered_by_user_sid, 
		mr.entered_dtm, mr.note, mr.reference, mr.cost, mr.meter_document_id, mr.created_invoice_id
	  FROM csr.all_meter am, csr.meter_reading mr
	 WHERE am.app_sid = mr.app_sid
	   AND am.region_sid = mr.region_sid
	   AND am.meter_source_type_id = mr.meter_source_type_id
;

CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_METER_CONSUMPTION(
	REGION_SID			NUMBER(10)		NOT NULL,
	START_DTM			DATE			NOT NULL,
	END_DTM				DATE			NOT NULL,
	VAL_NUMBER			NUMBER(24, 10),
	PER_DIEM			NUMBER(24, 10)
) ON COMMIT DELETE ROWS;

GRANT SELECT,INSERT ON CSR.METER_READING TO CSRIMP;

-- RLS on new meter reading table
DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
	policy_already_exists exception;
	pragma exception_init(policy_already_exists, -28101);
	type t_tabs is table of varchar2(30);
	v_list t_tabs;
	v_null_list t_tabs;
	v_found number;
begin	
	v_list := t_tabs(
		'METER_READING'
	);
	for i in 1 .. v_list.count loop
		declare
			v_name varchar2(30);
			v_i pls_integer default 1;
		begin
			loop
				begin
					-- verify that the table has an app_sid column (dev helper)
					select count(*) 
					  into v_found
					  from all_tab_columns 
					 where owner = 'CSR' 
					   and table_name = UPPER(v_list(i))
					   and column_name = 'APP_SID';
					
					if v_found = 0 then
						raise_application_error(-20001, 'CSR.'||v_list(i)||' does not have an app_sid column');
					end if;
					
					if v_i = 1 then
						v_name := SUBSTR(v_list(i), 1, 23)||'_POLICY';
					else
						v_name := SUBSTR(v_list(i), 1, 21)||'_POLICY_'||v_i;
					end if;
					dbms_output.put_line('doing '||v_name);
				    dbms_rls.add_policy(
				        object_schema   => 'CSR',
				        object_name     => v_list(i),
				        policy_name     => v_name,
				        function_schema => 'CSR',
				        policy_function => 'appSidCheck',
				        statement_types => 'select, insert, update, delete',
				        update_check	=> true,
				        policy_type     => dbms_rls.context_sensitive );
				    -- dbms_output.put_line('done  '||v_name);
				  	exit;
				exception
					when policy_already_exists then
						v_i := v_i + 1;
					WHEN FEATURE_NOT_ENABLED THEN
						DBMS_OUTPUT.PUT_LINE('RLS policy '||v_name||' not applied as feature not enabled');
						exit;
				end;
			end loop;
		end;
	end loop;
end;
/

@../meter_pkg
@../property_pkg

@../meter_body
@../property_body
@../energy_star_body
@../schema_body
@../utility_body
@../utility_report_body
@../csrimp/imp_body
