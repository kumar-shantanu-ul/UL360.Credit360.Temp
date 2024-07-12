define version=2853
define minor_version=0
define is_combined=1
@update_header

update security.user_table
   set account_enabled = 0
 where sid_id in ( 
   select cu.csr_user_sid
   from csr.region r
   join csr.csr_user cu on cu.region_mount_point_sid = r.region_sid and cu.app_sid != r.app_sid
   join csr.customer c on c.app_sid = cu.app_sid
);

update csr.csr_user
   set region_mount_point_sid = null
 where csr_user_sid in (
   select cu.csr_user_sid
   from csr.region r
   join csr.csr_user cu on cu.region_mount_point_sid = r.region_sid and cu.app_sid != r.app_sid
   join csr.customer c on c.app_sid = cu.app_sid
);

update security.user_table
   set account_enabled = 0
 where sid_id in (
   select cu.csr_user_sid
     from csr.csr_user cu 
    where region_mount_point_sid not in (
      select region_sid
        from csr.region
   )
);

update csr.csr_user
   set region_mount_point_sid = null
 where csr_user_sid in (
   select cu.csr_user_sid
     from csr.csr_user cu 
    where region_mount_point_sid not in (
      select region_sid
        from csr.region
   )
);

CREATE SEQUENCE CSR.METER_DATA_ID_SEQ
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20
	NOORDER
;
	CREATE SEQUENCE CSR.METER_AGGREGATE_TYPE_ID_SEQ
	START WITH 10000
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20
	NOORDER
;
CREATE TABLE CSR.METER_DATA_ID(
	APP_SID							NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	REGION_SID						NUMBER(10, 0)	NOT NULL,
	METER_BUCKET_ID					NUMBER(10, 0)	NOT NULL,
	METER_INPUT_ID					NUMBER(10, 0)	NOT NULL,
	AGGREGATOR						VARCHAR2(32)	NOT NULL,
	PRIORITY						NUMBER(10, 0)	NOT NULL,
	START_DTM						DATE			NOT NULL,
	METER_DATA_ID					NUMBER(10, 0)	NOT NULL,
	CONSTRAINT PK_METER_DATA_ID PRIMARY KEY (APP_SID, REGION_SID, METER_BUCKET_ID, METER_INPUT_ID, AGGREGATOR, PRIORITY, START_DTM)
);
CREATE TABLE CSR.METER_AGGREGATE_TYPE(
	APP_SID							NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	METER_AGGREGATE_TYPE_ID			NUMBER(10, 0)	NOT NULL,
	METER_INPUT_ID					NUMBER(10, 0)	NOT NULL,
	AGGREGATOR						VARCHAR2(32)	NOT NULL,
	ANALYTIC_FUNCTION				NUMBER(10, 0)	NOT NULL,
	DESCRIPTION						VARCHAR2(255)	NOT NULL,
	CONSTRAINT PK_METER_AGGREGATE_TYPE PRIMARY KEY (APP_SID, METER_AGGREGATE_TYPE_ID)
);
ALTER TABLE CSR.METER_AGGREGATE_TYPE ADD (
	ACCUMULATIVE					NUMBER(1)		DEFAULT 0 NOT NULL,
	CONSTRAINT CHK_MTR_AGG_TYP_CUMULATIVE_1_0 CHECK (ACCUMULATIVE IN (1, 0))
);
CREATE TABLE CSRIMP.METER_DATA_ID(
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	REGION_SID						NUMBER(10, 0)	NOT NULL,
	METER_BUCKET_ID					NUMBER(10, 0)	NOT NULL,
	METER_INPUT_ID					NUMBER(10, 0)	NOT NULL,
	AGGREGATOR						VARCHAR2(32) 	NOT NULL,
	PRIORITY						NUMBER(10, 0)	NOT NULL,
	START_DTM						DATE			NOT NULL,
	METER_DATA_ID					NUMBER(10, 0)	NOT NULL,
	CONSTRAINT PK_METER_DATA_ID PRIMARY KEY (CSRIMP_SESSION_ID, REGION_SID, METER_BUCKET_ID, METER_INPUT_ID, AGGREGATOR, PRIORITY, START_DTM),
	CONSTRAINT FK_METER_DATA_ID FOREIGN KEY
	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
	ON DELETE CASCADE
);
CREATE TABLE CSRIMP.METER_AGGREGATE_TYPE(
	CSRIMP_SESSION_ID				NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	METER_AGGREGATE_TYPE_ID			NUMBER(10, 0)	NOT NULL,
	METER_INPUT_ID					NUMBER(10, 0)	NULL,
	AGGREGATOR						VARCHAR2(32)	NOT NULL,
	ANALYTIC_FUNCTION				NUMBER(10, 0)	NOT NULL,
	DESCRIPTION						VARCHAR2(255)	NOT NULL,
	CONSTRAINT PK_METER_AGGREGATE_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, METER_AGGREGATE_TYPE_ID),
	CONSTRAINT FK_METER_AGGREGATE_TYPE FOREIGN KEY
	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
	ON DELETE CASCADE
);
ALTER TABLE CSRIMP.METER_AGGREGATE_TYPE ADD (
	ACCUMULATIVE					NUMBER(1)		NOT NULL,
	CONSTRAINT CHK_MTR_AGG_TYP_CUMULATIVE_1_0 CHECK (ACCUMULATIVE IN (1, 0))
);
CREATE TABLE csrimp.map_meter_data_id  (
	CSRIMP_SESSION_ID				NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_meter_data_id				NUMBER(10)		NOT NULL,
	new_meter_data_id				NUMBER(10)		NOT NULL,
	CONSTRAINT pk_map_meter_data_id primary key (csrimp_session_id, old_meter_data_id) USING INDEX,
	CONSTRAINT uk_map_meter_bucket_id unique (csrimp_session_id, new_meter_data_id) USING INDEX,
    CONSTRAINT fk_map_meter_data_id FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);
