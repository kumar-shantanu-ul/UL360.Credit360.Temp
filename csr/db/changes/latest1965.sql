-- Please update version.sql too -- this keeps clean builds in sync
define version=1965
@update_header

CREATE OR REPLACE PACKAGE CHEM.substance_helper_pkg
AS
END;
/

GRANT EXECUTE ON chem.substance_helper_pkg TO WEB_USER;
GRANT EXECUTE ON chem.substance_helper_pkg TO CSR;

grant select on csr.ind to chem;

@..\chem\substance_helper_pkg
@..\sheet_body
@..\chem\substance_pkg
@..\chem\substance_body

@update_tail