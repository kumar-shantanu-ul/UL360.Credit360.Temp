-- Please update version.sql too -- this keeps clean builds in sync
define version=1947
@update_header

CREATE SEQUENCE chem.substance_process_use_id_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    nocycle
    CACHE 5
    noorder;
    
CREATE SEQUENCE chem.subst_process_cas_dest_id_seq 
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    nocycle
    CACHE 5
    noorder;
    
CREATE SEQUENCE chem.subst_proc_cas_dest_chg_id_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    nocycle
    CACHE 5
    noorder;

CREATE SEQUENCE chem.subst_proc_use_change_id_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    nocycle
    CACHE 5
    noorder;

CREATE SEQUENCE chem.subst_proc_use_file_id_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    nocycle
    CACHE 5
    noorder;

CREATE SEQUENCE chem.subst_rgn_proc_process_id_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    nocycle
    CACHE 5
    noorder;


-- Drop all foreign key constraints for CHEM
ALTER TABLE CHEM.CAS_RESTRICTED DROP CONSTRAINT FK_CAS_CAS_RESTR;

ALTER TABLE CHEM.SUBSTANCE DROP CONSTRAINT FK_MFR_SUBST;

ALTER TABLE CHEM.SUBSTANCE DROP CONSTRAINT FK_CLASSIF_SUBST;

ALTER TABLE CHEM.SUBSTANCE_CAS DROP CONSTRAINT FK_CAS_SUBST_CAS;

ALTER TABLE CHEM.SUBSTANCE_CAS DROP CONSTRAINT FK_SUBST_SUBST_CAS;

ALTER TABLE CHEM.PROCESS_DESTINATION DROP CONSTRAINT FK_USAGE_PROC_DEST;

ALTER TABLE CHEM.PROCESS_DESTINATION DROP CONSTRAINT FK_PROC_PROC_DEST;

ALTER TABLE CHEM.SUBSTANCE_FILE DROP CONSTRAINT FK_SUBST_SUBST_FILE;

ALTER TABLE CHEM.SUBSTANCE_REGION DROP CONSTRAINT FK_SUBST_SUBST_RGN;

ALTER TABLE CHEM.SUBSTANCE_REGION DROP CONSTRAINT FK_WAIVR_STAT_SUBST_RGN;

ALTER TABLE CHEM.SUBSTANCE_USE DROP CONSTRAINT FK_SUBST_SUBST_USE;

ALTER TABLE CHEM.SUBSTANCE_USE DROP CONSTRAINT FK_SUBST_RGN_SUBST_USE;

ALTER TABLE CHEM.SUBSTANCE_USE DROP CONSTRAINT FK_PROC_DEST_SUBST_USE;

ALTER TABLE CHEM.WAIVER DROP CONSTRAINT FK_SUBST_WAIVER;

ALTER TABLE CHEM.WAIVER DROP CONSTRAINT FK_CAS_WAIVER;

ALTER TABLE CHEM.SUBSTANCE_USE_FILE DROP CONSTRAINT FK_SUBST_USE_SUBST_USE_FILE;

ALTER TABLE CHEM.PROCESS DROP CONSTRAINT FK_SUBST_RGN_PROC;

ALTER TABLE CHEM.PROCESS DROP CONSTRAINT FK_SUBST_PROC;

ALTER TABLE CHEM.CAS_GROUP DROP CONSTRAINT FK_CAS_GRP_CAS_GRP;

ALTER TABLE CHEM.CAS_GROUP_MEMBER DROP CONSTRAINT FK_CAS_CAS_GRP_MBR;

ALTER TABLE CHEM.CAS_GROUP_MEMBER DROP CONSTRAINT FK_CAS_GRP_CAS_GRP_MBR;

ALTER TABLE CHEM.USAGE_AUDIT_LOG DROP CONSTRAINT FK_SUBST_USAGE_AUDIT;

ALTER TABLE CHEM.SUBSTANCE_AUDIT_LOG DROP CONSTRAINT FK_SUBST_SUBSTANCE_AUDIT;

-- Rename a check constraint
ALTER TABLE CHEM.SUBSTANCE_FILE
DROP CONSTRAINT TCC_SUBSTANCE_FILE_1;

