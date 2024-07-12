CREATE OR REPLACE PACKAGE BODY DONATIONS.tag_Pkg
IS

-- Securable object callbacks for tag group
PROCEDURE CreateObject(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_sid_id						IN security_pkg.T_SID_ID,
	in_class_id						IN security_pkg.T_CLASS_ID,
	in_name							IN security_pkg.T_SO_NAME,
	in_parent_sid_id				IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

PROCEDURE RenameObject(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_sid_id						IN security_pkg.T_SID_ID,
	in_new_name						IN security_pkg.T_SO_NAME
) AS
BEGIN
	UPDATE tag_group
	   SET name = in_new_name
	 WHERE tag_group_sid = in_sid_id;
END;

PROCEDURE DeleteObject(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_sid_id						IN security_pkg.T_SID_ID
) AS
BEGIN
	-- TODO: this might orphan tags, i.e. tags which no longer belong to a group
	DELETE FROM tag_group_member
	 WHERE tag_group_sid = in_sid_id;

	DELETE FROM scheme_tag_group
	 WHERE tag_group_sid = in_sid_id;

	DELETE FROM tag_group
	 WHERE tag_group_sid = in_sid_id;
END;

PROCEDURE MoveObject(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_sid_id						IN security_pkg.T_SID_ID,
	in_new_parent_sid_id			IN security_pkg.T_SID_ID
) AS
BEGIN
	NULL;
END;

PROCEDURE CreateTagGroup(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	in_name							IN	tag_group.name%TYPE,
	in_multi_select					IN	tag_group.multi_select%TYPE,
	in_mandatory					IN	tag_group.mandatory%TYPE,
	in_render_as					IN	tag_group.render_as%TYPE,
	in_render_in					IN	tag_group.render_in%TYPE,
	out_tag_group_sid				OUT	security_pkg.T_SID_ID
)
AS
	v_parent_sid	security_pkg.T_SID_ID;
BEGIN
	-- get securable object Donations/RegionGroup
	v_parent_sid := securableobject_pkg.GetSIDFromPath(in_act_id, in_app_sid, 'Donations/TagGroups');

	SecurableObject_Pkg.CreateSO(in_act_id, v_parent_sid, class_pkg.getClassID('DonationsTagGroup'), in_name, out_tag_group_sid);

	INSERT INTO tag_group
				(tag_group_sid, app_sid, name, multi_select, mandatory, render_as, render_in
				)
		 VALUES (out_tag_group_sid, in_app_sid, in_name, in_multi_select, in_mandatory, in_render_as, in_render_in
				);
END;

PROCEDURE AmendTagGroup (
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_tag_group_sid				IN	security_pkg.T_SID_ID,
	in_name							IN	tag_group.name%TYPE,
	in_multi_select					IN	tag_group.multi_select%TYPE,
	in_mandatory					IN	tag_group.mandatory%TYPE,
	in_render_as					IN	tag_group.render_as%TYPE,
	in_render_in					IN	tag_group.render_in%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_tag_group_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	UPDATE tag_group
	   SET multi_select = in_multi_select,
		   mandatory = in_mandatory,
		   render_as = in_render_as,
		   render_in = in_render_in
	 WHERE tag_group_sid = in_tag_group_sid;

	 -- we update the name here
	 securableobject_pkg.RenameSO(in_act_id, in_tag_group_sid, in_name);
END;

-- associate tag group with a scheme
PROCEDURE AssociateTagGroupWithSchemes (
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_tag_group_sid				IN	security_pkg.T_SID_ID,
	in_scheme_sids					IN	tag_group.name%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_tag_group_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	-- set pos to -1 so we know what is no longer used later
	FOR r IN (
		SELECT item, pos
		  FROM TABLE(csr.utils_pkg.SplitString(in_scheme_sids,',')))
	LOOP
		BEGIN
			INSERT INTO scheme_tag_group
				(scheme_sid, tag_group_sid, pos)
				SELECT r.item, in_tag_group_sid, NVL(MAX(pos),0) +1
				  FROM scheme_tag_group
				 WHERE tag_group_sid = in_tag_group_sid;
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL; -- leave pos along
		END;
	END LOOP;

	DELETE FROM scheme_tag_group
	 WHERE tag_group_sid = in_tag_group_sid
	   AND scheme_sid IN
		(SELECT scheme_sid
		   FROM scheme_tag_group
		  WHERE tag_group_sid = in_tag_group_sid
		  MINUS
		 SELECT TO_NUMBER(item)
		   FROM TABLE(csr.utils_pkg.SplitString(in_scheme_sids,','))
		);
END;

PROCEDURE AssociateSchemeWithTagGroups (
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_scheme_sid					IN	security_pkg.T_SID_ID,
	in_tag_group_sids				IN	VARCHAR2
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_scheme_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	DELETE FROM scheme_tag_group
	 WHERE scheme_sid = in_scheme_sid;

	INSERT INTO scheme_tag_group
		(scheme_sid, tag_group_sid, pos)
	SELECT in_scheme_sid, item, pos FROM TABLE(csr.utils_pkg.SplitString(in_tag_group_sids,','));
END;

PROCEDURE UpdateTag(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_tag_group_sid				IN	security_pkg.T_SID_ID,
	in_tag_id						IN	tag.tag_id%TYPE,
	in_tag							IN	tag.tag%TYPE,
	in_explanation					IN	tag.explanation%TYPE,
	in_pos							IN	tag_group_member.pos%TYPE,
	in_is_visible					IN	tag_group_member.is_visible%TYPE
)
AS
BEGIN
	-- check write permissions on tag_group
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_tag_group_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on tag group');
	END IF;

	UPDATE tag
	   SET tag = in_tag, explanation = in_explanation
	 WHERE tag_id = in_tag_id;

	UPDATE tag_group_member
	   SET pos = in_pos, is_visible = in_is_visible
	 WHERE tag_id = in_tag_id
	   AND tag_group_sid = in_tag_Group_sid;
END;

PROCEDURE AddNewTagToGroup(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_tag_group_sid				IN	security_pkg.T_SID_ID,
	in_tag							IN	tag.tag%TYPE,
	in_explanation					IN	tag.explanation%TYPE,
	in_pos							IN	tag_group_member.pos%TYPE,
	in_is_visible					IN	tag_group_member.is_visible%TYPE,
	out_tag_id						OUT	tag.tag_id%TYPE
)
AS
BEGIN
	-- check write permissions on tag_group
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_tag_group_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	INSERT INTO tag
		(tag_id, tag, explanation)
	VALUES
		(tag_id_seq.NEXTVAL, in_tag, in_explanation)
	RETURNING tag_id INTO out_tag_id;

	INSERT INTO tag_group_member
		(tag_group_sid, tag_id, pos, is_visible)
	SELECT in_tag_group_sid, out_tag_id, NVL(in_pos, NVL(MAX(POS),0)+1), in_is_visible FROM tag_group_member;
END;

PROCEDURE RemoveTagFromGroup(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_tag_group_sid				IN	security_pkg.T_SID_ID,
	in_tag_id						IN	tag.tag_id%TYPE
)
AS
	v_in_use	NUMBER(10);
BEGIN
	-- check write permissions on tag_group
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_tag_group_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	-- check to see if tag is in use for this tag_group_sid
	SELECT COUNT(*) INTO v_in_use
	  FROM donation d, donation_tag dt, scheme_tag_group stg
	 WHERE dt.tag_id = in_tag_id	-- donations where tag is in use
	   AND dt.donation_id = d.donation_id -- join to donation
	   AND d.scheme_sid = stg.scheme_sid -- join to scheme_tag_group
	   AND stg.tag_group_sid = in_tag_group_sid; -- in our tag group

	IF v_in_use > 0 THEN
		RAISE_APPLICATION_ERROR(scheme_pkg.ERR_TAG_IN_USE, 'Tag in use');
	END IF;

	DELETE FROM tag_group_member
	 WHERE tag_group_sid = in_Tag_Group_sid
	   AND tag_id = in_tag_id;

	-- try deleting the tag - ignore constraint errors since this
	-- just means that another tag_group is using this tag

	-- TODO: when this is tested then disable constraint errors
	DELETE FROM tag
	 WHERE tag_id = in_tag_id;
END;

PROCEDURE RemoveTagsFromGroup(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_tag_group_sid				IN	security_pkg.T_SID_ID,
	-- NOTE: the tag ids from in_tags_to_leave will REMAIN in DB; the others that belongs to same tag_group will be deleted
	in_tags_to_leave				IN	VARCHAR2
)
AS
BEGIN
	FOR r IN (
		-- select IDS to be deleted
		SELECT t.tag_id FROM tag t, tag_group_member tgm
		 WHERE t.tag_id = tgm.tag_id
		   AND tgm.tag_group_sid = in_tag_group_sid
		   AND t.tag_id NOT IN (SELECT item FROM TABLE(csr.utils_pkg.SplitString(in_tags_to_leave,',')))
	)
	LOOP
		-- delete  constraint
		DELETE FROM tag_group_member
		 WHERE tag_id = r.tag_id;

		-- delete tag
		DELETE FROM tag
		 WHERE tag_id = r.tag_id;
	END LOOP;
END;

PROCEDURE SetDonationTags(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_donation_id					IN	donation.donation_id%TYPE,
	in_tag_ids						IN	VARCHAR2
)
AS
	tags_cur				security_pkg.T_OUTPUT_CUR;
	tags_permitted_cur		security_pkg.T_OUTPUT_CUR;
	v_tags_old				varchar2(32767);
	v_tags_new				varchar2(32767);
	v_tags_permitted		varchar2(32767);
	--v_tag_group_name		tag_group.name%TYPE;
	v_scheme_sid			security_pkg.T_SID_ID;
	v_app_sid				security_pkg.T_SID_ID;
BEGIN
	v_app_sid := security_pkg.GetApp();

	-- find out the tags already assigned
	OPEN tags_cur FOR
		SELECT t.tag
		  FROM tag t, donation_tag d
		 WHERE d.donation_id = in_donation_id
		   AND t.tag_id = d.tag_id
		 ORDER BY tag;

	v_tags_old :=  csr.utils_pkg.JoinString(tags_cur);

	OPEN tags_permitted_cur FOR
		SELECT t.tag_id
		  FROM tag t, tag_group_member tgm, tag_group tg
		 WHERE t.tag_id = tgm.tag_id
		   AND tgm.tag_group_sid = tg.tag_group_sid
		   AND security_pkg.SQL_IsAccessAllowedSID(in_act_id, tg.tag_group_sid, donations.scheme_pkg.PERMISSION_UPDATE_TAGS) = 1;

	v_tags_permitted :=  csr.utils_pkg.JoinString(tags_permitted_cur);

	SELECT scheme_sid
	  INTO v_scheme_sid
	  FROM donation
	 WHERE donation_id = in_donation_id;

	DELETE FROM donation_tag
	 WHERE donation_id = in_donation_id
	   AND tag_id IN (SELECT item FROM TABLE(csr.utils_pkg.SplitString(v_tags_permitted,',')));

	INSERT INTO donation_tag
		(donation_id, tag_id, pct_of_value)
	SELECT in_donation_id, tgm.tag_id, COUNT(tag_group_sid) OVER (PARTITION BY tag_group_sid)
	  FROM TABLE(csr.utils_pkg.SplitString(in_tag_ids,','))t, tag_group_member tgm
	 WHERE t.item = tgm.tag_id
	   AND t.item IN (SELECT item FROM TABLE(csr.utils_pkg.SplitString(v_tags_permitted,',')));

	-- find out the new set of tags
	OPEN tags_cur FOR
		SELECT t.tag
		  FROM tag t, donation_tag d
		 WHERE d.donation_id = in_donation_id
		   AND t.tag_id = d.tag_id
		 ORDER BY tag;

	v_tags_new :=  csr.utils_pkg.JoinString(tags_cur);

	-- write to audit
	csr.csr_data_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_DONATIONS_DONATION, v_app_sid,
		v_scheme_sid, 'Tags', v_tags_old, v_tags_new, in_donation_id);

	-- TODO
	-- would be nice if we can split tag by the tag_group. Currently it just writes the set from -> to of tags, without such partition
END;

PROCEDURE SetRecipientTags(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_recipient_sid				IN	recipient.recipient_sid%TYPE,
	in_tag_ids						IN	VARCHAR2
)
AS
	tags_cur			security_pkg.T_OUTPUT_CUR;
	v_tags_old			varchar2(32767);
	v_tags_new			varchar2(32767);
	v_tag_group_name	tag_group.name%TYPE;
	v_app_sid			security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY','APP');
	v_scheme_sid		security_pkg.T_SID_ID;
BEGIN

	-- find out the tags already assigned
	OPEN tags_cur FOR
		SELECT t.tag
		  FROM tag t, recipient_tag rt
		 WHERE rt.recipient_sid = in_recipient_sid
		   AND t.tag_id = rt.tag_id
		 ORDER BY tag;

	v_tags_old := csr.utils_pkg.JoinString(tags_cur);

	DELETE FROM recipient_tag
	 WHERE recipient_sid = in_recipient_sid;

	INSERT INTO recipient_tag
				(app_sid, recipient_sid, tag_id)
	SELECT v_app_sid, in_recipient_sid, tgm.tag_id
	  FROM TABLE(csr.utils_pkg.SplitString(in_tag_ids,','))t, tag_group_member tgm
	 WHERE t.item = tgm.tag_id;

	-- find out the new set of tags
	OPEN tags_cur FOR
		SELECT t.tag
		  FROM tag t, recipient_tag rt
		 WHERE rt.recipient_sid = in_recipient_sid
		   AND t.tag_id = rt.tag_id
		 ORDER BY tag;

	v_tags_new := csr.utils_pkg.JoinString(tags_cur);

	-- write to audit
	csr.csr_data_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_DONATIONS_RECIPIENT, v_app_sid, in_recipient_sid, 'Recipient Tags', v_tags_old, v_tags_new, NULL);
END;

-- returns the schemes and tag groups this user can see
PROCEDURE GetTagGroups(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT tg.tag_group_sid, tg.name, tg.mandatory, tg.multi_select, tg.render_as, tg.render_in, note, detailed_note,
		       CASE WHEN security_pkg.SQL_IsAccessAllowedSID(in_act_id, tg.tag_group_sid, donations.scheme_pkg.PERMISSION_UPDATE_TAGS)=1 THEN 1 ELSE 0 END can_set_tags
		  FROM tag_group tg
		 WHERE tg.app_sid = in_app_sid
		   AND security_pkg.SQL_IsAccessAllowedSID(in_act_id, tg.tag_group_sid, security_pkg.PERMISSION_READ) = 1;
END;

PROCEDURE GetTagGroupsForScheme(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_scheme_sid					IN	security_pkg.T_SID_ID,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT tg.tag_group_sid, tg.name, tg.mandatory, tg.multi_select, tg.render_as, tg.render_in, stg.pos,
		       note, detailed_note, CASE WHEN security_pkg.SQL_IsAccessAllowedSID(in_act_id, tg.tag_group_sid, donations.scheme_pkg.PERMISSION_UPDATE_TAGS)=1 THEN 1 ELSE 0 END can_set_tags
		  FROM tag_group tg, scheme_tag_group stg, scheme s
		 WHERE stg.scheme_sid = in_scheme_sid
		   AND tg.tag_group_sid = stg.tag_group_sid
		   AND stg.scheme_sid = s.scheme_sid
		   AND security_pkg.SQL_IsAccessAllowedSID(in_act_id, tg.tag_group_sid, security_pkg.PERMISSION_READ)=1
		   AND ((s.track_payments = 0 AND tg.render_in not in ('P')) OR (s.track_payments = 1))	-- exclude fields that will not get displayed (to avoid showing error on form)
		   AND ((s.track_company_giving = 0 AND tg.render_in not in ('O','M','I','A')) OR (s.track_company_giving = 1));
END;

PROCEDURE GetTagGroupsForRecipient(
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT tg.tag_group_sid, tg.name, tg.mandatory, tg.multi_select, tg.render_as, tg.render_in, rtg.pos,
		       note, detailed_note, CASE WHEN security_pkg.SQL_IsAccessAllowedSID(sys_context('security','act'), tg.tag_group_sid, donations.scheme_pkg.PERMISSION_UPDATE_TAGS)=1 THEN 1 ELSE 0 END can_set_tags
		  FROM tag_group tg, recipient_tag_group rtg
		 WHERE tg.tag_group_sid = rtg.tag_group_sid
		   AND security_pkg.SQL_IsAccessAllowedSID(sys_context('security','act'), tg.tag_group_sid, security_pkg.PERMISSION_READ) = 1;
END;

-- returns basic details of specified tag_group
PROCEDURE GetTagGroup(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_tag_group_sid				IN	security_pkg.T_SID_ID,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- check permissions on tag_group
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_tag_group_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT tag_group_sid, name, multi_select, mandatory, render_as, render_in, note, detailed_note
		  FROM tag_group
		 WHERE tag_group_sid = in_tag_group_sid;
END;

-- return all tag groups and the Projects they are associated with for given app_sid
PROCEDURE GetAllTagGroups(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- TODO: what SO do we check permission on?
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT tg.tag_group_sid, NAME, tg.show_in_filter, tg.note, tg.detailed_note, multi_select, mandatory, render_as, tgm.tag_Id, tgm.pos, tgm.is_visible, t.tag, t.explanation,
		       CASE WHEN rtg.tag_group_sid IS NOT NULL THEN 1 ELSE 0 END is_recipient
		  FROM tag_group tg, tag_group_member tgm, tag t, recipient_tag_group rtg
		 WHERE tg.tag_group_sid = tgm.tag_group_sid(+)
		   AND tgm.tag_group_sid = rtg.tag_group_sid(+)
		   AND tgm.tag_id = t.tag_id(+)
		   AND tg.app_sid = in_app_sid
		 ORDER BY tg.tag_group_sid, tgm.pos;
END;

-- return tag groups and their members for this scheme
-- optional donation_id (null if not interested) which will return selected if
-- selected for given donation
PROCEDURE GetVisibleTagGroupsForScheme(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_scheme_sid					IN	security_pkg.T_SID_ID,
	in_donation_Id					IN	donation.donation_id%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- check permission on scheme
	-- (we assume that if they can see the scheme, they can see associated tag_groups)
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_scheme_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT tg.tag_group_sid, tg.name, tg.multi_select, tg.mandatory, stg.pos,
		       t.tag_id, t.tag, t.explanation, DECODE(dt.donation_id, null, 0, 1) selected, render_as, render_in
		  FROM scheme_tag_group stg, tag_group tg, tag_group_member tgm, tag t, donation_tag dt
		 WHERE stg.tag_group_sid = tg.tag_group_sid
		   AND tg.tag_group_sid = tgm.tag_group_sid
		   AND tgm.is_visible = 1
		   AND tgm.tag_id = t.tag_id
		   AND stg.scheme_sid = in_scheme_sid
		   AND dt.tag_id(+) = t.tag_id
		   AND dt.donation_id(+) = in_donation_id
		 ORDER BY tag_group_sid, tgm.pos, tag_id;
END;

PROCEDURE GetTagGroupMembers(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_tag_group_sid				IN	security_pkg.T_SID_ID,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- check permission on tag_group
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_tag_group_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT t.tag_id, tag, explanation, is_visible, pos
		  FROM tag_group_member tgm, tag t
		 WHERE tgm.tag_id = t.tag_id
		   AND tgm.tag_group_sid = in_tag_group_sid
		 ORDER BY pos;
END;

-- return all tag groups and the schemes they are associated with for given app_sid
PROCEDURE GetTagGroupsForSetup(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT tg.tag_group_sid, tg.name, multi_select, mandatory, stg.scheme_sid
		 FROM tag_group tg, scheme_tag_group stg
		WHERE tg.tag_group_sid = stg.tag_group_sid(+)
		  AND tg.app_sid = in_app_sid
		  AND security_pkg.SQL_IsAccessAllowedSID(in_act_id, tg.tag_group_sid, security_pkg.PERMISSION_READ) = 1
		ORDER BY tg.tag_group_sid;
END;

PROCEDURE GetTagGroupsForSchemeSetup(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	in_scheme_sid					IN	security_pkg.T_SID_ID,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_scheme_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading scheme with sid '||in_scheme_sid);
	END IF;

	OPEN out_cur FOR
		SELECT tg.tag_group_sid, tg.name, multi_select, mandatory, stg.scheme_sid
		  FROM tag_group tg, scheme_tag_group stg
		 WHERE tg.tag_group_sid = stg.tag_group_sid(+)
		   AND stg.scheme_sid(+) = in_scheme_sid
		   AND tg.app_sid = in_app_sid
		 ORDER BY stg.pos;
END;

PROCEDURE GetTagGroupsForFcSetup(
	in_scheme_sid					IN	security_pkg.T_SID_ID,
	in_funding_commitment_sid		IN	security_pkg.T_SID_ID,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_fc_tag_group_sid			security_pkg.T_SID_ID;
	v_fc_paid_tag_group_sid		security_pkg.T_SID_ID;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_scheme_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading scheme with sid '||in_scheme_sid);
	END IF;

	-- find out the FC 'Yes' tag group sid, to exclude it from the TagGroup set (this one sets automatically when create fc_donation)
	SELECT tgm.tag_group_sid
	  INTO v_fc_tag_group_sid
	  FROM customer_options co, tag_group_member tgm
	 WHERE co.fc_tag_id = tgm.tag_id;

	-- find out the Paid 'Commited' tag group_sid to exclude from set (this one sets automatically when create Fc donation)
	SELECT tgm.tag_group_sid
	  INTO v_fc_paid_tag_group_sid
	  FROM customer_options co, tag_group_member tgm
	 WHERE co.fc_paid_tag_id = tgm.tag_id;

	IF in_funding_commitment_sid IS NULL THEN
		OPEN out_cur FOR
			SELECT tg.tag_group_sid, tg.name tag_group_name, multi_select, mandatory, t.tag_id, t.tag tag_name, CASE WHEN fdt.tag_id IS NOT NULL THEN 1 ELSE 0 END is_selected
			  FROM tag_group tg, scheme_tag_group stg, tag_group_member tgm, tag t, fc_default_tag fdt
			 WHERE tg.tag_group_sid = stg.tag_group_sid
			   AND tg.tag_group_sid = tgm.tag_group_sid
			   AND tgm.tag_id = t.tag_id
			   AND fdt.tag_id(+) = t.tag_id
			   AND tg.tag_group_sid != v_fc_tag_group_sid
			   AND tg.tag_group_sid != v_fc_paid_tag_group_sid
			   AND stg.scheme_sid = in_scheme_sid
			 ORDER BY tag_group_sid, stg.pos, tgm.pos;
	ELSE
		OPEN out_cur FOR
			SELECT tg.tag_group_sid, tg.name tag_group_name, multi_select, mandatory, t.tag_id, t.tag tag_name, CASE WHEN ft.tag_id IS NULL THEN 0 ELSE 1 END AS is_selected
			  FROM tag_group tg, scheme_tag_group stg, tag_group_member tgm, tag t, fc_tag ft
			 WHERE tg.tag_group_sid = stg.tag_group_sid
			   AND tg.tag_group_sid = tgm.tag_group_sid
			   AND tgm.tag_id = t.tag_id
			   AND ft.tag_id(+) = t.tag_id
			   AND stg.scheme_sid = in_scheme_sid
			   AND ft.funding_commitment_sid(+) = in_funding_commitment_sid
			   AND tg.tag_group_sid != v_fc_tag_group_sid
			   AND tg.tag_group_sid != v_fc_paid_tag_group_sid
			 ORDER BY tag_group_sid, stg.pos, tgm.pos;
	END IF;
END;

FUNCTION ConcatTagGroupMembers(
	in_tag_group_sid				IN	security_pkg.T_SID_ID,
	in_max_length					IN	INTEGER
) RETURN VARCHAR2
AS
	v_s			VARCHAR2(512);
	v_sep		VARCHAR2(10);
BEGIN
	v_s := '';
	v_sep := '';
	FOR r IN (
		SELECT tag
		  FROM tag_group_member tgm, tag t
		 WHERE tgm.tag_id = t.tag_id
		   AND tgm.tag_group_sid = in_tag_group_sid)
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

PROCEDURE GetTagGroupsSummary(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT tag_group_sid, name,
			(SELECT COUNT(*) FROM tag_group_member tgm WHERE tag_group_sid = tg.tag_group_sid) member_count,
			tag_pkg.ConcatTagGroupMembers(tg.tag_group_sid, 30) members
		  FROM tag_group tg
		 WHERE app_sid = in_app_sid;
END;

PROCEDURE GetTagDonationTags(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_donation_id					IN	donation.donation_id%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- Securty check?
	OPEN out_cur FOR
		SELECT t.tag_id, d.donation_id, d.pct_of_value, t.tag, t.explanation
		  FROM tag t, donation_tag d
		 WHERE d.donation_id = in_donation_id
		   AND t.tag_id = d.tag_id;
END;

PROCEDURE GetTagRecipientTags(
	in_recipient_sid				IN	security_pkg.T_SID_ID,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- check permission on recipient
	IF NOT security_pkg.IsAccessAllowedSID(sys_context('security','act'), in_recipient_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT t.tag_id, rt.recipient_sid, t.tag, t.explanation
		  FROM tag t, recipient_tag rt
		 WHERE rt.recipient_sid = in_recipient_sid
		   AND t.tag_id = rt.tag_id;
END;

PROCEDURE GetTagsForScheme(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_tag_group_sid				IN	tag_group.tag_group_sid%TYPE,
	in_scheme_sid					IN	scheme.scheme_sid%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT t.tag_id, t.tag, t.explanation, is_visible, tgm.pos
		  FROM tag t, scheme_tag_group stg, tag_group_member tgm
		 WHERE stg.tag_group_sid = tgm.tag_group_sid
		   AND t.tag_id = tgm.tag_id
		   AND tgm.tag_group_sid = in_tag_group_sid
		   AND stg.scheme_sid = in_scheme_sid
		   AND t.tag_id NOT IN (SELECT tag_id FROM exclude_tag WHERE scheme_sid = in_scheme_sid);
END;

PROCEDURE GetTag(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_tag_id						IN	tag.tag_id%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- Securty chack?
	OPEN out_cur FOR
		SELECT tag_id, tag, explanation
		  FROM tag
		 WHERE tag_id = in_tag_id;
END;

PROCEDURE GetRegionTagGroups(
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT tg.tag_group_id, name, multi_select, mandatory, tgm.tag_id, tgm.pos, t.tag, t.explanation
		  FROM csr.v$tag_group tg, csr.tag_group_member tgm, csr.v$tag t, region_filter_tag_group rftg
		 WHERE tg.tag_group_id = tgm.tag_group_id
		   AND tgm.tag_id = t.tag_id
		   AND applies_to_regions = 1
		   AND rftg.region_tag_group_id = tg.tag_group_id
		   AND tg.app_sid = SYS_CONTEXT('SECURITY','APP')
		 ORDER BY tg.tag_group_id, tgm.pos, NLSSORT(t.tag, 'NLS_SORT=generic_m');
END;

PROCEDURE GetRecipientTagGroups(
	out_cur							OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT tg.tag_group_sid, tg.name, tg.mandatory, tg.multi_select, tg.render_as, tg.render_in, note, detailed_note
		  FROM tag_group tg
		 WHERE tg.app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND render_in = 'R'
		   AND security_pkg.SQL_IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), tg.tag_group_sid, security_pkg.PERMISSION_READ) = 1;
END;

FUNCTION GetTagGroupSidFromGroupName(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_name							IN	tag_group.name%TYPE,
	in_app_sid						IN	security_pkg.T_SID_ID
) RETURN NUMBER
AS
	v_out						NUMBER;
BEGIN
	-- Security check?
	BEGIN
		SELECT tag_group_sid INTO v_out
		  FROM tag_group
		 WHERE LOWER(TRIM(name)) = LOWER(TRIM(in_name))
		   AND app_sid = in_app_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Could not find tag group with name ' || in_name || ' for application if ID ' || in_app_sid );
	END;

	RETURN v_out;
END;

FUNCTION GetTagIdFromName(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_tag							IN	tag.tag%TYPE,
	in_tag_group_sid				IN	security_pkg.T_SID_ID
) RETURN NUMBER
AS
	v_out						NUMBER;
BEGIN
	-- Security check?
	BEGIN
		SELECT t.tag_id INTO v_out
		  FROM tag t, tag_group_member tgm, tag_group tg
		 WHERE t.tag_id = tgm.tag_id
		   AND tgm.tag_group_sid = tg.tag_group_sid
		   AND tg.tag_group_sid = in_tag_group_sid
		   AND LOWER(TRIM(t.tag)) = LOWER(TRIM(in_tag));
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Could not find tag with name ' || in_tag || ' for tag group with SID ' || in_tag_group_sid );
	END;

	RETURN v_out;
END;

END tag_Pkg;
/
