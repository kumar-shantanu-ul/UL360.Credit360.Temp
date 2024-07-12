-- Please update version.sql too -- this keeps clean builds in sync
define version=2481
@update_header


CREATE OR REPLACE TYPE BODY CHAIN.T_BUS_REL_COMP_ROW AS
	MAP MEMBER FUNCTION MAP
		RETURN VARCHAR2
	IS
	BEGIN
		RETURN BUSINESS_RELATIONSHIP_ID||'/'||BUSINESS_RELATIONSHIP_TIER_ID;
	END;
END;
/

@..\issue_pkg
@..\chain\company_pkg

@..\issue_body
@..\chain\company_body

@update_tail
