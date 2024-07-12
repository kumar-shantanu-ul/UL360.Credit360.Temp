CREATE OR REPLACE PACKAGE BODY DONATIONS.funding_commitment_pkg
IS

-- Securable object callbacks
PROCEDURE CreateObject(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_sid_id			IN security_pkg.T_SID_ID,
	in_class_id			IN security_pkg.T_CLASS_ID,
	in_name				IN security_pkg.T_SO_NAME,
	in_parent_sid_id	IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

PROCEDURE RenameObject(
	in_act_id		IN security_pkg.T_ACT_ID,
	in_sid_id		IN security_pkg.T_SID_ID,
	in_new_name		IN security_pkg.T_SO_NAME
) AS
BEGIN
	NULL;
END;

PROCEDURE DeleteObject(
	in_act_id		IN security_pkg.T_ACT_ID,
	in_sid_id		IN security_pkg.T_SID_ID
) AS
BEGIN
	DELETE FROM fc_upload
	 WHERE funding_commitment_sid = in_sid_id;
		   
	DELETE FROM fc_budget
	 WHERE funding_commitment_sid = in_sid_id;

	DELETE FROM fc_tag
	 WHERE funding_commitment_sid = in_sid_id;
	 
	-- delete fc_donation mapping (constraints prevents from deleting such donation, which is deliberate, 
	-- as we don't want users to delete them manually
	FOR r IN (
		SELECT donation_id FROM FC_DONATION WHERE funding_commitment_sid = in_sid_id
	)
	LOOP
		DELETE FROM fc_donation
		 WHERE funding_commitment_sid = in_sid_id
		   AND donation_id = r.donation_id;

		donation_pkg.DeleteDonation(in_act_id, r.donation_id);		
	END LOOP;
	
	DELETE FROM funding_commitment 
	 WHERE funding_commitment_sid = in_sid_id;
END;

PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
) AS	
BEGIN	 
	NULL;
END;

-- 
-- PROCEDURE: CreateFundingCommitment
--
PROCEDURE CreateFundingCommitment(
	in_name						IN funding_commitment.name%TYPE,
	in_description				IN funding_commitment.description%TYPE,
	in_scheme_sid				IN funding_commitment.scheme_sid%TYPE,
	in_recipient_sid			IN funding_commitment.recipient_sid%TYPE,
	in_region_group_sid			IN funding_commitment.region_group_sid%TYPE,
	in_region_sid				IN funding_commitment.region_sid%TYPE,
	in_donation_status_sid		IN funding_commitment.donation_status_sid%TYPE,
	in_reminder_dtm				IN funding_commitment.reminder_dtm%TYPE,
	in_payment_dtm				IN funding_commitment.payment_dtm%TYPE,
	in_review_on_expiry			IN funding_commitment.review_on_expiry%TYPE,
	in_tag_ids					IN security_pkg.T_SID_IDS,
	out_funding_commitment_sid	OUT security_PKG.T_SID_ID
)
AS
	v_parent_sid	security_pkg.T_SID_ID;
BEGIN
	-- get securable object Donations/Recipients
	v_parent_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Donations/FundingCommitment');
	
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), v_parent_sid, security_pkg.PERMISSION_ADD_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to add contents to FundingCommitments container');
	END IF;
	
	-- use a null name (possibly they want dupe names?)
	SecurableObject_Pkg.CreateSO(SYS_CONTEXT('SECURITY','ACT'), v_parent_sid, class_pkg.getClassID('DonationsFundingCommitment'), null, out_funding_commitment_sid);

	INSERT INTO funding_commitment
		(funding_commitment_sid, app_sid, name, description, scheme_sid, recipient_sid, region_group_sid, region_sid, donation_status_sid, csr_user_sid, reminder_dtm, payment_dtm, review_on_expiry)
	VALUES 
		(out_funding_commitment_sid, SYS_CONTEXT('SECURITY','APP'), in_name, in_description, in_scheme_sid, in_recipient_sid, in_region_group_sid, in_region_sid, in_donation_status_sid, SYS_CONTEXT('security','sid'), trunc(in_reminder_dtm, 'dd'), trunc(in_payment_dtm, 'dd'), in_review_on_expiry);
		
	internal_setTags(out_funding_commitment_sid, in_tag_ids);
END;