ALTER TABLE CHEM.SUBSTANCE_FILE
ADD CONSTRAINT CHK_SUBSTANCE_FILE CHECK (((FILENAME IS NULL AND MIME_TYPE IS NULL) AND URL IS NOT NULL) OR ((FILENAME IS NOT NULL AND MIME_TYPE IS NOT NULL) AND URL IS NULL));

-- Create new tables (without constraints, including PKs)
CREATE TABLE CHEM.SUBSTANCE_REGION_PROCESS (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    SUBSTANCE_ID NUMBER(10) NOT NULL,
    REGION_SID NUMBER(10) NOT NULL,
    PROCESS_ID NUMBER(10) NOT NULL,
    LABEL VARCHAR2(255) DEFAULT 'Default' NOT NULL,
    ACTIVE NUMBER(1) DEFAULT 1 NOT NULL,
    USAGE_ID NUMBER(10) NOT NULL,
    FIRST_USED_DTM DATE DEFAULT SYSDATE NOT NULL
);

CREATE TABLE CHEM.PROCESS_CAS_DEFAULT (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    SUBSTANCE_ID NUMBER(10) NOT NULL,
    REGION_SID NUMBER(10) NOT NULL,
    PROCESS_ID NUMBER(10) NOT NULL,
    CAS_CODE VARCHAR2(50) NOT NULL,
    TO_AIR_PCT NUMBER(5,4) NOT NULL,
    TO_PRODUCT_PCT NUMBER(5,4) NOT NULL,
    TO_WASTE_PCT NUMBER(5,4) NOT NULL,
    TO_WATER_PCT NUMBER(5,4) NOT NULL,
    REMAINING_PCT NUMBER(5,4) NOT NULL,
    REMAINING_DEST VARCHAR2(100)
);

CREATE TABLE CHEM.SUBSTANCE_PROCESS_USE (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    SUBSTANCE_PROCESS_USE_ID NUMBER(10) NOT NULL,
    SUBSTANCE_ID NUMBER(10) NOT NULL,
    REGION_SID NUMBER(10) NOT NULL,
    PROCESS_ID NUMBER(10) NOT NULL,
    ROOT_DELEGATION_SID NUMBER(10) NOT NULL,
    MASS_VALUE NUMBER(24,10),
    NOTE CLOB,
    START_DTM DATE,
    END_DTM DATE,
    ENTRY_STD_MEASURE_CONV_ID NUMBER(10),
    ENTRY_MASS_VALUE NUMBER(24,10)
);

CREATE TABLE CHEM.SUBSTANCE_PROCESS_USE_FILE (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    SUBSTANCE_PROCESS_USE_FILE_ID NUMBER(10) NOT NULL,
    SUBSTANCE_PROCESS_USE_ID NUMBER(10) NOT NULL,
    SUBSTANCE_ID NUMBER(10) NOT NULL,
    REGION_SID NUMBER(10) NOT NULL,
    PROCESS_ID NUMBER(10) NOT NULL,
    DATA BLOB,
    UPLOADED_DTM DATE DEFAULT SYSDATE,
    UPLOADED_USER_SID NUMBER(10),
    MIME_TYPE VARCHAR2(255),
    FILENAME VARCHAR2(2048)
);

CREATE TABLE CHEM.SUBSTANCE_PROCESS_CAS_DEST (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    SUBSTANCE_PROCESS_CAS_DEST_ID NUMBER(10) NOT NULL,
    SUBSTANCE_PROCESS_USE_ID NUMBER(10) NOT NULL,
    SUBSTANCE_ID NUMBER(10) NOT NULL,
    REGION_SID NUMBER(10) NOT NULL,
    PROCESS_ID NUMBER(10) NOT NULL,
    CAS_CODE VARCHAR2(50) NOT NULL,
    TO_AIR_PCT NUMBER(5,4) NOT NULL,
    TO_PRODUCT_PCT NUMBER(5,4) NOT NULL,
    TO_WASTE_PCT NUMBER(5,4) NOT NULL,
    TO_WATER_PCT NUMBER(5,4) NOT NULL,
    REMAINING_PCT NUMBER(5,4) NOT NULL,
    REMAINING_DEST VARCHAR2(100)
);

