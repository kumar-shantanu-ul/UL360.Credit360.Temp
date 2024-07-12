-- Please update version.sql too -- this keeps clean builds in sync
define version=1948
@update_header

-- we've got a small number of rows on live where the same substance is in more than once
-- for the same process, period, region, delegation. THis seems wrong and I want to set
-- a unique key, so this code safely adds up the dupe values. Some of the ones on live actually
-- look like accidents but Philips are keen to keep exactly the same historic values.
declare
  v_cnt number(10) := 0;
begin
	for r in (
		select * 
		  from (
		  select 
		      count(*) over (partition by APP_SID, SUBSTANCE_ID, REGION_SID, PROCESS_ID, ROOT_DELEGATION_SID, START_DTM, END_DTM) cnt, 
		      row_number() over (partition by APP_SID, SUBSTANCE_ID, REGION_SID, PROCESS_ID, ROOT_DELEGATION_SID, START_DTM, END_DTM order by substance_process_use_Id desc) rn, 
		      nvl(min(entry_std_measure_conv_id) over (partition by APP_SID, SUBSTANCE_ID, REGION_SID, PROCESS_ID, ROOT_DELEGATION_SID, START_DTM, END_DTM),-1) min_conv_id,
		      nvl(max(entry_std_measure_conv_id) over (partition by APP_SID, SUBSTANCE_ID, REGION_SID, PROCESS_ID, ROOT_DELEGATION_SID, START_DTM, END_DTM),-1) max_conv_id,
		      sum(entry_mass_value) over (partition by APP_SID, SUBSTANCE_ID, REGION_SID, PROCESS_ID, ROOT_DELEGATION_SID, START_DTM, END_DTM) sum_entry_mass_value,
		      sum(mass_value) over (partition by APP_SID, SUBSTANCE_ID, REGION_SID, PROCESS_ID, ROOT_DELEGATION_SID, START_DTM, END_DTM) sum_mass_value,
		      csr.stragg(note) over (partition by APP_SID, SUBSTANCE_ID, REGION_SID, PROCESS_ID, ROOT_DELEGATION_SID, START_DTM, END_DTM) aggr_note,
		      first_value(spu.substance_process_use_id) over (partition by APP_SID, SUBSTANCE_ID, REGION_SID, PROCESS_ID, ROOT_DELEGATION_SID, START_DTM, END_DTM) first_id, 
		      spu.substance_process_use_id, 
		      spu.substance_id, spu.region_sid, spu.process_id, spu.root_delegation_sid, spu.start_dtm, spu.end_dtm
		    from chem.SUBSTANCE_PROCESS_USE spu
		) where rn > 1
	)
	loop
		v_cnt := v_cnt + 1;
		IF r.min_conv_id != r.max_conv_id THEN
			RAISE_APPLICATION_ERROR(-20001, 'cannot aggregate - differing measure conversions');
		END IF;
		update chem.substance_process_use
		   set mass_value = r.sum_mass_value,
		    entry_mass_value = r.sum_entry_mass_value,
		    note = r.aggr_note
		 where substance_process_use_id = r.first_id;
		delete from chem.substance_process_use
		 where substance_process_use_id = r.substance_process_use_id;
		delete from chem.substance_process_cas_dest
    	 where substance_process_use_id = r.substance_process_use_id;
	end loop;
	dbms_output.put_line('count = '||v_cnt);
end;
/

-- fix up history tables
-- ALTER TABLE CHEM.SUBST_PROCESS_CAS_DEST_CHANGE DROP CONSTRAINT FK_SUBST_PROC_USE_CAS_DEST_C; 
-- ALTER TABLE CHEM.SUBSTANCE_PROCESS_USE_CHANGE DROP CONSTRAINT FK_SUBST_PROC_USE_CHANGE;
BEGIN
	FOR r IN (SELECT constraint_name FROM all_constraints WHERE owner = 'CHEM' AND constraint_name = 'FK_SUBST_PROC_USE_CAS_DEST_C')
	LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE CHEM.SUBST_PROCESS_CAS_DEST_CHANGE DROP CONSTRAINT FK_SUBST_PROC_USE_CAS_DEST_C'; 
	END LOOP;
	
	FOR r IN (SELECT constraint_name FROM all_constraints WHERE owner = 'CHEM' AND constraint_name = 'FK_SUBST_PROC_USE_CHANGE')
	LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE CHEM.SUBSTANCE_PROCESS_USE_CHANGE DROP CONSTRAINT FK_SUBST_PROC_USE_CHANGE'; 
	END LOOP;
END;
/

