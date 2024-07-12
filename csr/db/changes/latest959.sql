-- Please update version.sql too -- this keeps clean builds in sync
define version=959
@update_header

DECLARE
	v_exists NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_exists
	  FROM all_users
	 WHERE username = 'CHEM';
	IF v_exists <> 0 THEN
		EXECUTE IMMEDIATE 'DROP USER CHEM CASCADE';
	END IF;
END;
/

CREATE USER "CHEM" IDENTIFIED BY "CHEM" QUOTA UNLIMITED ON USERS;
-- USER SQL
ALTER USER "CHEM" 
DEFAULT TABLESPACE "USERS"
TEMPORARY TABLESPACE "TEMP"
ACCOUNT UNLOCK;

GRANT CREATE SESSION TO "CHEM";

grant references on csr.region to chem;
grant references on csr.customer to chem;
grant references on csr.file_upload to chem;

grant execute on security.security_pkg to chem;
grant execute on security.acl_pkg to chem;
grant execute on security.class_pkg to chem;
grant execute on security.securableobject_pkg to chem;

grant execute on csr.fileupload_pkg to chem;
grant execute on csr.csr_data_pkg to chem;

grant select on aspen2.filecache to chem;
grant select on csr.region to chem;

grant execute on security.user_pkg to chem;
grant execute on csr.region_pkg to chem;
grant execute on csr.sqlreport_pkg to chem;

/* ---------------------------------------------------------------------- */
/* Script generated with: DeZign for Databases V7.1.1                     */
/* Target DBMS:           Oracle 10g                                      */
/* Project file:          chem.dez                                        */
/* Project name:                                                          */
/* Author:                                                                */
/* Script type:           Database creation script                        */
/* Created on:            2012-06-08 12:17                                */
/* ---------------------------------------------------------------------- */


/* ---------------------------------------------------------------------- */
/* Sequences                                                              */
/* ---------------------------------------------------------------------- */

CREATE SEQUENCE CHEM.SUBSTANCE_USE_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    nocycle
    CACHE 5
    noorder;

CREATE SEQUENCE CHEM.PROCESS_DEST_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    nocycle
    CACHE 5
    noorder;

CREATE SEQUENCE CHEM.MANUFACTURER_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    nocycle
    CACHE 5
    noorder;

CREATE SEQUENCE CHEM.USAGE_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    nocycle
    CACHE 5
    noorder;

CREATE SEQUENCE CHEM.SUBSTANCE_USE_FILE_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    nocycle
    CACHE 5
    noorder;

CREATE SEQUENCE CHEM.SUBSTANCE_FILE_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    nocycle
    CACHE 5
    noorder;

CREATE SEQUENCE CHEM.CLASSIFICATION_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    nocycle
    CACHE 5
    noorder;

CREATE SEQUENCE CHEM.SUBSTANCE_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    nocycle
    CACHE 5
    noorder;

CREATE SEQUENCE CHEM.PROCESS_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    nocycle
    CACHE 5
    noorder;

/* ---------------------------------------------------------------------- */
/* Tables                                                                 */
/* ---------------------------------------------------------------------- */

/* ---------------------------------------------------------------------- */
/* Add table "CAS"                                                        */
/* ---------------------------------------------------------------------- */

CREATE TABLE CHEM.CAS (
    CAS_CODE VARCHAR2(50) NOT NULL,
    NAME VARCHAR2(200) NOT NULL,
    UNCONFIRMED NUMBER(1) DEFAULT 0 NOT NULL,
    CONSTRAINT PK_CAS PRIMARY KEY (CAS_CODE)
);

ALTER TABLE CHEM.CAS ADD CONSTRAINT CHK_CAS_UNCONFIRMED 
    CHECK (UNCONFIRMED IN (0,1));

COMMENT ON TABLE CHEM.CAS IS 'desc="CAS Codes", desc_col=cas_code,cmseditor';

COMMENT ON COLUMN CHEM.CAS.CAS_CODE IS 'desc="CAS Code"';

COMMENT ON COLUMN CHEM.CAS.NAME IS 'desc="Name"';

/* ---------------------------------------------------------------------- */
/* Add table "CAS_RESTRICTED"                                             */
/* ---------------------------------------------------------------------- */