CREATE TABLE csrimp.map_meter_aggregate_type  (
	CSRIMP_SESSION_ID				NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_meter_aggregate_type_id		NUMBER(10)		NOT NULL,
	new_meter_aggregate_type_id		NUMBER(10)		NOT NULL,
	CONSTRAINT pk_map_meter_aggregate_type primary key (csrimp_session_id, old_meter_aggregate_type_id) USING INDEX,
	CONSTRAINT uk_map_meter_aggregate_type unique (csrimp_session_id, new_meter_aggregate_type_id) USING INDEX,
    CONSTRAINT fk_map_meter_aggregate_type FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);
CREATE UNIQUE INDEX CSR.UK_METER_DATA_ID ON CSR.METER_DATA_ID(APP_SID, METER_DATA_ID);
CREATE INDEX CSR.IX_METER_DATA_ID_REGION ON CSR.METER_DATA_ID(APP_SID, REGION_SID);
CREATE INDEX CSR.IX_METER_DATA_ID_APP ON CSR.METER_DATA_ID(APP_SID);
CREATE INDEX CSR.IX_METER_LIVE_DATA_APP ON CSR.METER_LIVE_DATA(APP_SID);
CREATE TABLE chain.saved_filter_region (	
	app_sid							NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	saved_filter_sid				NUMBER(10)		NOT NULL,
	region_sid						NUMBER(10)		NOT NULL,
	CONSTRAINT pk_saved_filter_region PRIMARY KEY (app_sid, saved_filter_sid, region_sid),
	CONSTRAINT fk_svd_fltr_region_svd_fltr FOREIGN KEY (app_sid, saved_filter_sid)
		REFERENCES chain.saved_filter (app_sid, saved_filter_sid),
	CONSTRAINT fk_svd_fltr_region_region FOREIGN KEY (app_sid, region_sid)
		REFERENCES csr.region (app_sid, region_sid)
);
CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_METER_REGION_TAG (
	REGION_SID						NUMBER(10)		NOT NULL,
	TAG_ID							NUMBER(10)
) ON COMMIT DELETE ROWS;
CREATE TABLE CSR.METERING_OPTIONS(
    APP_SID							NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    ANALYTICS_MONTHS				NUMBER(10, 0),
    ANALYTICS_CURRENT_MONTH			NUMBER(1, 0) 	DEFAULT 0 NOT NULL,
    CHECK (ANALYTICS_CURRENT_MONTH IN(0,1)),
    CONSTRAINT PK_METERING_OPTIONS PRIMARY KEY (APP_SID)
);
CREATE TABLE CSRIMP.METERING_OPTIONS(
    CSRIMP_SESSION_ID				NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    ANALYTICS_MONTHS				NUMBER(10, 0),
    ANALYTICS_CURRENT_MONTH			NUMBER(1, 0)	DEFAULT 0 NOT NULL,
    CHECK (ANALYTICS_CURRENT_MONTH IN(0,1)),
    CONSTRAINT PK_METERING_OPTIONS PRIMARY KEY (CSRIMP_SESSION_ID)
);
CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_METER_PATCH_IMPORT_ROWS (
	SOURCE_ROW						NUMBER(10),
	REGION_SID						NUMBER(10),
	METER_INPUT_ID					NUMBER(10),
	PRIORITY						NUMBER(10),
	START_DTM						DATE,
	END_DTM							DATE,
	VAL								NUMBER(24,10),
	ERROR_MSG						VARCHAR(4000)
) ON COMMIT DELETE ROWS;
CREATE TABLE csrimp.chain_saved_filter_region (	
	csrimp_session_id				NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	saved_filter_sid				NUMBER(10)		NOT NULL,
	region_sid						NUMBER(10)		NOT NULL,
	CONSTRAINT pk_saved_filter_region PRIMARY KEY (csrimp_session_id, saved_filter_sid, region_sid),	
	CONSTRAINT fk_chain_saved_fltr_region_is FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);
CREATE TABLE CSR.REGION_START_POINT(
    APP_SID     					NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    USER_SID    					NUMBER(10, 0)    NOT NULL,
    REGION_SID  					NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_REGION_START_POINT PRIMARY KEY (APP_SID, USER_SID, REGION_SID),
    CONSTRAINT FK_IND_START_POINT_USER FOREIGN KEY (APP_SID, USER_SID)
    REFERENCES CSR.CSR_USER (APP_SID, CSR_USER_SID)
);
CREATE INDEX CSR.IX_REGION_START_POINT_REGION ON CSR.REGION_START_POINT (APP_SID, REGION_SID);
ALTER TABLE CSR.REGION_START_POINT ADD
    CONSTRAINT FK_REGION_START_POINT_REGION FOREIGN KEY (APP_SID, REGION_SID)
    REFERENCES CSR.REGION (APP_SID, REGION_SID);
