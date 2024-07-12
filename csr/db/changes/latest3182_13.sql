-- Please update version.sql too -- this keeps clean builds in sync
define version=3182
define minor_version=13
@update_header

-- *** DDL ***
-- Create tables

/* http://radino.eu/2008/05/31/bitwise-or-aggregate-function/ */
CREATE OR REPLACE TYPE csr.bitor_impl AS OBJECT
(
  bitor NUMBER,

  STATIC FUNCTION ODCIAggregateInitialize(ctx IN OUT bitor_impl) RETURN NUMBER,

  MEMBER FUNCTION ODCIAggregateIterate(SELF  IN OUT bitor_impl,
                                       VALUE IN NUMBER) RETURN NUMBER,

  MEMBER FUNCTION ODCIAggregateMerge(SELF IN OUT bitor_impl,
                                     ctx2 IN bitor_impl) RETURN NUMBER,

  MEMBER FUNCTION ODCIAggregateTerminate(SELF        IN OUT bitor_impl,
                                         returnvalue OUT NUMBER,
                                         flags       IN NUMBER) RETURN NUMBER
)
/

CREATE OR REPLACE TYPE BODY csr.bitor_impl IS
  STATIC FUNCTION ODCIAggregateInitialize(ctx IN OUT bitor_impl) RETURN NUMBER IS
  BEGIN
    ctx := bitor_impl(0);
    RETURN ODCIConst.Success;
  END ODCIAggregateInitialize;

  MEMBER FUNCTION ODCIAggregateIterate(SELF  IN OUT bitor_impl,
                                       VALUE IN NUMBER) RETURN NUMBER IS
  BEGIN
    SELF.bitor := SELF.bitor + VALUE - bitand(SELF.bitor, VALUE);
    RETURN ODCIConst.Success;
  END ODCIAggregateIterate;

  MEMBER FUNCTION ODCIAggregateMerge(SELF IN OUT bitor_impl,
                                     ctx2 IN bitor_impl) RETURN NUMBER IS
  BEGIN
    SELF.bitor := SELF.bitor + ctx2.bitor - bitand(SELF.bitor, ctx2.bitor);
    RETURN ODCIConst.Success;
  END ODCIAggregateMerge;

  MEMBER FUNCTION ODCIAggregateTerminate(SELF        IN OUT bitor_impl,
                                         returnvalue OUT NUMBER,
                                         flags       IN NUMBER) RETURN NUMBER IS
  BEGIN
    returnvalue := SELF.bitor;
    RETURN ODCIConst.Success;
  END ODCIAggregateTerminate;
END;
/

CREATE OR REPLACE FUNCTION csr.bitoragg(x IN NUMBER) RETURN NUMBER
PARALLEL_ENABLE
AGGREGATE USING bitor_impl;
/

CREATE SEQUENCE csr.audit_migration_fail_seq;

CREATE TABLE csr.audit_migration_failure(
	app_sid						NUMBER(10, 0)   DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	audit_migration_failure_id 	NUMBER(10, 0) 	NOT NULL,
	object_sid					NUMBER(10, 0) 	NOT NULL,
	grantee_sid					NUMBER(10, 0),
	validation_type_id			NUMBER(1) 		NOT NULL,	
	message						VARCHAR(128),
	CONSTRAINT pk_audit_migration_failure PRIMARY KEY (app_sid, audit_migration_failure_id)
);
-- Alter tables

-- *** Grants ***
GRANT UPDATE ON security.acl TO csr;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (56, 'Validate audit workflow migration', 
  'Checks if audits on this site can be migrated to a workflow. Will complete successfully if the validation passes, otherwise will throw an error. Find error details in "csr/site/admin/auditmigration/validationfailures.acds" page', 'CanMigrateAudits', NULL);

-- ** New package grants **
CREATE OR REPLACE PACKAGE csr.audit_migration_pkg AS END;
/
GRANT EXECUTE ON csr.audit_migration_pkg TO web_user;

-- *** Conditional Packages ***

-- *** Packages ***
@..\audit_migration_pkg
@..\unit_test_pkg
@..\util_script_pkg
@..\chain\test_chain_utils_pkg

@..\audit_migration_body
@..\unit_test_body
@..\util_script_body
@..\chain\test_chain_utils_body

@update_tail
