-- Please update version.sql too -- this keeps clean builds in sync
define version=39
@update_header

declare
	v_cnt number;
begin
	select count(*) into v_cnt from user_tab_columns where table_name = 'GT_FORMULATION_ANSWERS' and column_name = 'BS_ACCREDITED_PRIORITY_SRC';
	if v_cnt = 0 then
		execute immediate 'ALTER TABLE SUPPLIER.GT_FORMULATION_ANSWERS ADD (BS_ACCREDITED_PRIORITY_SRC  VARCHAR2(4000))';
	end if;
	select count(*) into v_cnt from user_tab_columns where table_name = 'GT_FORMULATION_ANSWERS' and column_name = 'BS_ACCREDITED_OTHER_SRC';
	if v_cnt = 0 then
		execute immediate 'ALTER TABLE SUPPLIER.GT_FORMULATION_ANSWERS ADD (BS_ACCREDITED_OTHER_SRC     VARCHAR2(4000))';
	end if;
end;
/

@update_tail