CREATE TABLE CSRIMP.REGION_START_POINT(
    CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    USER_SID    					NUMBER(10, 0)    NOT NULL,
    REGION_SID  					NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_REGION_START_POINT PRIMARY KEY (CSRIMP_SESSION_ID, USER_SID, REGION_SID),
    CONSTRAINT FK_REGION_START_POINT_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);
INSERT INTO CSR.REGION_START_POINT (APP_SID, USER_SID, REGION_SID)
	SELECT CU.APP_SID, CU.CSR_USER_SID, NVL(CU.REGION_MOUNT_POINT_SID, C.REGION_ROOT_SID)
	  FROM CSR.CSR_USER CU, CSR.CUSTOMER C
	 WHERE CU.APP_SID = C.APP_SID;
	  
ALTER TABLE CSR.CSR_USER DROP COLUMN REGION_MOUNT_POINT_SID CASCADE CONSTRAINTS;
ALTER TABLE CSR.CSR_USER DROP COLUMN IMP_SESSION_MOUNT_POINT_SID CASCADE CONSTRAINTS;
ALTER TABLE CSRIMP.CSR_USER DROP COLUMN REGION_MOUNT_POINT_SID CASCADE CONSTRAINTS;
ALTER TABLE CSRIMP.CSR_USER DROP COLUMN IMP_SESSION_MOUNT_POINT_SID CASCADE CONSTRAINTS;
CREATE OR REPLACE VIEW csr.V$ACTIVE_USER AS
	SELECT cu.csr_user_sid, cu.email, cu.app_sid, cu.full_name,
	  	   cu.user_name, cu.info_xml, cu.send_alerts, cu.guid, cu.friendly_name, 
	  	   ut.language, ut.culture, ut.timezone
	  FROM csr_user cu, security.user_table ut
	 WHERE cu.csr_user_sid = ut.sid_id
	   AND ut.account_enabled = 1;
CREATE OR REPLACE VIEW csr.v$csr_user AS
	SELECT cu.app_sid, cu.csr_user_sid, cu.email, cu.full_name, cu.user_name, cu.send_alerts,
		   cu.guid, cu.friendly_name, cu.info_xml, cu.show_portal_help, cu.donations_browse_filter_id, cu.donations_reports_filter_id,
		   cu.hidden, cu.phone_number, cu.job_title, ut.account_enabled active, ut.last_logon, cu.created_dtm, ut.expiration_dtm, 
		   ut.language, ut.culture, ut.timezone, so.parent_sid_id, cu.last_modified_dtm, cu.last_logon_type_Id, cu.line_manager_sid
      FROM csr_user cu, security.securable_object so, security.user_table ut, customer c
     WHERE cu.app_sid = c.app_sid
       AND cu.csr_user_sid = so.sid_id
       AND so.parent_sid_id != c.trash_sid
       AND ut.sid_id = so.sid_id
       AND cu.hidden = 0;

ALTER TABLE chain.customer_options ADD INVITATION_EXPIRATION_REM_DAYS NUMBER(10) DEFAULT 5 NOT NULL;
ALTER TABLE chain.customer_options ADD INVITATION_EXPIRATION_REM NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE chain.invitation ADD REMINDER_SENT NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE CSR.METER_DATA_ID ADD CONSTRAINT FK_METLIVDAT_METLIVDATID 
    FOREIGN KEY (APP_SID, REGION_SID, METER_BUCKET_ID, METER_INPUT_ID, AGGREGATOR, PRIORITY, START_DTM)
    REFERENCES CSR.METER_LIVE_DATA(APP_SID, REGION_SID, METER_BUCKET_ID, METER_INPUT_ID, AGGREGATOR, PRIORITY, START_DTM)
    ON DELETE CASCADE
;
ALTER TABLE CSR.METER_AGGREGATE_TYPE ADD CONSTRAINT FK_METINPAGGR_METAGGRTYPE 
    FOREIGN KEY (APP_SID, METER_INPUT_ID, AGGREGATOR)
    REFERENCES CSR.METER_INPUT_AGGREGATOR(APP_SID, METER_INPUT_ID, AGGREGATOR)
;
ALTER TABLE CSR.METER_AGGREGATE_TYPE ADD CONSTRAINT PK_CUSTOMER_METAGGRTYPE 
    FOREIGN KEY (APP_SID)
    REFERENCES CSR.CUSTOMER(APP_SID)
