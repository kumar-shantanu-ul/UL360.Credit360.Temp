-- Please update version.sql too -- this keeps clean builds in sync
define version=3302
define minor_version=5
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- Fix Existing Data - took ~4 seconds to run on .sup
DECLARE 
	PROCEDURE UNSEC_RemoveFollowerRoles (
		in_purchaser_company_sid NUMBER,
		in_supplier_company_sid	 NUMBER,
		in_role_sid				 NUMBER
	) 
	IS	
		v_role_member_count NUMBER;
	BEGIN
		FOR r IN (
			SELECT rrm.region_sid, rrm.user_sid
			  FROM chain.supplier_follower sf
			  JOIN csr.supplier s ON s.company_sid = sf.supplier_company_sid
			  JOIN csr.region_role_member rrm ON rrm.region_sid = s.region_sid 
			   AND rrm.role_sid = in_role_sid
			   AND rrm.user_sid = sf.user_sid
			 WHERE sf.purchaser_company_sid = in_purchaser_company_sid
			   AND sf.supplier_company_sid = in_supplier_company_sid
		) LOOP
			DELETE FROM csr.region_role_member
			 WHERE role_sid = in_role_sid
			   AND inherited_from_sid = r.region_sid  -- The top most region is marked as inherited from itself, so we delete that and anything inherited from it.
			   AND user_sid = r.user_sid;
			
			IF SQL%ROWCOUNT > 0 THEN
				SELECT COUNT(*)
				  INTO v_role_member_count
				  FROM csr.region_role_member
				 WHERE role_sid = in_role_sid
				   AND user_sid = r.user_sid;

				--If the user is no longer a member of this role, delete him from the group too
				IF v_role_member_count =  0 THEN
					DELETE FROM security.group_members
					 WHERE member_sid_id = r.user_sid
					   AND group_sid_id = in_role_sid;
				END IF;
			END IF;
		END LOOP;
	END UNSEC_RemoveFollowerRoles;
BEGIN
	security.user_pkg.logonAdmin;

	FOR i IN (
		SELECT DISTINCT sf.app_sid, sf.purchaser_company_sid, sf.supplier_company_sid, ctr.follower_role_sid
		  FROM chain.supplier_follower sf
		  JOIN chain.company p ON p.app_sid = sf.app_sid AND p.company_sid = sf.purchaser_company_sid
		  JOIN chain.company s ON s.app_sid = sf.app_sid AND s.company_sid = sf.supplier_company_sid
		  JOIN CHAIN.company_type_relationship ctr ON ctr.app_sid = p.app_sid 
		   AND ctr.primary_company_type_id = p.company_type_id 
		   AND ctr.secondary_company_type_id = s.company_type_id
		 WHERE ctr.follower_role_sid IS NOT NULL
		   AND EXISTS(
			SELECT 1 
			  FROM chain.supplier_relationship sr 
			 WHERE sr.purchaser_company_sid = p.company_sid 
			   AND sr.supplier_company_sid = s.company_sid
			   AND sr.deleted = 1
			)
		 ORDER BY sf.app_sid
	)
	LOOP
		security.security_pkg.setapp(i.app_sid);
		UNSEC_RemoveFollowerRoles (
			in_purchaser_company_sid => i.purchaser_company_sid,
			in_supplier_company_sid	 => i.supplier_company_sid,
			in_role_sid				 => i.follower_role_sid
		);
		
		DELETE FROM chain.supplier_follower 
		 WHERE purchaser_company_sid = i.purchaser_company_sid
		   AND supplier_company_sid = i.supplier_company_sid;
	END LOOP;
	security.security_pkg.setapp(NULL);
	security.user_pkg.logoff(SYS_CONTEXT('SECURITY', 'ACT'));
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../chain/test_chain_utils_pkg
@../chain/test_chain_utils_body

@../supplier_pkg
@../supplier_body
@../chain/company_body

@update_tail