CREATE TABLE CHEM.CAS_RESTRICTED (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    CAS_CODE VARCHAR2(50) NOT NULL,
    ROOT_REGION_SID NUMBER(10) NOT NULL,
    START_DTM DATE,
    END_DTM DATE,
    CATEGORY VARCHAR2(20),
    REMARKS VARCHAR2(2048),
    SOURCE VARCHAR2(200),
    CLP_TABLE_3_1 VARCHAR2(1024),
    CLP_TABLE_3_2 VARCHAR2(1024),
    CONSTRAINT PK_CAS_RESTRICTED PRIMARY KEY (APP_SID, CAS_CODE, ROOT_REGION_SID)
);

COMMENT ON TABLE CHEM.CAS_RESTRICTED IS 'desc="CAS Restrictions", desc_col=cas_code,cmseditor';

COMMENT ON COLUMN CHEM.CAS_RESTRICTED.APP_SID IS 'app_sid';

COMMENT ON COLUMN CHEM.CAS_RESTRICTED.CAS_CODE IS 'desc="CAS Code"';

COMMENT ON COLUMN CHEM.CAS_RESTRICTED.ROOT_REGION_SID IS 'region';

COMMENT ON COLUMN CHEM.CAS_RESTRICTED.START_DTM IS 'desc="Start Date"';

COMMENT ON COLUMN CHEM.CAS_RESTRICTED.END_DTM IS 'desc="End Date"';

COMMENT ON COLUMN CHEM.CAS_RESTRICTED.CATEGORY IS 'desc="Category"';

COMMENT ON COLUMN CHEM.CAS_RESTRICTED.REMARKS IS 'desc="Remarks"';

COMMENT ON COLUMN CHEM.CAS_RESTRICTED.SOURCE IS 'desc="Source"';

COMMENT ON COLUMN CHEM.CAS_RESTRICTED.CLP_TABLE_3_1 IS 'desc="CLP Table 3.1 classification"';

COMMENT ON COLUMN CHEM.CAS_RESTRICTED.CLP_TABLE_3_2 IS 'desc="CLP Table 3.2 classification"';

/* ---------------------------------------------------------------------- */
/* Add table "CLASSIFICATION"                                             */
/* ---------------------------------------------------------------------- */

CREATE TABLE CHEM.CLASSIFICATION (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    CLASSIFICATION_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(100),
    CONSTRAINT PK_CLASSIFICATION PRIMARY KEY (APP_SID, CLASSIFICATION_ID)
);

CREATE UNIQUE INDEX CHEM.UK_CLASSIFICATION ON CHEM.CLASSIFICATION (APP_SID,UPPER(DESCRIPTION));

COMMENT ON TABLE CHEM.CLASSIFICATION IS 'desc="Substance Classification"';

/* ---------------------------------------------------------------------- */
/* Add table "MANUFACTURER"                                               */
/* ---------------------------------------------------------------------- */

CREATE TABLE CHEM.MANUFACTURER (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    MANUFACTURER_ID NUMBER(10) NOT NULL,
    CODE VARCHAR2(50) NOT NULL,
    CONSTRAINT PK_MANUFACTURER PRIMARY KEY (APP_SID, MANUFACTURER_ID)
);

CREATE UNIQUE INDEX CHEM.UK_MANUFACTURER ON CHEM.MANUFACTURER (APP_SID,UPPER(CODE));

COMMENT ON TABLE CHEM.MANUFACTURER IS 'desc="Manufacturer Code"';

/* ---------------------------------------------------------------------- */
/* Add table "SUBSTANCE"                                                  */
/* ---------------------------------------------------------------------- */

CREATE TABLE CHEM.SUBSTANCE (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    SUBSTANCE_ID NUMBER(10) NOT NULL,
    REF VARCHAR2(20),
    DESCRIPTION VARCHAR2(500),
    CLASSIFICATION_ID NUMBER(10) NOT NULL,
    MANUFACTURER_ID NUMBER(10) NOT NULL,
    REGION_SID NUMBER(10),
    CONSTRAINT PK_SUBSTANCE PRIMARY KEY (APP_SID, SUBSTANCE_ID)
);