;
GRANT SELECT, REFERENCES ON csr.meter_aggregate_type TO chain;
ALTER TABLE chain.customer_aggregate_type ADD (
	meter_aggregate_type_id			NUMBER(10),
	CONSTRAINT fk_cust_agg_type_meter_agg_typ FOREIGN KEY (app_sid, meter_aggregate_type_id)
		REFERENCES csr.meter_aggregate_type (app_sid, meter_aggregate_type_id)
		ON DELETE CASCADE
);
ALTER TABLE chain.customer_aggregate_type DROP CONSTRAINT chk_customer_aggregate_type;
ALTER TABLE chain.customer_aggregate_type ADD CONSTRAINT chk_customer_aggregate_type
	CHECK ((cms_aggregate_type_id IS NOT NULL AND initiative_metric_id IS NULL AND ind_sid IS NULL AND filter_page_ind_interval_id IS NULL AND meter_aggregate_type_id IS NULL)
	   OR (cms_aggregate_type_id IS NULL AND initiative_metric_id IS NOT NULL AND ind_sid IS NULL AND filter_page_ind_interval_id IS NULL AND meter_aggregate_type_id IS NULL)
	   OR (cms_aggregate_type_id IS NULL AND initiative_metric_id IS NULL AND ind_sid IS NOT NULL AND filter_page_ind_interval_id IS NULL AND meter_aggregate_type_id IS NULL)
	   OR (cms_aggregate_type_id IS NULL AND initiative_metric_id IS NULL AND ind_sid IS NULL AND filter_page_ind_interval_id IS NOT NULL AND meter_aggregate_type_id IS NULL)
	   OR (cms_aggregate_type_id IS NULL AND initiative_metric_id IS NULL AND ind_sid IS NULL AND filter_page_ind_interval_id IS NULL AND meter_aggregate_type_id IS NOT NULL));
	   
DROP INDEX CHAIN.UK_CUSTOMER_AGGREGATE_TYPE;
CREATE UNIQUE INDEX CHAIN.UK_CUSTOMER_AGGREGATE_TYPE ON CHAIN.CUSTOMER_AGGREGATE_TYPE (
		APP_SID, CARD_GROUP_ID, CMS_AGGREGATE_TYPE_ID, INITIATIVE_METRIC_ID, IND_SID, FILTER_PAGE_IND_INTERVAL_ID, METER_AGGREGATE_TYPE_ID)
;
	   
	   
ALTER TABLE csrimp.chain_customer_aggregate_type ADD (
	meter_aggregate_type_id			NUMBER(10)
);
ALTER TABLE csrimp.chain_customer_aggregate_type DROP CONSTRAINT chk_customer_aggregate_type;
ALTER TABLE csrimp.chain_customer_aggregate_type ADD CONSTRAINT chk_customer_aggregate_type
	CHECK ((cms_aggregate_type_id IS NOT NULL AND initiative_metric_id IS NULL AND ind_sid IS NULL AND filter_page_ind_interval_id IS NULL AND meter_aggregate_type_id IS NULL)
	   OR (cms_aggregate_type_id IS NULL AND initiative_metric_id IS NOT NULL AND ind_sid IS NULL AND filter_page_ind_interval_id IS NULL AND meter_aggregate_type_id IS NULL)
	   OR (cms_aggregate_type_id IS NULL AND initiative_metric_id IS NULL AND ind_sid IS NOT NULL AND filter_page_ind_interval_id IS NULL AND meter_aggregate_type_id IS NULL)
	   OR (cms_aggregate_type_id IS NULL AND initiative_metric_id IS NULL AND ind_sid IS NULL AND filter_page_ind_interval_id IS NOT NULL AND meter_aggregate_type_id IS NULL)
	   OR (cms_aggregate_type_id IS NULL AND initiative_metric_id IS NULL AND ind_sid IS NULL AND filter_page_ind_interval_id IS NULL AND meter_aggregate_type_id IS NOT NULL));
ALTER TABLE CSR.METER_INPUT ADD (
	IS_VIRTUAL					NUMBER(1, 0)	DEFAULT 0 NOT NULL,
	VALUE_HELPER				VARCHAR2(256),
	CONSTRAINT CHK_METER_INPUT_IS_VIRTUAL_1_0 CHECK (IS_VIRTUAL IN(0,1))
);
DROP TYPE CHAIN.T_FILTER_AGG_TYPE_TABLE;
CREATE OR REPLACE TYPE CHAIN.T_FILTER_AGG_TYPE_ROW AS 
	 OBJECT ( 
		CARD_GROUP_ID				NUMBER(10),
		AGGREGATE_TYPE_ID			NUMBER(10),	
		DESCRIPTION 				VARCHAR2(1023),
		FORMAT_MASK					VARCHAR2(255),
		FILTER_PAGE_IND_INTERVAL_ID	NUMBER(10),
		ACCUMULATIVE				NUMBER(1)
	 ); 
/
CREATE OR REPLACE TYPE CHAIN.T_FILTER_AGG_TYPE_TABLE AS 
	TABLE OF CHAIN.T_FILTER_AGG_TYPE_ROW;
/
create index chain.ix_customer_aggr_meter_aggrega on chain.customer_aggregate_type (app_sid, meter_aggregate_type_id);
create index chain.ix_saved_filter_region_sid on chain.saved_filter_region (app_sid, region_sid);
ALTER TABLE CSR.UTIL_SCRIPT_PARAM ADD PARAM_VALUE VARCHAR2(1024);
ALTER TABLE CSR.UTIL_SCRIPT_PARAM ADD PARAM_HIDDEN NUMBER(1) DEFAULT 0 NOT NULL;