ALTER TABLE CHEM.SUBSTANCE_PROCESS_USE ADD CONSTRAINT AC_SUBSTANCE_PROCESS_USE UNIQUE (APP_SID, SUBSTANCE_ID, REGION_SID, PROCESS_ID, ROOT_DELEGATION_SID, START_DTM, END_DTM);
ALTER TABLE CHEM.SUBSTANCE_PROCESS_USE_CHANGE DROP PRIMARY KEY DROP INDEX;
ALTER TABLE CHEM.SUBSTANCE_PROCESS_USE_CHANGE DROP COLUMN SUBSTANCE_PROCESS_USE_ID;
ALTER TABLE CHEM.SUBSTANCE_PROCESS_USE_CHANGE ADD (
	CONSTRAINT PK_SUBST_PROC_USE_CHANGE PRIMARY KEY (APP_SID, SUBST_PROC_USE_CHANGE_ID)
);

--ALTER TABLE CHEM.SUBST_PROCESS_CAS_DEST_CHANGE DROP CONSTRAINT FK_SUBST_PROC_CAS_DEST_CHANGE;
BEGIN
	FOR r IN (SELECT constraint_name FROM all_constraints WHERE owner = 'CHEM' AND constraint_name = 'FK_SUBST_PROC_CAS_DEST_CHANGE')
	LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE CHEM.SUBST_PROCESS_CAS_DEST_CHANGE DROP CONSTRAINT FK_SUBST_PROC_CAS_DEST_CHANGE'; 
	END LOOP;
END;
/



ALTER TABLE CHEM.SUBST_PROCESS_CAS_DEST_CHANGE DROP PRIMARY KEY DROP INDEX;
ALTER TABLE CHEM.SUBST_PROCESS_CAS_DEST_CHANGE DROP COLUMN SUBSTANCE_PROCESS_CAS_DEST_ID;
ALTER TABLE CHEM.SUBST_PROCESS_CAS_DEST_CHANGE DROP COLUMN SUBSTANCE_PROCESS_USE_ID;
ALTER TABLE CHEM.SUBST_PROCESS_CAS_DEST_CHANGE DROP COLUMN SUBSTANCE_ID;
ALTER TABLE CHEM.SUBST_PROCESS_CAS_DEST_CHANGE DROP COLUMN REGION_SID;
ALTER TABLE CHEM.SUBST_PROCESS_CAS_DEST_CHANGE DROP COLUMN PROCESS_ID;
ALTER TABLE CHEM.SUBST_PROCESS_CAS_DEST_CHANGE ADD (
	CONSTRAINT PK_SUBST_PROC_CAS_DEST_CHANGE PRIMARY KEY (APP_SID, SUBST_PROC_CAS_DEST_CHANGE_ID)
);

--build fix
DECLARE v_col_count NUMBER(10);
BEGIN
	SELECT count(*) 
	  INTO v_col_count 
	  FROM all_tab_columns 
	 WHERE owner = 'CHEM' 
	   AND table_name = 'SUBST_PROCESS_CAS_DEST_CHANGE' 
	   AND column_name = 'SUBST_PROC_USE_CHANGE_ID';
	
	IF v_col_count = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CHEM.SUBST_PROCESS_CAS_DEST_CHANGE ADD SUBST_PROC_USE_CHANGE_ID NUMBER(10)'; 
	END IF;
END;
/

ALTER TABLE CHEM.SUBSTANCE_PROCESS_USE_CHANGE ADD CONSTRAINT FK_SUBST_PROC_USE_CHANGE 
    FOREIGN KEY (APP_SID, SUBSTANCE_ID, REGION_SID, PROCESS_ID, ROOT_DELEGATION_SID, START_DTM, END_DTM) 
    REFERENCES CHEM.SUBSTANCE_PROCESS_USE (APP_SID,SUBSTANCE_ID,REGION_SID,PROCESS_ID, ROOT_DELEGATION_SID, START_DTM, END_DTM);

ALTER TABLE CHEM.SUBST_PROCESS_CAS_DEST_CHANGE ADD CONSTRAINT FK_SUBST_PROC_USE_CAS_DEST_C
    FOREIGN KEY (APP_SID, SUBST_PROC_USE_CHANGE_ID)
    REFERENCES CHEM.SUBSTANCE_PROCESS_USE_CHANGE (APP_SID,SUBST_PROC_USE_CHANGE_ID);


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
    ON spuc.subst_proc_use_change_id = spcdc.subst_proc_use_change_id
   AND spuc.app_sid = spcdc.app_sid
  JOIN substance_cas sc ON s.substance_id = sc.substance_id
  JOIN cas c ON sc.cas_code = c.cas_code
  LEFT JOIN cas_group_member cgm ON c.cas_code = cgm.cas_code
  LEFT JOIN cas_group cg ON cgm.cas_group_id = cg.cas_group_id AND cgm.app_sid = cg.app_sid;

@..\chem\substance_pkg
@..\chem\substance_body


@update_tail
