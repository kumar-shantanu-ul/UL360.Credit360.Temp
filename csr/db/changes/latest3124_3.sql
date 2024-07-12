-- Please update version too -- this keeps clean builds in sync
define version=3124
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
begin
	for r in (select data_type from all_tab_columns where owner='CSR' and table_name='IND' and column_name='CALC_XML' and data_type!='CLOB') loop
		execute immediate 'alter table csr.ind add calc_xml_2 clob lob (calc_xml_2) store as (enable storage in row)';
		execute immediate 'update /*+PARALLEL(40)*/ csr.ind set calc_xml_2 = extract(calc_xml, ''/'').getClobVal() where calc_xml is not null';
		execute immediate 'alter table csr.ind drop column calc_xml';
		execute immediate 'alter table csr.ind rename column calc_xml_2 to calc_xml';
	end loop;

	for r in (select data_type from all_tab_columns where owner='CSRIMP' and table_name='IND' and column_name='CALC_XML' and data_type!='CLOB') loop
		execute immediate 'alter table csrimp.ind add calc_xml_2 clob lob (calc_xml_2) store as (enable storage in row)';
		execute immediate 'update /*+PARALLEL(40)*/ csrimp.ind set calc_xml_2 = extract(calc_xml, ''/'').getClobVal() where calc_xml is not null';
		execute immediate 'alter table csrimp.ind drop column calc_xml';
		execute immediate 'alter table csrimp.ind rename column calc_xml_2 to calc_xml';
	end loop;

	execute immediate 'begin
	update csr.ind set calc_xml=null, ind_type = 0
	where dbms_lob.compare(calc_xml, ''<nop/>'', 6) = 0
		or dbms_lob.compare(calc_xml, ''<nop />'', 7) = 0;
	delete from csr.calc_dependency where (app_sid, calc_ind_sid) in (
		select app_sid, ind_sid from csr.ind where ind_type = 0 );
	end;';
end;
/

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***
begin
	for r in (select 1 from all_objects where owner='CSR' and object_name='VB_LEGACY_PKG' and object_type='PACKAGE') loop
		execute immediate 'drop package csr.vb_legacy_pkg';
	end loop;
end;
/

-- *** Packages ***
@../calc_pkg
@../actions/ind_template_body
@../actions/task_body
@../audit_body
@../calc_body
@../csrimp/imp_body
@../dataview_body
@../delegation_body
@../form_body
@../indicator_body
@../model_body
@../quick_survey_body
@../target_dashboard_body
@../testdata_body
@../util_script_body

@update_tail