CREATE OR REPLACE TYPE csr.stragg3_type AS OBJECT
(
m_string	VARCHAR2(4000),
m_clob		CLOB,
m_first 	NUMBER(1),
m_sep 		VARCHAR2(1),
STATIC FUNCTION ODCIAggregateInitialize
(
	sctx							IN OUT stragg3_type
)
RETURN NUMBER,
MEMBER FUNCTION ODCIAggregateIterate
(
	self						IN OUT stragg3_type,
	value						IN VARCHAR2
)
RETURN NUMBER,
MEMBER FUNCTION ODCIAggregateTerminate
(
	self        				IN stragg3_type,
	returnvalue					OUT CLOB,
	flags						IN NUMBER
)
RETURN NUMBER,
MEMBER FUNCTION ODCIAggregateMerge
(
	self 						IN OUT NOCOPY stragg3_type,
	ctx2 						IN stragg3_type
)
RETURN NUMBER
);
/
CREATE OR REPLACE TYPE BODY csr.stragg3_type
IS
STATIC FUNCTION ODCIAggregateInitialize
(
	sctx							IN OUT stragg3_type
)
RETURN NUMBER
IS
BEGIN  
	-- check if there's any separator set, otherwise use default ',' 
    sctx := stragg3_type( null, null, 1, NVL(SYS_CONTEXT('SECURITY', 'STRAGG2_SEP'), ',') ) ;
    RETURN ODCIConst.Success;
END;
MEMBER FUNCTION ODCIAggregateIterate
(
	self						IN OUT stragg3_type,
	value						IN VARCHAR2
)
RETURN NUMBER
IS
	v_len 							NUMBER;
BEGIN
	IF self.m_clob IS NULL THEN
		v_len := NVL(LENGTHB(value), 0) + CASE WHEN self.m_first = 0 THEN 1 ELSE 0 END;
		IF NVL(LENGTHB(m_string), 0) + v_len <= 4000 THEN
			IF self.m_first = 0 THEN
				self.m_string := self.m_string || self.m_sep;
			END IF;
			self.m_first := 0;
			self.m_string := self.m_string || value;
			RETURN ODCIConst.Success;
		END IF;
		
	    dbms_lob.createtemporary(self.m_clob, TRUE, dbms_lob.call);
		dbms_lob.open(self.m_clob, dbms_lob.lob_readwrite);
		
		IF m_string IS NOT NULL THEN
			dbms_lob.writeappend(self.m_clob, LENGTH(self.m_string), self.m_string);
		END IF;
	END IF;
	
	IF self.m_first = 0 THEN
  		dbms_lob.writeappend(self.m_clob, 1, self.m_sep);
	END IF;
	self.m_first := 0;
	dbms_lob.writeappend(self.m_clob, LENGTH(value), value);
	return ODCIConst.Success;
END;
MEMBER FUNCTION ODCIAggregateTerminate
(
	self        				IN stragg3_type,
	returnvalue					OUT CLOB,
	flags						IN NUMBER
)
RETURN NUMBER
IS
BEGIN
	--  Can't close this, oh well...
	--  dbms_lob.close(self.string);
	IF self.m_clob IS NULL THEN
		returnValue := self.m_string;
	ELSE
    	returnValue := self.m_clob;
	END IF;
    return ODCIConst.Success;
END;
MEMBER FUNCTION ODCIAggregateMerge
(
	self 						IN OUT NOCOPY stragg3_type,
	ctx2 						IN stragg3_type
)
RETURN NUMBER
IS
BEGIN
	IF ctx2.m_clob IS NULL THEN
		IF ctx2.m_string IS NOT NULL THEN
			return self.ODCIAggregateIterate(ctx2.m_string);
		END IF;
		-- (else there's no input data)
	ELSE
		IF self.m_clob IS NULL THEN
		    dbms_lob.createtemporary(self.m_clob, TRUE, dbms_lob.call);
			dbms_lob.open(self.m_clob, dbms_lob.lob_readwrite);
			
			IF m_string IS NOT NULL THEN
				dbms_lob.writeappend(self.m_clob, LENGTH(self.m_string), self.m_string);
			END IF;
		END IF;
		
		IF self.m_first = 0 THEN
  			dbms_lob.writeappend(self.m_clob, 1, self.m_sep);
		END IF;
		self.m_first := 0;
		
		-- Gets ORA-22922: nonexistent LOB value
		-- ORA-06512: at "SYS.DBMS_LOB", line 639
		-- ORA-06512: at "CSR.STRAGG3_TYPE", line 108
		-- 22922. 00000 -  "nonexistent LOB value"
		-- *Cause:    The LOB value associated with the input locator does not exist.
        --   The information in the locator does not refer to an existing LOB.
		-- *Action:   Repopulate the locator by issuing a select statement and retry
        --   the operation.
        -- I think the issue must the temporary lobs from the other parallel server
        -- session can't be seen (the lob value isn't null)
        -- Worked around by not marking the function as parallel_enable
        -- which seems to stop e.g.
        -- select /*+ parallel(ss 2) */ csr.stragg3(s) from mark.ss
        -- from failing at least.
		dbms_lob.append(self.m_clob, ctx2.m_clob);
	END IF;
    return ODCIConst.Success;
END;
END;
/
create or replace function csr.stragg3
  ( input varchar2 )
  return clob
  deterministic
  aggregate using stragg3_type
;
/
ALTER TABLE CHAIN.FILTER_FIELD ADD SHOW_OTHER NUMBER(1);
ALTER TABLE CSRIMP.CHAIN_FILTER_FIELD ADD SHOW_OTHER NUMBER(1);
UPDATE chain.filter_field
   SET show_other = 1
 WHERE top_n IS NOT NULL
    OR bottom_n IS NOT NULL;
