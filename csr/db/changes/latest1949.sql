-- Please update version.sql too -- this keeps clean builds in sync
define version=1949
@update_header

-- no idea why this guff is propagated through
ALTER TABLE chem.SUBSTANCE_PROCESS_USE_FILE DROP PRIMARY KEY DROP INDEX;
-- fix up history tables - the conditional constraint drops are because the model was different
-- to what was on live.
BEGIN
	FOR r IN (
		SELECT owner, table_name, constraint_name 
		  FROM sys.all_constraints 
		 WHERE constraint_name IN ('FK_SUBST_PROC_USE_SUBST_USE_F') AND owner='CHEM'
	)
	LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE '||r.owner||'.'||r.table_name||' DROP CONSTRAINT '||r.constraint_name;
	END LOOP;
END;
/

ALTER TABLE chem.SUBSTANCE_PROCESS_USE_FILE DROP COLUMN substance_id;
ALTER TABLE chem.SUBSTANCE_PROCESS_USE_FILE DROP COLUMN region_sid;
ALTER TABLE chem.SUBSTANCE_PROCESS_USE_FILE DROP COLUMN process_id;
ALTER TABLE chem.SUBSTANCE_PROCESS_USE_FILE ADD CONSTRAINT PK_SUBSTANCE_PROCESS_USE_FILE PRIMARY KEY (APP_SID, SUBSTANCE_PROCESS_USE_FILE_ID);

ALTER TABLE chem.SUBSTANCE_PROCESS_CAS_DEST DROP CONSTRAINT FK_SUBST_PROC_USE_SUBST_UPCD;

ALTER TABLE CHEM.SUBSTANCE_PROCESS_USE DROP PRIMARY KEY DROP INDEX;
ALTER TABLE CHEM.SUBSTANCE_PROCESS_USE ADD CONSTRAINT PK_SUBSTANCE_PROCESS_USE PRIMARY KEY (APP_SID, SUBSTANCE_PROCESS_USE_ID);


ALTER TABLE CHEM.SUBSTANCE_PROCESS_CAS_DEST DROP PRIMARY KEY DROP INDEX;
ALTER TABLE CHEM.SUBSTANCE_PROCESS_CAS_DEST ADD CONSTRAINT PK_SUBSTANCE_PROCESS_CAS_DEST PRIMARY KEY (APP_SID, SUBSTANCE_PROCESS_USE_ID, CAS_CODE);
    

ALTER TABLE CHEM.SUBSTANCE_PROCESS_USE_FILE ADD CONSTRAINT FK_SUBST_PROC_USE_SUBST_USE_F 
    FOREIGN KEY (APP_SID, SUBSTANCE_PROCESS_USE_ID) REFERENCES CHEM.SUBSTANCE_PROCESS_USE (APP_SID,SUBSTANCE_PROCESS_USE_ID);


-- break dependecy between audit log and main table since we can delete rows from the main table
ALTER TABLE CHEM.SUBSTANCE_PROCESS_USE_CHANGE DROP CONSTRAINT FK_SUBST_PROC_USE_CHANGE;

ALTER TABLE CHEM.SUBSTANCE_PROCESS_USE_CHANGE ADD CONSTRAINT FK_SBST_REG_PR_SBST_PR_USE_CH 
    FOREIGN KEY (APP_SID, SUBSTANCE_ID, REGION_SID, PROCESS_ID) 
    REFERENCES CHEM.SUBSTANCE_REGION_PROCESS (APP_SID,SUBSTANCE_ID,REGION_SID,PROCESS_ID);


ALTER TABLE chem.substance_process_cas_dest drop primary key drop index;
BEGIN
	FOR r IN (
		SELECT owner, table_name, constraint_name 
		  FROM sys.all_constraints 
		 WHERE constraint_name IN ('FK_SUBST_RGN_PROC_SUBST_UPCD') AND owner='CHEM'
	)
	LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE '||r.owner||'.'||r.table_name||' DROP CONSTRAINT '||r.constraint_name;
	END LOOP;
END;
/

BEGIN
	FOR r IN (
		SELECT owner, table_name, constraint_name 
		  FROM sys.all_constraints 
		 WHERE constraint_name IN ('UK_SUBSTANCE_PROCESS_CAS_DEST') AND owner='CHEM'
	)
	LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE '||r.owner||'.'||r.table_name||' DROP CONSTRAINT '||r.constraint_name;
	END LOOP;
END;
/

