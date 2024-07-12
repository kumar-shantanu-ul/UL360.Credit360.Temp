CREATE OR REPLACE PACKAGE csr.test_audit_migration_pkg AS

PROCEDURE SetUpFixture;

PROCEDURE TearDownFixture;

PROCEDURE SetUp;

PROCEDURE TearDown;

/* Tests */

PROCEDURE IdenticalPermissions_Pass;

PROCEDURE AuditWithExtraGroup_Fail;

PROCEDURE AuditWithMissingGroups_Fail;

PROCEDURE AuditWithExtraPerm_Fail;

PROCEDURE AuditWithMissingPerm_Fail;

PROCEDURE AggPermissionMatch_Pass;

PROCEDURE AggPermissionMismatch_Fail;

PROCEDURE CloseAudWithUserPerm_Fail;

PROCEDURE NonCsrGroupPermission_Fail;

PROCEDURE CloseAudWithGroup_Pass;

PROCEDURE ImportFindWithNonGroup_Fail;

PROCEDURE AllowPermSet_Pass;

PROCEDURE DenyPermSet_Fail;

PROCEDURE MigrateAudit_NoWorfklow;

PROCEDURE MigrateAudit_Workflow;

PROCEDURE MigratedAudit_Write;

PROCEDURE MigratedAudit_Read;

PROCEDURE MigratedAudit_Write_Delete;

PROCEDURE MigratedAudit_Read_Abilities;

PROCEDURE MigratedAudit_Write_Abilities;

PROCEDURE MigratedAudit_Wr_Del_Abilities;

PROCEDURE MigratedAudit_Close;

PROCEDURE MigratedAudit_ImportNC;

PROCEDURE MigratedAudit_RoleToGroup;

PROCEDURE MigratedAudit_RegUserToGroup;

PROCEDURE MigrateAudit_AuditorRole;

PROCEDURE MigrateAudit_AuditContactRole;

PROCEDURE MigrateAudit_AR_With_Closure;

PROCEDURE MigrateAudit_ACR_With_Closure;

END;
/