UPDATE csrimp.chain_filter_field
   SET show_other = 1
 WHERE top_n IS NOT NULL
    OR bottom_n IS NOT NULL;
ALTER TABLE CHAIN.FILTER_FIELD ADD CONSTRAINT CHK_FLTR_FLD_SHO_OTH_0_1 CHECK ((TOP_N IS NULL AND BOTTOM_N IS NULL) OR SHOW_OTHER IN (0,1)),
ALTER TABLE CSRIMP.CHAIN_FILTER_FIELD ADD CONSTRAINT CHK_FLTR_FLD_SHO_OTH_0_1 CHECK ((TOP_N IS NULL AND BOTTOM_N IS NULL) OR SHOW_OTHER IN (0,1)),

GRANT SELECT ON chain.saved_filter_region TO csr;
GRANT SELECT, INSERT, UPDATE ON chain.saved_filter_region TO csrimp;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.meter_data_id TO web_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.meter_aggregate_type TO web_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.metering_options TO web_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.chain_saved_filter_region TO web_user;
GRANT SELECT ON csr.meter_aggregate_type_id_seq TO csrimp;
GRANT SELECT ON csr.meter_data_id_seq TO csrimp;
GRANT SELECT, INSERT, UPDATE ON csr.meter_data_id TO csrimp;
GRANT SELECT, INSERT, UPDATE ON csr.meter_aggregate_type TO csrimp;
GRANT SELECT, INSERT, UPDATE ON csr.metering_options TO csrimp;
grant execute on chain.t_filter_agg_type_table TO csr;
grant execute on chain.t_filter_agg_type_row TO csr;
grant execute on chain.t_filter_agg_type_table TO cms;
grant execute on chain.t_filter_agg_type_row TO cms;
grant insert,select,update,delete on csrimp.region_start_point to web_user;
grant select,insert on csr.region_start_point to csrimp;
grant select,insert,update,delete on csrimp.region_start_point to web_user;
grant select on csr.region_start_point to actions;
grant select on csr.region_start_point to cms;
grant execute on csr.stragg3 to actions;


CREATE OR REPLACE VIEW CSR.V$PATCHED_METER_LIVE_DATA AS
	SELECT app_sid, region_sid, meter_input_id, aggregator, meter_bucket_id, 
			priority, start_dtm, end_dtm, meter_raw_data_id, modified_dtm, consumption
	  FROM (
		SELECT mld.app_sid, mld.region_sid, mld.meter_input_id, mld.aggregator, mld.meter_bucket_id, 
				mld.priority, mld.start_dtm, mld.end_dtm, mld.meter_raw_data_id, mld.modified_dtm, mld.consumption,
			ROW_NUMBER() OVER (PARTITION BY mld.app_sid, mld.region_sid, mld.meter_input_id, mld.aggregator, mld.meter_bucket_id, mld.start_dtm ORDER BY mld.priority DESC) rn
		  FROM csr.meter_live_data mld
	 )
	 WHERE rn = 1;
UPDATE security.menu
   SET action = '/csr/site/admin/trash/trash.acds'
 WHERE LOWER(action) = LOWER('/csr/site/admin/trash.acds');
CREATE OR REPLACE VIEW CHAIN.v$filter_field AS
	SELECT f.app_sid, f.filter_id, ff.filter_field_id, ff.name, ff.show_all, ff.group_by_index,
		   f.compound_filter_id, ff.top_n, ff.bottom_n, ff.column_sid, ff.period_set_id,
		   ff.period_interval_id, ff.show_other
	  FROM filter f
	  JOIN filter_field ff ON f.app_sid = ff.app_sid AND f.filter_id = ff.filter_id;

DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
    POLICY_ALREADY_EXISTS EXCEPTION;
    PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
BEGIN
 	FOR r IN (
		SELECT c.owner, c.table_name, c.nullable, (SUBSTR(c.table_name, 1, 26) || '_POL') policy_name
		  FROM all_tables t
		  JOIN all_tab_columns c ON t.owner = c.owner AND t.table_name = c.table_name
		 WHERE t.owner IN ('CSRIMP') AND (t.dropped = 'NO' OR t.dropped IS NULL) AND c.column_name = 'CSRIMP_SESSION_ID'
		   AND t.table_name IN ('CHAIN_SAVED_FILTER_REGION', 'METER_DATA_ID', 'METER_AGGREGATE_TYPE', 'MAP_METER_AGGREGATE_TYPE', 'MAP_METER_DATA_ID', 'METERING_OPTIONS')
 	)
 	LOOP
		dbms_output.put_line('Writing policy '||r.policy_name);
		dbms_rls.add_policy(
			object_schema   => r.owner,
			object_name     => r.table_name,
			policy_name     => r.policy_name, 
			function_schema => 'CSRIMP',
			policy_function => 'SessionIDCheck',
			statement_types => 'select, insert, update, delete',
			update_check	=> true,
			policy_type     => dbms_rls.context_sensitive);
	END LOOP;
EXCEPTION
	WHEN POLICY_ALREADY_EXISTS THEN
		DBMS_OUTPUT.PUT_LINE('Policy exists');
	WHEN FEATURE_NOT_ENABLED THEN
		DBMS_OUTPUT.PUT_LINE('RLS policies not applied as feature not enabled');
