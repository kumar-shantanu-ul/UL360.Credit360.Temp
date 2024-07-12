/*
Run EnableDonations.sql first.
Doesn't create all the objects needed to use Funding Commitments, but these can be created through the UI at /csr/site/donations/admin/setup.acds
*/

PROMPT please enter: host

whenever oserror exit failure rollback
whenever sqlerror exit failure rollback

declare
	v_act_id 							security.security_pkg.T_ACT_ID;
	v_app_sid 							security.security_pkg.T_SID_ID;
	-- Containers
	v_donations_sid 					security.security_pkg.T_SID_ID;
	v_funding_commitments_sid 			security.security_pkg.T_SID_ID;
	-- Menus
	v_menu_sid 							security.security_pkg.T_SID_ID;
	v_donations_menu_sid 				security.security_pkg.T_SID_ID;
	v_menu_fc_sid 						security.security_pkg.T_SID_ID;
	-- Groups
	v_groups_sid 						security.security_pkg.T_SID_ID;
	v_community_users_sid 				security.security_pkg.T_SID_ID;
	v_community_admins_sid 				security.security_pkg.T_SID_ID;
	-- Tag groups
	v_payment_status_tag_grp_sid 		security.security_pkg.T_SID_ID;
	v_payment_status_tag_grp_name 		donations.tag_group.name%type := 'Payment status';
	v_is_fc_tag_group_sid 				security.security_pkg.T_SID_ID;
	v_is_fc_tag_group_name 				donations.tag_group.name%type := 'Is Funding Commitment';
	-- Tags
	v_committed_tag 					donations.tag.tag%type := 'Committed';
	v_cancelled_tag 					donations.tag.tag%type := 'Cancelled';
	v_paid_tag 							donations.tag.tag%type := 'Paid';
	v_reconciled_tag 					donations.tag.tag%type := 'Reconciled';
	v_being_processed_tag 				donations.tag.tag%type := 'Being Processed';
	v_yes_tag 							donations.tag.tag%type := 'Yes';
	v_committed_tag_id 					donations.tag.tag_id%type;
	v_cancelled_tag_id 					donations.tag.tag_id%type;
	v_paid_tag_id 						donations.tag.tag_id%type;
	v_reconciled_tag_id 				donations.tag.tag_id%type;
	v_being_processed_tag_id 			donations.tag.tag_id%type;
	v_yes_tag_id 						donations.tag.tag_id%type;
	-- Region groups
	v_default_region_group_sid			security.security_pkg.T_SID_ID;
	-- Other
	v_amount_field_lookup_key 			donations.custom_field.lookup_key%type := 'cash_value';
begin
-- Log on
	security.user_pkg.logonadmin('&&host');
	v_act_id := security.security_pkg.getACT;
	v_app_sid := security.security_pkg.getApp;

-- Check Donations is enabled
	BEGIN
		v_donations_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Donations');	
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Please run EnableDonations.sql first');
	END;

-- Add menus
	v_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'menu');
	v_donations_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_menu_sid, 'donations_schemes');

	begin
		security.menu_pkg.CreateMenu(v_act_id, v_donations_menu_sid, 'csr_donations_fc_setup', 'Funding Commitments', '/csr/site/donations2/fundingCommitment/setup.acds', 5, null, v_menu_fc_sid);
	    exception
        when security.security_pkg.DUPLICATE_OBJECT_NAME then
            v_menu_fc_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_donations_menu_sid, 'csr_donations_fc_setup');
    end;

-- Add container
	begin
		security.securableobject_pkg.CreateSO(v_act_id, v_donations_sid, security.security_pkg.SO_CONTAINER, 'FundingCommitment', v_funding_commitments_sid);
		exception
			when security.security_pkg.DUPLICATE_OBJECT_NAME then
				v_funding_commitments_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_donations_sid, 'FundingCommitment');
		end;
	
	-- Permissions on menus
		v_groups_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
		v_community_users_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Community Users');
		v_community_admins_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Community Admins');
		
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_fc_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_community_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
		
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_fc_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_community_admins_sid, security.security_pkg.PERMISSION_STANDARD_READ);
		
	-- Permissions on SO
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_funding_commitments_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_community_admins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_funding_commitments_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_community_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
		
	-- Add a Payment status tag group
		BEGIN
			donations.tag_pkg.CreateTagGroup(v_act_id, v_app_sid, v_payment_status_tag_grp_name, 0, 0, 'X', 'C', v_payment_status_tag_grp_sid);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				v_payment_status_tag_grp_sid := donations.tag_pkg.GetTagGroupSidFromGroupName(v_act_id, v_payment_status_tag_grp_name, v_app_sid);
	END;
	