CREATE TABLE CHEM.SUBST_PROCESS_CAS_DEST_CHANGE (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    SUBST_PROC_CAS_DEST_CHANGE_ID NUMBER(10) NOT NULL,
    SUBSTANCE_PROCESS_CAS_DEST_ID NUMBER(10) NOT NULL,
    SUBSTANCE_PROCESS_USE_ID NUMBER(10) NOT NULL,
    SUBSTANCE_ID NUMBER(10) NOT NULL,
    REGION_SID NUMBER(10) NOT NULL,
    PROCESS_ID NUMBER(10) NOT NULL,
    CAS_CODE VARCHAR2(50) NOT NULL,
    TO_AIR_PCT NUMBER(5,4),
    TO_PRODUCT_PCT NUMBER(5,4),
    TO_WASTE_PCT NUMBER(5,4),
    TO_WATER_PCT NUMBER(5,4),
    REMAINING_PCT NUMBER(5,4),
    REMAINING_DEST VARCHAR2(100),
    CHANGED_BY NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'SID') NOT NULL,
    CHANGED_DTM TIMESTAMP DEFAULT sys_extract_utc(systimestamp) NOT NULL,
    CONSTRAINT PK_SUBST_PROC_CAS_DEST_CHANGE PRIMARY KEY (APP_SID, SUBST_PROC_CAS_DEST_CHANGE_ID, SUBSTANCE_PROCESS_CAS_DEST_ID, SUBSTANCE_PROCESS_USE_ID, CAS_CODE)
);

CREATE TABLE CHEM.SUBSTANCE_PROCESS_USE_CHANGE (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    SUBST_PROC_USE_CHANGE_ID NUMBER(10) NOT NULL,
    SUBSTANCE_PROCESS_USE_ID NUMBER(10) NOT NULL,
    SUBSTANCE_ID NUMBER(10) NOT NULL,
    REGION_SID NUMBER(10) NOT NULL,
    PROCESS_ID NUMBER(10) NOT NULL,
    ROOT_DELEGATION_SID NUMBER(10),
    MASS_VALUE NUMBER(24,10),
    NOTE CLOB,
    START_DTM DATE,
    END_DTM DATE,
    ENTRY_STD_MEASURE_CONV_ID NUMBER(10),
    ENTRY_MASS_VALUE NUMBER(24,10),
    CHANGED_BY NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'SID') NOT NULL,
    CHANGED_DTM TIMESTAMP DEFAULT sys_extract_utc(systimestamp) NOT NULL,
    RETIRED_DTM TIMESTAMP,
    CONSTRAINT PK_SUBST_PROC_USE_CHANGE PRIMARY KEY (APP_SID, SUBST_PROC_USE_CHANGE_ID, SUBSTANCE_PROCESS_USE_ID)
);

-- Migrate data to new tables

------------------------------------------------------
-- CHEM.PROCESS -> CHEM.SUBSTANCE_REGION_PROCESS (1:1)

INSERT INTO chem.substance_region_process (app_sid, substance_id, process_id, label, active, region_sid, usage_id)
	select app_sid, substance_id, process_id, label, active, region_sid, main_usage_id
	  from (
		 SELECT p.app_sid, p.substance_id, p.process_id, p.label, p.active, p.region_sid, pd.main_usage_id,
			row_number() over (partition by p.app_sid, p.substance_id, p.region_sid, p.process_id order by p.active desc) rn
		   FROM chem.process p
		   JOIN chem.process_destination pd ON p.process_id = pd.process_id
		)
		where rn = 1;

BEGIN
	FOR r IN (
		SELECT app_sid, process_id, substance_id, region_sid, main_usage_id, to_air_pct, to_water_pct, to_waste_pct, to_product_pct, remaining_pct, remaining_dest, first_used_dtm
		  FROM chem.process_destination
		 WHERE active = 1
	) LOOP
		-- update the usage information in the new process
		UPDATE chem.substance_region_process
		   SET first_used_dtm = r.first_used_dtm, usage_id = r.main_usage_id
		 WHERE app_sid = r.app_sid AND process_id = r.process_id AND substance_id = r.substance_id AND region_sid = r.region_sid;
		
	 	-- update the process and copy latest process destination information in the new defaults table (process_cas_default)
		INSERT INTO chem.process_cas_default (app_sid, process_id, substance_id, cas_code, region_sid, to_air_pct, to_water_pct, to_waste_pct, to_product_pct, remaining_pct, remaining_dest)
		     SELECT r.app_sid, r.process_id, r.substance_id, cas_code, r.region_sid, r.to_air_pct, r.to_water_pct, r.to_waste_pct, r.to_product_pct, r.remaining_pct, r.remaining_dest
			   FROM chem.substance_cas sc
			  WHERE app_sid = r.app_sid AND substance_id = r.substance_id;
	END LOOP;