END;
/

BEGIN
	INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from, std_alert_type_group_id) VALUES (5029,
		'Chain invitation expiration reminder',
		'A chain invitation is about to expire.',
		'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).',
		8
	);
EXCEPTION
	WHEN dup_val_on_index THEN
		UPDATE csr.std_alert_type SET
			description = 'Chain invitation expiration reminder',
			send_trigger = 'A chain invitation is about to expire.',
			sent_from = 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
		WHERE std_alert_type_id = 5029;
END;
/	
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5029, 0, 'TO_NAME', 'To full name', 'The name of the user the alert is being sent to', 1);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5029, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5029, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5029, 0, 'TO_COMPANY', 'To company', 'The company of the user the alert is being sent to', 4);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5029, 0, 'FROM_NAME', 'From full name', 'The name of the user the alert is being sent from', 5);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5029, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 6);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5029, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 7);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5029, 0, 'FROM_JOBTITLE', 'From jobtitle', 'The job title of the user the alert is being sent from', 8);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5029, 0, 'FROM_COMPANY', 'From company', 'The company of the user the alert is being sent from', 9);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5029, 1, 'QUESTIONNAIRE_NAME', 'Questionnaire name', 'The questionnaire name', 10);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5029, 0, 'LINK', 'Link', 'A hyperlink to the questionnaire', 11);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5029, 0, 'EXPIRATION', 'Expiration', 'The date the invitation expires', 12);		
DECLARE
	v_card_id         chain.card.card_id%TYPE;
	v_desc            chain.card.description%TYPE;
	v_class           chain.card.class_type%TYPE;
	v_js_path         chain.card.js_include%TYPE;
	v_js_class        chain.card.js_class_type%TYPE;
	v_css_path        chain.card.css_include%TYPE;
	v_actions         chain.T_STRING_LIST;
BEGIN
	-- Credit360.Property.Filters.PropertyFilter
	v_desc := 'Meter Data Filter';
	v_class := 'Credit360.Metering.Cards.MeterDataFilter';
	v_js_path := '/csr/site/meter/filters/MeterDataFilter.js';
	v_js_class := 'Credit360.Metering.Filters.MeterDataFilter';
	v_css_path := '';
	
	BEGIN
		INSERT INTO chain.card (card_id, description, class_type, js_include, js_class_type, css_include)
		VALUES (chain.card_id_seq.NEXTVAL, v_desc, v_class, v_js_path, v_js_class, v_css_path)
		RETURNING card_id INTO v_card_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE chain.card
			SET description = v_desc, class_type = v_class, js_include = v_js_path, css_include = v_css_path
			WHERE js_class_type = v_js_class
			RETURNING card_id INTO v_card_id;
	END;
	
	DELETE FROM chain.card_progression_action
	WHERE card_id = v_card_id
	AND action NOT IN ('default');
	
	v_actions := chain.T_STRING_LIST('default');
	
	FOR i IN v_actions.FIRST .. v_actions.LAST
	LOOP
		BEGIN
			INSERT INTO chain.card_progression_action (card_id, action)
			VALUES (v_card_id, v_actions(i));
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;
END;
/
DECLARE
	v_card_id	NUMBER(10);
BEGIN
	BEGIN
		INSERT INTO chain.card_group(card_group_id, name, description, helper_pkg, list_page_url)
		VALUES(46, 'Meter Data Filter', 'Allows filtering of meter data', 'csr.meter_report_pkg', '/csr/site/meter/list.acds?savedFilterSid=');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Credit360.Metering.Filters.MeterDataFilter';
	
	BEGIN	
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		    VALUES (chain.filter_type_id_seq.NEXTVAL, 'Meter Data Filter', 'csr.meter_report_pkg', v_card_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	-- setup filter card for all sites with initiatives
	FOR r IN (
		SELECT DISTINCT app_sid
		  FROM csr.meter_source_type
	) LOOP
		INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position)
		     VALUES (r.app_sid, 46, v_card_id, 0);
	END LOOP;
END;
/
BEGIN
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (46, 1, 'Total consumption');
	
	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
	VALUES (46, 1, 1, 'Meter region');
		
	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
	VALUES (46, 2, 2, 'Start date');
END;
/
DELETE FROM chain.card_group_column_type
	  WHERE card_group_id = 46
	    AND description = 'End date';
UPDATE chain.aggregate_type
   SET description = 'Total consumption'
 WHERE card_group_id = 46
   AND aggregate_type_id = 1;
DECLARE
	v_plugin_id			csr.plugin.plugin_id%TYPE;
BEGIN
	BEGIN
		INSERT INTO csr.plugin
			(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path)
		VALUES 
			(csr.plugin_id_seq.nextval, 1, 'Meter data list', 
				'/csr/site/meter/controls/meterListTab.js', 'Credit360.Metering.MeterListTab', 'Credit360.Metering.Plugins.MeterList', 
				'Quick Charts tab for meter data', '/csr/shared/plugins/screenshots/property_tab_meter_list.png');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
END;
/
DECLARE
	v_exists NUMBER;