-- Add some tags to the Payment status tag group
	BEGIN
		v_committed_tag_id := donations.tag_pkg.GetTagIdFromName(v_act_id, v_committed_tag, v_payment_status_tag_grp_sid);
	EXCEPTION
		WHEN OTHERS THEN
			donations.tag_pkg.AddNewTagToGroup(v_act_id, v_payment_status_tag_grp_sid, v_committed_tag, null, null, 1, v_committed_tag_id);	
	END;
	BEGIN
		v_cancelled_tag_id := donations.tag_pkg.GetTagIdFromName(v_act_id, v_cancelled_tag, v_payment_status_tag_grp_sid);
	EXCEPTION
		WHEN OTHERS THEN
			donations.tag_pkg.AddNewTagToGroup(v_act_id, v_payment_status_tag_grp_sid, v_cancelled_tag, null, null, 1, v_cancelled_tag_id);	
	END;
	BEGIN
		v_paid_tag_id := donations.tag_pkg.GetTagIdFromName(v_act_id, v_paid_tag, v_payment_status_tag_grp_sid);
	EXCEPTION
		WHEN OTHERS THEN
			donations.tag_pkg.AddNewTagToGroup(v_act_id, v_payment_status_tag_grp_sid, v_paid_tag, null, null, 1, v_paid_tag_id);	
	END;
	BEGIN
		v_reconciled_tag_id := donations.tag_pkg.GetTagIdFromName(v_act_id, v_reconciled_tag, v_payment_status_tag_grp_sid);
	EXCEPTION
		WHEN OTHERS THEN
			donations.tag_pkg.AddNewTagToGroup(v_act_id, v_payment_status_tag_grp_sid, v_reconciled_tag, null, null, 1, v_reconciled_tag_id);	
	END;
	BEGIN
		v_being_processed_tag_id := donations.tag_pkg.GetTagIdFromName(v_act_id, v_being_processed_tag, v_payment_status_tag_grp_sid);
	EXCEPTION
		WHEN OTHERS THEN
			donations.tag_pkg.AddNewTagToGroup(v_act_id, v_payment_status_tag_grp_sid, v_being_processed_tag, null, null, 1, v_being_processed_tag_id);	
	END;

