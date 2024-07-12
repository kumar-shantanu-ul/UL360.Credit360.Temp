-- Please update version.sql too -- this keeps clean builds in sync
define version=2345
@update_header

CREATE TABLE chain.FilterSupplierReportLinks
(
	APP_SID     NUMBER(10,0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	REPORT_URL	NVARCHAR2(2000)	NOT NULL,
	LABEL       NVARCHAR2(500)  NOT NULL
);

DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
	POLICY_ALREADY_EXISTS EXCEPTION;
	PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
BEGIN
	BEGIN
		dbms_rls.add_policy(
			object_schema   => 'CHAIN',
			object_name     => 'FilterSupplierReportLinks',
			policy_name     => 'FilterSuppReportLinks_POLICY',
			function_schema => 'CHAIN',
			policy_function => 'appSidCheck',
			statement_types => 'select, insert, update, delete',
			update_check    => true,
			policy_type     => dbms_rls.context_sensitive 
		);
	EXCEPTION
		WHEN POLICY_ALREADY_EXISTS THEN
			NULL;
		WHEN FEATURE_NOT_ENABLED THEN
			dbms_output.put_line('RLS policies not applied for "CHAIN.FilterSupplierReportLinks" as feature not enabled');
	END;
END;
/

set define off

BEGIN
	FOR r IN (
		SELECT host 
		  FROM chain.v$chain_host 
		 WHERE upper(name) = 'OTTOSC'
	)
	LOOP
		security.user_pkg.logonadmin(r.host);
		
		insert into chain.FilterSupplierReportLinks values (SECURITY.Security_Pkg.Getapp, '/otto-supplychain/reports/downloadReport.aspx?compoundFilterId={0}&reportId=1', 'Actual Perfromance');
		insert into chain.FilterSupplierReportLinks values (SECURITY.Security_Pkg.Getapp, '/otto-supplychain/reports/downloadReport.aspx?compoundFilterId={0}&reportId=2', 'Target Achievment');
		insert into chain.FilterSupplierReportLinks values (SECURITY.Security_Pkg.Getapp, '/otto-supplychain/reports/downloadReport.aspx?compoundFilterId={0}&reportId=3', 'Code of Conduct');
		insert into chain.FilterSupplierReportLinks values (SECURITY.Security_Pkg.Getapp, '/otto-supplychain/reports/downloadReport.aspx?compoundFilterId={0}&reportId=4', 'Audit/Qualification History');
		insert into chain.FilterSupplierReportLinks values (SECURITY.Security_Pkg.Getapp, '/otto-supplychain/reports/downloadReport.aspx?compoundFilterId={0}&reportId=5', 'BSCI Audit Detail');
		insert into chain.FilterSupplierReportLinks values (SECURITY.Security_Pkg.Getapp, '/otto-supplychain/reports/downloadReport.aspx?compoundFilterId={0}&reportId=6', 'Change of tier status');
		insert into chain.FilterSupplierReportLinks values (SECURITY.Security_Pkg.Getapp, '/otto-supplychain/reports/downloadReport.aspx?compoundFilterId={0}&reportId=7', 'Change of actual performance');
		insert into chain.FilterSupplierReportLinks values (SECURITY.Security_Pkg.Getapp, '{-}', 'separator');
		insert into chain.FilterSupplierReportLinks values (SECURITY.Security_Pkg.Getapp, '/otto-supplychain/reports/downloadReport.aspx?compoundFilterId={0}&reportId=0', 'Original drill down list');
		
	END LOOP;
	
END;
/




@../chain/helper_pkg
@../chain/helper_body

@update_tail