BEGIN
	UPDATE csr.ind
	   SET gas_type_id = NULL,
		   map_to_ind_sid = NULL
	 WHERE DECODE(map_to_ind_sid, NULL, 0, 1) != DECODE(gas_type_id, NULL, 0, 1);
	SELECT COUNT(*)
	  INTO v_exists
	  FROM sys.all_constraints
	 WHERE owner = 'CSR'
	   AND table_name = 'IND'
	   AND constraint_name = 'CK_IND_GAS_SETTINGS';
	IF v_exists = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE csr.ind 
							 ADD CONSTRAINT ck_ind_gas_settings CHECK (
								(gas_type_id IS NULL AND map_to_ind_sid IS NULL) OR
								(gas_type_id IS NOT NULL AND map_to_ind_sid IS NOT NULL)
						   )';
	END IF;
END;
/
INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID, UTIL_SCRIPT_NAME, DESCRIPTION, UTIL_SCRIPT_SP, WIKI_ARTICLE)
VALUES (9, 'Enable/Disable automatic parent-child sheet status matching', 'Updates customer.status_from_parent_on_subdeleg. See wiki for details.', 'SetFlag', 'W2570');
INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint, pos, param_value, param_hidden)
VALUES (9, 'Table', 'Fixed Param', 0, 'csr.customer', 1);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint, pos, param_value, param_hidden)
VALUES (9, 'Column', 'Fixed Param', 1, 'status_from_parent_on_subdeleg', 1);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint, pos)
VALUES (9, 'Setting value (0 off, 1 on)', 'The setting to use.', 2);
UPDATE CSR.UTIL_SCRIPT
   SET util_script_name = 'Toggle multi-period delegation flag',
       util_script_sp = 'ToggleDelegMultiPeriodFlag'
 WHERE util_script_id=4;
BEGIN
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
		 VALUES (57, 'Delegation status reports', 'EnableDelegationStatusReports', 'Enables delegation status reports');
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN NULL;
END;
/

CREATE OR REPLACE PACKAGE csr.meter_report_pkg AS END;
/
GRANT EXECUTE ON csr.meter_report_pkg TO web_user;
GRANT EXECUTE ON csr.meter_report_pkg TO chain;

@..\chain\invitation_pkg
@..\chain\chain_pkg
@..\chain\filter_pkg
@..\meter_report_pkg
@..\meter_pkg
@..\meter_monitor_pkg
@..\schema_pkg
@..\enable_pkg
@..\audit_report_pkg
@..\chain\company_filter_pkg
@..\initiative_report_pkg
@..\issue_report_pkg
@..\non_compliance_report_pkg
@..\property_report_pkg
@..\..\..\aspen2\cms\db\filter_pkg
@..\meter_patch_pkg
@..\util_script_pkg
@..\automated_import_pkg
@..\automated_export_pkg
@..\automated_export_import_pkg
@..\csr_data_pkg
@..\dataview_pkg
@..\indicator_pkg
@..\quick_survey_pkg
@..\region_pkg
@..\trash_pkg
@..\..\..\aspen2\db\aspen_user_pkg
@..\..\..\aspen2\db\fp_user_pkg
@..\actions\initiative_pkg
@..\actions\task_pkg
@..\campaign_pkg
@..\csr_user_pkg
@..\delegation_pkg
@..\doc_pkg
@..\issue_pkg
@..\snapshot_pkg
@..\training_pkg
@..\vb_legacy_pkg

column ethics_script_path new_value ethics_script_path noprint;
select decode(cnt, 0, 'null_script.sql', '..\ethics\company_user_pkg') ethics_script_path 
from (select count(*) cnt from all_users where username='ETHICS');
PROMPT Running &ethics_script_path
@&ethics_script_path

@..\quick_survey_body
@..\chain\plugin_body
@..\chain\invitation_body
@..\chain\setup_body
@..\factor_body
@..\chain\filter_body
@..\chain\chain_body
@..\meter_report_body
@..\meter_body
@..\meter_monitor_body
@..\meter_patch_body
@..\schema_body
@..\enable_body
@..\property_body
@..\csrimp\imp_body
@..\audit_report_body
@..\chain\company_filter_body
@..\initiative_report_body
@..\issue_report_body
@..\non_compliance_report_body
@..\property_report_body
@..\..\..\aspen2\cms\db\filter_body
@..\csr_app_body
@..\region_list_body
@..\util_script_body
@..\chain\company_body
@..\automated_import_body
@..\automated_export_body
@..\automated_export_import_body
@..\dataview_body
@..\indicator_body
@..\region_body
@..\trash_body

column ethics_script_path new_value ethics_script_path noprint;
select decode(cnt, 0, 'null_script.sql', '..\ethics\company_user_body') ethics_script_path 
from (select count(*) cnt from all_users where username='ETHICS');
PROMPT Running &ethics_script_path
@&ethics_script_path

@..\..\..\aspen2\cms\db\tab_body
@..\actions\gantt_body
@..\actions\initiative_body
@..\actions\setup_body
@..\actions\task_body
@..\campaign_body
@..\chain\company_user_body
@..\csr_user_body
@..\delegation_body
@..\doc_body
@..\initiative_body
@..\issue_body
@..\pending_body
@..\snapshot_body
@..\supplier\chain\company_user_body
@..\supplier\chain\registration_body
@..\supplier_body
@..\teamroom_body
@..\training_body
@..\unit_test_body
@..\utility_report_body
@..\val_body
@..\vb_legacy_body
@..\energy_star_body
@..\security_functions

@update_tail
