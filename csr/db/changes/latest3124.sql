-- Please update version.sql too -- this keeps clean builds in sync
define version=3124
define minor_version=0
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
end;
/

begin
	for r in (select data_type from all_tab_columns where owner='CSRIMP' and table_name='IND' and column_name='CALC_XML' and data_type!='CLOB') loop
		execute immediate 'alter table csrimp.ind add calc_xml_2 clob lob (calc_xml_2) store as (enable storage in row)';
		execute immediate 'update /*+PARALLEL(40)*/ csrimp.ind set calc_xml_2 = extract(calc_xml, ''/'').getClobVal() where calc_xml is not null';
		execute immediate 'alter table csrimp.ind drop column calc_xml';
		execute immediate 'alter table csrimp.ind rename column calc_xml_2 to calc_xml';
	end loop;
end;
/

begin
	execute immediate 'begin
	update csr.ind set calc_xml=null, ind_type = 0
	where dbms_lob.compare(calc_xml, ''<nop/>'', 6) = 0
		or dbms_lob.compare(calc_xml, ''<nop />'', 7) = 0;
	delete from csr.calc_dependency where (app_sid, calc_ind_sid) in (
		select app_sid, ind_sid from csr.ind where ind_type = 0 );
	end;';
end;
/

ALTER TABLE CSRIMP.DOC_FOLDER_NAME_TRANSLATION DROP CONSTRAINT UK_DOC_FOLDER_NAME;

ALTER TABLE CSRIMP.CHAIN_CERTIFICATION_TYPE DROP CONSTRAINT PK_CERTIFICATION;
ALTER TABLE CSRIMP.CHAIN_CERTIFICATION_TYPE ADD CONSTRAINT PK_CERTIFICATION PRIMARY KEY (CSRIMP_SESSION_ID, CERTIFICATION_TYPE_ID);

ALTER TABLE CSRIMP.CHAIN_CERT_TYPE_AUDIT_TYPE DROP CONSTRAINT PK_CERTIFICATION_AUDIT_TYPE;
ALTER TABLE CSRIMP.CHAIN_CERT_TYPE_AUDIT_TYPE ADD CONSTRAINT PK_CERTIFICATION_AUDIT_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, CERTIFICATION_TYPE_ID, INTERNAL_AUDIT_TYPE_ID);

ALTER TABLE CSRIMP.CHAIN_ALT_COMPANY_NAME DROP CONSTRAINT PK_CHAIN_ALT_COMPANY_NAME;
ALTER TABLE CSRIMP.CHAIN_ALT_COMPANY_NAME ADD CONSTRAINT PK_CHAIN_ALT_COMPANY_NAME PRIMARY KEY (CSRIMP_SESSION_ID, ALT_COMPANY_NAME_ID);

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
@../csrimp/imp_body

@update_tail
