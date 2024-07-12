-- Please update version.sql too -- this keeps clean builds in sync
define version=2863
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

CREATE OR REPLACE PROCEDURE chain.tmp_GrantCapability (
	in_capability_type		IN  NUMBER,
	in_capability			IN  VARCHAR2,
	in_group				IN  VARCHAR2,
	in_permission_set		IN  security.security_pkg.T_PERMISSION
)
AS
	v_capability_id			NUMBER;
	v_company_group_type_id	NUMBER;
BEGIN

	SELECT capability_id
	  INTO v_capability_id
	  FROM capability
	 WHERE capability_type_id = in_capability_type
	   AND capability_name = in_capability;
	
	SELECT company_group_type_id
	  INTO v_company_group_type_id
	  FROM company_group_type
	 WHERE name = in_group;
	
	INSERT INTO chain.group_capability(group_capability_id, company_group_type_id, capability_id, permission_set)
		VALUES(chain.group_capability_id_seq.NEXTVAL, v_company_group_type_id, v_capability_id, in_permission_set);
END;
/

BEGIN
	security.user_pkg.logonadmin;

	chain.tmp_GrantCapability(1 /* chain.chain_pkg.CT_COMPANY */,   'Company user', 'Administrators', security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE + security.security_pkg.PERMISSION_DELETE);
	chain.tmp_GrantCapability(1 /* chain.chain_pkg.CT_COMPANY */,   'Company user', 'Users', security.security_pkg.PERMISSION_READ);
	chain.tmp_GrantCapability(2 /* chain.chain_pkg.CT_SUPPLIERS */, 'Company user', 'Users', security.security_pkg.PERMISSION_READ);

END;
/

DROP PROCEDURE chain.tmp_GrantCapability;


-- ** New package grants **

-- *** Packages ***
@../chain/company_type_body

@update_tail