END;
/

---------------------------------------------------
-- CHEM.SUBSTANCE_USE -> CHEM.SUBSTANCE_PROCESS_USE

INSERT INTO chem.substance_process_use (app_sid, substance_process_use_id, substance_id, region_sid, process_id, root_delegation_sid, mass_value, note, start_dtm, end_dtm, entry_std_measure_conv_id, entry_mass_value)
     SELECT su.app_sid, su.substance_use_id, su.substance_id, su.region_sid, pd.process_id, su.root_delegation_sid, su.mass_value, su.note, su.start_dtm, su.end_dtm, su.entry_std_measure_conv_id, su.entry_mass_value
       FROM chem.v$substance_use su
  LEFT JOIN chem.process_destination pd ON su.app_sid = pd.app_sid AND su.process_destination_id = pd.process_destination_id;

-----------------------------------------
-- VARIOUS -> CHEM.PROCESS_CAS_DEST (1:1)
INSERT INTO chem.substance_process_cas_dest (app_sid, substance_process_cas_dest_id, substance_process_use_id, process_id, substance_id, cas_code, region_sid, to_air_pct, to_water_pct, to_waste_pct, to_product_pct, remaining_pct, remaining_dest)
     SELECT su.app_sid, chem.subst_process_cas_dest_id_seq.NEXTVAL, su.substance_use_id, process_id, su.substance_id, sc.cas_code, su.region_sid, pd.to_air_pct, pd.to_water_pct, pd.to_waste_pct, pd.to_product_pct, pd.remaining_pct, pd.remaining_dest
       FROM chem.v$substance_use su
       JOIN chem.substance_cas sc ON sc.app_sid = su.app_sid AND sc.substance_id = su.substance_id
       JOIN chem.process_destination pd ON pd.app_sid = su.app_sid AND pd.process_destination_id = su.process_destination_id;

-------------------------------------------------------------
-- CHEM.SUBSTANCE_USE_FILE -> CHEM.SUBSTANCE_PROCESS_USE_FILE
INSERT INTO chem.substance_process_use_file (app_sid, substance_process_use_file_id, substance_process_use_id, substance_id, region_sid, process_id, data, uploaded_dtm, uploaded_user_sid, mime_type, filename)
     SELECT suf.app_sid, suf.substance_use_file_id, spu.substance_process_use_id, suf.substance_id, suf.region_sid, spu.process_id, suf.data, suf.uploaded_dtm, suf.uploaded_user_sid, suf.mime_type, suf.filename
       FROM chem.substance_use_file suf
  LEFT JOIN chem.substance_process_use spu
         ON suf.app_sid = spu.app_sid AND suf.substance_use_id = spu.substance_process_use_id;

-- New indices

CREATE INDEX CHEM.IDX_SUBSTANCE_REGION_PROCESS ON CHEM.SUBSTANCE_REGION_PROCESS (APP_SID,SUBSTANCE_ID,REGION_SID,CASE WHEN ACTIVE = 0 THEN PROCESS_ID WHEN ACTIVE = 1 THEN -1 END,UPPER(LABEL));

ALTER TABLE CHEM.SUBSTANCE_REGION_PROCESS ADD CONSTRAINT CHK_SUBSTANCE_REGN_PROC_ACTIVE 
    CHECK (ACTIVE IN (0,1));

CREATE INDEX CHEM.IDX_SUBSTANCE_PROCESS_USE ON CHEM.SUBSTANCE_PROCESS_USE (APP_SID,START_DTM,END_DTM);

ALTER TABLE CHEM.SUBSTANCE_PROCESS_USE ADD CONSTRAINT CK_SUBST_PROC_USE_END_DTM 
    CHECK (TRUNC(END_DTM,'MON')=END_DTM);

ALTER TABLE CHEM.SUBSTANCE_PROCESS_USE ADD CONSTRAINT CK_SUBST_PROC_USE_START_DTM 
    CHECK (TRUNC(START_DTM,'MON') = START_DTM);

-- Restore old NOT NULLs

--ALTER TABLE chem.substance_region_process
--     MODIFY (region_sid NOT NULL);

--ALTER TABLE chem.substance_region_process
--     MODIFY (usage_id NOT NULL);

