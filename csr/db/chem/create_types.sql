--set serveroutput on
begin
	for r in (select type_name from all_types where owner='CHEM' and type_name in (
				'T_CAS_COMP_TABLE')) loop
		--dbms_output.put_line('drop '||r.type_name);
		execute immediate 'DROP TYPE CHEM.'||r.type_name;
	end loop;
end;
/

CREATE OR REPLACE TYPE CHEM.T_CAS_COMP_ROW AS
	OBJECT (
		CAS_CODE				VARCHAR2(50),
		PCT_COMPOSITION 			NUMBER(5,4) 
	);
/
CREATE OR REPLACE TYPE CHEM.T_CAS_COMP_TABLE AS
  TABLE OF CHEM.T_CAS_COMP_ROW;
/

