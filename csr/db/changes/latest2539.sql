-- Please update version.sql too -- this keeps clean builds in sync
define version=2539
@update_header

declare
	v_exists number;
begin
	select count(*) into v_exists from all_tab_columns where owner='CMS' and table_name='IMP_CONSTRAINTS' and column_name='STATUS';
	if v_exists = 0 then
		execute immediate 'alter table cms.imp_constraints add status varchar2(8)';
		execute immediate 'begin update cms.imp_constraints set status=''ENABLED''; commit; end;';
		execute immediate 'alter table cms.imp_constraints modify status not null';
	end if;
end;
/

CREATE OR REPLACE TYPE aspen2.T_NUMBER_TABLE AS TABLE OF NUMBER;
/

CREATE OR REPLACE FUNCTION aspen2.to_string (
	in_tbl							IN	aspen2.t_varchar2_table,
	in_delimiter					IN	VARCHAR2 DEFAULT ','
) RETURN VARCHAR2
AS
	v_i								PLS_INTEGER;
	v_result						VARCHAR2(32767);
	v_first							BOOLEAN := TRUE;
BEGIN
	v_i := in_tbl.FIRST;
	WHILE v_i IS NOT NULL LOOP
		IF v_result IS NOT NULL THEN
			v_result := v_result || in_delimiter;
		END IF;
		v_result := v_result || in_tbl(v_i);
		v_i := in_tbl.NEXT(v_i);
	END LOOP;
	RETURN v_result;
END;
/

CREATE OR REPLACE FUNCTION aspen2.to_string (
	in_tbl							IN	aspen2.t_number_table,
	in_delimiter					IN	VARCHAR2 DEFAULT ','
) RETURN VARCHAR2
AS
	v_i								PLS_INTEGER;
	v_result						VARCHAR2(32767);
	v_first							BOOLEAN := TRUE;
BEGIN
	v_i := in_tbl.FIRST;
	WHILE v_i IS NOT NULL LOOP
		IF v_result IS NOT NULL THEN
			v_result := v_result || in_delimiter;
		END IF;
		v_result := v_result || in_tbl(v_i);
		v_i := in_tbl.NEXT(v_i);
	END LOOP;
	RETURN v_result;
END;
/

grant execute on aspen2.to_string to web_user;
grant execute on aspen2.t_split_row to csr, cms, donations, actions, supplier;
grant execute on aspen2.t_split_table to csr, cms, donations, actions, supplier;
grant execute on aspen2.t_split_numeric_row to csr, cms, donations, actions, supplier;
grant execute on aspen2.t_split_numeric_table to csr, cms, donations, actions, supplier;
grant execute on aspen2.t_varchar2_table to csr, cms, donations, actions, supplier;
grant execute on aspen2.t_number_table to csr, cms, donations, actions, supplier;

@../../../aspen2/cms/db/tab_body
@../csrimp/imp_body

@update_tail