-- Restore (new) PK and check constraints

ALTER TABLE CHEM.SUBSTANCE_REGION_PROCESS ADD CONSTRAINT PK_SUBSTANCE_REGION_PROCESS PRIMARY KEY (APP_SID, SUBSTANCE_ID, REGION_SID, PROCESS_ID);

ALTER TABLE CHEM.PROCESS_CAS_DEFAULT ADD CONSTRAINT PK_PROCESS_CAS_DEFAULT PRIMARY KEY (APP_SID, SUBSTANCE_ID, REGION_SID, PROCESS_ID, CAS_CODE);
ALTER TABLE CHEM.PROCESS_CAS_DEFAULT ADD CONSTRAINT CHK_PROCESS_CAS_DEFAULT CHECK (TO_AIR_PCT >= 0 AND TO_PRODUCT_PCT >= 0 AND TO_WASTE_PCT >= 0 AND TO_WATER_PCT >= 0 AND REMAINING_PCT >= 0 AND (TO_AIR_PCT + TO_PRODUCT_PCT + TO_WASTE_PCT + TO_WATER_PCT + REMAINING_PCT) <= 1);

ALTER TABLE CHEM.SUBSTANCE_PROCESS_USE ADD CONSTRAINT PK_SUBSTANCE_PROCESS_USE PRIMARY KEY (APP_SID, SUBSTANCE_PROCESS_USE_ID, SUBSTANCE_ID, REGION_SID, PROCESS_ID);

ALTER TABLE CHEM.SUBSTANCE_PROCESS_CAS_DEST ADD CONSTRAINT CHK_SUBSTANCE_PROCESS_CAS_DEST CHECK (TO_AIR_PCT >= 0 AND TO_PRODUCT_PCT >= 0 AND TO_WASTE_PCT >= 0 AND TO_WATER_PCT >= 0 AND REMAINING_PCT >= 0 AND (TO_AIR_PCT + TO_PRODUCT_PCT + TO_WASTE_PCT + TO_WATER_PCT + REMAINING_PCT) <= 1);
ALTER TABLE CHEM.SUBSTANCE_PROCESS_CAS_DEST ADD CONSTRAINT PK_SUBSTANCE_PROCESS_CAS_DEST PRIMARY KEY (
	APP_SID, SUBSTANCE_PROCESS_CAS_DEST_ID
);

ALTER TABLE CHEM.SUBSTANCE_PROCESS_CAS_DEST ADD CONSTRAINT UK_SUBSTANCE_PROCESS_CAS_DEST UNIQUE (
	APP_SID, SUBSTANCE_PROCESS_USE_ID, SUBSTANCE_ID, REGION_SID, PROCESS_ID, CAS_CODE
);

ALTER TABLE CHEM.SUBSTANCE_PROCESS_USE_FILE ADD CONSTRAINT PK_SUBSTANCE_PROCESS_USE_FILE PRIMARY KEY (APP_SID, SUBSTANCE_PROCESS_USE_FILE_ID, SUBSTANCE_PROCESS_USE_ID, SUBSTANCE_ID, REGION_SID, PROCESS_ID);

-- Restore (new) FK constraints

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

ALTER TABLE CHEM.PROCESS_CAS_DEFAULT ADD CONSTRAINT FK_SUBST_RGN_PROC_PROC_CAS 
    FOREIGN KEY (APP_SID, PROCESS_ID, SUBSTANCE_ID, REGION_SID) REFERENCES CHEM.SUBSTANCE_REGION_PROCESS (APP_SID,PROCESS_ID,SUBSTANCE_ID,REGION_SID);

ALTER TABLE CHEM.PROCESS_CAS_DEFAULT ADD CONSTRAINT FK_SUBST_CAS_PROC_CAS 
    FOREIGN KEY (APP_SID, SUBSTANCE_ID, CAS_CODE) REFERENCES CHEM.SUBSTANCE_CAS (APP_SID,SUBSTANCE_ID,CAS_CODE);

ALTER TABLE CHEM.SUBSTANCE_FILE ADD CONSTRAINT FK_SUBST_SUBST_FILE 
    FOREIGN KEY (APP_SID, SUBSTANCE_ID) REFERENCES CHEM.SUBSTANCE (APP_SID,SUBSTANCE_ID);

