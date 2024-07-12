-- Please update version too -- this keeps clean builds in sync
define version=1751
@update_header
CREATE OR REPLACE PACKAGE CHAIN.ADMIN_HELPER_PKG
AS
PROCEDURE dummy;
END;
/

CREATE OR REPLACE PACKAGE BODY CHAIN.ADMIN_HELPER_PKG
AS
PROCEDURE dummy
AS
BEGIN
	NULL;
END;
END;
/

GRANT EXECUTE ON CHAIN.ADMIN_HELPER_PKG TO web_user;

@..\chain\admin_helper_pkg
@..\chain\admin_helper_body

-- recompiles added For andrei
@..\chain\chain_link_pkg
@..\chain\chain_link_body
@..\chain\product_pkg
@..\chain\product_body

@update_tail
