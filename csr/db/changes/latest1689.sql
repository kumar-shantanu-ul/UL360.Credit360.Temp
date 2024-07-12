-- Please update version.sql too -- this keeps clean builds in sync
define version=1689
@update_header

DECLARE
	v_count			number(10);
	TYPE t_idxs IS TABLE OF VARCHAR2(4000);
	v_list t_idxs := t_idxs(
		'create index csr.IDX_SHEET_END on CSR.SHEET(END_DTM,APP_SID)',
		'create index csr.IDX_SHEET_IND on CSR.SHEET_VALUE(APP_SID,IND_SID)',
		'create index csr.IDX_SHEET_VALUE on CSR.SHEET_VALUE(APP_SID,REGION_SID,STATUS,IND_SID)',
		'create index csr.IDX_SHEET_REGION on CSR.SHEET_VALUE(APP_SID,REGION_SID)',
		'create index csr.IDX_SV_CHANGE_IND on CSR.SHEET_VALUE_CHANGE(APP_SID,IND_SID)',
		'create index csr.IDX_SV_CHANGE_SVID on CSR.SHEET_VALUE_CHANGE(SHEET_VALUE_ID,APP_SID)',
		'create index csr.IDX_VAL_CHANGED_BY on CSR.VAL(APP_SID,CHANGED_BY_SID)',
		'create index csr.IDX_SHEET_DELEGATION on CSR.SHEET(APP_SID,DELEGATION_SID)',
		'create index csr.IDX_SV_CHANGE_REGION on CSR.SHEET_VALUE_CHANGE(APP_SID,REGION_SID)',
		'create index csr.IX_VAL_SOURCE_TYPE_SOURCE on CSR.VAL(APP_SID,SOURCE_TYPE_ID,SOURCE_ID)'
	);
BEGIN
	FOR i IN 1 .. v_list.count 
	LOOP
		BEGIN
			EXECUTE IMMEDIATE v_list(i);
		EXCEPTION
			WHEN OTHERS THEN
				NULL;
		END;
	END LOOP;
END;
/

@update_tail