-- Please update version.sql too -- this keeps clean builds in sync
define version=86
@update_header

VARIABLE version NUMBER
BEGIN :version := 86; END; -- CHANGE THIS TO MATCH VERSION NUMBER
/

WHENEVER SQLERROR EXIT SQL.SQLCODE
DECLARE
	v_version	version.db_version%TYPE;
BEGIN
	SELECT db_version INTO v_version FROM version;
	IF v_version >= :version THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||:version||' HAS ALREADY BEEN APPLIED =======');
	END IF;
	IF v_version + 1 <> :version THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||:version||' CANNOT BE APPLIED TO A DATABASE OF VERSION '||v_version||' =======');
	END IF;
END;
/

CREATE OR REPLACE VIEW VAL_CONVERTED AS
   SELECT v.val_id, v.ind_sid, v.region_sid, v.period_start_dtm, v.period_end_dtm,
          v.entry_val_number * NVL(NVL(mc.conversion_factor, mcp.conversion_factor),1) val_number, -- we derive val_number from entry_val_number in case of pct_ownership
          v.status, v.alert, v.flags, v.source_id, 
          v.entry_measure_conversion_id, v.entry_val_number, v.last_val_change_id,
          v.note, v.source_type_id, v.file_upload_sid,
          NVL(mc.conversion_factor, mcp.conversion_factor) factor
     FROM VAL V, MEASURE_CONVERSION MC, MEASURE_CONVERSION_PERIOD MCP
    WHERE MC.MEASURE_CONVERSION_ID = MCP.MEASURE_CONVERSION_ID(+)
      AND V.entry_measure_conversion_id = mc.measure_conversion_id(+)
      AND (v.period_start_dtm >= mcp.start_dtm or mcp.start_dtm is null)
      AND (v.period_start_dtm < mcp.end_dtm or mcp.end_dtm is null);  
      
      

CREATE OR REPLACE VIEW SHEET_VALUE_CONVERTED AS
    SELECT sv.sheet_value_id, sv.sheet_id, sv.ind_sid, sv.region_sid, 
           sv.entry_val_number * NVL(NVL(mc.conversion_factor, mcp.conversion_factor),1) val_number, -- we derive val_number from entry_val_number in case of pct_ownership
           sv.set_by_user_sid, sv.set_dtm, sv.note, 
           sv.entry_measure_conversion_id, sv.entry_val_number, 
           sv.is_inherited, sv.status, sv.last_sheet_value_change_id, 
           sv.alert, sv.file_upload_sid, sv.flag,
           NVL(mc.conversion_factor, mcp.conversion_factor) factor,
           s.start_dtm, s.end_dtm
      FROM SHEET_VALUE SV, SHEET S, MEASURE_CONVERSION MC, MEASURE_CONVERSION_PERIOD MCP
     WHERE SV.SHEET_ID = S.SHEET_ID
       AND SV.entry_measure_conversion_id = mc.measure_conversion_id(+)
       AND MC.MEASURE_CONVERSION_ID = MCP.MEASURE_CONVERSION_ID(+)
       AND (s.start_dtm >= mcp.start_dtm or mcp.start_dtm is null)
       AND (s.start_dtm < mcp.end_dtm or mcp.end_dtm is null);
       

UPDATE csr.version SET db_version = :version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT



@update_tail
