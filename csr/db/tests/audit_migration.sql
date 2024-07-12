set serveroutput on
set echo off

GRANT EXECUTE ON chain.test_chain_utils_pkg TO CSR;

@@test_audit_migration_pkg
@@test_audit_migration_body

BEGIN
 	-- Run tests in package
 	csr.unit_test_pkg.RunTests('csr.test_audit_migration_pkg', csr.unit_test_pkg.T_TESTS(
 		'IdenticalPermissions_Pass',
		'AuditWithExtraGroup_Fail',
		'AuditWithMissingGroups_Fail',
		'AuditWithExtraPerm_Fail',
		'AuditWithMissingPerm_Fail',
		'AggPermissionMatch_Pass',
		'AggPermissionMismatch_Fail',
		'CloseAudWithUserPerm_Fail',
		'CloseAudWithGroup_Pass',
		'ImportFindWithNonGroup_Fail',
		'NonCsrGroupPermission_Fail',
		'AllowPermSet_Pass',
		'DenyPermSet_Fail',
		'MigrateAudit_NoWorfklow',
		'MigrateAudit_Workflow',
		'MigratedAudit_Write',
		'MigratedAudit_Read',
		'MigratedAudit_Write_Delete',
		'MigratedAudit_Read_Abilities',
		'MigratedAudit_Write_Abilities',
		'MigratedAudit_Wr_Del_Abilities',
		'MigratedAudit_Close',
		'MigratedAudit_ImportNC',
		'MigratedAudit_RoleToGroup',
		'MigratedAudit_RegUserToGroup',
		'MigrateAudit_AuditorRole',
		'MigrateAudit_AuditContactRole',
		'MigrateAudit_AR_With_Closure',
		'MigrateAudit_ACR_With_Closure'
	), :bv_site_name);
END;
/

set echo on
