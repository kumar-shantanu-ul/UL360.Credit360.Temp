-- Please update version.sql too -- this keeps clean builds in sync
define version=2036
@update_header

ALTER TABLE csr.delegation_ind
	ADD allowed_na NUMBER(1) DEFAULT 0 NOT NULL;

ALTER TABLE csr.delegation_region
	ADD allowed_na NUMBER(1) DEFAULT 0 NOT NULL;

ALTER TABLE csr.sheet_value
	ADD is_na NUMBER(1) DEFAULT 0 NOT NULL;

create or replace view csr.v$delegation_ind as
	select di.app_sid, di.delegation_sid, di.ind_sid, di.mandatory, NVL(did.description, id.description) description,
		   di.pos, di.section_key, di.var_expl_group_id, di.visibility, di.css_class, di.allowed_na
	  from delegation_ind di
	  join ind_description id 
	    on di.app_sid = id.app_sid and di.ind_sid = id.ind_sid 
	   and id.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
	  left join delegation_ind_description did
	    on di.app_sid = did.app_sid AND di.delegation_sid = did.delegation_sid
	   and di.ind_sid = did.ind_sid AND did.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');

CREATE OR REPLACE VIEW csr.v$delegation_region AS
	SELECT dr.app_sid, dr.delegation_sid, dr.region_sid, dr.mandatory, NVL(drd.description, rd.description) description,
		   dr.pos, dr.aggregate_to_region_sid, dr.visibility, dr.allowed_na
	  FROM delegation_region dr
	  JOIN region_description rd
	    ON dr.app_sid = rd.app_sid AND dr.region_sid = rd.region_sid 
	   AND rd.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
	  LEFT JOIN delegation_region_description drd
	    ON dr.app_sid = drd.app_sid AND dr.delegation_sid = drd.delegation_sid
	   AND dr.region_sid = drd.region_sid AND drd.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');

CREATE OR REPLACE FORCE VIEW csr.sheet_value_converted 
	(app_sid, sheet_value_id, sheet_id, ind_sid, region_sid, val_number, set_by_user_sid, 
	 set_dtm, note, entry_measure_conversion_id, entry_val_number, is_inherited, 
	 status, last_sheet_value_change_id, alert, flag, factor_a, factor_b, factor_c, 
	 start_dtm, end_dtm, actual_val_number, var_expl_note, is_na) AS
  SELECT sv.app_sid, sv.sheet_value_id, sv.sheet_id, sv.ind_sid, sv.region_sid,
	       -- we derive val_number from entry_val_number in case of pct_ownership
	       -- we round the value to avoid Arithmetic Overflows from converting Oracle Decimals to .NET Decimals
		 ROUND(NVL(NVL(mc.a, mcp.a), 1) * POWER(sv.entry_val_number, NVL(NVL(mc.b, mcp.b), 1)) + NVL(NVL(mc.c, mcp.c), 0),10) val_number,		 
         sv.set_by_user_sid, sv.set_dtm, sv.note,
         sv.entry_measure_conversion_id, sv.entry_val_number,
         sv.is_inherited, sv.status, sv.last_sheet_value_change_id,
         sv.alert, sv.flag,
         NVL(mc.a, mcp.a) factor_a,
         NVL(mc.b, mcp.b) factor_b,
         NVL(mc.c, mcp.c) factor_c,
         s.start_dtm, s.end_dtm, sv.val_number actual_val_number, var_expl_note,
		 sv.is_na
    FROM sheet_value sv, sheet s, measure_conversion mc, measure_conversion_period mcp
   WHERE sv.app_sid = s.app_sid 
     AND sv.sheet_id = s.sheet_id
     AND sv.app_sid = mc.app_sid(+)
     AND sv.entry_measure_conversion_id = mc.measure_conversion_id(+)
     AND mc.app_sid = mcp.app_sid(+)
     AND mc.measure_conversion_id = mcp.measure_conversion_id(+)
     AND (s.start_dtm >= mcp.start_dtm or mcp.start_dtm is null)
     AND (s.start_dtm < mcp.end_dtm or mcp.end_dtm is null);

@..\vb_legacy_body
@..\csr_data_pkg
@..\csr_data_body
@..\sheet_body
@..\delegation_pkg
@..\delegation_body

@update_tail