-- 
-- PROCEDURE: AmendFundingCommitment
--
PROCEDURE AmendFundingCommitment(
	in_funding_commitment_sid	IN funding_commitment.funding_commitment_sid%TYPE,
	in_name						IN funding_commitment.name%TYPE,
	in_description				IN funding_commitment.description%TYPE,
	in_scheme_sid				IN funding_commitment.scheme_sid%TYPE,
	in_recipient_sid			IN funding_commitment.recipient_sid%TYPE,
	in_region_group_sid			IN funding_commitment.region_group_sid%TYPE,
	in_region_sid				IN funding_commitment.region_sid%TYPE,
	in_donation_status_sid		IN funding_commitment.donation_status_sid%TYPE,
	in_reminder_dtm				IN funding_commitment.reminder_dtm%TYPE,
	in_payment_dtm				IN funding_commitment.payment_dtm%TYPE,
	in_review_on_expiry			IN funding_commitment.review_on_expiry%TYPE,
	in_tag_ids					IN security_pkg.T_SID_IDS
)
AS
	v_parent_sid				security_pkg.T_SID_ID;
	v_reminder_sent_dtm			funding_commitment.reminder_sent_dtm%TYPE;
	v_is_super_admin			NUMBER(1) DEFAULT 0;
	v_region_owner_cnt			NUMBER(10);
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_funding_commitment_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	-- check if it's superadmin to be able to modify FC with region that's not his list
	IF user_pkg.IsUserInGroup(SYS_CONTEXT('SECURITY','ACT'), securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), 0, 'csr/SuperAdmins')) = 1 THEN
		v_is_super_admin := 1;
	END IF;

	-- ok, it's not superadmin so check if current FC's region belongs to him, raise error if not
	IF v_is_super_admin = 0 THEN
		SELECT COUNT(region_sid)
		  INTO v_region_owner_cnt
		  FROM csr.REGION_OWNER
		 WHERE user_sid = SYS_CONTEXT('SECURITY','SID')
		   AND region_sid IN (
				SELECT region_sid FROM funding_commitment
				 WHERE funding_commitment_sid = in_funding_commitment_sid
			   );
		IF v_region_owner_cnt = 0 THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'User can''t amend FC that doesn''t belong to region he is associated with');
		END IF;
	END IF;

	-- update commitment
	UPDATE funding_commitment
	   SET	name = in_name,
			description = in_description,
			scheme_sid = in_scheme_sid,
			recipient_sid = in_recipient_sid,
			region_group_sid = in_region_group_sid,
			region_sid = in_region_sid, 
			donation_status_sid = in_donation_status_sid, 
			csr_user_sid = SYS_CONTEXT('SECURITY','SID'), 
			reminder_dtm = trunc(in_reminder_dtm, 'dd'),	-- truncate hours
			payment_dtm = trunc(in_payment_dtm, 'dd'), -- truncate hours
			review_on_expiry = in_review_on_expiry
	 WHERE funding_commitment_sid = in_funding_commitment_sid;
   
	-- update any FC donations to show the new recipient as well (FB34151)
	UPDATE donation
	   SET recipient_sid = in_recipient_sid
	 WHERE donation_id IN 
		(
		SELECT donation_id 
		  FROM fc_donation 
		 WHERE funding_commitment_sid = in_funding_commitment_sid
		);
   
	-- update selected tags
	internal_setTags(in_funding_commitment_sid, in_tag_ids);
	
	-- if we changed reminder dtm, then we want to make sure the reminder will be sent again
	-- get the reminder sent dtm
	SELECT reminder_sent_dtm
	  INTO v_reminder_sent_dtm
	  FROM funding_commitment
	 WHERE funding_commitment_sid = in_funding_commitment_sid;
	
	-- clear reminder_sent_dtm if the new reminder_dtm is in the future.
	IF v_reminder_sent_dtm IS NOT NULL AND in_reminder_dtm IS NOT NULL AND in_reminder_dtm > v_reminder_sent_dtm THEN
		UPDATE funding_commitment
		   SET reminder_sent_dtm = null
		 WHERE funding_commitment_sid = in_funding_commitment_sid;
	END IF;
	
	
END;


FUNCTION GetFundingCommitmentRowNum(
	in_funding_commitment_sid		IN	security_pkg.T_SID_ID,
	in_order_by						IN	VARCHAR2,
	in_order_dir					IN	VARCHAR2,
	in_filter_ids					IN  security_Pkg.T_SID_IDS
) RETURN NUMBER
AS
	v_parent_sid				security_pkg.T_SID_ID;
	v_act_id 					security_pkg.T_ACT_ID;
	v_sql						VARCHAR2(8192);
	v_can_see_all				NUMBER(1);
	v_has_filter				NUMBER(1);
	v_order_by					VARCHAR2(32000);
	t_filter_ids				security.T_SID_TABLE;
	v_some_fcs					security.T_SID_TABLE;
	v_row_num					NUMBER(10);
