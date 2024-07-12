-- Please update version.sql too -- this keeps clean builds in sync
define version=2844
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables
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

-- Alter tables

-- this stuff seems to be missing from some databases -- latest1900 dropped it for some reason or other
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
--  parallel_enable
  aggregate using stragg3_type
;
/

-- *** Grants ***
grant select,insert on csr.region_start_point to csrimp;
grant select,insert,update,delete on csrimp.region_start_point to web_user;
grant select on csr.region_start_point to actions;
grant select on csr.region_start_point to cms;
grant execute on csr.stragg3 to actions;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***
column ethics_script_path new_value ethics_script_path noprint;
select decode(cnt, 0, 'null_script.sql', '../ethics/company_user_body') ethics_script_path 
from (select count(*) cnt from all_users where username='ETHICS');
PROMPT Running &ethics_script_path
@&ethics_script_path

@../../../aspen2/cms/db/tab_body
@../../../aspen2/db/aspen_user_pkg
@../../../aspen2/db/fp_user_pkg
@../actions/gantt_body
@../actions/initiative_body
@../actions/initiative_pkg
@../actions/setup_body
@../actions/task_body
@../actions/task_pkg
@../campaign_body
@../campaign_pkg
@../chain/company_user_body
@../csr_app_body
@../csr_user_body
@../csr_user_pkg
@../csrimp/imp_body
@../delegation_body
@../delegation_pkg
@../doc_body
@../doc_pkg
@../enable_body
@../indicator_body
@../indicator_pkg
@../initiative_body
@../issue_body
@../issue_pkg
@../issue_report_body
@../meter_body
@../meter_pkg
@../pending_body
@../quick_survey_body
@../region_body
@../region_pkg
@../security_functions
@../schema_body
@../schema_pkg
@../snapshot_body
@../snapshot_pkg
@../supplier/chain/company_user_body
@../supplier/chain/registration_body
@../supplier_body
@../teamroom_body
@../training_body
@../training_pkg
@../unit_test_body
@../utility_report_body
@../val_body
@../vb_legacy_body
@../vb_legacy_pkg

@update_tail