ALTER TABLE chem.substance_process_cas_dest drop column SUBSTANCE_PROCESS_CAS_DEST_ID;
ALTER TABLE chem.substance_process_cas_dest drop column REGION_SID;
ALTER TABLE chem.substance_process_cas_dest drop column PROCESS_ID;
ALTER TABLE chem.SUBSTANCE_PROCESS_USE ADD CONSTRAINT UC_SUBSTANCE_PROCESS_USE_2 UNIQUE (APP_SID, SUBSTANCE_PROCESS_USE_ID, SUBSTANCE_ID);
ALTER TABLE CHEM.SUBSTANCE_PROCESS_CAS_DEST ADD CONSTRAINT FK_SUBST_PROC_USE_SUBST_UPCD 
    FOREIGN KEY (APP_SID, SUBSTANCE_PROCESS_USE_ID, SUBSTANCE_ID) REFERENCES CHEM.SUBSTANCE_PROCESS_USE (APP_SID,SUBSTANCE_PROCESS_USE_ID, SUBSTANCE_ID);

ALTER TABLE chem.substance_process_cas_dest ADD CONSTRAINT PK_SUBSTANCE_PROCESS_CAS_DEST PRIMARY KEY (APP_SID, SUBSTANCE_PROCESS_USE_ID, CAS_CODE);

DROP SEQUENCE chem.subst_process_cas_dest_id_seq;
drop view CHEM.V$SUBSTANCE_USE;

alter table chem.subst_process_cas_dest_change modify to_air_pct not null;
alter table chem.subst_process_cas_dest_change modify to_product_pct not null;
alter table chem.subst_process_cas_dest_change modify to_waste_pct not null;
alter table chem.subst_process_cas_dest_change modify to_water_pct not null;

alter table chem.subst_process_cas_dest_change add (
	retired_dtm DATE
);

alter table chem.cas add (
    IS_VOC NUMBER(1) DEFAULT 0 NOT NULL
);

ALTER TABLE CHEM.CAS ADD CONSTRAINT CHK_CAS_IS_VOC 
    CHECK (is_voc IN (0,1));

-- index wasn't marked as unique
DROP INDEX CHEM.IDX_SUBSTANCE_REGION_PROCESS;

UPDATE chem.substance_region_process
   SET active = 0
 WHERE (app_sid, substance_id, region_sid, process_id) IN (
  SELECT app_sid, substance_id, region_sid, process_id
    FROM (
     SELECT app_sid, substance_id, region_sid, process_id,
      ROW_NUMBER() OVER (PARTITION BY APP_SID,SUBSTANCE_ID,REGION_SID,UPPER(LABEL) ORDER BY process_id DESC) rn
       FROM chem.substance_region_process
      WHERE active = 1
   )
   WHERE rn > 1
);

CREATE UNIQUE INDEX CHEM.IDX_SUBSTANCE_REGION_PROCESS ON CHEM.SUBSTANCE_REGION_PROCESS (APP_SID,SUBSTANCE_ID,REGION_SID,CASE WHEN ACTIVE = 0 THEN PROCESS_ID WHEN ACTIVE = 1 THEN -1 END,UPPER(LABEL));


CREATE OR REPLACE VIEW "CHEM"."V$OUTPUTS" 
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
   AND spu.app_sid = spcd.app_sid
  JOIN substance_cas sc ON s.substance_id = sc.substance_id
  JOIN cas c ON sc.cas_code = c.cas_code
  LEFT JOIN cas_group_member cgm ON c.cas_code = cgm.cas_code
  LEFT JOIN cas_group cg ON cgm.cas_group_id = cg.cas_group_id AND cgm.app_sid = cg.app_sid;

CREATE OR REPLACE VIEW "CHEM"."V$AUDIT_LOG"
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
    ON spuc.subst_proc_use_change_id = spcdc.subst_proc_use_change_id
   AND spuc.app_sid = spcdc.app_sid
  JOIN substance_cas sc ON s.substance_id = sc.substance_id
  JOIN cas c ON sc.cas_code = c.cas_code
  LEFT JOIN cas_group_member cgm ON c.cas_code = cgm.cas_code
  LEFT JOIN cas_group cg ON cgm.cas_group_id = cg.cas_group_id AND cgm.app_sid = cg.app_sid;

-- TODO: \cvs\clients\philips\db\chem\setvoc.sql

@..\chem\substance_pkg
@..\chem\substance_body

@update_tail
