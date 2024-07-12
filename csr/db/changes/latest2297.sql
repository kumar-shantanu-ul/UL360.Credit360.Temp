-- Please update version.sql too -- this keeps clean builds in sync
define version=2297
@update_header

DECLARE 
   column_exists exception; 
   pragma exception_init( column_exists , -1430 );
BEGIN
	EXECUTE IMMEDIATE 'ALTER TABLE csr.dataview_trend ADD (' || 
		'rounding_method NUMBER(5,0) DEFAULT 0 NOT NULL CONSTRAINT chk_dataview_trend_rounding_me CHECK ( rounding_method BETWEEN 0 AND 9 ),' ||
		'rounding_digits NUMBER(5,0) DEFAULT 0 NOT NULL CONSTRAINT chk_dataview_trend_rounding_di CHECK ( rounding_digits BETWEEN 0 AND 99 )' ||
	')';
EXCEPTION WHEN column_exists THEN
	dbms_output.put_line('Ignoring dataview_trend schema change - column already exists');
END;
/
	
@..\dataview_pkg;
@..\dataview_body;
@update_tail
