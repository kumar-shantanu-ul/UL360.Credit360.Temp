-- Please update version.sql too -- this keeps clean builds in sync
define version=2581
@update_header

declare
	v_exists number;
begin
	select count(*) into v_exists from all_tables where owner='CSR' and table_name='SECTION_VAL';
	if v_exists = 0 then
		execute immediate 
'CREATE TABLE csr.section_val(
	app_sid						NUMBER(10)		DEFAULT sys_context(''security'',''app'') NOT NULL,
	section_val_id				NUMBER(20)		NOT NULL,
	section_sid					NUMBER(10)		NOT NULL,
	fact_id						VARCHAR2(255)	NOT NULL,
	region_sid					NUMBER(10)		NULL,
	start_dtm					DATE			NULL,
	end_dtm						DATE			NULL,
	idx							NUMBER(10)		NOT NULL,
	val_number					NUMBER(24,10)	NULL,
	std_measure_conversion_id	NUMBER(10)		NULL,
	note						CLOB			NULL,
	CONSTRAINT pk_section_val PRIMARY KEY (app_sid, section_val_id)
)';

		execute immediate
'ALTER TABLE csr.section_val ADD CONSTRAINT fk_section_val_section_ind 
    FOREIGN KEY (app_sid, section_sid, fact_id)
    REFERENCES csr.section_ind(app_sid, section_sid, fact_id)';
    
    
    	execute immediate
'CREATE UNIQUE INDEX csr.uk_section_val ON csr.section_val (app_sid, section_sid, fact_id, region_sid, start_dtm, end_dtm, idx)';
end if;
end;
/


@update_tail