ALTER TABLE CHEM.SUBSTANCE_REGION ADD CONSTRAINT FK_SUBST_SUBST_RGN 
    FOREIGN KEY (APP_SID, SUBSTANCE_ID) REFERENCES CHEM.SUBSTANCE (APP_SID,SUBSTANCE_ID);

ALTER TABLE CHEM.SUBSTANCE_REGION ADD CONSTRAINT FK_WAIVR_STAT_SUBST_RGN 
    FOREIGN KEY (WAIVER_STATUS_ID) REFERENCES CHEM.WAIVER_STATUS (WAIVER_STATUS_ID);

ALTER TABLE CHEM.SUBSTANCE_PROCESS_USE ADD CONSTRAINT FK_SUBST_RGN_PROC_SUBST_PROC_U 
    FOREIGN KEY (APP_SID, SUBSTANCE_ID, REGION_SID, PROCESS_ID) REFERENCES CHEM.SUBSTANCE_REGION_PROCESS (APP_SID,SUBSTANCE_ID,REGION_SID,PROCESS_ID);

ALTER TABLE CHEM.WAIVER ADD CONSTRAINT FK_SUBST_WAIVER 
    FOREIGN KEY (APP_SID, SUBSTANCE_ID) REFERENCES CHEM.SUBSTANCE (APP_SID,SUBSTANCE_ID);

ALTER TABLE CHEM.WAIVER ADD CONSTRAINT FK_CAS_WAIVER 
    FOREIGN KEY (CAS_CODE) REFERENCES CHEM.CAS (CAS_CODE);

ALTER TABLE CHEM.SUBSTANCE_PROCESS_USE_FILE ADD CONSTRAINT FK_SUBST_PROC_USE_SUBST_USE_F 
    FOREIGN KEY (APP_SID, SUBSTANCE_PROCESS_USE_ID, SUBSTANCE_ID, REGION_SID, PROCESS_ID) 
    REFERENCES CHEM.SUBSTANCE_PROCESS_USE (APP_SID,SUBSTANCE_PROCESS_USE_ID,SUBSTANCE_ID,REGION_SID,PROCESS_ID) DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE CHEM.SUBSTANCE_REGION_PROCESS ADD CONSTRAINT FK_USAGE_SUBST_RGN_PROC 
    FOREIGN KEY (APP_SID, USAGE_ID) REFERENCES CHEM.USAGE (APP_SID,USAGE_ID);

ALTER TABLE CHEM.SUBSTANCE_REGION_PROCESS ADD CONSTRAINT FK_SUBST_RGN_SUBST_RGN_PROC 
    FOREIGN KEY (APP_SID, SUBSTANCE_ID, REGION_SID) REFERENCES CHEM.SUBSTANCE_REGION (APP_SID,SUBSTANCE_ID,REGION_SID);

ALTER TABLE CHEM.CAS_GROUP ADD CONSTRAINT FK_CAS_GRP_CAS_GRP 
    FOREIGN KEY (APP_SID, PARENT_GROUP_ID) REFERENCES CHEM.CAS_GROUP (APP_SID,CAS_GROUP_ID);

ALTER TABLE CHEM.CAS_GROUP_MEMBER ADD CONSTRAINT FK_CAS_CAS_GRP_MBR 
    FOREIGN KEY (CAS_CODE) REFERENCES CHEM.CAS (CAS_CODE);

ALTER TABLE CHEM.CAS_GROUP_MEMBER ADD CONSTRAINT FK_CAS_GRP_CAS_GRP_MBR 
    FOREIGN KEY (APP_SID, CAS_GROUP_ID) REFERENCES CHEM.CAS_GROUP (APP_SID,CAS_GROUP_ID);

ALTER TABLE CHEM.USAGE_AUDIT_LOG ADD CONSTRAINT FK_SUBST_USAGE_AUDIT_LOG
    FOREIGN KEY (APP_SID, SUBSTANCE_ID) REFERENCES CHEM.SUBSTANCE (APP_SID,SUBSTANCE_ID);

ALTER TABLE CHEM.SUBSTANCE_AUDIT_LOG ADD CONSTRAINT FK_SUBST_SUBST_AUDIT_LOG
    FOREIGN KEY (APP_SID, SUBSTANCE_ID) REFERENCES CHEM.SUBSTANCE (APP_SID,SUBSTANCE_ID);

