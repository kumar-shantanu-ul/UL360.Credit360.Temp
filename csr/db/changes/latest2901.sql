-- Please update version.sql too -- this keeps clean builds in sync
define version=2901
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE chain.tt_user_details ADD SEND_ALERTS NUMBER;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- Changed v$chain_company_user (csr/db/chain/create_views.sql) added account_enabled.
CREATE OR REPLACE VIEW CHAIN.v$chain_company_user AS
	/**********************************************************************************************************/
	/****************** any invitations from someone in my company to a user in my company  *******************/
	/**********************************************************************************************************/
	SELECT vai.app_sid, vai.to_company_sid company_sid, vcu.user_sid, vcu.visibility_id,
			vcu.user_name, vcu.email, vcu.full_name, vcu.friendly_name, vcu.phone_number, vcu.job_title, vcu.account_enabled
	  FROM v$active_invite vai, v$chain_user vcu
	 WHERE vai.app_sid = vcu.app_sid
	   AND vai.from_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND vai.to_company_sid = vai.from_company_sid -- an invitation to ourselves
	   AND vai.to_user_sid = vcu.user_sid
	 UNION ALL
	/****************************************************************/
	/****************** I can see all of my users *******************/
	/****************************************************************/
	SELECT cu.app_sid, cu.company_sid, vcu.user_sid, vcu.visibility_id, 
			vcu.user_name, vcu.email, vcu.full_name, vcu.friendly_name, vcu.phone_number, vcu.job_title, vcu.account_enabled
	  FROM v$chain_user vcu, v$company_user cu
	 WHERE vcu.app_sid = cu.app_sid
	   AND vcu.user_sid = cu.user_sid
	   AND cu.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND (cu.company_sid, vcu.user_sid) NOT IN (
	   		SELECT to_company_sid, to_user_sid
	   		  FROM v$active_invite
	   		 WHERE from_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   		   AND to_company_sid = from_company_sid
	   	   )
	 UNION ALL
	/*****************************************************************/
	/****************** I can see all of my admins *******************/
	/*****************************************************************/
	SELECT ca.app_sid, ca.company_sid, vcu.user_sid, vcu.visibility_id, 
	       vcu.user_name, vcu.email, vcu.full_name, vcu.friendly_name, vcu.phone_number, vcu.job_title, vcu.account_enabled
	  FROM v$chain_user vcu, v$company_admin ca
	 WHERE vcu.app_sid = ca.app_sid
	   AND vcu.user_sid = ca.user_sid
	   AND ca.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND (ca.company_sid, vcu.user_sid) NOT IN (
			SELECT to_company_sid, to_user_sid
			  FROM v$active_invite
			 WHERE from_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			   AND to_company_sid = from_company_sid
	   	   )
	 UNION 
	/***************************************************************************************************************/
	/****************** any invitations from someone in my company to someone in another company *******************/
	/***************************************************************************************************************/
	SELECT vai.app_sid, vai.to_company_sid company_sid, vcu.user_sid, vcu.visibility_id,
			NULL user_name, vcu.email, vcu.full_name, vcu.friendly_name, -- we can always see these if there's a pending invitation as we've probably filled it in ourselves
			CASE WHEN vcu.visibility_id = 3 THEN vcu.phone_number ELSE NULL END phone_number, 
			CASE WHEN vcu.visibility_id >= 1 THEN vcu.job_title ELSE NULL END job_title, vcu.account_enabled
	  FROM v$active_invite vai, v$chain_user vcu
	 WHERE vai.app_sid = vcu.app_sid
	   AND vai.from_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND vai.to_company_sid <> vai.from_company_sid -- not an invitation to ourselves (handled above)
	   AND vai.to_user_sid = vcu.user_sid
	 UNION ALL
	/****************************************************/
	/****************** everyone else *******************/
	/****************************************************/
	SELECT cu.app_sid, cu.company_sid, cu.user_sid, cu.visibility_id, NULL user_name,
			CASE WHEN cu.visibility_id = 3 THEN cu.email ELSE NULL END email, 
			CASE WHEN cu.visibility_id >= 2 THEN cu.full_name ELSE NULL END full_name, 
			CASE WHEN cu.visibility_id >= 2 THEN cu.friendly_name ELSE NULL END friendly_name, 
			CASE WHEN cu.visibility_id = 3 THEN cu.phone_number ELSE NULL END phone_number, 
			cu.job_title, cu.account_enabled -- we always see this as we've filtered 'hidden' users
	  FROM v$company_user cu, v$company_relationship cr
	 WHERE cu.app_sid = cr.app_sid(+)
	   AND cu.company_sid = cr.company_sid(+) -- we can see companies that we are in a relationship with
	   AND cu.visibility_id <> 0 -- don't show hidden users
	   AND NOT (cu.visibility_id = 1 AND cu.job_title IS NULL)
	   AND (cr.company_sid IS NOT NULL OR SYS_CONTEXT('SECURITY', 'CHAIN_CAN_SEE_ALL_COMPANIES') = 1 AND cu.company_sid != SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'))
	   AND (cu.company_sid, cu.user_sid) NOT IN (					-- minus any active questionnaire invitations as these have already been dealt with
	   			SELECT to_company_sid, to_user_sid 
	   			  FROM v$active_invite
	   			 WHERE from_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   	   )
;

-- Changed v$chain_user: added send_alerts.
CREATE OR REPLACE VIEW CHAIN.v$chain_user AS
	SELECT csru.app_sid, csru.csr_user_sid user_sid, csru.email, csru.user_name,   -- CSR_USER data
		   csru.full_name, csru.friendly_name, csru.phone_number, csru.job_title,   -- CSR_USER data
		   cu.visibility_id, cu.registration_status_id,								-- CHAIN_USER data
		   cu.receive_scheduled_alerts, cu.details_confirmed, ut.account_enabled, csru.send_alerts
	  FROM csr.csr_user csru, chain_user cu, security.user_table ut
	 WHERE csru.app_sid = cu.app_sid
	   AND csru.csr_user_sid = cu.user_sid
	   AND cu.user_sid = ut.sid_id
	   AND cu.registration_status_id <> 2 -- not rejected 
	   AND cu.registration_status_id <> 3 -- not merged 
	   AND cu.deleted = 0
;

-- *** Data changes ***
-- RLS

-- Data
CREATE OR REPLACE PROCEDURE chain.Temp_RegisterCapability (
	in_capability_type			IN  NUMBER,
	in_capability				IN  VARCHAR2, 
	in_perm_type				IN  NUMBER,
	in_is_supplier				IN  NUMBER DEFAULT 0
)
AS
	v_count						NUMBER(10);
	v_ct						NUMBER(10);
BEGIN
	IF in_capability_type = 3 /*chain_pkg.CT_COMPANIES*/ THEN
		Temp_RegisterCapability(1 /*chain_pkg.CT_COMPANY*/, in_capability, in_perm_type);
		Temp_RegisterCapability(2 /*chain_pkg.CT_SUPPLIERS*/, in_capability, in_perm_type, 1);
		RETURN;	
	END IF;
	
	IF in_capability_type = 1 AND in_is_supplier <> 0 /* chain_pkg.IS_NOT_SUPPLIER_CAPABILITY */ THEN
		RAISE_APPLICATION_ERROR(-20001, 'Company capabilities cannot be supplier centric');
	ELSIF in_capability_type = 2 /* chain_pkg.CT_SUPPLIERS */ AND in_is_supplier <> 1 /* chain_pkg.IS_SUPPLIER_CAPABILITY */ THEN
		RAISE_APPLICATION_ERROR(-20001, 'Supplier capabilities must be supplier centric');
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM chain.capability
	 WHERE capability_name = in_capability
	   AND capability_type_id = in_capability_type
	   AND perm_type = in_perm_type;
	
	IF v_count > 0 THEN
		-- this is already registered
		RETURN;
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM chain.capability
	 WHERE capability_name = in_capability
	   AND perm_type <> in_perm_type;
	
	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'A capability named '''||in_capability||''' already exists using a different permission type');
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM chain.capability
	 WHERE capability_name = in_capability
	   AND (
			(capability_type_id = 0 /*chain_pkg.CT_COMMON*/ AND (in_capability_type = 0 /*chain_pkg.CT_COMPANY*/ OR in_capability_type = 2 /*chain_pkg.CT_SUPPLIERS*/))
	   		 OR (in_capability_type = 0 /*chain_pkg.CT_COMMON*/ AND (capability_type_id = 1 /*chain_pkg.CT_COMPANY*/ OR capability_type_id = 2 /*chain_pkg.CT_SUPPLIERS*/))
	   	   );
	
	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'A capability named '''||in_capability||''' is already registered as a different capability type');
	END IF;
	
	INSERT INTO chain.capability 
	(capability_id, capability_name, capability_type_id, perm_type, is_supplier) 
	VALUES 
	(chain.capability_id_seq.NEXTVAL, in_capability, in_capability_type, in_perm_type, in_is_supplier);
	
END;
/

DECLARE 
	v_capability_id		NUMBER;
BEGIN
	chain.Temp_RegisterCapability(
		in_capability_type	=> 1,  		/* CT_COMPANY*/
		in_capability	=> 'Manage user' /* chain.chain_pkg.MANAGE_USER */, 
		in_perm_type	=> 1, 			/* BOOLEAN_PERMISSION */
		in_is_supplier 	=> 0
	);
	
	chain.Temp_RegisterCapability(
		in_capability_type	=> 2,  		/* CT_SUPPLIERS*/
		in_capability	=> 'Manage user' /* chain.chain_pkg.MANAGE_USER */, 
		in_perm_type	=> 1, 			/* BOOLEAN_PERMISSION */
		in_is_supplier 	=> 1
	);
	
END;
/

DECLARE 
	v_capability_id		NUMBER;
BEGIN
	chain.Temp_RegisterCapability(
		in_capability_type	=> 1,  		/* CT_COMPANY*/
		in_capability	=> 'Add user to company' /* chain.chain_pkg.ADD_USER_TO_COMPANY */, 
		in_perm_type	=> 1, 			/* BOOLEAN_PERMISSION */
		in_is_supplier 	=> 0
	);
	
	chain.Temp_RegisterCapability(
		in_capability_type	=> 2,  		/* CT_SUPPLIERS*/
		in_capability	=> 'Add user to company' /* chain.chain_pkg.ADD_USER_TO_COMPANY */, 
		in_perm_type	=> 1, 			/* BOOLEAN_PERMISSION */
		in_is_supplier 	=> 1
	);
	
END;
/

DROP PROCEDURE chain.Temp_RegisterCapability;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/chain_pkg
@../chain/company_user_pkg
@../chain/company_user_body
@../chain/business_relationship_body
@../chain/company_body

@update_tail
