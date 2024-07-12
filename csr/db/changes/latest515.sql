-- Please update version.sql too -- this keeps clean builds in sync
define version=515
@update_header

begin
	for r in (select type_name from user_types where type_name in (
				'T_CHANGES_TABLE')) loop
		--dbms_output.put_line('drop '||r.type_name);
		execute immediate 'DROP TYPE '||r.type_name;
	end loop;
end;
/

CREATE OR REPLACE TYPE T_CHANGES_ROW AS 
  OBJECT ( 
	CHANGE_TYPE			NUMBER(10,0),
	FROM_VALUE			NUMBER(24,10),
	FROM_FORMAT_MASK	VARCHAR2(255),
	FROM_DESCRIPTION	VARCHAR2(255),
	TO_VALUE			NUMBER(24,10),
	TO_FORMAT_MASK		VARCHAR2(255),
	TO_DESCRIPTION		VARCHAR2(255),
	SHEET_VALUE_ID		NUMBER(10,0)
  );
/
CREATE OR REPLACE TYPE T_CHANGES_TABLE AS 
  TABLE OF T_CHANGES_ROW;
/

@../csr_data_pkg
@../delegation_body

@update_tail