COMMENT ON TABLE CHEM.SUBSTANCE IS 'desc="Substance"';

COMMENT ON COLUMN CHEM.SUBSTANCE.APP_SID IS 'app_sid';

COMMENT ON COLUMN CHEM.SUBSTANCE.SUBSTANCE_ID IS 'desc="Id", auto';

COMMENT ON COLUMN CHEM.SUBSTANCE.REF IS 'desc="Reference Number"';

COMMENT ON COLUMN CHEM.SUBSTANCE.DESCRIPTION IS 'desc="Description"';

COMMENT ON COLUMN CHEM.SUBSTANCE.CLASSIFICATION_ID IS 'desc="Substance Classification",enum,enum_desc_col=description,enum_pos_col=classification_id';

COMMENT ON COLUMN CHEM.SUBSTANCE.MANUFACTURER_ID IS 'desc="Manufacturer Code",enum,enum_desc_col=code,enum_pos_col=manufacturer_id';

/* ---------------------------------------------------------------------- */
/* Add table "SUBSTANCE_CAS"                                              */
/* ---------------------------------------------------------------------- */

CREATE TABLE CHEM.SUBSTANCE_CAS (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    SUBSTANCE_ID NUMBER(10) NOT NULL,
    CAS_CODE VARCHAR2(50) NOT NULL,
    PCT_COMPOSITION NUMBER(5,4),
    CONSTRAINT PK_SUBSTANCE_CAS PRIMARY KEY (APP_SID, SUBSTANCE_ID, CAS_CODE)
);

COMMENT ON TABLE CHEM.SUBSTANCE_CAS IS 'desc="Substance CAS"';

COMMENT ON COLUMN CHEM.SUBSTANCE_CAS.APP_SID IS 'app_sid';

COMMENT ON COLUMN CHEM.SUBSTANCE_CAS.SUBSTANCE_ID IS 'desc="Substance"';

COMMENT ON COLUMN CHEM.SUBSTANCE_CAS.CAS_CODE IS 'desc="CAS Code"';

COMMENT ON COLUMN CHEM.SUBSTANCE_CAS.PCT_COMPOSITION IS 'desc="Percentage Composition"';

/* ---------------------------------------------------------------------- */
/* Add table "SUBSTANCE_FILE"                                             */
/* ---------------------------------------------------------------------- */

CREATE TABLE CHEM.SUBSTANCE_FILE (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    SUBSTANCE_FILE_ID NUMBER(10) NOT NULL,
    SUBSTANCE_ID NUMBER(10) NOT NULL,
    DATA BLOB,
    UPLOADED_DTM DATE DEFAULT SYSDATE,
    UPLOADED_USER_SID NUMBER(10),
    MIME_TYPE VARCHAR2(256) NOT NULL,
    URL VARCHAR2(2048),
    FILENAME VARCHAR2(2048),
    CONSTRAINT PK_SUBSTANCE_FILE PRIMARY KEY (APP_SID, SUBSTANCE_FILE_ID),
    CONSTRAINT TCC_SUBSTANCE_FILE_1 CHECK (((FILENAME IS NULL AND MIME_TYPE IS NULL) AND URL IS NOT NULL) OR ((FILENAME IS NOT NULL AND MIME_TYPE IS NOT NULL) AND URL IS NULL))
);

COMMENT ON TABLE CHEM.SUBSTANCE_FILE IS 'desc="Substance Reference"';

COMMENT ON COLUMN CHEM.SUBSTANCE_FILE.APP_SID IS 'app_sid';

COMMENT ON COLUMN CHEM.SUBSTANCE_FILE.SUBSTANCE_ID IS 'desc="Substance"';

COMMENT ON COLUMN CHEM.SUBSTANCE_FILE.DATA IS 'desc="Reference Document", file, file_mime=mime_type,file_name=filename';

/* ---------------------------------------------------------------------- */
/* Add table "USAGE"                                                      */
/* ---------------------------------------------------------------------- */

CREATE TABLE CHEM.USAGE (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    USAGE_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(100),
    CONSTRAINT PK_USAGE PRIMARY KEY (APP_SID, USAGE_ID)
);

CREATE UNIQUE INDEX CHEM.UK_USAGE ON CHEM.USAGE (APP_SID,UPPER(DESCRIPTION));