ALTER TABLE CHEM.SUBSTANCE_PROCESS_CAS_DEST ADD CONSTRAINT FK_SUBST_CAS_SUBST_UPCD 
    FOREIGN KEY (APP_SID, SUBSTANCE_ID, CAS_CODE) REFERENCES CHEM.SUBSTANCE_CAS (APP_SID,SUBSTANCE_ID,CAS_CODE) ON DELETE CASCADE;

ALTER TABLE CHEM.SUBSTANCE_PROCESS_CAS_DEST ADD CONSTRAINT FK_SUBST_PROC_USE_SUBST_UPCD 
    FOREIGN KEY (APP_SID, SUBSTANCE_PROCESS_USE_ID, SUBSTANCE_ID, REGION_SID, PROCESS_ID) 
    REFERENCES CHEM.SUBSTANCE_PROCESS_USE (APP_SID,SUBSTANCE_PROCESS_USE_ID,SUBSTANCE_ID,REGION_SID,PROCESS_ID) DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE CHEM.SUBSTANCE_PROCESS_CAS_DEST ADD CONSTRAINT FK_SUBST_RGN_PROC_SUBST_UPCD 
    FOREIGN KEY (APP_SID, PROCESS_ID, SUBSTANCE_ID, REGION_SID) REFERENCES CHEM.SUBSTANCE_REGION_PROCESS (APP_SID,PROCESS_ID,SUBSTANCE_ID,REGION_SID);

CREATE OR REPLACE VIEW "CHEM"."V$OUTPUTS" (
	app_sid, cas_group_label, cas_group_id, cas_code, name, substance_ref, substance_description,
	waiver_status_id, region_sid, start_dtm, end_dtm, air_mass_value, water_mass_value, cas_weight,
	to_air_pct, to_water_pct, to_waste_pct, to_product_pct, remaining_pct, root_delegation_sid, local_ref,
	first_used_dtm, process_first_used_dtm
)
AS
SELECT spu.app_sid, NVL(cg.label, 'Unknown') cas_group_label, cg.cas_group_id,
	   c.cas_code, c.name,
	   s.ref substance_ref, s.description substance_description,
	   sr.waiver_status_id, sr.region_sid, spu.start_dtm, spu.end_dtm,
	   spcd.to_air_pct * spu.mass_value * sc.pct_composition air_mass_value,
	   spcd.to_water_pct * spu.mass_value * sc.pct_composition water_mass_value,
	   spu.mass_value * sc.pct_composition cas_weight,
	   spcd.to_air_pct,
	   spcd.to_water_pct,
	   spcd.to_waste_pct,
	   spcd.to_product_pct,
	   spcd.remaining_pct,
	   root_delegation_sid,
	   sr.local_ref,
	   sr.first_used_dtm,
	   srp.first_used_dtm process_first_used_dtm
  FROM substance_process_use spu
  JOIN substance s ON spu.substance_id = s.substance_id AND spu.app_sid = s.app_sid
  JOIN substance_region sr ON spu.substance_id = sr.substance_id AND spu.region_sid = sr.region_sid AND spu.app_sid = sr.app_sid
  JOIN substance_region_process srp
    ON spu.substance_id = srp.substance_id
   AND spu.region_sid = srp.region_sid
   AND spu.process_id = srp.process_id
   AND spu.app_sid = srp.app_sid
  LEFT JOIN substance_process_cas_dest spcd
    ON spu.substance_process_use_id = spcd.substance_process_use_id
   AND spu.substance_id = spcd.substance_id
   AND spu.region_sid = spcd.region_sid
   AND spu.process_id = spcd.process_id
   AND spu.app_sid = spcd.app_sid
  JOIN substance_cas sc ON s.substance_id = sc.substance_id
  JOIN cas c ON sc.cas_code = c.cas_code
  LEFT JOIN cas_group_member cgm ON c.cas_code = cgm.cas_code
  LEFT JOIN cas_group cg ON cgm.cas_group_id = cg.cas_group_id AND cgm.app_sid = cg.app_sid;

