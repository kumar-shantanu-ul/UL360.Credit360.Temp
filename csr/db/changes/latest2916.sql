-- Please update version.sql too -- this keeps clean builds in sync
define version=2916
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
declare
	v_exists number;

	procedure dc(in_tn varchar2, in_cn varchar2) as
		v_exists number;
	begin
		select count(*) into v_exists from all_constraints where owner='CSRIMP' and table_name=in_tn and constraint_name=in_cn;
		if v_exists = 1 then
			execute immediate 'alter table csrimp.'||in_tn||' drop constraint '||in_cn;
		end if;
	end;
begin	
	dc('ISSUE_CUSTOM_FIELD_DATE_VAL', 'FK_ISS_CUST_FLD_DATE_FLD');
	dc('ISSUE_CUSTOM_FIELD_DATE_VAL', 'FK_ISSUE_CUST_FLD_DATE_VAL');
	dc('ISSUE_CUSTOM_FIELD_DATE_VAL', 'FK_ISSUE_CUST_IS');
	dc('QUICK_SURVEY_SCORE_THRESHOLD', 'FK_IND_QSST');
	dc('QUICK_SURVEY_SCORE_THRESHOLD', 'FK_QS_QSST');
	dc('QUICK_SURVEY_SCORE_THRESHOLD', 'FK_ST_QSST');
	dc('SUPPLIER_SURVEY_RESPONSE', 'FK_SUPP_SURV_RESP_QK_SURV_RESP');
	dc('SUPPLIER_SURVEY_RESPONSE', 'FK_SUPP_SURV_RESP_SUPPLIER');
	
	select count(*) into v_exists from all_constraints where constraint_name='FK_ISS_CUST_FLD_IS' and owner='CSRIMP' and table_name='ISSUE_CUSTOM_FIELD_DATE_VAL';
	if v_exists = 0 then execute immediate
		'alter table csrimp.ISSUE_CUSTOM_FIELD_DATE_VAL add CONSTRAINT FK_ISS_CUST_FLD_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE';
	end if;
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

-- *** Packages ***

@update_tail