COMMENT ON TABLE CHEM.USAGE IS 'desc="Usage"';

COMMENT ON COLUMN CHEM.USAGE.APP_SID IS 'app_sid';

COMMENT ON COLUMN CHEM.USAGE.DESCRIPTION IS 'desc="Description"';

/* ---------------------------------------------------------------------- */
/* Add table "WAIVER"                                                     */
/* ---------------------------------------------------------------------- */

CREATE TABLE CHEM.WAIVER (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    SUBSTANCE_ID NUMBER(10) NOT NULL,
    CAS_CODE VARCHAR2(50) NOT NULL,
    REGION_SID NUMBER(10) NOT NULL,
    COMMENTS VARCHAR2(2048),
    EXPIRES_DTM DATE,
    DENIED NUMBER(1) NOT NULL,
    CONSTRAINT PK_WAIVER PRIMARY KEY (APP_SID, SUBSTANCE_ID, CAS_CODE, REGION_SID),
    CONSTRAINT CHK_WAIVER_DENIED CHECK ( DENIED IN (0,1))
);

COMMENT ON TABLE CHEM.WAIVER IS 'desc="Waiver"';

COMMENT ON COLUMN CHEM.WAIVER.APP_SID IS 'app_sid';

COMMENT ON COLUMN CHEM.WAIVER.SUBSTANCE_ID IS 'desc="Substance"';

COMMENT ON COLUMN CHEM.WAIVER.CAS_CODE IS 'desc="CAS Code"';

COMMENT ON COLUMN CHEM.WAIVER.REGION_SID IS 'region';

COMMENT ON COLUMN CHEM.WAIVER.COMMENTS IS 'desc="Comments"';

COMMENT ON COLUMN CHEM.WAIVER.EXPIRES_DTM IS 'desc="Expires Date"';

COMMENT ON COLUMN CHEM.WAIVER.DENIED IS 'desc="Denied"';

/* ---------------------------------------------------------------------- */
/* Add table "WAIVER_STATUS"                                              */
/* ---------------------------------------------------------------------- */