CREATE OR REPLACE VIEW "CHEM"."V$AUDIT_LOG" (
	app_sid, cas_group_label, cas_group_id, cas_code, name, substance_ref, substance_description, 
	waiver_status_id, region_sid, start_dtm, end_dtm, air_mass_value, water_mass_value, cas_weight, 
	to_air_pct, to_water_pct, to_waste_pct, to_product_pct, remaining_pct, root_delegation_sid, 
	changed_by, changed_dtm, mass_value, retired_dtm
)
AS
SELECT spuc.app_sid, NVL(cg.label, 'Unknown') cas_group_label, cg.cas_group_id,
	c.cas_code, c.name,
	s.ref substance_ref, s.description substance_description,
	sr.waiver_status_id, sr.region_sid, spuc.start_dtm, spuc.end_dtm,
	spcdc.to_air_pct * spuc.mass_value * sc.pct_composition air_mass_value,
	spcdc.to_water_pct * spuc.mass_value * sc.pct_composition water_mass_value,
	spuc.mass_value * sc.pct_composition cas_weight,
	spcdc.to_air_pct,
	spcdc.to_water_pct,
	spcdc.to_waste_pct,
	spcdc.to_product_pct,
	spcdc.remaining_pct,
	root_delegation_sid,
	spuc.changed_by,
	spuc.changed_dtm,
	spuc.mass_value,
	spuc.retired_dtm
  FROM substance_process_use_change spuc
  JOIN substance s ON spuc.substance_id = s.substance_id AND spuc.app_sid = s.app_sid
  JOIN substance_region sr ON spuc.substance_id = sr.substance_id AND spuc.region_sid = sr.region_sid AND spuc.app_sid = sr.app_sid
  LEFT JOIN subst_process_cas_dest_change spcdc
    ON spuc.substance_process_use_id = spcdc.substance_process_use_id
   AND spuc.substance_id = spcdc.substance_id
   AND spuc.region_sid = spcdc.region_sid
   AND spuc.process_id = spcdc.process_id
   AND spuc.app_sid = spcdc.app_sid
  JOIN substance_cas sc ON s.substance_id = sc.substance_id
  JOIN cas c ON sc.cas_code = c.cas_code
  LEFT JOIN cas_group_member cgm ON c.cas_code = cgm.cas_code
  LEFT JOIN cas_group cg ON cgm.cas_group_id = cg.cas_group_id AND cgm.app_sid = cg.app_sid;

DECLARE
	v_cnt	NUMBER(10);
	TYPE T_TABS IS TABLE OF VARCHAR2(100);
	v_tabs T_TABS;
	v_seq T_TABS;
	v_ids T_TABS;
BEGIN	
	v_seq := T_TABS(  
		'chem.subst_proc_cas_dest_chg_id_seq',
		'chem.subst_proc_use_change_id_seq',
		'chem.subst_proc_use_file_id_seq',
		'chem.subst_process_cas_dest_id_seq',
		--'chem.subst_rgn_proc_process_id_seq',
		'chem.substance_process_use_id_seq'
	);
	v_tabs := T_TABS(  
		'chem.subst_process_cas_dest_change',
		'chem.substance_process_use_change',
		'chem.substance_process_use_file',
		'chem.substance_process_cas_dest',
		--'chem.subst_rgn_proc_process',
		'chem.substance_process_use'
	);
	v_ids := T_TABS(  
		'subst_proc_cas_dest_change_id',
		'subst_proc_use_change_id',
		'substance_process_use_file_id',
		'substance_process_cas_dest_id',
		--'subst_rgn_proc_process',
		'substance_process_use_id'
	);
	FOR I IN 1 .. v_seq.count 
	LOOP
		EXECUTE IMMEDIATE 'SELECT NVL(MAX('||v_ids(i)||'),0) FROM '||v_tabs(i)
		   INTO v_cnt;
		DBMS_OUTPUT.PUT_LINE('Recreating sequence '||v_seq(i)||' starting with '||(v_cnt + 1)||'...');
		EXECUTE IMMEDIATE 'DROP SEQUENCE '||v_seq(i);
		EXECUTE IMMEDIATE 'CREATE SEQUENCE '||v_seq(i)||' START WITH '||(v_cnt+1)||' INCREMENT BY 1 NOMINVALUE NOMAXVALUE nocycle CACHE 5 noorder';
	END LOOP;
END;
/

	


-- Drop old tables
DROP TABLE CHEM.PROCESS;

DROP TABLE CHEM.PROCESS_DESTINATION;

DROP TABLE CHEM.SUBSTANCE_USE;

DROP TABLE CHEM.SUBSTANCE_USE_FILE;

@..\chem\substance_pkg
@..\chem\substance_body


@update_tail
