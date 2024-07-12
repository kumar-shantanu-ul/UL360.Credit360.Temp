-- Please update version.sql too -- this keeps clean builds in sync
define version=3197
define minor_version=9
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE CSR.SHEET_VALUE ADD (
	IS_OVERRIDE_IND	NUMBER(1)
);

ALTER TABLE CSRIMP.SHEET_VALUE ADD (
	IS_OVERRIDE_IND	NUMBER(1)
);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.
CREATE OR REPLACE FORCE VIEW csr.sheet_value_converted
	(app_sid, sheet_value_id, sheet_id, ind_sid, region_sid, val_number, set_by_user_sid,
	 set_dtm, note, entry_measure_conversion_id, entry_val_number, is_inherited,
	 status, last_sheet_value_change_id, alert, flag, factor_a, factor_b, factor_c,
	 start_dtm, end_dtm, actual_val_number, var_expl_note, is_na, is_override_ind) AS
  SELECT sv.app_sid, sv.sheet_value_id, sv.sheet_id, sv.ind_sid, sv.region_sid,
	       -- we derive val_number from entry_val_number in case of pct_ownership
	       -- we round the value to avoid Arithmetic Overflows from converting Oracle Decimals to .NET Decimals
		 ROUND(COALESCE(mc.a, mcp.a, 1) * POWER(sv.entry_val_number, COALESCE(mc.b, mcp.b, 1)) + COALESCE(mc.c, mcp.c, 0), 10) val_number,
         sv.set_by_user_sid, sv.set_dtm, sv.note,
         sv.entry_measure_conversion_id, sv.entry_val_number,
         sv.is_inherited, sv.status, sv.last_sheet_value_change_id,
         sv.alert, sv.flag,
         NVL(mc.a, mcp.a) factor_a,
         NVL(mc.b, mcp.b) factor_b,
         NVL(mc.c, mcp.c) factor_c,
         s.start_dtm, s.end_dtm, sv.val_number actual_val_number, var_expl_note,
		 sv.is_na, sv.is_override_ind
    FROM sheet_value sv, sheet s, measure_conversion mc, measure_conversion_period mcp
   WHERE sv.app_sid = s.app_sid
     AND sv.sheet_id = s.sheet_id
     AND sv.app_sid = mc.app_sid(+)
     AND sv.entry_measure_conversion_id = mc.measure_conversion_id(+)
     AND mc.app_sid = mcp.app_sid(+)
     AND mc.measure_conversion_id = mcp.measure_conversion_id(+)
     AND (s.start_dtm >= mcp.start_dtm or mcp.start_dtm is null)
     AND (s.start_dtm < mcp.end_dtm or mcp.end_dtm is null);


-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../delegation_pkg

@../delegation_body
@../sheet_body
@../schema_body
@../csrimp/imp_body


@update_tail