CREATE TABLE CHEM.WAIVER_STATUS (
    WAIVER_STATUS_ID NUMBER(1) NOT NULL,
    DESCRIPTION VARCHAR2(40) NOT NULL,
    CONSTRAINT PK_WAIVER_STATUS PRIMARY KEY (WAIVER_STATUS_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "SUBSTANCE_REGION"                                           */
/* ---------------------------------------------------------------------- */

CREATE TABLE CHEM.SUBSTANCE_REGION (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    SUBSTANCE_ID NUMBER(10) NOT NULL,
    REGION_SID NUMBER(10) NOT NULL,
    WAIVER_STATUS_ID NUMBER(1),
    CONSTRAINT PK_SUBSTANCE_REGION PRIMARY KEY (APP_SID, SUBSTANCE_ID, REGION_SID)
);

COMMENT ON TABLE CHEM.SUBSTANCE_REGION IS 'desc="Substance Region"';

COMMENT ON COLUMN CHEM.SUBSTANCE_REGION.APP_SID IS 'app_sid';

COMMENT ON COLUMN CHEM.SUBSTANCE_REGION.SUBSTANCE_ID IS 'desc="Substance"';

COMMENT ON COLUMN CHEM.SUBSTANCE_REGION.REGION_SID IS 'region';

COMMENT ON COLUMN CHEM.SUBSTANCE_REGION.WAIVER_STATUS_ID IS 'desc="Waiver Status",enum,enum_desc_col=description,enum_pos_col=waiver_status_id';

/* ---------------------------------------------------------------------- */
/* Add table "PROCESS"                                                    */
/* ---------------------------------------------------------------------- */

CREATE TABLE CHEM.PROCESS (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    PROCESS_ID NUMBER(10) CONSTRAINT NN_PROCESS_PROCESS_ID NOT NULL,
    SUBSTANCE_ID NUMBER(10) CONSTRAINT NN_PROCESS_SUBSTANCE_ID NOT NULL,
    REGION_SID NUMBER(10) NOT NULL,
    LABEL VARCHAR2(255) DEFAULT 'Default' NOT NULL,
    ACTIVE NUMBER(1) DEFAULT 1 NOT NULL,
    CONSTRAINT PK_PROCESS PRIMARY KEY (APP_SID, PROCESS_ID, SUBSTANCE_ID, REGION_SID)
);

CREATE UNIQUE INDEX CHEM.IDX_PROCESS_1 ON CHEM.PROCESS (APP_SID,SUBSTANCE_ID,REGION_SID,UPPER(LABEL));

ALTER TABLE CHEM.PROCESS ADD CONSTRAINT CHK_PROCESS_ACTIVE 
    CHECK (ACTIVE IN (0,1));

/* ---------------------------------------------------------------------- */
/* Add table "PROCESS_DESTINATION"                                        */
/* ---------------------------------------------------------------------- */

CREATE TABLE CHEM.PROCESS_DESTINATION (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    PROCESS_DESTINATION_ID NUMBER(10) NOT NULL,
    PROCESS_ID NUMBER(10),
    SUBSTANCE_ID NUMBER(10),
    REGION_SID NUMBER(10),
    TO_AIR_PCT NUMBER(5,4) NOT NULL,
    TO_PRODUCT_PCT NUMBER(5,4) NOT NULL,
    TO_WASTE_PCT NUMBER(5,4) NOT NULL,
    TO_WATER_PCT NUMBER(5,4) NOT NULL,
    REMAINING_PCT NUMBER(5,4) NOT NULL,
    REMAINING_DEST VARCHAR2(100) NOT NULL,
    MAIN_USAGE_ID NUMBER(10) NOT NULL,
    COMMENTS VARCHAR2(2048),
    ACTIVE NUMBER(1),
    CONSTRAINT PK_PROCESS_DESTINATION PRIMARY KEY (APP_SID, PROCESS_DESTINATION_ID)
);

CREATE UNIQUE INDEX CHEM.UK_PROCESS_DESTINATION_1 ON CHEM.PROCESS_DESTINATION (APP_SID,CASE WHEN ACTIVE = 0 THEN PROCESS_DESTINATION_ID WHEN ACTIVE = 1 THEN -1 END,PROCESS_ID);

ALTER TABLE CHEM.PROCESS_DESTINATION ADD CONSTRAINT CHK_PROCESS_DESTINATION_ACTIVE 
    CHECK (ACTIVE IN (0,1));

COMMENT ON TABLE CHEM.PROCESS_DESTINATION IS 'desc="Substance Destination"';

COMMENT ON COLUMN CHEM.PROCESS_DESTINATION.APP_SID IS 'app_sid';

COMMENT ON COLUMN CHEM.PROCESS_DESTINATION.PROCESS_DESTINATION_ID IS 'desc="Id", auto';

COMMENT ON COLUMN CHEM.PROCESS_DESTINATION.TO_AIR_PCT IS 'desc="Percentage to Air"';

COMMENT ON COLUMN CHEM.PROCESS_DESTINATION.TO_PRODUCT_PCT IS 'desc="Percentage to Product"';

COMMENT ON COLUMN CHEM.PROCESS_DESTINATION.TO_WASTE_PCT IS 'desc="Percentage to Waste"';

COMMENT ON COLUMN CHEM.PROCESS_DESTINATION.TO_WATER_PCT IS 'desc="Percentage to Water"';

COMMENT ON COLUMN CHEM.PROCESS_DESTINATION.REMAINING_PCT IS 'desc="Remaining Percentage"';

COMMENT ON COLUMN CHEM.PROCESS_DESTINATION.REMAINING_DEST IS 'desc="Remaining Destination"';

COMMENT ON COLUMN CHEM.PROCESS_DESTINATION.MAIN_USAGE_ID IS 'desc="Main Usage", enum, enum_desc_col=description';

COMMENT ON COLUMN CHEM.PROCESS_DESTINATION.COMMENTS IS 'desc="Comments"';

/* ---------------------------------------------------------------------- */
/* Add table "SUBSTANCE_USE"                                              */
/* ---------------------------------------------------------------------- */

CREATE TABLE CHEM.SUBSTANCE_USE (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    SUBSTANCE_USE_ID NUMBER(10) NOT NULL,
    SUBSTANCE_ID NUMBER(10) NOT NULL,
    REGION_SID NUMBER(10) NOT NULL,
    PROCESS_DESTINATION_ID NUMBER(10),
    ROOT_DELEGATION_SID NUMBER(10) NOT NULL,
    MASS_VALUE NUMBER(24,10),
    NOTE CLOB,
    START_DTM DATE,
    END_DTM DATE,
    ENTRY_STD_MEASURE_CONV_ID NUMBER(10),
    ENTRY_MASS_VALUE NUMBER(24,10),
    CONSTRAINT PK_SUBSTANCE_USE PRIMARY KEY (APP_SID, SUBSTANCE_USE_ID, SUBSTANCE_ID, REGION_SID),
    CONSTRAINT UC_SUBSTANCE_USE_1 UNIQUE (APP_SID, SUBSTANCE_ID, REGION_SID, START_DTM, END_DTM, ROOT_DELEGATION_SID)
);

CREATE INDEX CHEM.IDX_SUBSTANCE_USE_1 ON CHEM.SUBSTANCE_USE (APP_SID,REGION_SID,START_DTM,END_DTM,NVL(PROCESS_DESTINATION_ID,-1));

ALTER TABLE CHEM.SUBSTANCE_USE ADD CONSTRAINT CK_SUBST_USE_END_DTM 
    CHECK (TRUNC(END_DTM,'MON')=END_DTM);

ALTER TABLE CHEM.SUBSTANCE_USE ADD CONSTRAINT CK_SUBST_USE_START_DTM 
    CHECK (TRUNC(START_DTM,'MON') = START_DTM);

COMMENT ON TABLE CHEM.SUBSTANCE_USE IS 'desc="Substance Use"';

COMMENT ON COLUMN CHEM.SUBSTANCE_USE.APP_SID IS 'app_sid';

COMMENT ON COLUMN CHEM.SUBSTANCE_USE.SUBSTANCE_USE_ID IS 'desc="Id", auto';

COMMENT ON COLUMN CHEM.SUBSTANCE_USE.SUBSTANCE_ID IS 'desc="Substance"';

COMMENT ON COLUMN CHEM.SUBSTANCE_USE.REGION_SID IS 'region';

COMMENT ON COLUMN CHEM.SUBSTANCE_USE.MASS_VALUE IS 'desc="Mass"';

COMMENT ON COLUMN CHEM.SUBSTANCE_USE.NOTE IS 'desc="Note"';

COMMENT ON COLUMN CHEM.SUBSTANCE_USE.START_DTM IS 'desc="Start Date"';

COMMENT ON COLUMN CHEM.SUBSTANCE_USE.END_DTM IS 'desc="End Date"';

COMMENT ON COLUMN CHEM.SUBSTANCE_USE.ENTRY_STD_MEASURE_CONV_ID IS 'desc="Entry STD Measure"';

COMMENT ON COLUMN CHEM.SUBSTANCE_USE.ENTRY_MASS_VALUE IS 'desc="Entry Mass"';

/* ---------------------------------------------------------------------- */
/* Add table "SUBSTANCE_USE_FILE"                                         */
/* ---------------------------------------------------------------------- */

CREATE TABLE CHEM.SUBSTANCE_USE_FILE (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    SUBSTANCE_USE_FILE_ID NUMBER(10) NOT NULL,
    SUBSTANCE_USE_ID NUMBER(10),
    DATA BLOB,
    UPLOADED_DTM DATE DEFAULT SYSDATE,
    UPLOADED_USER_SID NUMBER(10),
    MIME_TYPE VARCHAR2(255),
    FILENAME VARCHAR2(2048),
    SUBSTANCE_ID NUMBER(10),
    REGION_SID NUMBER(10),
    CONSTRAINT PK_SUBSTANCE_USE_FILE PRIMARY KEY (APP_SID, SUBSTANCE_USE_FILE_ID)
);

COMMENT ON TABLE CHEM.SUBSTANCE_USE_FILE IS 'desc="Substance Reference"';

COMMENT ON COLUMN CHEM.SUBSTANCE_USE_FILE.APP_SID IS 'app_sid';

COMMENT ON COLUMN CHEM.SUBSTANCE_USE_FILE.DATA IS 'desc="Reference Document", file, file_mime=mime_type,file_name=filename';

/* ---------------------------------------------------------------------- */
/* Foreign key constraints                                                */
/* ---------------------------------------------------------------------- */

ALTER TABLE CHEM.CAS_RESTRICTED ADD CONSTRAINT FK_CAS_CAS_RESTR 
    FOREIGN KEY (CAS_CODE) REFERENCES CHEM.CAS (CAS_CODE);

ALTER TABLE CHEM.SUBSTANCE ADD CONSTRAINT FK_MFR_SUBST 
    FOREIGN KEY (APP_SID, MANUFACTURER_ID) REFERENCES CHEM.MANUFACTURER (APP_SID,MANUFACTURER_ID);

ALTER TABLE CHEM.SUBSTANCE ADD CONSTRAINT FK_CLASSIF_SUBST 
    FOREIGN KEY (APP_SID, CLASSIFICATION_ID) REFERENCES CHEM.CLASSIFICATION (APP_SID,CLASSIFICATION_ID);

ALTER TABLE CHEM.SUBSTANCE_CAS ADD CONSTRAINT FK_CAS_SUBST_CAS 
    FOREIGN KEY (CAS_CODE) REFERENCES CHEM.CAS (CAS_CODE);

ALTER TABLE CHEM.SUBSTANCE_CAS ADD CONSTRAINT FK_SUBST_SUBST_CAS 
    FOREIGN KEY (APP_SID, SUBSTANCE_ID) REFERENCES CHEM.SUBSTANCE (APP_SID,SUBSTANCE_ID);

ALTER TABLE CHEM.PROCESS_DESTINATION ADD CONSTRAINT FK_USAGE_PROC_DEST 
    FOREIGN KEY (APP_SID, MAIN_USAGE_ID) REFERENCES CHEM.USAGE (APP_SID,USAGE_ID);

ALTER TABLE CHEM.PROCESS_DESTINATION ADD CONSTRAINT FK_PROC_PROC_DEST 
    FOREIGN KEY (APP_SID, PROCESS_ID, SUBSTANCE_ID, REGION_SID) REFERENCES CHEM.PROCESS (APP_SID,PROCESS_ID,SUBSTANCE_ID,REGION_SID);

ALTER TABLE CHEM.SUBSTANCE_FILE ADD CONSTRAINT FK_SUBST_SUBST_FILE 
    FOREIGN KEY (APP_SID, SUBSTANCE_ID) REFERENCES CHEM.SUBSTANCE (APP_SID,SUBSTANCE_ID);

ALTER TABLE CHEM.SUBSTANCE_REGION ADD CONSTRAINT FK_SUBST_SUBST_RGN 
    FOREIGN KEY (APP_SID, SUBSTANCE_ID) REFERENCES CHEM.SUBSTANCE (APP_SID,SUBSTANCE_ID);

ALTER TABLE CHEM.SUBSTANCE_REGION ADD CONSTRAINT FK_WAIVR_STAT_SUBST_RGN 
    FOREIGN KEY (WAIVER_STATUS_ID) REFERENCES CHEM.WAIVER_STATUS (WAIVER_STATUS_ID);

ALTER TABLE CHEM.SUBSTANCE_USE ADD CONSTRAINT FK_SUBST_SUBST_USE 
    FOREIGN KEY (APP_SID, SUBSTANCE_ID) REFERENCES CHEM.SUBSTANCE (APP_SID,SUBSTANCE_ID);

ALTER TABLE CHEM.SUBSTANCE_USE ADD CONSTRAINT FK_SUBST_RGN_SUBST_USE 
    FOREIGN KEY (APP_SID, SUBSTANCE_ID, REGION_SID) REFERENCES CHEM.SUBSTANCE_REGION (APP_SID,SUBSTANCE_ID,REGION_SID);

ALTER TABLE CHEM.SUBSTANCE_USE ADD CONSTRAINT FK_PROC_DEST_SUBST_USE 
    FOREIGN KEY (APP_SID, PROCESS_DESTINATION_ID) REFERENCES CHEM.PROCESS_DESTINATION (APP_SID,PROCESS_DESTINATION_ID);

ALTER TABLE CHEM.WAIVER ADD CONSTRAINT FK_SUBST_WAIVER 
    FOREIGN KEY (APP_SID, SUBSTANCE_ID) REFERENCES CHEM.SUBSTANCE (APP_SID,SUBSTANCE_ID);

ALTER TABLE CHEM.WAIVER ADD CONSTRAINT FK_CAS_WAIVER 
    FOREIGN KEY (CAS_CODE) REFERENCES CHEM.CAS (CAS_CODE);

ALTER TABLE CHEM.SUBSTANCE_USE_FILE ADD CONSTRAINT FK_SUBST_USE_SUBST_USE_FILE 
    FOREIGN KEY (APP_SID, SUBSTANCE_USE_ID, SUBSTANCE_ID, REGION_SID) REFERENCES CHEM.SUBSTANCE_USE (APP_SID,SUBSTANCE_USE_ID,SUBSTANCE_ID,REGION_SID);

ALTER TABLE CHEM.PROCESS ADD CONSTRAINT FK_SUBST_RGN_PROC 
    FOREIGN KEY (APP_SID, SUBSTANCE_ID, REGION_SID) REFERENCES CHEM.SUBSTANCE_REGION (APP_SID,SUBSTANCE_ID,REGION_SID);

ALTER TABLE CHEM.PROCESS ADD CONSTRAINT FK_SUBST_PROC 
    FOREIGN KEY (APP_SID, SUBSTANCE_ID) REFERENCES CHEM.SUBSTANCE (APP_SID,SUBSTANCE_ID);

@..\chem\substance_pkg
@..\chem\substance_body

grant execute on chem.substance_pkg to csr;
grant execute on chem.substance_pkg to web_user;

CREATE OR REPLACE FUNCTION chem.appSidCheck (
	in_schema 		IN	varchar2, 
	in_object 		IN	varchar2
)
RETURN VARCHAR2
AS
BEGIN
	-- Only show data if you are logged on and data is for the current application
	RETURN 'app_sid = sys_context(''SECURITY'', ''APP'')';	
END;
/

ALTER TABLE CHEM.SUBSTANCE ADD CONSTRAINT FK_SUBST_REGION
    FOREIGN KEY (APP_SID, REGION_SID)
    REFERENCES CSR.REGION(APP_SID, REGION_SID);

BEGIN
	FOR r IN (
		SELECT object_name, policy_name 
		  FROM all_policies
		 WHERE function = 'APPSIDCHECK'
		   AND object_owner = 'CHEM'
	) LOOP
		dbms_output.put_line('Dropping policy '||r.policy_name);
		dbms_rls.drop_policy(
            object_schema   => 'CHEM',
            object_name     => r.object_name,
            policy_name     => r.policy_name
        );
    END LOOP;
END;
/

BEGIN	
 	FOR r IN (
		SELECT c.owner, c.table_name, c.nullable, (SUBSTR(c.table_name, 1, 26) || '_POL') policy_name
		  FROM all_tables t
			JOIN all_tab_columns c ON t.owner = c.owner AND t.table_name = c.table_name
		 WHERE t.owner = 'CHEM' AND (t.dropped = 'NO' OR t.dropped IS NULL) AND c.column_name = 'APP_SID'
 	)
 	LOOP
		dbms_output.put_line('Writing policy '||r.policy_name);
		dbms_rls.add_policy(
			object_schema   => r.owner,
			object_name     => r.table_name,
			policy_name     => r.policy_name, 
			function_schema => r.owner,
			policy_function => 'APPSIDCHECK',
			statement_types => 'select, insert, update, delete',
			update_check	=> true,
			policy_type     => dbms_rls.context_sensitive);
	END LOOP;
	
END;
/

set define off

begin
insert into chem.waiver_status(waiver_status_id, description) values (0, 'Not Required');
insert into chem.waiver_status(waiver_status_id, description) values (1, 'Required');
insert into chem.waiver_status(waiver_status_id, description) values (2, 'Denied');
insert into chem.waiver_status(waiver_status_id, description) values (3, 'Granted');
insert into chem.waiver_status(waiver_status_id, description) values (4, 'Expired');
end;
/

set define on

@update_tail