BEGIN
	v_act_id := SYS_CONTEXT('SECURITY','ACT');
	
	v_parent_sid := securableobject_pkg.GetSIDFromPath(v_act_id, SYS_CONTEXT('SECURITY','APP'), 'Donations/FundingCommitment');
	

	IF NOT security.security_pkg.IsAccessAllowedSID(v_act_id, v_parent_sid, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Read permission denied on the Funding Commitments container');
	END IF;
	
	internal_PrepareFcFilters(v_act_id, v_parent_sid, in_order_by, in_order_dir, in_filter_ids, v_has_filter, v_can_see_all, v_order_by, t_filter_ids);
	
	-- get interesting funding commitment sids
    SELECT fc.funding_commitment_sid
      BULK COLLECT INTO v_some_fcs
	  FROM v$funding_commitment fc
	 WHERE fc.app_sid = SYS_CONTEXT('SECURITY','APP') 
	   AND (v_has_filter = 0 OR fc.status IN (select column_value from TABLE(t_filter_ids)))
	   AND (v_can_see_all = 1 OR fc.region_sid IN (SELECT region_sid FROM  csr.region_owner WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID')));

	   v_sql :=
'		SELECT y.rn FROM ' ||
'			(SELECT ROWNUM rn, x.funding_commitment_sid ' ||
'			   FROM ( ' ||
'				SELECT funding_commitment_sid, fc.region_group_sid, rg.description region_group_description, fc.name, fc.description, fc.scheme_sid, s.name scheme_name, fc.recipient_sid, r.org_name recipient_name, ' ||
'						fc.region_sid, cr.description region_description, fc.csr_user_sid, cu.full_name user_name, fc.donation_status_sid, ' ||
'						ds.description donation_status_description, payment_dtm, reminder_dtm, notes, last_review_dtm, review_on_expiry, fc.status fc_status, funding_commitment_pkg.internal_ConcatTags(funding_commitment_sid) fc_tags, ' ||
'						COUNT(*) OVER () total_rows ' ||
'				  FROM TABLE(SecurableObject_pkg.GetSIDsWithPermAsTable(SYS_CONTEXT(''SECURITY'',''ACT'') , :v_some_fcs, :permission_read)) so, v$funding_commitment fc, scheme s,recipient r, region_group rg, csr.v$region cr, csr.csr_user cu, donation_status ds ' ||
'				 WHERE fc.funding_commitment_sid = so.sid_id ' ||
'				   AND fc.scheme_sid = s.scheme_sid ' ||
'				   AND fc.recipient_sid = r.recipient_sid ' ||
'				   AND fc.region_group_sid = rg.region_group_sid ' ||
'				   AND fc.region_sid = cr.region_sid ' ||
'				   AND fc.csr_user_sid = cu.csr_user_sid ' ||
'				   AND fc.donation_status_sid = ds.donation_status_sid ' ||
'				   ORDER BY '||v_order_by||' '||in_order_dir || 
'				) x' ||
'			) y' ||
'		 WHERE y.funding_commitment_sid = :in_funding_commitment_sid';
	
	BEGIN
		EXECUTE IMMEDIATE v_sql
		INTO v_row_num
		USING v_some_fcs, security.security_pkg.PERMISSION_READ, in_funding_commitment_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_row_num := 1; -- rownum may possibly not be found depending on the filter, so return 1 
	END;
	
	RETURN v_row_num;
END;


PROCEDURE GetFundingCommitments(
	in_start_row					IN	INTEGER,
	in_row_count					IN	INTEGER,
	in_order_by						IN	VARCHAR2,
	in_order_dir					IN	VARCHAR2,
	out_cur							OUT security_Pkg.T_OUTPUT_CUR
)
AS
	v_empty_filters					security_pkg.T_SID_IDS;
BEGIN
	SELECT NULL 
	BULK COLLECT INTO v_empty_filters
	FROM DUAL;
	GetFundingCommitments(in_start_row, in_row_count, in_order_by, in_order_dir, v_empty_filters, out_cur);
END;

PROCEDURE GetFundingCommitments(
	in_start_row					IN	INTEGER,
	in_row_count					IN	INTEGER,
	in_order_by						IN	VARCHAR2,
	in_order_dir					IN	VARCHAR2,
	in_filter_ids					IN  security_Pkg.T_SID_IDS,	-- not sids but will do
	out_cur							OUT security_Pkg.T_OUTPUT_CUR
)
AS
	v_parent_sid				security_pkg.T_SID_ID;
	v_act_id 					security_pkg.T_ACT_ID;
	v_sql						VARCHAR2(8192);
	v_can_see_all				NUMBER(1);
	v_has_filter				NUMBER(1) DEFAULT 1;
	v_order_by					VARCHAR2(32000);
	t_filter_ids				security.T_SID_TABLE;
	v_some_fcs					security.T_SID_TABLE;
BEGIN
	v_act_id := SYS_CONTEXT('SECURITY','ACT');
	
	v_parent_sid := securableobject_pkg.GetSIDFromPath(v_act_id, SYS_CONTEXT('SECURITY','APP'), 'Donations/FundingCommitment');
	
	IF NOT security.security_pkg.IsAccessAllowedSID(v_act_id, v_parent_sid, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Read permission denied on the Funding Commitments container');
	END IF;
	
	internal_PrepareFcFilters(v_act_id, v_parent_sid, in_order_by, in_order_dir, in_filter_ids, v_has_filter, v_can_see_all, v_order_by, t_filter_ids);

	-- get interesting funding commitment sids
    SELECT fc.funding_commitment_sid
      BULK COLLECT INTO v_some_fcs
	  FROM v$funding_commitment fc
	 WHERE fc.app_sid = SYS_CONTEXT('SECURITY','APP') 
	   AND (v_has_filter = 0 OR fc.status IN (select column_value from TABLE(t_filter_ids)))
	   AND (v_can_see_all = 1 OR fc.region_sid IN (SELECT region_sid FROM  csr.region_owner WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID')));

	v_sql := 
'		SELECT y.* FROM ' ||
'			(SELECT ROWNUM rn, x.* ' ||
'			   FROM ( ' ||
'				SELECT funding_commitment_sid, fc.region_group_sid, rg.description region_group_description, fc.name, fc.description, fc.scheme_sid, s.name scheme_name, fc.recipient_sid, r.org_name recipient_name, ' ||
'						fc.region_sid, cr.description region_description, fc.csr_user_sid, cu.full_name user_name, fc.donation_status_sid, ' ||
'						ds.description donation_status_description, payment_dtm, reminder_dtm, notes, last_review_dtm, review_on_expiry, fc.status fc_status, funding_commitment_pkg.internal_ConcatTags(funding_commitment_sid) fc_tags, ' ||
'						COUNT(*) OVER () total_rows ' ||
'				  FROM TABLE(SecurableObject_pkg.GetSIDsWithPermAsTable(SYS_CONTEXT(''SECURITY'',''ACT'') , :v_some_fcs, :permission_read)) so, v$funding_commitment fc, scheme s,recipient r, region_group rg, csr.v$region cr, csr.csr_user cu, donation_status ds ' ||
'				 WHERE fc.funding_commitment_sid = so.sid_id ' ||
'				   AND fc.scheme_sid = s.scheme_sid ' ||
'				   AND fc.recipient_sid = r.recipient_sid ' ||
'				   AND fc.region_group_sid = rg.region_group_sid ' ||
'				   AND fc.region_sid = cr.region_sid ' ||
'				   AND fc.csr_user_sid = cu.csr_user_sid ' ||
'				   AND fc.donation_status_sid = ds.donation_status_sid' ||
'				   ORDER BY '||v_order_by||' '||in_order_dir || 
'				) x' ||
'			  WHERE rownum <= :in_start_row + :in_row_count) y' ||
'		 WHERE y.rn > :in_start_row';
	 
	OPEN out_cur FOR v_sql  
		USING v_some_fcs, security.security_pkg.PERMISSION_READ, in_start_row , in_row_count, in_start_row;
END;

PROCEDURE GetAllFundingCommitments(
	out_cur							OUT security_Pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- security checked in called proc
	GetFundingCommitments(0, 2147483645, 'name', 'asc', out_cur);
END;

PROCEDURE GetFundingCommitment(
	in_funding_commitment_sid		IN	security_pkg.T_SID_ID,
	out_cur							OUT security_Pkg.T_OUTPUT_CUR
)
AS
BEGIN 
	IF NOT security.security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_funding_commitment_sid, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Read permission denied on the Funding Commitment with sid ' || in_funding_commitment_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT funding_commitment_sid, fc.name, fc.description, scheme_sid, fc.region_group_sid, rg.description region_group_description, fc.recipient_sid, r.org_name recipient_name, 
			   fc.region_sid, cr.description region_description, fc.csr_user_sid, cu.full_name user_name, fc.donation_status_sid, 
			   ds.description donation_status_description, payment_dtm, reminder_dtm, notes, review_on_expiry, co.fc_tag_id, co.fc_amount_field_lookup_key, internal_ConcatTagIds(in_funding_commitment_sid) fc_tag_ids, (SELECT count(donation_id) FROM fc_donation WHERE funding_commitment_sid = fc.funding_commitment_sid) donations_count,
			   fc.status status
		  FROM v$funding_commitment fc, recipient r, region_group rg, csr.v$region cr, csr.csr_user cu, donation_status ds, customer_options co
		 WHERE fc.recipient_sid = r.recipient_sid 
		   AND co.app_sid = fc.app_sid
		   AND fc.region_group_sid = rg.region_group_sid
		   AND fc.region_sid = cr.region_sid 
		   AND fc.csr_user_sid = cu.csr_user_sid 
		   AND fc.donation_status_sid = ds.donation_status_sid
		   AND fc.funding_commitment_sid = in_funding_commitment_sid;
END;

PROCEDURE GetFcSchemes(
	out_cur							OUT security_Pkg.T_OUTPUT_CUR
)
AS
	v_parent_sid	security_pkg.T_SID_ID;
	v_act_id		security_pkg.T_ACT_ID;
BEGIN
	-- get securable object Donations/Recipients
	v_act_id := SYS_CONTEXT('SECURITY','ACT');
	v_parent_sid := securableobject_pkg.GetSIDFromPath(v_act_id, SYS_CONTEXT('SECURITY','APP'), 'Donations/FundingCommitment');
	
	IF NOT security_pkg.IsAccessAllowedSID(v_act_id, v_parent_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to read FundingCommitments container');
	END IF;

	-- Let the Funding Commitment be applicable only for schemes where you track Charity Budget
	-- only BL uses it now, and they requested it, so if we want something more generic, we need to refactor it
	OPEN out_cur FOR
		SELECT scheme_sid, name, description, active, extra_fields_xml,
     		security_pkg.SQL_IsAccessAllowedSID(v_act_id, scheme_sid, security_pkg.PERMISSION_WRITE) can_write,
	    	track_payments, track_company_giving, track_charity_budget, helper_pkg,
			note_hack -- xml block with info about notes to show on edit screen
          FROM SCHEME
         WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
           AND security_pkg.SQL_IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), scheme_sid, security_pkg.PERMISSION_READ) = 1
           AND track_charity_budget = 1
         ORDER BY name;
END;

PROCEDURE GetFcFromDonationId(
	in_donation_id					IN  donation.donation_id%TYPE,
	out_cur							OUT security_Pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT fc.funding_commitment_sid, fc.name, fc.description
		  FROM funding_commitment fc, fc_donation fd
		 WHERE fd.donation_id = in_donation_id
		   AND fc.funding_commitment_sid = fd.funding_commitment_sid
		   AND fc.app_sid = SYS_CONTEXT('SECURITY','APP');
END;

PROCEDURE GetBudgets(
	in_funding_commitment_sid		IN	security_pkg.T_SID_ID,
	out_budgets_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_sel_budgets_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_scheme_sid				security_pkg.T_SID_ID;
	v_region_group_sid 			security_pkg.T_SID_ID;
	v_actual_amount_field_num	security_pkg.T_SID_ID;
	v_fc_status_tag_group_sid	security_pkg.T_SID_ID;
BEGIN 
	IF NOT security.security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_funding_commitment_sid, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Read permission denied on the Funding Commitment with sid ' || in_funding_commitment_sid);
	END IF;
	
	SELECT scheme_sid, region_group_sid
	  INTO v_scheme_sid, v_region_group_sid
	  FROM funding_commitment 
	 WHERE funding_commitment_sid = in_funding_commitment_sid;
	
	donations.budget_pkg.GetBudgetList(SYS_CONTEXT('SECURITY','ACT'), v_scheme_sid, v_region_group_sid, out_budgets_cur);
	
	SELECT field_num, fc_status_tag_group_sid
	  INTO v_actual_amount_field_num, v_fc_status_tag_group_sid
	  FROM custom_field cf, customer_options co
     WHERE co.fc_amount_field_lookup_key = cf.lookup_key
       AND co.app_sid = SYS_CONTEXT('SECURITY','APP');
			
			
	OPEN out_sel_budgets_cur FOR
'		SELECT fc.budget_id, fc.amount, b.start_dtm, b.end_dtm, d.donation_id, d.custom_'||  v_actual_amount_field_num ||' actual_amount, dt.tag payment_status_tag, dt.tag_id payment_status_tag_id' ||
'		  FROM fc_budget fc, budget b, donation d, fc_donation fd, (' ||
'				SELECT dt.donation_id, t.tag, t.tag_id' ||
'				  FROM donation_tag dt, tag t' ||
'				 WHERE t.tag_id = dt.tag_id' ||
'				   AND dt.tag_id IN (SELECT tag_id FROM tag_group_member WHERE tag_group_sid = :1)' ||
'				) dt' ||
'		 WHERE fc.budget_id = b.budget_id' ||
'		   AND fd.donation_id = d.donation_id' ||
'		   AND d.budget_id = fc.budget_id' ||
'		   AND fd.funding_commitment_sid = fc.funding_commitment_sid' ||
'		   AND fc.funding_commitment_sid = :2' ||
'		   AND dt.donation_id(+) = d.donation_id'
	USING v_fc_status_tag_group_sid, in_funding_commitment_sid;
END;

PROCEDURE SetBudgets(
	in_funding_commitment_sid		IN security_pkg.T_SID_ID,
	in_budget_ids					IN security_pkg.T_SID_IDS,
	in_budget_amounts				IN donation_pkg.T_DECIMAL_ARRAY
)
AS
	--t_budget_ids	security.T_SID_TABLE;
BEGIN
	IF NOT security.security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_funding_commitment_sid, security.security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Write permission denied on the Funding Commitment with sid ' || in_funding_commitment_sid);
	END IF;
	
	--t_budget_ids := security_pkg.SidArrayToTable(in_budget_ids);
		
	-- delete old
	DELETE FROM fc_budget
	 WHERE funding_commitment_sid = in_funding_commitment_sid;
	  
	-- hack for ODP.NET which doesn't support empty arrays
	IF in_budget_ids.COUNT = 1 AND in_budget_ids(1) IS NULL THEN
		RETURN;
	END IF;

	-- insert new
	FOR i IN in_budget_ids.FIRST .. in_budget_ids.LAST
	LOOP
		INSERT INTO fc_budget (app_sid, funding_commitment_sid, budget_id, amount)
			VALUES (SYS_CONTEXT('SECURITY','APP'), in_funding_commitment_sid, in_budget_ids(i), in_budget_amounts(i));
	END LOOP;
END;

PROCEDURE SetFcDonation(
	in_funding_commitment_sid		IN security_pkg.T_SID_ID,
	in_donation_id					IN donation.donation_id%TYPE,
	in_aligned_dtm					IN donation.entered_dtm%TYPE
)
AS
	v_app_sid			security_pkg.T_SID_ID;
	v_fc_tag_id 		security_pkg.T_SID_ID;
BEGIN
	v_app_sid := SYS_CONTEXT('SECURITY','APP');
	
	IF NOT security.security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_funding_commitment_sid, security.security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Write permission denied on the Funding Commitment with sid ' || in_funding_commitment_sid);
	END IF;

	-- make sure the donation has FC_TAG_ID associated with it (it should be read-only even for admins, so you won't be able to set it using tag_pkg.SetDonationTag etc)
	BEGIN
		SELECT fc_tag_id INTO v_fc_tag_id FROM customer_options WHERE app_sid = v_app_sid;
	
		INSERT
		  INTO donation_tag
				(app_sid, donation_id, tag_id, pct_of_value)
		VALUES 
				(v_app_sid, in_donation_id, v_fc_tag_id, 100);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	
	BEGIN
		INSERT 
		  INTO fc_donation 
				(app_sid, funding_commitment_sid, donation_id)
		 VALUES
				(v_app_sid, in_funding_commitment_sid, in_donation_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	
	-- poke the entered_dtm value as per clients requirement
	UPDATE donation SET entered_dtm = in_aligned_dtm WHERE donation_id = in_donation_id;
	
END;


PROCEDURE DeleteFcDonation(
	in_donation_id					IN	donation.donation_id%TYPE,
	in_funding_commitment_sid		IN	funding_commitment.funding_commitment_sid%TYPE
)
AS
	v_act_id			security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY','ACT');
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(v_act_id, in_funding_commitment_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	-- delete from FC_DONATION table to have no constraint lock
	DELETE FROM fc_donation
	 WHERE funding_commitment_sid = in_funding_commitment_sid
	   AND donation_id = in_donation_id;
	   
	-- delete the donation finally
	donation_pkg.DeleteDonation(v_act_id, in_donation_id);

END;

FUNCTION GetFcDonationId(
	in_funding_commitment_sid		IN security_pkg.T_SID_ID,
	in_budget_id					IN budget.budget_id%TYPE
)
RETURN NUMBER
AS
	v_donation_id	NUMBER(10);
BEGIN
	IF NOT security.security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_funding_commitment_sid, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Read permission denied on the Funding Commitment with sid ' || in_funding_commitment_sid);
	END IF;
	
	BEGIN
	  SELECT fd.donation_id 
	    INTO v_donation_id
	    FROM fc_donation fd, donation d
       WHERE fd.funding_commitment_sid = in_funding_commitment_sid 
         AND d.donation_id = fd.donation_id
         AND d.budget_id = in_budget_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN -1;
	END;
	
	RETURN v_donation_id;
END;

FUNCTION GetStatus(
	in_funding_commitment_sid		IN security_pkg.T_SID_ID
)
RETURN NUMBER
AS
	v_review_on_expiry			NUMBER(1);
	v_last_budget_end_dtm		DATE;
BEGIN
	
	-- get the last budget end dtm
	SELECT MAX(b.end_dtm)
	  INTO v_last_budget_end_dtm
	  FROM budget b, fc_budget fb
	 WHERE b.budget_id = fb.budget_id
	   AND fb.funding_commitment_sid = in_funding_commitment_sid;

	IF v_last_budget_end_dtm IS NULL THEN
		RETURN FC_NO_BUDGETS;
	END IF;
	
	SELECT review_on_expiry 
	  INTO v_review_on_expiry
	  FROM funding_commitment
	 WHERE funding_commitment_sid = in_funding_commitment_sid;
	 
	-- if last budget end_dtm is in future return 'Active'
	IF v_last_budget_end_dtm > sysdate THEN
		RETURN FC_ACTIVE;
	-- if last budget_end_dtm is in the past then check the 'Review Commitment on Expiry'
	ELSIF v_last_budget_end_dtm <= sysdate THEN
		IF v_review_on_expiry = 1 THEN 
			RETURN FC_EXPIRED_PENDING_REV;
		ELSE
			RETURN FC_EXPIRED;
		END IF;
	END IF;
	
	RETURN FC_INVALID;
		
END;

PROCEDURE GetReview(
	in_funding_commitment_sid		IN	security_pkg.T_SID_ID,
	out_review_cur					OUT security_Pkg.T_OUTPUT_CUR,
	out_docs_cur					OUT security_Pkg.T_OUTPUT_CUR
)
AS
BEGIN 
	IF NOT security.security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_funding_commitment_sid, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Read permission denied on the Funding Commitment with sid ' || in_funding_commitment_sid);
	END IF;
	
	OPEN out_review_cur FOR
		SELECT notes, last_review_dtm
		  FROM funding_commitment 
		 WHERE funding_commitment_sid = in_funding_commitment_sid;
	
	OPEN out_docs_cur FOR
		SELECT fc_upload_sid sid, fu.filename file_name, fu.mime_type mime_type
		  FROM fc_upload fcu
		  JOIN csr.file_upload fu ON fcu.fc_upload_sid = fu.file_upload_sid
		 WHERE funding_commitment_sid = in_funding_commitment_sid; 
END;



PROCEDURE SetReview(
	in_funding_commitment_sid		IN security_pkg.T_SID_ID,
	in_notes						IN funding_commitment.notes%TYPE,
	in_last_review_dtm				IN funding_commitment.last_review_dtm%TYPE
)
AS
BEGIN
	IF NOT security.security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_funding_commitment_sid, security.security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Write permission denied on the Funding Commitment with sid ' || in_funding_commitment_sid);
	END IF;

	UPDATE funding_commitment
	   SET notes = in_notes,
	       last_review_dtm = in_last_review_dtm
	 WHERE funding_commitment_sid = in_funding_commitment_sid;
END;

PROCEDURE SetReviewDocs(
	in_funding_commitment_sid		IN security_pkg.T_SID_ID,
	in_fc_upload_sids				IN security_pkg.T_SID_IDS
)
AS
BEGIN
	IF NOT security.security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_funding_commitment_sid, security.security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Write permission denied on the Funding Commitment with sid ' || in_funding_commitment_sid);
	END IF;

	DELETE FROM fc_upload
	 WHERE funding_commitment_sid = in_funding_commitment_sid;
	
	-- hack for ODP.NET which doesn't support empty arrays
	IF in_fc_upload_sids.COUNT = 1 AND in_fc_upload_sids(1) IS NULL THEN
		RETURN;
	END IF;

	-- insert new
	FOR i IN in_fc_upload_sids.FIRST .. in_fc_upload_sids.LAST
	LOOP
		INSERT INTO fc_upload (app_sid, funding_commitment_sid, fc_upload_sid)
			VALUES (SYS_CONTEXT('SECURITY','APP'), in_funding_commitment_sid, in_fc_upload_sids(i));
	END LOOP;	
END;


PROCEDURE GetFcForAlert(
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN 
	csr.alert_pkg.BeginStdAlertBatchRun(csr.csr_data_pkg.ALERT_DONATION_FC_REMINDER);
	
	OPEN out_cur FOR
		SELECT fc.funding_commitment_sid, fc.name, internal_getThisYearDate(fc.reminder_dtm) this_year_reminder_dtm, payment_dtm, fc.csr_user_sid, fc.app_sid, cu.friendly_name
          FROM funding_commitment fc
          JOIN csr.temp_alert_batch_run tabr ON fc.app_sid = tabr.app_sid 
           AND fc.csr_user_sid = tabr.csr_user_sid 
          JOIN csr.csr_user cu ON fc.csr_user_sid = cu.csr_user_sid
           AND cu.app_sid = fc.app_sid
          JOIN fc_budget fb ON fc.funding_commitment_sid = fb.funding_commitment_sid
          JOIN budget b ON fb.budget_id = b.budget_id
		 WHERE tabr.std_alert_type_id = csr.csr_data_pkg.ALERT_DONATION_FC_REMINDER
		   AND (fc.reminder_sent_dtm IS NULL OR TO_CHAR(fc.reminder_sent_dtm, 'YYYY') != TO_CHAR(sysdate, 'YYYY')) -- this will return only the FC where reminder wasn't sent at all or it was sent year ago
		   AND internal_getThisYearDate(fc.reminder_dtm) <= sysdate	-- only these which reminder date is either in the past or today
		   AND internal_getThisYearDate(fc.reminder_dtm) BETWEEN b.start_dtm AND b.end_dtm	-- only if there is corresponding budget (year) associated with FC
		   AND fc.reminder_dtm IS NOT NULL
         ORDER BY fc.app_sid, fc.csr_user_sid, fc.funding_commitment_sid;
END;

PROCEDURE RecordUserBatchRun(	
	in_app_sid						security_pkg.T_SID_ID,
	in_csr_user_sid					security_pkg.T_SID_ID,
	in_funding_commitment_sid 		security_pkg.T_SID_ID
)	
AS
BEGIN
	UPDATE funding_commitment SET reminder_sent_dtm = SYSDATE WHERE funding_commitment_sid = in_funding_commitment_sid;
	csr.alert_pkg.RecordUserBatchRun(in_app_sid, in_csr_user_sid, csr.csr_data_pkg.ALERT_DONATION_FC_REMINDER);
END;

PROCEDURE internal_setTags(
	in_funding_commitment_sid		security_pkg.T_SID_ID,
	in_tag_ids						security_pkg.T_SID_IDS
)
AS
	t_tag_ids		security.T_SID_TABLE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_funding_commitment_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	-- set tags
	t_tag_ids := security_pkg.SidArrayToTable(in_tag_ids);
	
	FOR r IN (SELECT column_value FROM TABLE(t_tag_ids))
	LOOP
		BEGIN
			INSERT INTO FC_TAG 
				(app_sid, funding_commitment_sid, tag_id) 
			VALUES 
				(SYS_CONTEXT('SECURITY','APP'), in_funding_commitment_sid, r.column_value);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL; -- ignore if already there
		END;
	END LOOP;
	
	-- delete leftovers
	DELETE FROM fc_tag
     WHERE app_sid = SYS_CONTEXT('SECURITY','APP') 
	   AND funding_commitment_sid = in_funding_commitment_sid
	   AND  tag_id NOT IN (SELECT column_value from TABLE(t_tag_ids));
END;

FUNCTION HasFundingCommitments
RETURN NUMBER
AS
	v_has_filter				NUMBER(1);
BEGIN
	SELECT CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END 
	  INTO v_has_filter
	  FROM FUNDING_COMMITMENT
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP');
	RETURN v_has_filter;
END;

FUNCTION internal_GetFcTagId
RETURN NUMBER
AS
	v_tag_id					NUMBER(10);
BEGIN
	SELECT FC_TAG_ID
	  INTO v_tag_id
	  FROM CUSTOMER_OPTIONS
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP');
	RETURN v_tag_id;
END;


FUNCTION internal_ConcatTagIds(
	in_funding_commitment_sid	IN security_pkg.T_SID_ID
) RETURN VARCHAR2
AS
	v_s		VARCHAR2(4096);	
	v_sep	VARCHAR2(2);
BEGIN
	v_s := '';
	v_sep := '';
	FOR r IN (SELECT tag_id FROM FC_TAG WHERE FUNDING_COMMITMENT_SID = in_funding_commitment_sid)
	LOOP
		v_s := v_s || v_sep || r.tag_id;
		v_sep := ',';
	END LOOP;	
	RETURN v_s;
END;

FUNCTION internal_ConcatTags(
	in_funding_commitment_sid	IN security_pkg.T_SID_ID,
	in_max_length				IN 	INTEGER DEFAULT 100
) RETURN VARCHAR2
AS
	v_s	VARCHAR2(512);
	v_sep VARCHAR2(10);
BEGIN
	v_s := '';
	v_sep := '';
	FOR r IN (
		SELECT tag FROM FC_TAG ft, TAG t 
		 WHERE FUNDING_COMMITMENT_SID = in_funding_commitment_sid
		   AND ft.tag_id = t.tag_id
	)
	LOOP
		IF LENGTH(v_s) + LENGTH(r.tag) + 3 >= in_max_length THEN
			v_s := v_s || '...';
			EXIT;
		END IF;
		v_s := v_s || v_sep || r.tag;		
		v_sep := ', ';
	END LOOP;
	RETURN v_s;
END;

FUNCTION internal_GetThisYearDate(
	in_dtm		IN	DATE
) RETURN DATE
AS
BEGIN
	IF in_dtm IS NULL THEN
		RETURN null;
	ELSE
		RETURN TO_DATE( TO_CHAR(in_dtm , 'DD-MM-') || TO_CHAR(sysdate, 'YYYY') , 'DD-MM-YYYY');
	END IF;
END;

PROCEDURE internal_PrepareFcFilters(
	in_act_id 						IN security_pkg.T_ACT_ID,
	in_parent_sid					IN security_pkg.T_SID_ID,
	in_order_by						IN	VARCHAR2,
	in_order_dir					IN	VARCHAR2,
	in_filter_ids					IN  security_Pkg.T_SID_IDS,
	out_has_filter					OUT NUMBER,
	out_can_see_all					OUT NUMBER,
	out_order_by					OUT VARCHAR2,
	out_filter_ids					OUT security.T_SID_TABLE
	
)
AS
BEGIN
	-- sanity check order_by to avoid SQL injection
	IF LOWER(in_order_by) NOT IN ('name','description','payment_dtm', 'recipient_name', 'region_group_description', 'scheme_name', 'region_description', 'user_name', 'donation_status_description', 'reminder_dtm', 'notes', 'review_on_expiry', 'fc_status', 'last_review_dtm') THEN
		RAISE_APPLICATION_ERROR(-20001, 'Unknown order_by column name '||in_order_by);
	END IF;
	
	-- tweak order_by for proper alphabetical sorting
	out_order_by :=
	CASE
		WHEN SUBSTR(LOWER(in_order_by),-4,4) = '_dtm' OR LOWER(in_order_by) = 'fc_status' THEN in_order_by
		ELSE 'NLSSORT('||in_order_by||', ''NLS_SORT=BINARY_CI'')'
	END;
	
	IF LOWER(in_order_dir) NOT IN ('asc','desc') THEN
		RAISE_APPLICATION_ERROR(-20001, 'Unknown order_dir value '||in_order_dir);
	END IF;
	
	-- if we have write permissions on Funding Commitments container then we can see all of them, otherwise we filter results with respect to csr.region_owner
	IF security.security_pkg.IsAccessAllowedSID(in_act_id, in_parent_sid, security.security_pkg.PERMISSION_WRITE) THEN
		out_can_see_all := 1;
	END IF;
	
	out_filter_ids := security_pkg.SidArrayToTable(in_filter_ids);
	IF in_filter_ids.COUNT = 1 AND in_filter_ids(1) IS NULL THEN
		out_has_filter := 0;
	ELSE
		out_has_filter := 1;
	END IF;
END;

END funding_commitment_pkg;
/