-- Add an Is Funding Commitment tag group
	BEGIN
		donations.tag_pkg.CreateTagGroup(v_act_id, v_app_sid, v_is_fc_tag_group_name, 1, 0, 'X', 'C', v_is_fc_tag_group_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_is_fc_tag_group_sid := donations.tag_pkg.GetTagGroupSidFromGroupName(v_act_id, v_is_fc_tag_group_name, v_app_sid);
	END;
	
-- Add tag to the Is Funding Commitment tag group
	BEGIN
		v_yes_tag_id := donations.tag_pkg.GetTagIdFromName(v_act_id, v_yes_tag, v_is_fc_tag_group_sid);
	EXCEPTION
		WHEN OTHERS THEN
			donations.tag_pkg.AddNewTagToGroup(v_act_id, v_is_fc_tag_group_sid, v_yes_tag, null, null, 1, v_yes_tag_id);	
	END;
	
-- Insert/update customer options
	BEGIN
		INSERT INTO donations.customer_options (DEFAULT_COUNTRY, DEFAULT_CURRENCY, DEFAULT_FIELD, DOCUMENT_DESCRIPTION_ENABLED, IS_RECIPIENT_TAX_ID_MANDATORY, IS_RECIPIENT_ADDRESS_MANDATORY, SHOW_ALL_YEARS_BY_DEFAULT, FC_TAG_ID, FC_AMOUNT_FIELD_LOOKUP_KEY, FC_STATUS_TAG_GROUP_SID, FC_PAID_TAG_ID, FC_RECONCILED_TAG_ID, FC_BEING_PROCESSED_TAG_ID)
		VALUES (null, null, null, null, 0, 0, 0, v_yes_tag_id, v_amount_field_lookup_key, v_payment_status_tag_grp_sid, v_paid_tag_id, v_reconciled_tag_id, v_being_processed_tag_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE donations.customer_options
			SET
				FC_TAG_ID					= v_yes_tag_id,
				FC_AMOUNT_FIELD_LOOKUP_KEY 	= v_amount_field_lookup_key,
				FC_STATUS_TAG_GROUP_SID 	= v_payment_status_tag_grp_sid,
				FC_PAID_TAG_ID 				= v_paid_tag_id,
				FC_RECONCILED_TAG_ID 		= v_reconciled_tag_id,
				FC_BEING_PROCESSED_TAG_ID 	= v_being_processed_tag_id
			WHERE app_sid = v_app_sid;
	END;

	--security.class_pkg.createClass(v_act_id,
	--4,
	--'DonationsFundingCommitment',
	--'donations.funding_commitment_pkg',
	--null,
	--out_class_id);
	
	COMMIT;
END;
/

PROMPT *************************************************************************
PROMPT To use funding commitments you will need to create
PROMPT REGION GROUPS, RECIPIENTS, SCHEMES, BUDGETS and DONATION STATUSES.
PROMPT This can be done through the UI. Alternatively, create dummy objects with
PROMPT the code at the end of this script.
PROMPT *************************************************************************


/*	
DECLARE
	v_region_group_cnt					NUMBER(10);
	v_region_sid						security.security_pkg.T_SID_ID;
	v_scheme_cnt						NUMBER(10);
	v_dummy_scheme_sid					security.security_pkg.T_SID_ID;
	v_recipient_cnt						NUMBER(10);
	v_dummy_recipient_sid				security.security_pkg.T_SID_ID;
	v_donation_status_cnt				NUMBER(10);
	v_dummy_donation_status_sid			security.security_pkg.T_SID_ID;
	v_default_region_group_sid			security.security_pkg.T_SID_ID;
BEGIN
	user_pkg.logonadmin('&host');
-- Create a region group if there are none.
	SELECT count(*)
	INTO v_region_group_cnt
	FROM donations.region_group;
	
	IF v_region_group_cnt = 0 THEN
		donations.region_group_pkg.CreateRegionGroup(security.security_pkg.getact, security.security_pkg.getapp, 'Dummy region group', v_default_region_group_sid);
	
	-- Add root region to the group for now
		SELECT region_tree_root_sid
		INTO v_region_sid
		FROM csr.region_tree
		WHERE is_primary = 1;
		
		IF v_region_sid IS NOT NULL THEN
			donations.region_group_pkg.SetRegionGroupMembers(security.security_pkg.getact, v_default_region_group_sid, v_region_sid);
		END IF;
				
	END IF;

-- Create a default scheme
	SELECT count(*)
	INTO v_scheme_cnt
	FROM donations.scheme;
	
	IF v_scheme_cnt = 0 THEN
		donations.scheme_pkg.CreateScheme(security.security_pkg.getact, security.security_pkg.getapp, 'Dummy scheme', null, 1, '<fields />', v_dummy_scheme_sid);
		
		update donations.scheme set track_charity_budget = 1 where scheme_sid = v_dummy_scheme_sid;

		-- Create a budget
		donations.budget_pkg.SetBudgets(security.security_pkg.getact, v_dummy_scheme_sid, v_default_region_group_sid, DATE '2013-01-01', DATE '2014-01-01', 'Budget year 2013', null, null, 'GBP', 1, null);
		
		-- Create a dummy donation status and apply to scheme
		SELECT count(*)
		INTO v_donation_status_cnt
		FROM donations.donation_status;

		IF v_donation_status_cnt = 0 THEN
			donations.status_pkg.CreateStatus('Dummy status', 1, 0, 1, 0, 0, v_dummy_donation_status_sid);

			INSERT INTO donations.scheme_donation_status (scheme_sid, app_sid, donation_status_sid) 
			VALUES (v_dummy_scheme_sid, security.security_pkg.getapp, v_dummy_donation_status_sid);
		END IF;
		
	END IF;

-- Create a recipient
	SELECT count(*)
	INTO v_recipient_cnt
	FROM donations.recipient;

	IF v_recipient_cnt = 0 THEN
		donations.recipient_pkg.CreateRecipient(security.security_pkg.getact, security.security_pkg.getapp, null, 'Dummy recipient',
		null, null, null, null, null, null, null, null,
		'gb', null, null, null, null, null, null, null, null, null,
		v_dummy_recipient_sid);
	END IF;
	
	COMMIT;
END;
/
*/	
