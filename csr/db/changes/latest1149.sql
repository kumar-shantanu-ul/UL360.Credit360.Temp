-- Please update version.sql too -- this keeps clean builds in sync
define version=1149
@update_header
--set serveroutput on

grant select,references on aspen2.translation_set to csr;

begin
	for r in (select table_name, constraint_name from all_constraints where owner='CSR' and r_constraint_name='PK_TRANSLATION_SET' and r_owner='ASPEN2') loop
		--dbms_output.put_line('alter table csr.'||r.table_name||' drop constraint '||r.constraint_name);
		execute immediate 'alter table csr.'||r.table_name||' drop constraint '||r.constraint_name;
	end loop;
end;
/

ALTER TABLE CSR.ALERT_FRAME_BODY ADD CONSTRAINT FK_ALERT_FRM_BDY_TRAN_SET 
    FOREIGN KEY (APP_SID, LANG)
    REFERENCES ASPEN2.TRANSLATION_SET(APPLICATION_SID, LANG)
;

 
ALTER TABLE CSR.ALERT_TEMPLATE_BODY ADD CONSTRAINT FK_ALT_TPL_BDY_BDY_TRAN_SET 
    FOREIGN KEY (APP_SID, LANG)
    REFERENCES ASPEN2.TRANSLATION_SET(APPLICATION_SID, LANG)
;

ALTER TABLE CSR.IND_DESCRIPTION ADD CONSTRAINT FK_IND_DESCRIPTION_ASPEN2_TS
	FOREIGN KEY (APP_SID, LANG)
	REFERENCES ASPEN2.TRANSLATION_SET (APPLICATION_SID, LANG)
;
	
ALTER TABLE CSR.DATAVIEW_IND_DESCRIPTION ADD CONSTRAINT FK_DV_IND_DESC_ASPEN2_TS
	FOREIGN KEY (APP_SID, LANG)
	REFERENCES ASPEN2.TRANSLATION_SET (APPLICATION_SID, LANG)
;

@update_tail

