define version=3164
define minor_version=0
define is_combined=1
@update_header

-- clean out junk in csrimp
begin
for r in (select table_name from all_tables where owner='CSRIMP' and table_name!='CSRIMP_SESSION') loop
execute immediate 'truncate table csrimp.'||r.table_name;
end loop;
delete from csrimp.csrimp_session;
commit;
end;
/


ALTER TABLE CSR.CUSTOMER ADD CONSTRAINT CHK_ADJ_FACTORSET_STARTMONTH CHECK (ADJ_FACTORSET_STARTMONTH IN (0,1));


GRANT EXECUTE ON csr.branding_pkg TO tool_user;








BEGIN
	security.user_pkg.logonadmin;
	UPDATE chain.supplier_relationship
	   SET deleted = 1,
	   	   active = 0
	 WHERE purchaser_company_sid = supplier_company_sid;
END;
/
BEGIN
	security.user_pkg.logonadmin;
	UPDATE security.menu
	   SET action = '/csr/site/flow/admin/pseudoRoles.acds'
	 WHERE LOWER(action) = '/csr/site/chain/admin/pseudoroles.acds';
END;
/






@..\integration_api_pkg
@..\branding_pkg


@..\chain\company_dedupe_body
@..\integration_api_body
@..\branding_body
@..\automated_import_body
@..\chain\company_body
@..\calc_body
@..\enable_body
@..\quick_survey_body
@..\region_body
@..\factor_body



@update_tail
