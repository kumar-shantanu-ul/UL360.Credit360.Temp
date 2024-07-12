CREATE OR REPLACE PACKAGE BODY CSR.property_pkg IS

PROC_NOT_FOUND				EXCEPTION;
PRAGMA EXCEPTION_INIT(PROC_NOT_FOUND, -06550);

/*
ASSIGNING USERS!!
neatest way to set sys_context('security','chain_company') in sql?
company_pkg.setcompany
company_user_pkg.CreateUserINTERNAL
*/

PROCEDURE INTERNAL_SetFundOwnership(
	in_region_sid					IN security_pkg.T_SID_ID,
	in_fund_id						IN NUMBER,
	in_ownership					IN NUMBER,
	in_start_date					IN DATE,
	in_update_fund_tree				IN NUMBER
);

FUNCTION FormatDocFolderName (
	in_property_name				IN  VARCHAR2,
	in_property_sid					IN  security_pkg.T_SID_ID
) RETURN VARCHAR2
AS
BEGIN
	RETURN SUBSTRB(REPLACE(in_property_name,'/','-'), 1, 240) || ' ('|| in_property_sid ||')';
END;

FUNCTION GetFundTreeRoot
RETURN security_pkg.T_SID_ID
AS
	v_root_sid						security_pkg.T_SID_ID;
BEGIN
	SELECT MIN(rt.region_tree_root_sid)
	  INTO v_root_sid
	  FROM csr.region_tree rt
	 WHERE rt.app_sid = security_pkg.GetApp
	   AND rt.is_fund = 1;

	-- create a new secondary tree if one doesn't exist
	IF v_root_sid IS NULL THEN
		region_pkg.CreateRegionTreeRoot(
			in_act_id					=> security.security_pkg.GetACT,
			in_app_sid					=> security.security_pkg.GetApp,
			in_name						=> 'Funds',
			in_is_primary				=> 0,
			out_region_tree_root_sid	=> v_root_sid
		);

		UPDATE csr.region_tree
		   SET is_fund = 1
		 WHERE region_tree_root_sid = v_root_sid;
	END IF;

	RETURN v_root_sid;
END;

-- copy and paste of GetProperty
PROCEDURE GetFundProperties(
	in_fund_id				IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT p.app_sid, p.region_sid, p.description, p.parent_sid, p.region_ref, p.street_addr_1, p.street_addr_2, p.city,
			p.state, p.postcode, p.country_code, p.country_name, p.country_currency,
			p.property_type_id, p.property_type_label,
			p.property_sub_type_id, p.property_sub_type_label,
			p.flow_item_id, p.current_state_id, p.current_state_label, p.current_state_lookup_key,
			p.current_state_colour,
			p.active, p.acquisition_dtm, p.disposal_dtm, p.lng, p.lat,
			p.mgmt_company_id, p.mgmt_company_other, p.mgmt_company_contact_id, p.company_sid,
			p.energy_star_sync, p.energy_star_push, -- raw energy star option flags
			p.energy_star_sync is_energy_star, DECODE(p.energy_star_sync, 0, 0, p.energy_star_push) is_energy_star_push, -- takes into account the sync flag being set to zero,
			NVL(es.pm_building_id, p.pm_building_id) pm_building_id,
			pg.asset_id gresb_asset_id
		  FROM v$property p
		  LEFT JOIN property_gresb pg ON pg.region_sid = p.region_sid
		  LEFT JOIN (
			-- I would have thought you could only map something once but there's
			-- no unique constraint on est_building.region_sid. If we knew it was unique we could
			-- join straight to est_building. One to check and talk to Dickie about
			-- TODO: I think Dickie has added this now so this could be changed?
			SELECT DISTINCT b.region_sid, b.pm_building_id
			  FROM est_building b
			 WHERE b.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND b.region_sid IS NOT NULL
		  )es ON p.region_sid = es.region_sid
		  JOIN property_fund pf ON pf.app_sid = p.app_sid AND pf.region_sid = p.region_sid
		 WHERE pf.fund_id = in_fund_id;
END;

-- Role based property security
PROCEDURE CheckRolesForRegions(
	in_state				IN	property.state%TYPE DEFAULT NULL,
	in_country_code			IN  region.geo_country%TYPE,
	out_has_roles			OUT number
)
AS
	v_has_role 				number(1);
	v_company_region_sid	security_pkg.T_SID_ID;
	v_country_region_sid	security_pkg.T_SID_ID;
	v_state_region_sid		security_pkg.T_SID_ID;
BEGIN

	v_has_role := 0;

	SELECT region_sid
	  INTO v_company_region_sid
	  FROM supplier
	 WHERE company_sid = SYS_CONTEXT('SECURITY','CHAIN_COMPANY');

	-- get the region sid of the country we are checking
	BEGIN
		SELECT region_sid
		  INTO v_country_region_sid
		  FROM region
		 WHERE name = in_country_code
		   AND parent_sid = v_company_region_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_country_region_sid := null;
	END;

	-- some countries such as England are listed as states of
	-- parent country United Kingdom
	IF in_state IS NOT NULL THEN
		BEGIN
			SELECT region_sid
			  INTO v_state_region_sid
			  FROM region
			 WHERE name = in_state
			   AND parent_sid = v_country_region_sid;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_state_region_sid := null;
		END;
	END IF;

	-- check if user has property manager role on either the country, state or chain company regions
	SELECT COUNT(*)
	  INTO v_has_role
	  FROM ( SELECT 1
			   FROM dual
			  WHERE EXISTS(SELECT 1
							 FROM csr.region_role_member
							WHERE user_sid = security.security_pkg.GetSid
							  AND region_sid IN (v_state_region_sid, v_country_region_sid, v_company_region_sid)
							  AND role_sid IN (SELECT role_sid
												 FROM csr.role
												WHERE is_property_manager = 1)));

	out_has_roles := v_has_role;

END;

PROCEDURE INTERNAL_CallHelperPkg(
	in_procedure_name	IN	VARCHAR2,
	in_region_sid		IN	security_pkg.T_SID_Id
)
AS
	v_helper_pkg		property_options.property_helper_pkg%TYPE;
BEGIN
	-- call helper proc if there is one, to setup custom forms
	BEGIN
		SELECT property_helper_pkg
		  INTO v_helper_pkg
		  FROM property_options
		 WHERE app_sid = security_pkg.GetApp;
	EXCEPTION
		WHEN no_data_found THEN
			null;
	END;

	IF v_helper_pkg IS NOT NULL THEN
		BEGIN
			EXECUTE IMMEDIATE 'begin '||v_helper_pkg||'.'||in_procedure_name||'(:1);end;'
				USING in_region_sid;
		EXCEPTION
			WHEN PROC_NOT_FOUND THEN
				NULL; -- it is acceptable that it is not supported
		END;
	END IF;
END;

PROCEDURE CheckPmBuildingId(
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_pm_building_id	IN	property.pm_building_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- some security check
	IF in_region_sid IS NOT NULL AND NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied trying to read property with sid '||in_region_sid);
	END IF;

	OPEN out_cur FOR
		SELECT r.description region_desc, b.building_name, x.region_sid, x.pm_building_id, x.reason
		  FROM v$region r, est_building b, (
			-- pm_building_id already mapped to dfferent region in est_building
			SELECT region_sid, pm_building_id, 'Energy Star property already mapped to another property region' reason
			  FROM est_building
			 WHERE pm_building_id = in_pm_building_id
			   AND region_sid IS NOT NULL
			   AND (in_region_sid IS NULL OR region_sid != in_region_sid)
			UNION
			-- pm_building_id already mapped to dfferent region in property
			SELECT region_sid, pm_building_id, 'Portfolio Manager ID already in use by another property region' reason
			  FROM property
			 WHERE pm_building_id = in_pm_building_id
			   AND (in_region_sid IS NULL OR region_sid != in_region_sid)
		) x
		 WHERE r.region_sid = x.region_sid
		   AND b.pm_building_id = x.pm_building_id;
END;

FUNCTION INTERNAL_CheckPmBuildingId(
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_pm_building_id	IN	property.pm_building_id%TYPE
) RETURN BOOLEAN
AS
BEGIN
	FOR r IN (
		-- pm_building_id already mapped to dfferent region in est_building
		SELECT 1 x
		  FROM est_building
		 WHERE pm_building_id = in_pm_building_id
		   AND region_sid IS NOT NULL
		   AND region_sid != in_region_sid
		UNION
		-- pm_building_id already mapped to dfferent region in property
		SELECT 1 x
		  FROM property
		 WHERE pm_building_id = in_pm_building_id
		   AND region_sid != in_region_sid
	) LOOP
		RETURN FALSE;
	END LOOP;
	RETURN TRUE;
END;

PROCEDURE SetPmBuildingId(
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_pm_building_id	IN  property.pm_building_id%TYPE
)
AS
	v_act	security_pkg.T_ACT_ID;
	CURSOR c IS
		SELECT p.app_sid, NVL(b.pm_building_id, p.pm_building_id) pm_building_id
		  FROM property p
		  LEFT JOIN est_building b ON b.app_sid = p.app_sid AND b.region_sid = p.region_sid
		 WHERE p.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND p.region_sid = in_region_sid;
	current c%ROWTYPE;

	v_new_est_account_sid		security_pkg.T_SID_ID;
BEGIN
	v_act := SYS_CONTEXT('SECURITY','ACT');

	-- security check
	IF NOT security_pkg.IsAccessAllowedSID(v_act, in_region_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the property with sid '||in_region_sid);
	END IF;

	IF NOT csr.csr_data_pkg.CheckCapability('Remap Energy Star property') AND
	   NOT INTERNAL_CheckPmBuildingId(in_region_sid, in_pm_building_id) THEN
		RAISE_APPLICATION_ERROR(ERR_PM_BUILDING_ID, 'Energy Star ID validation failed');
	END IF;

	-- Fetch the current state for this region
	OPEN c;
	FETCH c INTO current;
	CLOSE c;

	-- Fetch the account sid for the newly mapped building
	BEGIN
		SELECT est_account_sid
		  INTO v_new_est_account_sid
		  FROM est_building
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND pm_building_id = in_pm_building_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- The new building has not been shared yet
			v_new_est_account_sid := NULL;
	END;

	-- check the id is changing
	IF NVL(current.pm_building_id, -1) != NVL(in_pm_building_id, -1) THEN
		-- Is the property already connected to energy star or is
		-- the energy star building already connected to a property?
		FOR r IN (
			-- This property already connected
			SELECT b.est_account_sid, b.pm_customer_id, b.pm_building_id
			  FROM est_building b, property p
			 WHERE b.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND b.app_sid = p.app_sid
			   AND b.region_sid = p.region_sid
			   AND b.region_sid = in_region_sid
			UNION
			-- Another property already connected to the building
			SELECT b.est_account_sid, b.pm_customer_id, b.pm_building_id
			  FROM est_building b
			 WHERE b.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND b.region_sid != in_region_sid
			   AND b.pm_building_id = in_pm_building_id
		) LOOP
			-- "Remap Energy Star property" capability is required at this stage.
			IF NOT csr.csr_data_pkg.CheckCapability('Remap Energy Star property') THEN
				RAISE_APPLICATION_ERROR(ERR_PM_BUILDING_ID, 'The "Remap Energy Star property" capability is required to perform a remapping.');
			END IF;

			IF in_pm_building_id IS NULL THEN
				-- This is just an unmapping.
				UPDATE all_property
				   SET pm_building_id = NULL
				 WHERE region_sid = in_region_sid;

				-- Unmap using the *connected* building details
				energy_star_pkg.UnmapBuilding(
					r.est_account_sid,
					r.pm_customer_id,
					r.pm_building_id
				);
			END IF;
		END LOOP;
	END IF;

	-- Call the mapping helper here if the user has the remap capability.
	-- This allows the user to put a mapping back when there will be no sharing request,
	-- if for example it was removed by mistake (only possible with the capability)
	IF csr.csr_data_pkg.CheckCapability('Remap Energy Star property') THEN
		-- This might be a remapping, use the *new* building details.
		-- Note we don't trash orphan objects in the region tree as this can take
		-- minutes if there are many nodes and we don't want the page to time out.
		-- The batch process should deal with orphan object trashing.
		energy_star_pkg.MappingHelper(
			v_new_est_account_sid,
			in_region_sid,
			in_pm_building_id,
			0 -- Don't trash orphan objects
		);
	ELSE
		-- There's no existing connection, just update the property table
		-- and wait for the sharing request to be processed by the batch process.
		-- No capability required for this.
		UPDATE all_property
		   SET pm_building_id = in_pm_building_id
		 WHERE region_sid = in_region_sid;
	END IF;

	-- Audit the change
	csr_data_pkg.AuditValueChange(v_act, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.GetAPP,
		in_region_sid, 'Energy Star property ID', current.pm_building_id, in_pm_building_id);
END;


PROCEDURE SetPmBuildingId(
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_pm_building_id	IN	property.pm_building_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	CheckPmBuildingId(in_region_sid, in_pm_building_id, out_cur);
	IF INTERNAL_CheckPmBuildingId(in_region_sid, in_pm_building_id) THEN
		SetPmBuildingId(in_region_sid, in_pm_building_id);
	END IF;
END;


PROCEDURE SetTagIds(
	in_region_sid   	IN  security_pkg.T_SID_ID,
	in_tag_group_id		IN  security_pkg.T_SID_ID,
	in_tag_ids		    IN  security_pkg.T_SID_IDS
)
AS
BEGIN
	-- some security check
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_region_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the property with sid '||in_region_sid);
	END IF;

	-- clear down - not best from an audit perspective
	DELETE FROM region_tag
	 WHERE region_sid = in_region_sid
	   AND tag_id IN (
			SELECT tag_id
			  FROM tag_group_member
			 WHERE tag_group_id = in_tag_group_id
	   );

	-- crap hack for ODP.NET
	IF in_tag_ids.COUNT = 1 AND in_tag_ids(1) IS NULL THEN
		NULL; -- collection is null by default
	ELSE
		FORALL i IN in_tag_ids.FIRST..in_tag_ids.LAST
			INSERT INTO region_tag (region_sid, tag_id)
				VALUES (in_region_sid, in_tag_ids(i));
	END IF;

	-- Update any dynamic delegation plans that depend on this region
	region_pkg.ApplyDynamicPlans(in_region_sid, 'Region tags changed');

	INTERNAL_CallHelperPkg('PropertyTagsUpdated', in_region_sid);
END;

PROCEDURE INTERNAL_GetRegionCursors(
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_tags_cur			OUT	SYS_REFCURSOR,
	out_metric_values_cur	OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_tags_cur FOR
		SELECT r.region_sid, tgm.tag_group_id, t.tag_id
		  FROM region r
			JOIN region_tag rt ON r.region_sid = rt.region_sid AND r.app_sid = rt.app_sid
			JOIN tag t ON rt.tag_id = t.tag_id AND rt.app_sid = t.app_sid
			JOIN tag_group_member tgm ON t.tag_id = tgm.tag_id AND t.app_sid = tgm.app_sid
		 WHERE r.region_sid = in_region_sid
		 ORDER BY tgm.tag_group_id, tgm.pos;

	OPEN out_metric_values_cur FOR
		SELECT rmv.region_sid, rmv.ind_sid, rmv.effective_dtm, rmv.entry_val AS val, rmv.note, rmv.entry_measure_conversion_id AS measure_conversion_id, rmv.measure_sid,
			   NVL(mc.description, m.description) measure_description,
			   NVL(i.format_mask, m.format_mask) format_mask,
			   rm.show_measure
		  FROM (
			SELECT
				ROW_NUMBER() OVER (PARTITION BY app_sid, region_sid, ind_sid ORDER BY effective_dtm DESC) rn,
				FIRST_VALUE(region_metric_val_id) OVER (PARTITION BY app_sid, region_sid, ind_sid ORDER BY effective_dtm DESC) region_metric_val_id
			  FROM region_metric_val
			 WHERE effective_dtm < SYSDATE  -- we only want to show the current applicable value
			   AND region_sid = in_region_sid
			) rmvl
		  JOIN region_metric_val rmv ON rmvl.region_metric_val_id = rmv.region_metric_val_id
		  JOIN region_metric rm ON rmv.ind_sid = rm.ind_sid AND rmv.app_sid = rm.app_sid
		  JOIN ind i ON rm.ind_sid = i.ind_sid AND rm.app_sid = i.app_sid
		  JOIN measure m ON rmv.measure_sid = m.measure_sid AND rmv.app_sid = m.app_sid
	 LEFT JOIN measure_conversion mc ON rmv.entry_measure_conversion_id = mc.measure_conversion_id AND rmv.measure_sid = mc.measure_sid AND rmv.app_sid = mc.app_sid
		 WHERE rmvl.rn = 1
	  ORDER BY rmv.effective_dtm DESC;
END;

PROCEDURE GetSpace(
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR,
	out_tags_cur			OUT	SYS_REFCURSOR,
	out_metric_values_cur	OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- some security check
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the property with sid '||in_region_sid);
	END IF;

	OPEN out_cur FOR
		SELECT s.region_sid, s.description, s.space_type_id, s.space_type_label
		  FROM v$space s
		 WHERE s.region_sid = in_region_sid;

	INTERNAL_GetRegionCursors(in_region_sid, out_tags_cur, out_metric_values_cur);
END;

PROCEDURE GetMeter(
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR,
	out_tags_cur			OUT	SYS_REFCURSOR,
	out_metric_values_cur	OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- some security check
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the property with sid '||in_region_sid);
	END IF;

	OPEN out_cur FOR
		SELECT DISTINCT -- Crunch up multiple meter ind mappings
			m.region_sid, m.reference, m.description, m.parent_sid, m.note, m.meter_type_id,
			m.primary_ind_sid, m.primary_description, m.primary_measure, m.primary_measure_conversion_id,
			m.cost_ind_sid, m.cost_description, m.cost_measure, m.cost_measure_conversion_id,
			m.meter_source_type_id, m.source_type_name, m.source_type_description,
			m.manual_data_entry, m.arbitrary_period, m.add_invoice_data,
			m.show_in_meter_list, m.descending, m.allow_reset,
			m.active, m.acquisition_dtm, m.disposal_dtm,
			c.last_reading_dtm, c.val_number last_reading, c.first_reading_dtm, c.reading_count,
			CASE WHEN m.active = 1 AND SYSDATE - NVL(c.last_reading_dtm, SYSDATE) BETWEEN 30 AND 37 then 1 else 0 end is_almost_overdue,
			CASE WHEN m.active = 1 AND SYSDATE - NVL(c.last_reading_dtm, SYSDATE) > 37 then 1 else 0 end is_overdue,
			DECODE(parent_r.region_sid, NULL, m.region_sid, parent_r.region_sid) meter_region_sid,
			DECODE(parent_r.region_sid, NULL, m.description, parent_r.description) meter_description,
			DECODE(parent_r.region_sid, NULL, NULL, m.region_sid) rate_region_sid,
			DECODE(parent_r.region_sid, NULL, NULL, m.description) rate_description,
			UNSEC_GetSpaceSid(m.region_sid) space_sid, -- Nasty, nasty, nasty!
			MAX(DECODE(mcm.meter_type, NULL, 0, 1)) OVER (PARTITION BY m.region_sid) is_est_compatible
		  FROM v$property_meter m
		  LEFT JOIN meter_list_cache c ON m.region_sid = c.region_sid
		  LEFT JOIN v$region parent_r ON m.parent_sid = parent_r.region_sid AND m.region_type = csr_data_pkg.REGION_TYPE_RATE
		  -- This is used to check for Energy Star comaptibility
		  LEFT JOIN est_options op ON m.app_sid = op.app_sid
		  LEFT JOIN est_meter em ON m.app_sid = em.app_sid AND m.region_sid = em.region_sid
		  LEFT JOIN est_meter_type_mapping mtm
				 ON m.app_sid = mtm.app_sid
				AND m.meter_type_id = mtm.meter_type_id
				AND NVL(em.est_account_sid, op.default_account_sid) = mtm.est_account_sid
		  LEFT JOIN est_conv_mapping mcm
				 ON m.app_sid = mcm.app_sid
				AND mtm.meter_type = mcm.meter_type
				AND m.primary_measure_sid = mcm.measure_sid
				AND NVL(m.primary_measure_conversion_id, -1) = NVL(mcm.measure_conversion_id, -1)
				AND mcm.est_account_sid = NVL(em.est_account_sid, op.default_account_sid)
		 WHERE m.region_sid = in_region_sid;

	INTERNAL_GetRegionCursors(in_region_sid, out_tags_cur, out_metric_values_cur);
END;

PROCEDURE GetTransitions(
	in_region_sid		IN  security_pkg.T_SID_ID,
	out_cur 			OUT SYS_REFCURSOR
)
AS
	v_flow_item_id		property.flow_item_id%TYPE;
	v_region_sids		security_pkg.T_SID_IDS;
BEGIN
	SELECT in_region_sid
	  BULK COLLECT INTO v_region_sids
	  FROM DUAL;

	SELECT flow_item_id
	  INTO v_flow_item_id
	  FROM property
	 WHERE region_sid = in_region_sid;

	flow_pkg.GetFlowItemTransitions(
		in_flow_item_id		=> v_flow_item_id,
		in_region_sids		=> v_region_sids,
		out_cur 			=> out_cur
	);
END;

PROCEDURE GetPropertyTypes(
	out_property_types 			OUT  SYS_REFCURSOR,
	out_property_sub_types 		OUT  SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_property_types FOR
		SELECT property_type_id, label, gresb_property_type_id
		  FROM property_type
		 ORDER BY LOWER(label);

	OPEN out_property_sub_types FOR
		SELECT property_sub_type_id, property_type_id, label, gresb_property_type_id, gresb_property_sub_type_id
		  FROM property_sub_type
		 ORDER BY LOWER(label);

END;

PROCEDURE GetPropertyTypesMapSpaceTypes(
	out_property_types 		OUT  SYS_REFCURSOR,
	out_spaces_cur 			OUT  SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_property_types FOR
		SELECT property_type_id, label, gresb_property_type_id
		  FROM property_type
		 ORDER BY LOWER(label);

	OPEN out_spaces_cur FOR
		SELECT st.space_type_id, st.label, ptst.property_type_id
		  FROM space_type st
		  JOIN property_type_space_type ptst
			ON st.app_sid = ptst.app_sid
		   AND st.space_type_id = ptst.space_type_id
		ORDER BY LOWER(st.label);
END;

PROCEDURE GetPropertyOptions(
	out_property_types 			OUT  SYS_REFCURSOR,
	out_property_sub_types		OUT  SYS_REFCURSOR,
	out_tag_groups 				OUT  SYS_REFCURSOR,
	out_tag_group_members		OUT  SYS_REFCURSOR,
	out_metrics 				OUT  SYS_REFCURSOR,
	out_mgmt_companies			OUT  SYS_REFCURSOR,
	out_mgmt_company_contacts	OUT  SYS_REFCURSOR,
	out_property_element_layout	OUT  SYS_REFCURSOR
)
AS
BEGIN
	-- what could we secure?? (that would make sense?)

	GetPropertyTypes(out_property_types, out_property_sub_types);

	-- why doesn't it return stuff for spaces too?
	OPEN out_tag_groups FOR
		SELECT DISTINCT tg.tag_group_id, tg.name, tg.multi_select, tg.mandatory, tg.lookup_key
		  FROM v$tag_group tg
		 WHERE tg.applies_to_regions = 1
		   AND (tg.app_sid, tg.tag_group_id) NOT IN (
				SELECT DISTINCT app_sid,tag_group_id
				  FROM region_type_tag_group
				)
			OR (tg.app_sid, tg.tag_group_id) IN (
				SELECT DISTINCT app_sid,tag_group_id
				  FROM region_type_tag_group
				 WHERE region_type IN (
						csr_data_pkg.REGION_TYPE_PROPERTY, csr_data_pkg.REGION_TYPE_METER
				 )
			);

	OPEN out_tag_group_members FOR
		SELECT tg.tag_group_id, t.tag_id, t.tag, t.lookup_key
		  FROM tag_group tg
		  JOIN tag_group_member tgm ON tg.tag_group_id = tgm.tag_group_id AND tg.app_sid = tgm.app_sid
		  JOIN v$tag t ON tgm.tag_Id = t.tag_id AND tgm.app_sid = t.app_sid
		 WHERE tg.applies_to_regions = 1
		   AND (tg.app_sid, tg.tag_group_id) NOT IN (
				SELECT DISTINCT app_sid,tag_group_id
				  FROM region_type_tag_group
				)
			OR (tg.app_sid, tg.tag_group_id) IN (
				SELECT DISTINCT app_sid,tag_group_id
				  FROM region_type_tag_group
				 WHERE region_type IN (csr_data_pkg.REGION_TYPE_PROPERTY, csr_data_pkg.REGION_TYPE_METER)
				 )
		 ORDER BY tg.tag_group_id, tgm.pos;

	OPEN out_metrics FOR
		-- all the metrics for properties and spaces (and meters maybe?)
		SELECT rm.ind_sid, m.measure_sid,
			NVL(i.format_mask, m.format_mask) format_mask, i.lookup_Key, i.description,
			rm.is_mandatory, rtm.region_type, rm.show_measure
		  FROM region_type_metric rtm
			JOIN region_metric rm ON rtm.ind_sid = rm.ind_sid AND rtm.app_sid = rm.app_sid
			JOIN v$ind i ON rm.ind_sid = i.ind_sid AND rm.app_sid = i.app_sid
			JOIN measure m ON i.measure_sid = m.measure_sid AND i.app_sid = m.app_sid
		   WHERE rtm.region_type IN (csr_data_pkg.REGION_TYPE_METER, csr_data_pkg.REGION_TYPE_PROPERTY, csr_data_pkg.REGION_TYPE_SPACE);

	OPEN out_mgmt_companies FOR
		SELECT mgmt_company_id, name
		  FROM mgmt_company
		 ORDER BY name;

	OPEN out_mgmt_company_contacts FOR
		SELECT mgmt_company_id, mgmt_company_contact_id, name, email, phone
		  FROM mgmt_company_contact
		 ORDER BY mgmt_company_id, name;

	OPEN out_property_element_layout FOR
		SELECT element_name, pos, ind_sid, tag_group_id
		  FROM property_element_layout
		 ORDER BY pos;
END;

PROCEDURE GetPropertyOptions(
	out_property_types 			OUT  SYS_REFCURSOR,
	out_property_sub_types		OUT  SYS_REFCURSOR,
	out_tag_groups 				OUT  SYS_REFCURSOR,
	out_tag_group_members		OUT  SYS_REFCURSOR,
	out_metrics 				OUT  SYS_REFCURSOR,
	out_mgmt_companies			OUT  SYS_REFCURSOR,
	out_mgmt_company_contacts	OUT  SYS_REFCURSOR,
	out_property_element_layout	OUT  SYS_REFCURSOR,
	out_property_addr_options	OUT  SYS_REFCURSOR
)
AS
BEGIN
	GetPropertyOptions(
		out_property_types, out_property_sub_types,
		out_tag_groups, out_tag_group_members,
		out_metrics,
		out_mgmt_companies, out_mgmt_company_contacts,
		out_property_element_layout);

	OPEN out_property_addr_options FOR
		SELECT element_name, mandatory
		  FROM property_address_options
		 ORDER BY element_name;

END;

PROCEDURE GetPropertyOptions(
	out_property_types 			OUT  SYS_REFCURSOR,
	out_property_sub_types		OUT  SYS_REFCURSOR,
	out_tag_groups 				OUT  SYS_REFCURSOR,
	out_tag_group_members		OUT  SYS_REFCURSOR,
	out_metrics 				OUT  SYS_REFCURSOR,
	out_mgmt_companies			OUT  SYS_REFCURSOR,
	out_mgmt_company_contacts	OUT  SYS_REFCURSOR,
	out_property_element_layout	OUT  SYS_REFCURSOR,
	out_property_addr_options	OUT  SYS_REFCURSOR,
	out_space_types				OUT	 SYS_REFCURSOR,
	out_property_char_layout	OUT	 SYS_REFCURSOR,
	out_meter_element_layout	OUT	 SYS_REFCURSOR
)
AS
BEGIN
	GetPropertyOptions(
		out_property_types, out_property_sub_types,
		out_tag_groups, out_tag_group_members,
		out_metrics,
		out_mgmt_companies, out_mgmt_company_contacts,
		out_property_element_layout,
		out_property_addr_options
		);

	OPEN out_space_types FOR
		SELECT space_type_id, label
		  FROM space_type
		ORDER BY LOWER(label) ASC;

	OPEN out_property_char_layout FOR
		SELECT element_name, pos, col, ind_sid, tag_group_id
		  FROM property_character_layout
		 ORDER BY col, pos;

	OPEN out_meter_element_layout FOR
		SELECT mel.meter_element_layout_id, mel.pos, mel.ind_sid,
				mel.tag_group_id, i.description, tg.name
		  FROM meter_element_layout mel
		  LEFT JOIN v$ind i
			ON i.ind_sid = mel.ind_sid
		  LEFT JOIN v$tag_group tg
			ON tg.tag_group_id = mel.tag_group_id
		 ORDER BY pos;
END;

/**
 * Checks which company the property belongs to and then returns a list of possible
 * funds. If no property is passed in it uses the current company.
 */
PROCEDURE GetFunds(
	in_region_sid			IN  security_pkg.T_SID_ID	DEFAULT NULL,
	out_funds_cur			OUT SYS_REFCURSOR,
	out_mgmt_contacts		OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF in_region_sid IS NOT NULL THEN
		-- some security check
		IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_region_sid, security_pkg.PERMISSION_READ) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the property with sid '||in_region_sid);
		END IF;
	END IF;

	-- XXX: do we secure funds further? Presume it's safe to assume SYS_CONTEXT is right

	OPEN out_funds_cur FOR
		SELECT f.fund_id, f.name, f.year_of_inception, f.fund_type_id, ft.label fund_type_label,
			   f.mgr_contact_name, f.mgr_contact_email, f.mgr_contact_phone,
			   f.default_mgmt_company_id, f.company_sid
		  FROM fund f
		  LEFT JOIN fund_type ft ON f.fund_type_id = ft.fund_type_id AND f.app_sid = ft.app_sid
		  LEFT JOIN property p ON f.company_sid = p.company_sid AND f.app_sid = p.app_sid AND p.region_sid = in_region_sid
		 WHERE (f.company_sid = NVL(p.company_sid, SYS_CONTEXT('SECURITY','CHAIN_COMPANY'))
			   OR chain.helper_pkg.IsTopCompany > 0) -- Include all funds when logged in as top company
		 ORDER BY LOWER(f.name);

	-- XXX: This returns contacts that the user might not have permission to

	OPEN out_mgmt_contacts FOR
		SELECT mcc.mgmt_company_contact_id, mcc.mgmt_company_id, mcc.name, mcc.email, mcc.phone,
				fmc.fund_id
		  FROM mgmt_company_contact mcc
		  JOIN fund_mgmt_contact fmc
			ON mcc.mgmt_company_contact_id = fmc.mgmt_company_contact_id;
END;

PROCEDURE GetFundCompanies(
	out_fund_companies		OUT	SYS_REFCURSOR
)
AS
	v_fund_company_type_id	csr.property_options.fund_company_type_id%TYPE;
BEGIN

	SELECT MIN(fund_company_type_id)
	  INTO v_fund_company_type_id
	  FROM csr.property_options po
	 WHERE po.app_sid = SYS_CONTEXT('SECURITY', 'APP');

	 -- Nab the default company type if nothing is specified in csr.property_options
	 IF v_fund_company_type_id IS NULL THEN
		SELECT MIN(company_type_id) 
		  INTO v_fund_company_type_id
		  FROM chain.company_type ct
		 WHERE ct.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND ct.is_default=1;
	 END IF;

	-- TODO: This should return only the fund companies that are of a specific type or that
	--       the logged in company has a relationship with. For now just return the logged in
	--       company or *ALL* companies if the logged in company is top
	OPEN out_fund_companies FOR
		SELECT company_sid, name
		  FROM chain.company
		 WHERE (company_sid = SYS_CONTEXT('SECURITY','CHAIN_COMPANY')
			OR chain.helper_pkg.IsTopCompany > 0)
			AND company_type_id = v_fund_company_type_id;
END;

PROCEDURE SaveFund(
	in_fund_id					IN	fund.fund_id%TYPE,
	in_company_sid				IN	fund.company_sid%TYPE,
	in_fund_name				IN	fund.name%TYPE,
	in_year_of_incep			IN	fund.year_of_inception%TYPE,
	in_fund_type_id				IN	fund.fund_type_id%TYPE,
	in_mgr_contact_name			IN	fund.mgr_contact_name%TYPE,
	in_mgr_contact_email		IN	fund.mgr_contact_email%TYPE,
	in_mgr_contact_phone		IN	fund.mgr_contact_phone%TYPE,
	in_default_mgmt_company_id	IN fund.default_mgmt_company_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_fund_id				fund.fund_id%TYPE;
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can add/update funds.');
	END IF;

	-- XXX: this is a bad idea - should upsert and have a unique key like the company_sid and name?
	-- If we've not been given a tennant ID,
	-- we must be adding. Otherwise, update.
	IF NVL(in_fund_id, -1) = -1 THEN
		INSERT INTO fund(fund_id, company_sid, name, year_of_inception, fund_type_id,
				mgr_contact_name, mgr_contact_email, mgr_contact_phone, default_mgmt_company_id)
		VALUES(fund_id_seq.NEXTVAL, in_company_sid, in_fund_name, in_year_of_incep, in_fund_type_id,
				in_mgr_contact_name, in_mgr_contact_email, in_mgr_contact_phone, in_default_mgmt_company_id)
		RETURNING fund_id INTO v_fund_id;

		INTERNAL_CallHelperPkg('FundCreated', v_fund_id);
	ELSE
		UPDATE fund
		   SET company_sid = in_company_sid,
			   name = in_fund_name,
			   year_of_inception = in_year_of_incep,
			   fund_type_id = in_fund_type_id,
			   mgr_contact_name = in_mgr_contact_name,
			   mgr_contact_email = in_mgr_contact_email,
			   mgr_contact_phone = in_mgr_contact_phone,
			   default_mgmt_company_id = in_default_mgmt_company_id
		 WHERE fund_id = in_fund_id;

		 v_fund_id := in_fund_id;
	END IF;

	OPEN out_cur FOR
		SELECT fund_id, name, fund_type_id, mgr_contact_name,
			   mgr_contact_email, mgr_contact_phone, default_mgmt_company_id
		  FROM fund
		 WHERE fund_id = v_fund_id;
END;

PROCEDURE DeleteFund(
	in_fund_id	IN	fund.fund_id%TYPE
)
AS
	v_fund_region					security_pkg.T_SID_ID;
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can delete funds');
	END IF;

	SELECT region_sid
	  INTO v_fund_region
	  FROM fund
	 WHERE fund_id = in_fund_id;

	-- Remove from associated properties
	DELETE FROM csr.property_fund_ownership
	 WHERE fund_id = in_fund_id
	   AND app_sid = security_pkg.GetApp;

	DELETE FROM csr.property_fund
	 WHERE fund_id = in_fund_id
	   AND app_sid = security_pkg.GetApp;

	DELETE FROM fund_mgmt_contact
	 WHERE fund_id = in_fund_id
	   AND app_sid = security_pkg.GetApp;

	DELETE FROM fund
	 WHERE fund_id = in_fund_id
	   AND app_sid = security_pkg.GetApp;

	-- Delete fund node in secondary region tree
	IF v_fund_region IS NOT NULL THEN
		securableobject_pkg.DeleteSO(
			in_act_id			=> security_pkg.GetAct,
			in_sid_id			=> v_fund_region
		);
	END IF;
END;

PROCEDURE AddFundMgmtContact(
	in_fund_id						IN	fund.fund_id%TYPE,
	in_mgmt_company_id				IN	mgmt_company_contact.mgmt_company_id%TYPE,
	in_mgmt_company_contact_id		IN	mgmt_company_contact.mgmt_company_contact_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can delete fund contacts');
	END IF;

	INSERT INTO fund_mgmt_contact(fund_id, mgmt_company_id, mgmt_company_contact_id)
	VALUES(in_fund_id, in_mgmt_company_id, in_mgmt_company_contact_id);
END;

-- Removes all Management Contacts for a fund.
-- (used when a user clears all contacts and saves).
PROCEDURE DeleteAllMgmtContacts(
	in_fund_id		IN	fund.fund_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can delete fund contacts');
	END IF;

	DELETE FROM fund_mgmt_contact
	 WHERE fund_id = in_fund_id;
END;

-- Actually, get the region's parent space or property sid
FUNCTION UNSEC_GetSpaceSid(
	in_region_sid	IN	security_pkg.T_SID_ID
)
RETURN security_pkg.T_SID_ID
AS
	v_space_sid  	security_pkg.T_SID_ID;
BEGIN
	WITH space AS (
		SELECT region_sid, region_type
		  FROM region
		 WHERE CONNECT_BY_ISLEAF = 1
		 START WITH region_sid = in_region_sid
		 CONNECT BY PRIOR parent_sid = region_sid
		   AND PRIOR region_type != csr_data_pkg.REGION_TYPE_PROPERTY
		   AND PRIOR region_type != csr_data_pkg.REGION_TYPE_SPACE
	)
	SELECT CASE
			WHEN space.region_type = csr_data_pkg.REGION_TYPE_PROPERTY THEN space.region_sid
			WHEN space.region_type = csr_data_pkg.REGION_TYPE_SPACE THEN space.region_sid
			ELSE NULL
		END property_sid
	  INTO v_space_sid
	  FROM space;

	RETURN v_space_sid;
END;

PROCEDURE GetProperty(
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- some security check
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the property with sid '||in_region_sid);
	END IF;

	OPEN out_cur FOR
		SELECT p.app_sid, p.region_sid, description, parent_sid, region_ref, street_addr_1, street_addr_2, city,
			state, postcode, country_code, country_name, geo_type, country_currency,
			property_type_id, property_type_label,
			property_sub_type_id, property_sub_type_label,
			flow_item_id, current_state_id, current_state_label, current_state_lookup_key,
			current_state_colour,
			active, acquisition_dtm, disposal_dtm, lng, lat, fund_id,
			mgmt_company_id, mgmt_company_other, mgmt_company_contact_id, company_sid,
			p.energy_star_sync, p.energy_star_push, -- raw energy star option flags
			p.energy_star_sync is_energy_star, DECODE(p.energy_star_sync, 0, 0, p.energy_star_push) is_energy_star_push, -- takes into account the sync flag being set to zero,
			NVL(es.pm_building_id, p.pm_building_id) pm_building_id, property_type_lookup_key,
			pg.asset_id gresb_asset_id
		  FROM v$property p
		  LEFT JOIN property_gresb pg ON pg.region_sid = p.region_sid
		  LEFT JOIN (
			-- I would have thought you could only map something once but there's
			-- no unique constraint on est_building.region_sid. If we knew it was unique we could
			-- join straight to est_building. One to check and talk to Dickie about
			-- TODO: I think Dickie has added this now so this could be changed?
			SELECT DISTINCT b.region_sid, b.pm_building_id
			  FROM est_building b
			 WHERE b.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND b.region_sid IS NOT NULL
		  )es ON p.region_sid = es.region_sid
		 WHERE p.region_sid = in_region_sid;
END;

PROCEDURE GetProperty(
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR,
	out_roles_cur			OUT	SYS_REFCURSOR,
	out_tags_cur			OUT	SYS_REFCURSOR,
	out_metric_values_cur	OUT	SYS_REFCURSOR
)
AS
BEGIN
	GetProperty(in_region_sid, out_cur);

	OPEN out_roles_cur FOR
		SELECT rrm.role_sid, rrm.user_sid, cu.csr_user_sid, cu.full_name, cu.email, cu.user_name, r.name role_name,
			CASE WHEN inherited_from_sid != region_sid THEN 1 ELSE 0 END is_inherited, cu.active is_active
		  FROM region_role_member rrm
		  JOIN v$csr_user cu ON rrm.user_sid = cu.csr_user_sid
		  JOIN role r ON rrm.role_sid = r.role_sid
		  LEFT JOIN trash t on cu.csr_user_sid = t.trash_sid
		  LEFT JOIN superadmin sa on cu.csr_user_sid = sa.csr_user_sid
		 WHERE region_sid = in_region_sid
		   AND t.trash_sid IS NULL
		   AND sa.csr_user_sid IS NULL;

	INTERNAL_GetRegionCursors(in_region_sid, out_tags_cur, out_metric_values_cur);
END;

FUNCTION CanViewProperty(
	in_region_sid  	IN  security_pkg.T_SID_ID,
	out_is_editable OUT NUMBER
) RETURN BOOLEAN
AS
BEGIN
	-- CHECK BASED ON WORKFLOW ROLE
	BEGIN
		SELECT MAX(is_editable)
		  INTO out_is_editable
		  FROM v$my_property
		 WHERE region_sid = in_region_sid
		 GROUP BY region_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			out_is_editable := 0;
			RETURN FALSE;
	END;

	-- some security check
	RETURN security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_region_sid, security_pkg.PERMISSION_READ);
END;


FUNCTION CanViewProperty(
	in_region_sid  IN  security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
	v_is_editable NUMBER(10);
BEGIN
	RETURN CanViewProperty(in_region_sid, v_is_editable);
END;

PROCEDURE GetSpaceTypesForProperty(
	in_region_sid				IN	security_pkg.T_SID_ID,
	out_space_types_cur			 	OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_space_types_cur FOR
		-- space types valid for this property
		SELECT st.space_type_id, st.label, st.is_tenantable, DECODE(stm.est_space_type, NULL, 0, 1) is_est_compatible
		  FROM property p
			JOIN property_type_space_type ptst ON p.property_type_id = ptst.property_type_Id AND p.app_sid = ptst.app_sid
			JOIN space_type st ON ptst.space_type_id = st.space_type_id AND ptst.app_sid = st.app_sid
			-- This is used to check for Energy Star comaptibility
			LEFT JOIN est_space_type_map stm ON st.app_sid = stm.app_sid AND st.space_type_id = stm.space_type_id
		 WHERE p.region_sid = in_region_sid;
END;

-- full fat version
PROCEDURE GetProperty(
	in_region_sid			 	IN	security_pkg.T_SID_ID,
	out_prop_cur			 	OUT SYS_REFCURSOR,
	out_roles_cur			 	OUT SYS_REFCURSOR,
	out_space_types_cur		 	OUT SYS_REFCURSOR,
	out_spc_typ_rgn_mtrc_cur 	OUT SYS_REFCURSOR,
	out_metrics_cur	 		 	OUT SYS_REFCURSOR,
	out_spaces_cur			 	OUT SYS_REFCURSOR,
	out_meters_cur			 	OUT SYS_REFCURSOR,
	out_tag_groups_cur 			OUT SYS_REFCURSOR,
	out_tag_group_members_cur 	OUT SYS_REFCURSOR,
	out_tags_cur			 	OUT SYS_REFCURSOR,
	out_metric_values_cur	 	OUT SYS_REFCURSOR,
	out_transitions			 	OUT SYS_REFCURSOR,
	out_flow_state_log_cur		OUT SYS_REFCURSOR,
	out_photos_cur				OUT	SYS_REFCURSOR
)
AS
	v_is_editable NUMBER(10);
BEGIN
	IF NOT CanViewProperty(in_region_sid, v_is_editable) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the property with sid '||in_region_sid);
	END IF;

	GetTransitions(in_region_sid, out_transitions);

	OPEN out_flow_state_log_cur FOR
		SELECT x.comment_text, x.set_dtm, x.set_by_user_sid, x.full_name, x.email
		  FROM (
			SELECT comment_text, set_dtm, set_by_user_sid, cu.full_name, cu.email,
				ROW_NUMBER() OVER (ORDER BY flow_state_log_id DESC) rn
			  FROM flow_state_log fsl
			  JOIN csr_user cu ON fsl.set_by_user_sid = cu.csr_user_sid AND fsl.app_sid = cu.app_sid
			 WHERE flow_item_id = (
				SELECT flow_Item_id FROM property WHERE region_sid = in_region_sid
			 )
		 )x
		 WHERE rn < 3;

	OPEN out_prop_cur FOR
		SELECT p.app_sid, p.region_sid, p.description, p.region_ref, p.street_addr_1, p.street_addr_2,
			p.city, p.state, p.postcode, p.country_code, p.country_name, p.geo_type, p.country_currency, p.flow_item_id,
			p.current_state_id, p.current_state_label, p.current_state_lookup_key, p.current_state_colour,
			p.active, p.acquisition_dtm, p.disposal_dtm,
			p.lng, p.lat, p.property_type_id, p.property_type_label, p.property_sub_type_id, p.property_sub_type_label,
			p.fund_id, f.name fund_name, f.name fund,
			p.mgmt_company_id, p.mgmt_company_other, mc.name mgmt_company_name, NVL(mc.name, p.mgmt_company_other) mgmt_company,
			p.mgmt_company_contact_id, mcc.name mgmt_company_contact_name, mcc.email mgmt_company_contact_email, mcc.phone mgmt_company_contact_phone,
			cc.name company_name, v_is_editable is_editable, property_type_lookup_key,
			p.energy_star_sync, p.energy_star_push, -- raw energy star option flags
			p.energy_star_sync is_energy_star, DECODE(p.energy_star_sync, 0, 0, p.energy_star_push) is_energy_star_push, -- takes into account the sync flag being set to zero
			pg.asset_id gresb_asset_id
		  FROM v$property p
		  LEFT JOIN fund f ON p.fund_id = f.fund_id AND p.company_sid = f.company_sid AND p.app_sid = f.app_sid
		  LEFT JOIN property_gresb pg ON pg.region_sid = p.region_sid
		  LEFT JOIN mgmt_company mc ON p.mgmt_company_id = mc.mgmt_company_id AND p.app_sid = mc.app_sid
		  LEFT JOIN mgmt_company_contact mcc ON p.mgmt_company_contact_id = mcc.mgmt_company_contact_id
		  LEFT JOIN chain.company cc ON p.company_sid = cc.company_sid AND p.app_sid = cc.app_sid
			-- join to member company?
		 WHERE p.region_sid = in_region_sid;

	OPEN out_roles_cur FOR
		SELECT rrm.role_sid, rrm.user_sid, cu.csr_user_sid, cu.full_name, cu.email, cu.user_name, r.name role_name,
			CASE WHEN inherited_from_sid != region_sid THEN 1 ELSE 0 END is_inherited
		  FROM region_role_member rrm
			JOIN v$csr_user cu ON rrm.user_sid = cu.csr_user_sid
			JOIN role r ON rrm.role_sid = r.role_sid
			LEFT JOIN csr.trash t on cu.csr_user_sid = t.trash_sid
			LEFT JOIN superadmin sa on cu.csr_user_sid = sa.csr_user_sid
		 WHERE region_sid = in_region_sid
		   AND t.trash_sid IS NULL
		   AND sa.csr_user_sid IS NULL
		   AND cu.active = 1;

	GetSpaceTypesForProperty(in_region_sid, out_space_types_cur);

	OPEN out_spc_typ_rgn_mtrc_cur FOR
		-- the metrics for each space_type
		-- TODO: energy star comaptible flag
		SELECT strm.space_type_id, strm.ind_sid
		  FROM property p
			JOIN property_type_space_type ptst ON p.property_type_id = ptst.property_type_Id AND p.app_sid = ptst.app_sid
			JOIN space_type st ON ptst.space_type_id = st.space_type_id AND ptst.app_sid = st.app_sid
			JOIN space_type_region_metric strm ON st.space_type_id = strm.space_type_id AND st.app_sid = strm.app_sid
		 WHERE p.region_sid = in_region_sid;

	OPEN out_metrics_cur FOR
		-- all the metrics for properties and spaces and meters
		SELECT rm.ind_sid, m.measure_sid,
			NVL(i.format_mask, m.format_mask) format_mask, i.lookup_Key, i.description,
			rm.is_mandatory
		  FROM region_type_metric rtm
			JOIN region_metric rm ON rtm.ind_sid = rm.ind_sid AND rtm.app_sid = rm.app_sid
			JOIN v$ind i ON rm.ind_sid = i.ind_sid AND rm.app_sid = i.app_sid
			JOIN measure m ON i.measure_sid = m.measure_sid AND i.app_sid = m.app_sid
		 WHERE rtm.region_type IN (csr_data_pkg.REGION_TYPE_PROPERTY, csr_data_pkg.REGION_TYPE_SPACE,
									csr_data_pkg.REGION_TYPE_METER, csr_data_pkg.REGION_TYPE_REALTIME_METER)
		  ORDER BY i.description;

	GetPropertySpaces(in_region_sid, out_spaces_cur);

	OPEN out_meters_cur FOR
		SELECT DISTINCT -- Crunch up multiple meter ind mappings
			pm.region_sid, pm.reference, pm.parent_sid, pm.note, pm.meter_type_id, pm.description,
			pm.group_label, pm.group_key,
			pm.primary_ind_sid, pm.primary_description, pm.primary_measure, pm.primary_measure_conversion_id,
			pm.cost_ind_sid, pm.cost_description, pm.cost_measure, pm.cost_measure_conversion_id,
			pm.meter_source_type_id, pm.source_type_name, pm.source_type_description, pm.manual_data_entry,
			pm.arbitrary_period, pm.add_invoice_data,
			pm.show_in_meter_list, pm.descending, pm.allow_reset,
			mlc.last_reading_dtm, mlc.val_number last_reading, mlc.first_reading_dtm, mlc.reading_count,
			CASE WHEN pm.active = 1 AND SYSDATE - NVL(mlc.last_reading_dtm, SYSDATE) BETWEEN 30 AND 37 then 1 else 0 end is_almost_overdue,
			CASE WHEN pm.active = 1 AND SYSDATE - NVL(mlc.last_reading_dtm, SYSDATE) > 37 then 1 else 0 end is_overdue,
			pm.acquisition_dtm, pm.active, pm.disposal_dtm,
			DECODE(parent_r.region_sid, NULL, pm.region_sid, parent_r.region_sid) meter_region_sid,
			DECODE(parent_r.region_sid, NULL, pm.description, parent_r.description) meter_description,
			DECODE(parent_r.region_sid, NULL, NULL, pm.region_sid) rate_region_sid,
			DECODE(parent_r.region_sid, NULL, NULL, pm.description) rate_description,
			UNSEC_GetSpaceSid(pm.region_sid) space_sid, -- Nasty, nasty, nasty!
			extractvalue(v.info_xml, '/fields/field[@name="definition"]/text()') as ind_detail, -- don't put this in v$property_meter, it more than doubles the time taken to get this cursor
			MAX(DECODE(mcm.meter_type, NULL, 0, 1)) OVER (PARTITION BY pm.region_sid) is_est_compatible
		  FROM v$property_meter pm
		  LEFT JOIN meter_list_cache mlc ON pm.region_sid = mlc.region_sid AND pm.app_sid = mlc.app_sid
		  LEFT JOIN v$ind v ON pm.primary_ind_sid = v.ind_sid AND v.app_sid = pm.app_sid
		  LEFT JOIN v$region parent_r ON pm.parent_sid = parent_r.region_sid AND pm.region_type = csr_data_pkg.REGION_TYPE_RATE
		  -- This is used to check for Energy Star comaptibility
		  LEFT JOIN est_options op ON pm.app_sid = op.app_sid
		  LEFT JOIN est_meter em ON pm.app_sid = em.app_sid AND pm.region_sid = em.region_sid
		  LEFT JOIN est_meter_type_mapping mtm
				 ON pm.app_sid = mtm.app_sid
				AND pm.meter_type_id = mtm.meter_type_id
				AND NVL(em.est_account_sid, op.default_account_sid) = mtm.est_account_sid
		  LEFT JOIN est_conv_mapping mcm
				 ON pm.app_sid = mcm.app_sid
				AND mtm.meter_type = mcm.meter_type
				AND pm.primary_measure_sid = mcm.measure_sid
				AND NVL(pm.primary_measure_conversion_id, -1) = NVL(mcm.measure_conversion_id, -1)
				AND mcm.est_account_sid = NVL(em.est_account_sid, op.default_account_sid)
		 WHERE pm.region_sid IN (
			 SELECT region_sid
			   FROM region
			  START WITH region_sid = in_region_sid
			CONNECT BY PRIOR region_sid = parent_sid
		 )
		 ORDER BY pm.active desc, LOWER(pm.description);

	-- We use DISTINCT to crunch up the property and meter tag-groups for these two cursors.
	-- we might want to split this out so we know which are for properties and which are for meters?
	-- Currently in the UI the javascript controls let you select which tag groups to show and in
	-- what order so it makes sense just to pass everything back.
	OPEN out_tag_groups_cur FOR
		SELECT DISTINCT tg.tag_group_id, tg.name, tg.multi_select, tg.mandatory, tg.lookup_key
		  FROM v$tag_group tg
		 WHERE tg.applies_to_regions = 1
		   AND ((tg.app_sid, tg.tag_group_id) NOT IN (SELECT DISTINCT app_sid,tag_group_id FROM region_type_tag_group)
			OR (tg.app_sid, tg.tag_group_id) IN (SELECT DISTINCT app_sid,tag_group_id FROM region_type_tag_group
													 WHERE region_type IN (csr_data_pkg.REGION_TYPE_PROPERTY, csr_data_pkg.REGION_TYPE_METER)))
		   AND lookup_key IS NOT NULL;

	OPEN out_tag_group_members_cur FOR
		SELECT DISTINCT tg.tag_group_id, t.tag_id, t.tag, t.lookup_key, tgm.pos
		  FROM tag_group tg
			JOIN tag_group_member tgm ON tg.tag_group_id = tgm.tag_group_id AND tg.app_sid = tgm.app_sid
			JOIN v$tag t ON tgm.tag_Id = t.tag_id AND tgm.app_sid = t.app_sid
		   WHERE tg.applies_to_regions = 1
		   AND ((tg.app_sid, tg.tag_group_id) NOT IN (SELECT DISTINCT app_sid,tag_group_id FROM region_type_tag_group)
			  OR (tg.app_sid, tg.tag_group_id) IN (SELECT DISTINCT app_sid,tag_group_id FROM region_type_tag_group
													 WHERE region_type IN (csr_data_pkg.REGION_TYPE_PROPERTY, csr_data_pkg.REGION_TYPE_METER)))
			 AND tg.lookup_key IS NOT NULL
		   ORDER BY tg.tag_group_id, tgm.pos;

	OPEN out_tags_cur FOR
		SELECT r.region_sid, tgm.tag_group_id, t.tag_id
		  FROM region r
			JOIN region_tag rt ON r.region_sid = rt.region_sid AND r.app_sid = rt.app_sid
			JOIN tag t ON rt.tag_id = t.tag_id AND rt.app_sid = t.app_sid
			JOIN tag_group_member tgm ON t.tag_id = tgm.tag_id AND t.app_sid = tgm.app_sid
		 WHERE r.region_sid IN (
			 SELECT region_sid
			   FROM region
			  START WITH region_sid = in_region_sid
			CONNECT BY PRIOR region_sid = parent_sid
		 )
		 ORDER BY tgm.tag_group_id, tgm.pos;

	OPEN out_metric_values_cur FOR
		SELECT rmv.region_sid, rmv.ind_sid, rmv.effective_dtm, rmv.entry_val AS val, rmv.note, rmv.entry_measure_conversion_id AS measure_conversion_id, rmv.measure_sid,
			   NVL(mc.description, m.description) measure_description,
			   NVL(i.format_mask, m.format_mask) format_mask,
			   rm.show_measure
		  FROM (
			SELECT
				ROW_NUMBER() OVER (PARTITION BY app_sid, region_sid, ind_sid ORDER BY effective_dtm DESC) rn,
				FIRST_VALUE(region_metric_val_id) OVER (PARTITION BY app_sid, region_sid, ind_sid ORDER BY effective_dtm DESC) region_metric_val_id
			  FROM region_metric_val
			 WHERE effective_dtm < SYSDATE  -- we only want to show the current applicable value
			   AND region_sid IN (
					 SELECT region_sid
					   FROM region
					  START WITH region_sid = in_region_sid
					CONNECT BY PRIOR region_sid = parent_sid
				 )
			) rmvl
		  JOIN region_metric_val rmv ON rmvl.region_metric_val_id = rmv.region_metric_val_id
		  JOIN region_metric rm ON rmv.ind_sid = rm.ind_sid AND rmv.app_sid = rm.app_sid
		  JOIN ind i ON rm.ind_sid = i.ind_sid AND rm.app_sid = i.app_sid
		  JOIN measure m ON rmv.measure_sid = m.measure_sid AND rmv.app_sid = m.app_sid
	 LEFT JOIN measure_conversion mc ON rmv.entry_measure_conversion_id = mc.measure_conversion_id AND rmv.measure_sid = mc.measure_sid AND rmv.app_sid = mc.app_sid
		 WHERE rmvl.rn = 1
	  ORDER BY rmv.effective_dtm DESC;

	GetPropertyPhotos(in_region_sid, out_photos_cur);
END;

PROCEDURE GetPropertyPhotos(
	in_region_sid					IN security_pkg.T_SID_ID,
	out_photos_cur					OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_photos_cur FOR
		SELECT pp.property_photo_id, pp.property_region_sid, pp.space_region_sid, pp.filename,
			   pp.mime_type, sr.description space_region_description
		  FROM property_photo pp
		  LEFT JOIN v$region sr ON pp.space_region_sid = sr.region_sid
		 WHERE property_region_sid = in_region_sid
		 ORDER BY property_photo_id;
END;


PROCEDURE GetPropertySpaces(
	in_region_sid				IN  security_pkg.T_SID_ID,
	out_spaces_cur				OUT SYS_REFCURSOR
)
AS
BEGIN
	-- some security check
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the property with sid '||in_region_sid);
	END IF;

	OPEN out_spaces_cur FOR
		SELECT s.region_sid, s.description, s.space_type_id, s.space_type_label, s.disposal_dtm,
			s.current_lease_id, s.current_tenant_name, s.active, s.property_region_sid,
			l.lease_id, l.start_dtm lease_start_dtm, l.end_dtm lease_end_dtm,
			l.next_break_dtm, l.next_rent_review,
			l.current_rent, l.normalised_rent, l.currency_code,
			l.tenant_id, l.tenant_name,
			DECODE(stm.est_space_type, NULL, 0, 1) is_est_compatible
		  FROM v$space s
	 LEFT JOIN v$lease l ON l.lease_id = s.current_lease_id
	 -- This is used to check for Energy Star comaptibility
	 LEFT JOIN est_space_type_map stm ON s.app_sid = stm.app_sid AND s.space_type_id = stm.space_type_id
		 WHERE s.parent_sid = in_region_sid
		 ORDER BY s.description ASC;
END;

PROCEDURE AddToFlow(
	in_region_sid				IN  security_pkg.T_SID_ID,
	out_flow_item_id			OUT	flow_item.flow_item_id%TYPE
)
AS
	v_flow_sid				security_pkg.T_SID_ID;
	v_default_state_id		flow.default_state_id%TYPE;
	v_flow_state_log_id		flow_state_log.flow_state_log_id%TYPE;
	v_flow_item_id			section.flow_item_id%TYPE;
BEGIN
	-- some security check
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the property with sid '||in_region_sid);
	END IF;

	SELECT flow_item_id
	  INTO v_flow_item_id
	  FROM property
	 WHERE region_sid = in_region_sid;

	IF v_flow_item_id IS NOT NULL THEN
		out_flow_item_id := v_flow_item_id;
		RETURN;
	END IF;

	SELECT property_flow_sid
	  INTO v_flow_sid
	  FROM customer
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP');

	IF v_flow_sid IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'Property workflow not configured for this customer');
	END IF;

	SELECT default_state_id
	  INTO v_default_state_id
	  FROM flow
	 WHERE flow_sid = v_flow_sid;

	INSERT INTO flow_item
		(flow_item_id, flow_sid, current_state_id)
	VALUES
		(flow_item_id_seq.NEXTVAL, v_flow_sid, v_default_state_id)
	RETURNING
		flow_item_id INTO out_flow_item_id;

	v_flow_state_log_id := flow_pkg.AddToLog(in_flow_item_id => out_flow_item_id);

	UPDATE all_property
	   SET flow_item_id = out_flow_item_id
	 WHERE region_sid = in_region_sid;
END;

FUNCTION GetFlowRegionSids(
	in_flow_item_id		IN	csr.flow_item.flow_item_id%TYPE
)RETURN security.T_SID_TABLE
AS
	v_region_sids_t			security.T_SID_TABLE DEFAULT security.T_SID_TABLE();
BEGIN
	SELECT region_sid
	  BULK COLLECT INTO v_region_sids_t
	  FROM v$property p
	 WHERE app_sid = security_pkg.getApp
	   AND flow_item_id = in_flow_item_id;

	RETURN v_region_sids_t;
END;

FUNCTION FlowItemRecordExists(
	in_flow_item_id		IN	csr.flow_item.flow_item_id%TYPE
)RETURN NUMBER
AS
	v_count					NUMBER;
BEGIN

	SELECT DECODE(count(*), 0, 0, 1)
	  INTO v_count
	  FROM v$property p
	 WHERE app_sid = security_pkg.getApp
	   AND flow_item_id = in_flow_item_id;

	RETURN v_count;
END;

PROCEDURE GetFlowAlerts(
	out_cur		OUT		security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT x.app_sid, x.from_state_Label, x.to_state_label, x.set_dtm, x.customer_alert_type_id,
			   x.flow_state_log_id, x.flow_state_transition_id, x.flow_item_generated_alert_id,
			   x.set_by_user_sid, x.set_by_user_name, x.set_by_full_name, x.set_by_email,
			   x.to_user_sid, x.to_user_name, x.to_full_name, x.to_email, x.to_friendly_name, x.to_initiator,
			   x.flow_alert_helper, x.flow_Item_id,
			   p.description, p.region_ref, p.city, p.state, p.country_name, p.region_sid,
			   p.property_type_label, p.lookup_key, p.postcode, p.parent_sid,
			   p.current_state_label , p.street_addr_1, p.street_addr_2,
			   x.comment_text
		  FROM v$open_flow_item_gen_alert x
		  JOIN v$property p ON x.flow_item_id = p.flow_item_id AND x.app_sid = p.app_sid
		 ORDER BY x.app_sid, x.customer_alert_type_id, x.to_user_sid, x.flow_item_id; -- order matters!
END;

PROCEDURE GetMyProperties(
	in_just_inactive			IN 	 NUMBER DEFAULT 0,
	in_restrict_to_region_sid	IN   security_pkg.T_SID_ID,
	out_cur 					OUT  SYS_REFCURSOR,
	out_roles   				OUT  SYS_REFCURSOR
)
AS
	v_tag_ids		security_pkg.T_SID_IDS;
BEGIN
	GetMyProperties(in_just_inactive,in_restrict_to_region_sid,v_tag_ids,out_cur, out_roles);
END;

-- TODO: add server side filtering (currently it's all client side)
PROCEDURE GetMyProperties(
	in_just_inactive			IN 	 NUMBER DEFAULT 0,
	in_restrict_to_region_sid	IN   security_pkg.T_SID_ID,
	in_tag_ids					IN  security_pkg.T_SID_IDS,
	out_cur 					OUT  SYS_REFCURSOR,
	out_roles   				OUT  SYS_REFCURSOR
)
AS
	cur_dummy	security_pkg.T_OUTPUT_CUR;
	v_period_name				reporting_period.name%TYPE;
	v_period_start_dtm			reporting_period.start_dtm%TYPE;
	v_period_end_dtm			reporting_period.end_dtm%TYPE;
	v_count						NUMBER(10);
	t_tag_ids					security.T_SID_TABLE;
	
	v_temp_flow_filter			T_FLOW_FILTER_DATA_TABLE;		
BEGIN
	t_tag_ids := security_pkg.SidArrayToTable(in_tag_ids);

	SELECT COUNT(*)
	  INTO v_count
	  FROM TABLE(t_tag_ids);

	-- XXX: should we check perms on restrict to region_sid? Surely it doesnt matter since we're still USING
	-- roles via v$my_property

	-- dump IDs into array
	DELETE FROM temp_flow_filter;
	INSERT INTO temp_flow_filter (id, is_editable)
		SELECT region_sid, MAX(is_editable)
		  FROM v$my_property
		 WHERE ((in_just_inactive = 0 AND active = 1) OR (in_just_inactive = 1 AND active = 0))
		   AND (in_restrict_to_region_sid IS NULL OR region_sid IN (
				SELECT nvl(link_to_region_sid, region_sid)
				  FROM region
				 START WITH region_sid = in_restrict_to_region_sid
				CONNECT BY PRIOR region_sid = parent_sid
		   ))
		   AND (v_count = 0 OR ((region_sid,v_count) IN  (SELECT r.region_sid,COUNT(DISTINCT t.tag_Id) as row_count FROM  csr.region r
			JOIN  csr.region_tag rt ON r.region_sid = rt.region_sid AND r.app_sid = rt.app_sid
			JOIN  csr.tag t ON rt.tag_id = t.tag_id AND rt.app_sid = t.app_sid
			JOIN  csr.tag_group_member tgm ON t.tag_id = tgm.tag_id AND t.app_sid = tgm.app_sid
			JOIN TABLE(t_tag_ids) ti ON ti.column_value = t.tag_Id
			GROUP BY r.region_sid
			)))
		 GROUP BY region_sid;

	-- Use current reporting period for sheets.
	reporting_period_pkg.GetCurrentPeriod(SYS_CONTEXT('SECURITY', 'APP'), v_period_name, v_period_start_dtm, v_period_end_Dtm);

	SELECT T_FLOW_FILTER_DATA_ROW(tff.id, tff.is_editable)
	  BULK COLLECT INTO v_temp_flow_filter
	  FROM temp_flow_filter tff;

	OPEN out_cur FOR
		SELECT p.region_sid, p.description, p.region_ref, p.street_addr_1, p.street_addr_2, p.city, p.state,
			p.postcode, p.country_code, p.country_name, p.country_currency,
			p.property_type_id, p.property_type_label, p.property_sub_type_id, p.property_sub_type_label,
			p.flow_item_id, p.current_state_id, p.current_state_label, p.current_state_colour, p.current_state_lookup_key, p.active,
			p.acquisition_dtm, p.disposal_dtm, p.lng, p.lat, tff.is_editable,
			mc.mgmt_company_id, NVL(mc.name, mgmt_company_other) mgmt_company_name, f.name fund_name, p.fund_id,
			cc.name member_name, sheet_status.total_sheets, sheet_status.total_overdue_sheets,
			NVL(photo_counts.number_of_photos, 0) number_of_photos,
			p.energy_star_sync, p.energy_star_push, -- raw energy star option flags
			p.energy_star_sync is_energy_star, DECODE(p.energy_star_sync, 0, 0, p.energy_star_push) is_energy_star_push, -- takes into account the sync flag being set to zero
			pg.asset_id gresb_asset_id
		  FROM v$property p
		  JOIN TABLE(v_temp_flow_filter) tff ON p.region_sid = tff.id
		  LEFT JOIN mgmt_company mc ON p.mgmt_company_id = mc.mgmt_company_id AND p.app_sid = mc.app_sid
		  LEFT JOIN fund f ON p.fund_id = f.fund_id AND p.app_sid = f.app_sid
		  LEFT JOIN property_gresb pg ON pg.region_sid = p.region_sid
		  LEFT JOIN chain.company cc ON p.company_sid = cc.company_sid AND p.app_sid = cc.app_sid
		  LEFT JOIN (
			-- Get total of sheets + overdue sheets for each region/property.
			SELECT COUNT(s.sheet_id) total_sheets, COUNT(CASE WHEN sla.status = 1 THEN 1 ELSE NULL END) total_overdue_sheets, dr.region_sid
			  FROM csr.sheet s
			  JOIN csr.delegation_region dr
				ON s.delegation_sid = dr.delegation_sid
			  JOIN csr.delegation d
				ON d.delegation_sid = dr.delegation_sid
			  JOIN csr.sheet_with_last_action sla
				ON sla.sheet_id = s.sheet_id
			  JOIN TABLE(v_temp_flow_filter) tff
				ON dr.region_sid = tff.id
			 WHERE s.is_visible = 1
			   AND d.start_dtm = v_period_start_dtm
			   AND d.end_dtm = v_period_end_dtm
			 GROUP BY dr.region_sid
		  ) sheet_status ON p.region_sid = sheet_status.region_sid
		  LEFT JOIN (
			SELECT property_region_sid, COUNT(property_photo_id) number_of_photos
			  FROM property_photo
			 WHERE space_region_sid IS NULL
			 GROUP BY property_region_sid
		  ) photo_counts ON p.region_sid = photo_counts.property_region_sid
		  ORDER BY p.description;

	OPEN out_roles FOR
		SELECT rrm.region_sid, rrm.role_Sid, rrm.user_sid, cu.csr_user_sid, cu.full_name, cu.email, cu.user_name, r.name role_name,
			CASE WHEN rrm.inherited_from_sid != region_sid THEN 1 ELSE 0 END is_inherited
		  FROM region_role_member rrm
		  JOIN TABLE(v_temp_flow_filter) tff ON rrm.region_sid = id
		  JOIN csr_user cu ON rrm.user_sid = cu.csr_user_sid AND rrm.app_sid = cu.app_sid
		  JOIN role r ON rrm.role_sid = r.role_sid AND rrm.app_sid = r.app_sid;
END;

PROCEDURE GetPropertyParentSid(
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_property_type_id		IN	property.property_type_id%TYPE DEFAULT NULL,
	in_property_sub_type_id	IN	property.property_sub_type_id%TYPE DEFAULT NULL,
	in_country_code			IN  region.geo_country%TYPE,
	in_state				IN	property.state%TYPE DEFAULT NULL,
	in_city					IN	property.city%TYPE DEFAULT NULL,
	out_region_sid			OUT	security_pkg.T_SID_Id
)
AS
	v_helper_pkg			property_options.property_helper_pkg%TYPE;
	v_did_execute_helper	NUMBER DEFAULT 0;
	v_country_name			postcode.country.name%TYPE;
	v_company_region_sid	security_pkg.T_SID_ID;
BEGIN
	BEGIN
		SELECT property_helper_pkg
		  INTO v_helper_pkg
		  FROM property_options
		 WHERE app_sid = security_pkg.GetApp;
	EXCEPTION
		WHEN no_data_found THEN
			null;
	END;

	IF v_helper_pkg IS NOT NULL THEN
		BEGIN
			EXECUTE IMMEDIATE 'begin '||v_helper_pkg||'.GetPropertyParentSid(:1,:2,:3,:4,:5,:6,:7);end;'
				USING in_company_sid, in_property_type_id, in_property_sub_type_id, in_country_code, in_state, in_city, OUT out_region_sid;

			v_did_execute_helper := 1;
		EXCEPTION
			WHEN PROC_NOT_FOUND THEN
				v_did_execute_helper := 0;
		END;
	END IF;

	IF v_did_execute_helper != 1 THEN

		-- our default policy is to create country nodes under the supplier
		SELECT region_sid
			INTO v_company_region_sid
			FROM supplier
			WHERE company_sid = NVL(in_company_sid, SYS_CONTEXT('SECURITY','CHAIN_COMPANY'));

		SELECT name
			INTO v_country_name
			FROM postcode.country
			WHERE country = in_country_code;

		BEGIN
			csr.region_pkg.createregion(
				in_parent_sid => v_company_region_sid,
				in_name => in_country_code,
				in_description => v_country_name,
				in_geo_type => csr.region_pkg.REGION_GEO_TYPE_COUNTRY,
				in_geo_country => in_country_code,
				in_apply_deleg_plans => 0,
				out_region_sid => out_region_sid
			);
		EXCEPTION
			WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
				SELECT sid_id
					INTO out_region_sid
					FROM security.securable_object
					WHERE parent_sid_id = v_company_region_sid
					AND LOWER(name) = LOWER(in_country_code);
		END;
	END IF;

END;

PROCEDURE INTERNAL_DidCreateProperty(
	in_region_sid			IN security_pkg.T_SID_ID,
	in_company_sid			IN security_pkg.T_SID_ID
)
AS
	v_flow_item_id			flow_item.flow_item_id%TYPE;
	v_doc_folder			security_pkg.T_SID_ID;
BEGIN
	-- bang in the company_sid
	UPDATE all_property
	   SET company_sid = in_company_sid
	 WHERE region_sid = in_region_sid;

	CreatePropertyDocLibFolder(
		in_property_sid				=> in_region_sid,
		out_folder_sid				=> v_doc_folder
	);

	-- add to workflow
	property_pkg.AddToFlow(in_region_sid, v_flow_item_id);

	INTERNAL_CallHelperPkg('PropertyCreated', in_region_sid);

	-- Create energy star jobs if required
	energy_star_job_pkg.OnRegionChange(in_region_sid);
END;

PROCEDURE CreateProperty(
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_parent_sid			IN  security_pkg.T_SID_ID DEFAULT NULL,
	in_description			IN	region_description.description%TYPE,
	in_region_ref			IN	region.region_ref%TYPE DEFAULT NULL,
	in_property_type_id		IN	property.property_type_id%TYPE DEFAULT NULL,
	in_property_sub_type_id	IN	property.property_sub_type_id%TYPE DEFAULT NULL,
	in_street_addr_1		IN	property.street_addr_2%TYPE	DEFAULT NULL,
	in_street_addr_2		IN	property.street_addr_2%TYPE DEFAULT NULL,
	in_city					IN	property.city%TYPE DEFAULT NULL,
	in_state				IN	property.state%TYPE DEFAULT NULL,
	in_country_code			IN  region.geo_country%TYPE,
	in_postcode				IN	property.postcode%TYPE DEFAULT NULL,
	in_geo_longitude		IN  region.geo_longitude%TYPE DEFAULT NULL,
	in_geo_latitude			IN  region.geo_latitude%TYPE DEFAULT NULL,
	in_acquisition_dtm		IN	region.acquisition_dtm%TYPE DEFAULT TRUNC(SYSDATE),
	out_region_sid			OUT security_pkg.T_SID_ID
)
AS
	v_geo_type 				region.geo_type%TYPE;
	v_parent_sid			security_pkg.T_SID_ID;
	v_egrid_ref				postcode_egrid.egrid_ref%TYPE := null;
BEGIN
	IF in_geo_longitude IS NOT NULL AND in_geo_latitude IS NOT NULL THEN
		v_geo_type := region_pkg.REGION_GEO_TYPE_LOCATION;
	ELSIF in_country_code IS NOT NULL THEN
        -- CreateRegion will get the geo properties from the parent and then overwrite them with the input parameters if not null
		v_geo_type := region_pkg.REGION_GEO_TYPE_COUNTRY;
    ELSE
        -- CreateRegion will get the geo properties from the parent and ignore the input parameters
		v_geo_type := region_pkg.REGION_GEO_TYPE_INHERITED;
	END IF;

	IF in_parent_sid IS NULL THEN
		GetPropertyParentSid(
			in_company_sid => in_company_sid,
			in_property_type_id => in_property_type_id,
			in_property_sub_type_id => in_property_sub_type_id,
			in_country_code => in_country_code,
			in_state => in_state,
			in_city => in_city,
			out_region_sid => v_parent_sid
		);
	END IF;

	IF in_country_code = 'us' THEN
		-- try to find the egrid subregion based on zip
		SELECT MIN(egrid_ref)
		  INTO v_egrid_ref
		  FROM postcode_egrid
		 WHERE country = in_country_code
		   AND postcode = in_postcode;
	END IF;

	region_pkg.CreateRegion(
		in_parent_sid => NVL(in_parent_sid, v_parent_sid),
		in_name =>  null,
		in_description => in_description,
		in_geo_country => in_country_code,
		in_geo_longitude => in_geo_longitude,
		in_geo_latitude => in_geo_latitude,
		in_geo_type => v_geo_type,
		in_egrid_ref => v_egrid_ref,
		in_region_ref => in_region_ref,
		in_acquisition_dtm => in_acquisition_dtm,
		out_region_sid => out_region_sid
	);

    SetProperty(
		in_region_sid => out_region_sid,
		in_description => in_description,
		in_property_type_id => in_property_type_id,
		in_property_sub_type_id => in_property_sub_type_id,
		in_street_addr_1 => in_street_addr_1,
		in_street_addr_2 => in_street_addr_2,
		in_city => in_city,
		in_state => in_state,
		in_country_code => in_country_code,
		in_postcode => in_postcode,
		in_region_ref => in_region_ref, -- double sets
		in_acquisition_dtm => in_acquisition_dtm  -- double sets
	);

	INTERNAL_DidCreateProperty(out_region_sid, in_company_sid);
END;

/**
 *	Converts a region into a property.
 *
 *	@param	in_is_create			A non-zero value causes the region to be inserted into the property
 *									workflow and create notifications to be sent to the appropriate helper
 *									packages. This should be set if the property is being made out of a new
 *									region, or a region that was not previously a property.
 */
PROCEDURE MakeProperty(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_company_sid			IN  security_pkg.T_SID_ID DEFAULT NULL,
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_property_type_id		IN	property.property_type_id%TYPE DEFAULT NULL,
	in_property_sub_type_id	IN	property.property_sub_type_id%TYPE DEFAULT NULL,
	in_street_addr_1		IN	property.street_addr_2%TYPE	DEFAULT NULL,
	in_street_addr_2		IN	property.street_addr_2%TYPE DEFAULT NULL,
	in_city					IN	property.city%TYPE DEFAULT NULL,
	in_state				IN	property.state%TYPE DEFAULT NULL,
	in_postcode				IN	property.postcode%TYPE DEFAULT NULL,
	in_is_create			IN	NUMBER
)
AS
	v_region_ref			region.region_ref%TYPE;
	v_acquisition_dtm		region.acquisition_dtm%TYPE;
	v_geo_country			region.geo_country%TYPE;
	v_description			region_description.description%TYPE;
	v_company_sid			security_pkg.T_SID_ID;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_region_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to property with sid '||in_region_sid);
	END IF;

	SELECT region_ref, acquisition_dtm, geo_country, description
	  INTO v_region_ref, v_acquisition_dtm, v_geo_country, v_description
	  FROM v$region
	 WHERE region_sid = in_region_sid;

	IF in_company_sid IS NULL THEN
		BEGIN
			SELECT company_sid
			  INTO v_company_sid
			  FROM property
			 WHERE region_sid = in_region_sid;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				NULL;
		END;
	END IF;

	SetProperty(
		in_region_sid => in_region_sid,
		in_description => v_description,
		in_property_type_id => in_property_type_id,
		in_property_sub_type_id => in_property_sub_type_id,
		in_street_addr_1 => in_street_addr_1,
		in_street_addr_2 => in_street_addr_2,
		in_city => in_city,
		in_state => in_state,
		in_country_code => v_geo_country,
		in_postcode => in_postcode,
		in_region_ref => v_region_ref,
		in_acquisition_dtm => v_acquisition_dtm
	);

	IF in_is_create = 1 THEN
		INTERNAL_DidCreateProperty(in_region_sid, NVL(in_company_sid, v_company_sid));
	END IF;
END;

PROCEDURE UnmakeProperty(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_region_type			IN	region.region_type%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_region_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to property with sid '||in_region_sid);
	END IF;

	-- Set region type to new type
	region_pkg.SetRegionType(in_region_sid, in_region_type);

	-- unmake spaces
	FOR r IN (
		SELECT * FROM all_space WHERE property_region_sid = in_region_sid
	) LOOP
		space_pkg.UnmakeSpace(in_act_id, r.region_sid, csr_data_pkg.REGION_TYPE_NORMAL);
	END LOOP;

	-- Create energy star jobs if required
	energy_star_job_pkg.OnRegionChange(in_region_sid);

END;

PROCEDURE SetMgmtCompany(
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_mgmt_company_id			IN  property.mgmt_company_id%TYPE,
	in_mgmt_company_other		IN  property.mgmt_company_other%TYPE DEFAULT NULL,
	in_mgmt_company_contact_id	IN  property.mgmt_company_contact_id%TYPE DEFAULT NULL
)
AS
	v_act	security_pkg.T_ACT_ID;
	CURSOR c IS
		SELECT p.app_sid, NVL(mgmt_company_other, mc.name) company_name, mcc.name contact_name
		  FROM property p
		  LEFT JOIN mgmt_company mc ON p.mgmt_company_id = mc.mgmt_company_id AND p.app_sid = mc.app_sid
		  LEFT JOIN mgmt_company_contact mcc ON p.mgmt_company_id = mcc.mgmt_company_id AND p.mgmt_company_contact_id = mcc.mgmt_company_contact_id AND p.app_sid = mcc.app_sid
		 WHERE region_sid = in_region_sid;
	r c%ROWTYPE;
	v_company_name		mgmt_company.name%TYPE;
	v_contact_name		mgmt_company_contact.name%TYPE;
BEGIN
	v_act := SYS_CONTEXT('SECURITY','ACT');

	-- security check
	IF NOT security_pkg.IsAccessAllowedSID(v_act, in_region_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the property with sid '||in_region_sid);
	END IF;

	OPEN c;
	FETCH c INTO r;
	CLOSE c;

	BEGIN
		SELECT name
			INTO v_company_name
			FROM mgmt_company
			WHERE mgmt_company_id = in_mgmt_company_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_company_name := null;
	END;

	BEGIN
		SELECT name
			INTO v_contact_name
			FROM mgmt_company_contact
			WHERE mgmt_company_id = in_mgmt_company_id
			  AND mgmt_company_contact_id = in_mgmt_company_contact_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_contact_name := null;
	END;

	csr_data_pkg.AuditValueChange(v_act, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid,
		in_region_sid, 'Management company', r.company_name, NVL(v_company_name, in_mgmt_company_other));

	csr_data_pkg.AuditValueChange(v_act, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid,
		in_region_sid, 'Management company contact', r.contact_name, v_contact_name);

	UPDATE all_property
		SET mgmt_company_id = in_mgmt_company_id,
			mgmt_company_other = in_mgmt_company_other,
			mgmt_company_contact_id = in_mgmt_company_contact_id
		WHERE region_sid = in_region_sid;

	INTERNAL_CallHelperPkg('PropMgmtCoUpdated', in_region_sid);
END;

PROCEDURE SetFund(
	in_region_sid	IN	security_pkg.T_SID_ID,
	in_name			IN  fund.name%TYPE,
	out_fund_id		OUT fund.fund_id%TYPE
)
AS
	v_company_sid  	security_pkg.T_SID_ID;
BEGIN
	SELECT NVL(p.company_sid, co.top_company_sid)
	  INTO v_company_sid
	  FROM property p
	  JOIN chain.customer_options co ON p.app_sid = co.app_sid
	 WHERE region_sid = in_region_sid;

	BEGIN
		INSERT INTO fund (fund_id, company_sid, name)
			VALUES (fund_id_seq.nextval, v_company_sid, in_name)
			RETURNING fund_id INTO out_fund_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			SELECT fund_id
			  INTO out_fund_id
			  FROM fund
			 WHERE company_sid = v_company_sid
			   AND UPPER(TRIM(name)) = UPPER(TRIM(in_name));
	END;

	-- this will do the security check
	SetFund(in_region_sid, out_fund_id);
END;

PROCEDURE SetFund(
	in_region_sid	IN	security_pkg.T_SID_ID,
	in_fund_id		IN  fund.fund_id%TYPE
)
AS
	v_act	security_pkg.T_ACT_ID;
	CURSOR c IS
		SELECT p.app_sid, f.name
		  FROM v$property p
		  LEFT JOIN fund f ON p.fund_id = f.fund_id AND p.app_sid = f.app_sid
		 WHERE p.region_sid = in_region_sid;
	r c%ROWTYPE;
	v_name		fund.name%TYPE;
BEGIN
	v_act := SYS_CONTEXT('SECURITY','ACT');

	-- security check
	IF NOT security_pkg.IsAccessAllowedSID(v_act, in_region_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the property with sid '||in_region_sid);
	END IF;

	OPEN c;
	FETCH c INTO r;
	CLOSE c;

	BEGIN
		SELECT name
		  INTO v_name
		  FROM fund
		 WHERE fund_id = in_fund_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_name := null;
	END;

	csr_data_pkg.AuditValueChange(v_act, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid,
		in_region_sid, 'Fund', r.name, v_name);

	ClearFundOwnership(in_region_sid);
	SetFundOwnership(
		in_region_sid				=> in_region_sid,
		in_fund_id					=> in_fund_id,
		in_ownership				=> 1,
		in_start_date				=> NULL
	);
END;


PROCEDURE SetProperty(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_description			IN	region_description.description%TYPE,
	in_property_type_id		IN	property.property_type_id%TYPE DEFAULT NULL,
	in_property_sub_type_id	IN	property.property_sub_type_id%TYPE DEFAULT NULL,
	in_street_addr_1		IN	property.street_addr_2%TYPE	DEFAULT NULL,
	in_street_addr_2		IN	property.street_addr_2%TYPE DEFAULT NULL,
	in_city					IN	property.city%TYPE DEFAULT NULL,
	in_state				IN	property.state%TYPE DEFAULT NULL,
	in_country_code			IN  region.geo_country%TYPE,
	in_postcode				IN	property.postcode%TYPE DEFAULT NULL,
	in_region_ref			IN  region.region_ref%TYPE DEFAULT NULL,
	in_acquisition_dtm		IN  region.acquisition_dtm%TYPE DEFAULT NULL
)
AS
	v_act	security_pkg.T_ACT_ID;

	CURSOR c IS
		SELECT r.app_sid, r.region_sid, r.active, r.region_ref, r.acquisition_dtm,  r.disposal_dtm,
			r.geo_type, r.info_xml, r.geo_country, r.geo_city_id, r.geo_region, r.map_entity, r.egrid_ref,
			p.street_addr_1, p.street_addr_2, p.city, p.state, p.postcode,
			p.property_type_id, pt.label property_type_label,
			p.property_sub_type_id, pst.label property_sub_type_label, r.description
		  FROM v$region r
			LEFT JOIN property p ON r.region_sid = p.region_sid AND p.app_sid = r.app_sid
			LEFT JOIN property_type pt ON p.property_type_id = pt.property_Type_id AND p.app_sid = pt.app_sid
			LEFT JOIN property_sub_type pst ON p.property_sub_type_id = pst.property_sub_Type_id AND p.app_sid = pst.app_sid
		 WHERE r.region_sid = in_region_sid;
	r c%ROWTYPE;

	v_property_type_label		property_type.label%TYPE;
	v_property_sub_type_label	property_sub_type.label%TYPE;
	v_property_sub_type_id		property_sub_type.property_sub_type_id%TYPE;
	v_egrid_ref					postcode_egrid.egrid_ref%TYPE := null;
	v_country_code				VARCHAR2(3) := in_country_code;
BEGIN
	v_act := SYS_CONTEXT('SECURITY','ACT');

	-- some security check
	IF NOT security_pkg.IsAccessAllowedSID(v_act, in_region_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the property with sid '||in_region_sid);
	END IF;

	OPEN c;
	FETCH c INTO r;
	IF c%NOTFOUND THEN
		-- nothing in region
		RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'Region Sid '||in_region_sid||' not found');
	END IF;

	BEGIN
		SELECT label
		  INTO v_property_type_label
		  FROM property_type
		 WHERE property_type_id = in_property_type_Id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_property_type_label := null;
	END;

	v_property_sub_type_Id := in_property_sub_type_id;
	BEGIN
		SELECT label
		  INTO v_property_sub_type_label
		  FROM property_sub_type
		 WHERE property_sub_type_id = v_property_sub_type_Id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_property_sub_type_label := null;
	END;

	IF in_property_type_Id != r.property_type_id AND r.property_type_id IS NOT NULL THEN
		-- if they've changed the property type (and it wasn't null before then we have to clear down the subtype)
		v_property_sub_type_label := null;
		v_property_sub_type_id := null;
	END IF;

	csr_data_pkg.AuditValueChange(v_act, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid,
		in_region_sid, 'Street address 1', r.street_addr_1, in_street_addr_1);
	csr_data_pkg.AuditValueChange(v_act, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid,
		in_region_sid, 'Street address 2', r.street_addr_2, in_street_addr_2);
	csr_data_pkg.AuditValueChange(v_act, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid,
		in_region_sid, 'City', r.city, in_city);
	csr_data_pkg.AuditValueChange(v_act, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid,
		in_region_sid, 'State', r.state, in_state);
	csr_data_pkg.AuditValueChange(v_act, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid,
		in_region_sid, 'Property type', r.property_type_label, v_property_type_label);
	csr_data_pkg.AuditValueChange(v_act, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid,
		in_region_sid, 'Property sub type', r.property_sub_type_label, v_property_sub_type_label);

	BEGIN
		INSERT INTO all_property (region_sid, street_addr_1, street_addr_2, city, state, postcode, property_type_id, property_sub_type_id)
			VALUES (in_region_sid, in_street_addr_1, in_street_addr_2, in_city, in_state, in_postcode, in_property_type_id, v_property_sub_type_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE all_space
			   SET property_type_id = in_property_type_id
			 WHERE property_region_sid = in_region_sid;

			UPDATE all_property
			   SET street_addr_1 = in_street_addr_1,
				street_addr_2 = in_street_addr_2,
				city = in_city,
				state = in_state,
				postcode = in_postcode,
				property_type_id = in_property_type_id,
				property_sub_type_id = in_property_sub_type_id
			 WHERE region_sid = in_region_sid;
	END;

	IF LENGTH(v_country_code) = 3 THEN
		-- convert ISO3 to ISO2
		SELECT country
		  INTO v_country_code
		  FROM postcode.country
		 WHERE iso3 = v_country_code;
	END IF;

	-- derive egrid from zip in US if the current egrid_ref is NOT set OR if the
	-- zip code has changed. We leave it the same otherwise as they might have
	-- manually changed this to something different on purpose
	IF v_country_code = 'us' AND (r.egrid_ref IS NULL OR r.postcode != in_postcode OR r.postcode IS NULL) THEN
		-- try to find the egrid subregion based on zip
		SELECT MIN(egrid_ref)
		  INTO v_egrid_ref
		  FROM postcode_egrid
		 WHERE country = v_country_code
		   AND postcode = in_postcode;
	END IF;

	-- Apply name change to the document library folder
	IF r.description != in_description THEN
		DECLARE
			v_doc_folder				security_pkg.T_SID_ID := GetDocLibFolder(in_region_sid);
		BEGIN
			IF v_doc_folder IS NOT NULL THEN
				securableobject_pkg.RenameSO(
					in_act_id			=> v_act,
					in_sid_id			=> v_doc_folder,
					in_object_name		=> FormatDocFolderName(in_description, in_region_sid)
				);
			END IF;
		END;
	END IF;

	region_pkg.AmendRegion(
		in_act_id			=> v_act,
		in_region_sid		=> in_region_sid,
		in_description		=> in_description,
		in_active			=> r.active,
		in_pos				=> 0,
		in_geo_type			=> NVL(r.geo_type, region_pkg.REGION_GEO_TYPE_COUNTRY),
		in_info_xml			=> r.info_xml,
		in_geo_country		=> v_country_code,
		in_geo_region		=> r.geo_region,
		in_geo_city			=> r.geo_city_Id,
		in_map_entity		=> r.map_entity,
		in_egrid_ref		=> NVL(v_egrid_ref, r.egrid_ref),
		in_region_ref		=> in_region_ref,
		in_acquisition_dtm	=> in_acquisition_dtm,
		in_disposal_dtm		=> r.disposal_Dtm,
		in_region_type		=> csr_data_pkg.REGION_TYPE_PROPERTY
	);

	INTERNAL_CallHelperPkg('PropertyUpdated', in_region_sid);

	-- Create energy star jobs if required
	energy_star_job_pkg.OnRegionChange(in_region_sid);

END;

PROCEDURE SetPropertyAndLocation(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_description			IN	region_description.description%TYPE,
	in_property_type_id		IN	property.property_type_id%TYPE DEFAULT NULL,
	in_property_sub_type_id	IN	property.property_sub_type_id%TYPE DEFAULT NULL,
	in_street_addr_1		IN	property.street_addr_2%TYPE	DEFAULT NULL,
	in_street_addr_2		IN	property.street_addr_2%TYPE DEFAULT NULL,
	in_city					IN	property.city%TYPE DEFAULT NULL,
	in_state				IN	property.state%TYPE DEFAULT NULL,
	in_country_code			IN  region.geo_country%TYPE,
	in_postcode				IN	property.postcode%TYPE DEFAULT NULL,
	in_region_ref			IN  region.region_ref%TYPE DEFAULT NULL,
	in_acquisition_dtm		IN  region.acquisition_dtm%TYPE DEFAULT NULL,
	in_latitude				IN	region.geo_latitude%TYPE DEFAULT NULL,
	in_longitude			IN	region.geo_longitude%TYPE DEFAULT NULL
)
AS
	v_act	security_pkg.T_ACT_ID;

	CURSOR c IS
		SELECT r.app_sid, r.region_sid, r.active, r.region_ref, r.acquisition_dtm,  r.disposal_dtm,
			r.geo_type, r.info_xml, r.geo_country, r.geo_city_id, r.geo_region, r.map_entity, r.egrid_ref,
			p.street_addr_1, p.street_addr_2, p.city, p.state, p.postcode,
			p.property_type_id, pt.label property_type_label,
			p.property_sub_type_id, pst.label property_sub_type_label, r.description
		  FROM v$region r
			LEFT JOIN property p ON r.region_sid = p.region_sid AND p.app_sid = r.app_sid
			LEFT JOIN property_type pt ON p.property_type_id = pt.property_Type_id AND p.app_sid = pt.app_sid
			LEFT JOIN property_sub_type pst ON p.property_sub_type_id = pst.property_sub_Type_id AND p.app_sid = pst.app_sid
		 WHERE r.region_sid = in_region_sid;
	r c%ROWTYPE;

	v_property_type_label		property_type.label%TYPE;
	v_property_sub_type_label	property_sub_type.label%TYPE;
	v_property_sub_type_id		property_sub_type.property_sub_type_id%TYPE;
	v_egrid_ref					postcode_egrid.egrid_ref%TYPE := null;
	v_country_code				VARCHAR2(3) := in_country_code;
	v_geo_type					region.geo_type%TYPE;
BEGIN
	v_act := SYS_CONTEXT('SECURITY','ACT');

	-- some security check
	IF NOT security_pkg.IsAccessAllowedSID(v_act, in_region_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the property with sid '||in_region_sid);
	END IF;

	OPEN c;
	FETCH c INTO r;
	IF c%NOTFOUND THEN
		-- nothing in region
		RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'Region Sid '||in_region_sid||' not found');
	END IF;

	BEGIN
		SELECT label
		  INTO v_property_type_label
		  FROM property_type
		 WHERE property_type_id = in_property_type_Id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_property_type_label := null;
	END;

	v_property_sub_type_Id := in_property_sub_type_id;
	BEGIN
		SELECT label
		  INTO v_property_sub_type_label
		  FROM property_sub_type
		 WHERE property_sub_type_id = v_property_sub_type_Id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_property_sub_type_label := null;
	END;

	IF in_property_type_Id != r.property_type_id AND r.property_type_id IS NOT NULL THEN
		-- if they've changed the property type (and it wasn't null before then we have to clear down the subtype)
		v_property_sub_type_label := null;
		v_property_sub_type_id := null;
	END IF;

	csr_data_pkg.AuditValueChange(v_act, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid,
		in_region_sid, 'Street address 1', r.street_addr_1, in_street_addr_1);
	csr_data_pkg.AuditValueChange(v_act, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid,
		in_region_sid, 'Street address 2', r.street_addr_2, in_street_addr_2);
	csr_data_pkg.AuditValueChange(v_act, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid,
		in_region_sid, 'City', r.city, in_city);
	csr_data_pkg.AuditValueChange(v_act, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid,
		in_region_sid, 'State', r.state, in_state);
	csr_data_pkg.AuditValueChange(v_act, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid,
		in_region_sid, 'Property type', r.property_type_label, v_property_type_label);
	csr_data_pkg.AuditValueChange(v_act, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid,
		in_region_sid, 'Property sub type', r.property_sub_type_label, v_property_sub_type_label);

	BEGIN
		INSERT INTO all_property (region_sid, street_addr_1, street_addr_2, city, state, postcode, property_type_id, property_sub_type_id)
			VALUES (in_region_sid, in_street_addr_1, in_street_addr_2, in_city, in_state, in_postcode, in_property_type_id, v_property_sub_type_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE all_space
			   SET property_type_id = in_property_type_id
			 WHERE property_region_sid = in_region_sid;

			UPDATE all_property
			   SET street_addr_1 = in_street_addr_1,
				street_addr_2 = in_street_addr_2,
				city = in_city,
				state = in_state,
				postcode = in_postcode,
				property_type_id = in_property_type_id,
				property_sub_type_id = in_property_sub_type_id
			 WHERE region_sid = in_region_sid;
	END;

	v_geo_type := NVL(r.geo_type, region_pkg.REGION_GEO_TYPE_COUNTRY);

	IF LENGTH(v_country_code) > 0 THEN
		v_geo_type := region_pkg.REGION_GEO_TYPE_COUNTRY;
	END IF;

	IF LENGTH(v_country_code) = 3 THEN
		-- convert ISO3 to ISO2
		SELECT country
		  INTO v_country_code
		  FROM postcode.country
		 WHERE iso3 = v_country_code;
	END IF;

	-- derive egrid from zip in US if the current egrid_ref is NOT set OR if the
	-- zip code has changed. We leave it the same otherwise as they might have
	-- manually changed this to something different on purpose
	IF v_country_code = 'us' AND (r.egrid_ref IS NULL OR r.postcode != in_postcode OR r.postcode IS NULL) THEN
		-- try to find the egrid subregion based on zip
		SELECT MIN(egrid_ref)
		  INTO v_egrid_ref
		  FROM postcode_egrid
		 WHERE country = v_country_code
		   AND postcode = in_postcode;
	END IF;

	-- Apply name change to the document library folder
	IF r.description != in_description THEN
		DECLARE
			v_doc_folder				security_pkg.T_SID_ID := GetDocLibFolder(in_region_sid);
		BEGIN
			IF v_doc_folder IS NOT NULL THEN
				securableobject_pkg.RenameSO(
					in_act_id			=> v_act,
					in_sid_id			=> v_doc_folder,
					in_object_name		=> FormatDocFolderName(in_description, in_region_sid)
				);
			END IF;
		END;
	END IF;

	region_pkg.AmendRegion(
		in_act_id			=> v_act,
		in_region_sid		=> in_region_sid,
		in_description		=> in_description,
		in_active			=> r.active,
		in_pos				=> 0,
		in_geo_type			=> v_geo_type,
		in_info_xml			=> r.info_xml,
		in_geo_country		=> v_country_code,
		in_geo_region		=> r.geo_region,
		in_geo_city			=> r.geo_city_Id,
		in_map_entity		=> r.map_entity,
		in_egrid_ref		=> NVL(v_egrid_ref, r.egrid_ref),
		in_region_ref		=> in_region_ref,
		in_acquisition_dtm	=> in_acquisition_dtm,
		in_disposal_dtm		=> r.disposal_Dtm,
		in_region_type		=> csr_data_pkg.REGION_TYPE_PROPERTY
	);

	IF in_country_code IS NULL
		OR LENGTH(in_country_code) = 0
		OR (in_latitude IS NOT NULL AND in_longitude IS NOT NULL)
	THEN
		region_pkg.SetLatLong(in_region_sid, in_latitude, in_longitude);
	END IF;

	INTERNAL_CallHelperPkg('PropertyUpdated', in_region_sid);

	-- Create energy star jobs if required
	energy_star_job_pkg.OnRegionChange(in_region_sid);

END;

PROCEDURE SetPropertyAddress (
	in_region_sid					IN	security_pkg.T_SID_ID,
	in_street_addr_1				IN	property.street_addr_2%TYPE	DEFAULT NULL,
	in_street_addr_2				IN	property.street_addr_2%TYPE DEFAULT NULL,
	in_city							IN	property.city%TYPE DEFAULT NULL,
	in_state						IN	property.state%TYPE DEFAULT NULL,
	in_country_code					IN  region.geo_country%TYPE,
	in_postcode						IN	property.postcode%TYPE DEFAULT NULL,
	in_latitude						IN	region.geo_latitude%TYPE,
	in_longitude					IN	region.geo_longitude%TYPE
)
AS
	v_description					region_description.description%TYPE;
	v_property_type_id				all_property.property_type_id%TYPE;
	v_property_sub_type_id			all_property.property_sub_type_id%TYPE;
	v_region_ref					region.region_ref%TYPE;
	v_acquisition_dtm				region.acquisition_dtm%TYPE;
BEGIN
	-- Security check handled by SetProperty

	SELECT description, property_type_id, property_sub_type_id, region_ref, acquisition_dtm
	  INTO v_description, v_property_type_id, v_property_sub_type_id, v_region_ref, v_acquisition_dtm
	  FROM v$property
	 WHERE region_sid = in_region_sid;

	-- not named params as we don't want any new ones to default null and wipe out data
	SetProperty(
			in_region_sid, v_description, v_property_type_id, v_property_sub_type_id,
			in_street_addr_1, in_street_addr_2, in_city, in_state, in_country_code,
			in_postcode, v_region_ref, v_acquisition_dtm
	);

	IF in_country_code IS NULL
		OR LENGTH(in_country_code) = 0
		OR (in_latitude IS NOT NULL AND in_longitude IS NOT NULL)
	THEN
		region_pkg.SetLatLong(in_region_sid, in_latitude, in_longitude);
	END IF;
END;

PROCEDURE SetFlowState(
	in_region_sids 		IN 	security_pkg.T_SID_IDS,
	in_to_state_Id		IN	flow_state.flow_state_id%TYPE,
	in_comment_text		IN	flow_state_log.comment_text%TYPE,
	in_cache_keys		IN	security_pkg.T_VARCHAR2_ARRAY
)
AS
	t_region_sids			security.T_SID_TABLE;
BEGIN
	-- TODO: DO SOME KIND OF PERMISSION CHECK!!!

	t_region_sids := security_pkg.SidArrayToTable(in_region_sids);

	FOR r IN (
		SELECT fi.flow_item_id
		  FROM TABLE(t_region_sids) r
		  JOIN property p ON r.column_value = p.region_sid
		  JOIN flow_item fi ON p.flow_item_id = fi.flow_item_id
	)
	LOOP
		-- yikes - potential for uploading loads of the same file?
		-- TODO: optimise FLOW_STATE_LOG_FILE to share file data based on SHA1
		flow_pkg.SetItemState(
			in_flow_item_id => r.flow_item_id,
			in_to_state_id => in_to_state_id,
			in_comment_text => in_comment_text,
			in_cache_keys => in_cache_keys
		);
	END LOOP;

END;


PROCEDURE SetFlowState(
	in_region_sid 		IN 	security_pkg.T_SID_ID,
	in_flow_item_id		IN	flow_item.flow_item_id%TYPE,
	in_to_state_Id		IN	flow_state.flow_state_id%TYPE,
	in_comment_text		IN	flow_state_log.comment_text%TYPE,
	in_cache_keys		IN	security_pkg.T_VARCHAR2_ARRAY,
	out_property 		OUT SYS_REFCURSOR,
	out_transitions		OUT SYS_REFCURSOR
)
AS
	v_cnt 	NUMBER(10);
	v_temp_flow_filter			T_FLOW_FILTER_DATA_TABLE;
BEGIN
	-- TODO: DO SOME KIND OF PERMISSION CHECK!!!

	-- just check flow item id and region match
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM property p
		JOIN flow_item fi ON p.flow_item_id = fi.flow_item_id
	 WHERE p.flow_item_id = in_flow_item_id
	   AND p.region_sid = in_region_sid;

	IF v_cnt = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Mismatched region_sid and flow_item_id');
	END IF;

	flow_pkg.SetItemState(
		in_flow_item_id => in_flow_item_id,
		in_to_state_id => in_to_state_id,
		in_comment_text => in_comment_text,
		in_cache_keys => in_cache_keys
	);

	-- dump IDs into array
	INSERT INTO temp_flow_filter (id, is_editable)
		SELECT region_sid, MAX(is_editable)
		  FROM v$my_property
		 WHERE region_sid = in_region_sid
		 GROUP BY region_sid;

	SELECT T_FLOW_FILTER_DATA_ROW(tff.id, tff.is_editable)
	  BULK COLLECT INTO v_temp_flow_filter
	  FROM temp_flow_filter tff;

	OPEN out_property FOR
		SELECT p.current_state_id, p.current_state_label, p.current_state_colour,
			p.current_state_lookup_key, tff.is_editable
		  FROM v$property p
		  JOIN TABLE(v_temp_flow_filter) tff ON p.region_sid = tff.id;

	property_pkg.GetTransitions(in_region_sid, out_transitions);
END;

/**
 * This returns all properties where you can actively do something in the workflow
 */
PROCEDURE GetPropertiesNeedingAttn(
	out_summary			OUT  SYS_REFCURSOR,
	out_properties 		OUT  SYS_REFCURSOR,
	out_findings		OUT  SYS_REFCURSOR
)
AS
BEGIN
	-- uses v$my_property so no security needed
	OPEN out_summary FOR
		SELECT current_state_id, COUNT(DISTINCT region_sid) cnt
		  FROM v$my_property
		 WHERE active = 1
		 GROUP BY current_state_id, current_state_label, current_state_lookup_key, current_state_colour;

	-- no security needed as it uses the user_sid in the query
	OPEN out_properties FOR
		SELECT x.region_sid, r.description, r.region_ref, x.flow_item_id, x.current_state_id, x.current_state_lookup_key, x.label, x.state_colour,
			fsl.set_by_user_sid, cu.full_name, cu.email, cu.user_name, fsl.set_dtm, last_flow_state_log_id,
			CASE WHEN x.last_flow_state_transition_id IS NULL THEN 1 ELSE 0 END not_yet_submitted,
			valid_transition_ids
		  FROM (
			SELECT p.region_sid, fi.flow_item_id, fi.current_state_id, fs.lookup_key current_state_lookup_key, fs.label, fs.state_colour, fi.last_flow_state_transition_id,
				fi.last_flow_state_log_id, p.app_sid, STRAGG(fst.flow_state_transition_id) valid_transition_ids
			  FROM property p
				JOIN flow_item fi ON p.flow_item_id = fi.flow_item_id AND p.app_sid = fi.app_sid
				JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id AND fi.flow_sid = fs.flow_sid AND fi.app_sid = fs.app_sid
				JOIN flow_state_transition fst ON fs.flow_state_id = fst.from_state_id AND fs.flow_sid = fst.flow_sid AND fs.app_sid = fst.app_sid
				JOIN flow_state_transition_role fstr
					ON fst.flow_state_transition_id = fstr.flow_state_transition_id
					AND fst.from_state_id = fstr.from_state_id
					AND fst.app_sid = fstr.app_sid
				JOIN role r on fstr.role_sid = r.role_sid AND fstr.app_sid = r.app_sid
				JOIN region rg ON p.app_sid = rg.app_sid AND p.region_sid = rg.region_sid
				JOIN region_role_member rrm
					ON fstr.role_sid = rrm.role_sid
					AND p.app_sid = rrm.app_sid
					AND p.region_sid = rrm.region_sid
					AND rrm.user_sid = SYS_CONTEXT('SECURITY','SID')
				WHERE rg.active = 1
			  GROUP BY p.region_sid, fi.flow_item_id, fi.current_state_id, fs.lookup_key, fs.label, fs.state_colour, fi.last_flow_state_transition_id,
				fi.last_flow_state_log_id, p.app_sid
			 )x
			 JOIN flow_state_log fsl ON x.flow_item_id = fsl.flow_item_id AND x.last_flow_state_log_id = fsl.flow_state_log_id AND x.app_sid = fsl.app_sid
			 JOIN csr_user cu ON fsl.set_by_user_sid = cu.csr_user_sid AND fsl.app_sid = cu.app_sid
			 JOIN v$region r ON x.region_sid = r.region_sid AND x.app_sid = r.app_sid
			ORDER BY current_state_id, description;

	-- uses v$my_property so no security needed
	OPEN out_findings FOR
		SELECT rsf.region_sid,
			SUM(case when explained_dtm is null then 1 else 0 end) unexplained_cnt,
			SUM(case when explained_dtm is not null then 1 else 0 end) explained_cnt,
			SUM(case when approved_dtm is not null then 1 else 0 end) approved_cnt
		  FROM ruleset rs
			JOIN customer c ON rs.app_sid = c.app_sid AND c.current_reporting_period_sid = rs.reporting_period_sid
			JOIN ruleset_run_finding rsf ON rs.ruleset_sid = rsf.ruleset_sid
		 WHERE rsf.region_sid IN (
			SELECT region_sid FROM v$my_property
		 )
		   AND is_currently_valid = 1
		 GROUP BY rsf.region_sid;
END;

PROCEDURE Validate(
	in_region_sid 				IN   security_pkg.T_SID_ID,
	in_reporting_period_sid		IN   security_pkg.T_SID_ID,
	out_findings_cur			OUT  SYS_REFCURSOR,
	out_mandatory_spaces_cur	OUT  SYS_REFCURSOR,
	out_mandatory_build_cur		OUT  SYS_REFCURSOR
)
AS
	v_period_end_dtm		DATE;
BEGIN
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading meter sid '||in_region_sid);
	END IF;

	SELECT end_dtm
	  INTO v_period_end_dtm
	  FROM reporting_period
	 WHERE reporting_period_sid = in_reporting_period_sid;

	OPEN out_findings_cur FOR
		-- rulesets at property level
		SELECT rrf.label
		  FROM ruleset_run_finding rrf
		  JOIN ruleset r ON rrf.ruleset_sid = r.ruleset_sid AND rrf.app_sid = r.app_sid
		 WHERE rrf.is_currently_valid = 1
		   AND rrf.region_sid = in_region_sid
		   AND explanation IS NULL
		   AND r.enabled = 1
		   AND r.reporting_period_sid = in_reporting_period_sid;

	OPEN out_mandatory_spaces_cur FOR
		-- spaces with null data
		SELECT s.region_sid, r.description space_description, rm.ind_sid, i.description ind_description
		  FROM v$region r
		  JOIN space s on r.region_sid = s.region_sid
		  JOIN space_type_region_metric strm ON s.space_type_Id = strm.space_type_id
		  JOIN region_metric rm
			ON strm.ind_sid = rm.ind_sid AND strm.app_sid = rm.app_sid
			AND rm.is_mandatory = 1
		  JOIN v$ind i ON rm.ind_sid = i.ind_sid AND rm.app_sid = i.app_sid
		  LEFT JOIN region_metric_val rmv ON rm.ind_sid = rmv.ind_sid AND r.region_sid = rmv.region_sid AND rm.app_sid = rmv.app_sid
			--AND effective_dtm < v_period_end_dtm
		 WHERE r.region_sid IN (
			SELECT region_sid
			  FROM region
			 WHERE active = 1
			 START WITH region_sid = in_region_sid
		   CONNECT BY PRIOR region_sid = parent_sid
		 )
		 GROUP BY s.region_sid, r.description, i.description, rm.ind_sid
		 HAVING MAX(rmv.entered_dtm) IS NULL
		 ORDER BY r.description, i.description;

	OPEN out_mandatory_build_cur FOR
		-- building metrics with null data
		SELECT i.ind_sid, i.description, r.region_sid
		  FROM region r
		  JOIN region_type_metric rtm ON r.region_type = rtm.region_type AND r.app_sid = rtm.app_sid
			AND r.region_type = csr_data_pkg.REGION_TYPE_PROPERTY
		  JOIN region_metric rm ON rtm.ind_sid = rm.ind_sid AND rtm.app_sid = rm.app_sid
			AND rm.is_mandatory = 1
		  JOIN v$ind i ON rm.ind_sid = i.ind_sid AND rm.app_sid = i.app_sid
		  LEFT JOIN region_metric_val rmv ON rm.ind_sid = rmv.ind_sid AND r.region_sid = rmv.region_sid AND rm.app_sid = rmv.app_sid
			--AND effective_dtm < v_period_end_dtm -- HACK TO ALLOW 2013 data for Greenprint - revert
		 WHERE r.region_sid IN (
			SELECT region_sid
			  FROM region
			 WHERE active = 1
			 START WITH region_sid = in_region_sid
		   CONNECT BY PRIOR region_sid = parent_sid
		 )
		 GROUP BY i.ind_sid, i.description, r.region_sid
		 HAVING MAX(rmv.entered_dtm) IS NULL
		 ORDER BY i.description;
END;


PROCEDURE GetPropertyTabs (
	out_cur					OUT SYS_REFCURSOR,
	out_restrict_to_types	OUT SYS_REFCURSOR
)
AS
BEGIN
	-- TODO: Extend this to check tab group role sid against region role member for the property
	-- if we need to lock down by role (but keep this version for the Rest API)
	OPEN out_cur FOR
		SELECT p.plugin_id, p.plugin_type_id, p.cs_class, p.js_include, p.js_class, pt.tab_label, pt.pos,
			   p.tab_sid, p.form_path, p.group_key, p.control_lookup_keys, p.portal_sid, pd.portal_group,
			   p.use_reporting_period, p.saved_filter_sid, p.result_mode, p.form_sid, p.pre_filter_sid
		  FROM plugin p
	 LEFT JOIN portal_dashboard pd ON pd.portal_sid = p.portal_sid
		  JOIN property_tab pt ON p.plugin_id = pt.plugin_id
		  JOIN property_tab_group ptg ON pt.plugin_id = ptg.plugin_id
		  JOIN TABLE(act_pkg.GetUsersAndGroupsInACT(security_pkg.GetACT)) y
			ON ptg.group_sid = y.column_value
		 GROUP BY p.plugin_id, p.plugin_type_id, p.cs_class, p.js_include, p.js_class, pt.tab_label, pt.pos,
			   p.tab_sid, p.form_path, p.group_key, p.control_lookup_keys, p.portal_sid, pd.portal_group,
			   p.use_reporting_period, p.saved_filter_sid, p.result_mode, p.form_sid, p.pre_filter_sid
		 ORDER BY pt.pos;

	OPEN out_restrict_to_types FOR
		SELECT ptpt.property_type_id, ptpt.plugin_id
		  FROM prop_type_prop_tab ptpt;
END;

PROCEDURE SavePropertyTab (
	in_plugin_id					IN  property_tab.plugin_id%TYPE,
	in_tab_label					IN  property_tab.tab_label%TYPE,
	in_pos							IN  property_tab.pos%TYPE,
	in_restrict_to_prop_type_ids	IN	security_pkg.T_SID_IDS,
	out_cur							OUT security_pkg.T_OUTPUT_CUR,
	out_restrict_to_types			OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_pos 							property_tab.pos%TYPE;
	v_tab_sid						security_pkg.T_SID_ID;
	v_issue_plugin_id				plugin.plugin_id%TYPE;
	v_issue_filter_card_id			chain.card.card_id%TYPE;
	v_prop_type_ids_table			security.T_SID_TABLE;
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can add/update property tabs.');
	END IF;

	v_pos := in_pos;
	v_prop_type_ids_table := security_pkg.SidArrayToTable(in_restrict_to_prop_type_ids);

	IF in_pos < 0 THEN
		SELECT NVL(max(pos) + 1, 1)
		  INTO v_pos
		  FROM property_tab;
	END IF;

	BEGIN
		INSERT INTO property_tab (plugin_type_id, plugin_id, pos, tab_label)
			VALUES (csr_data_pkg.PLUGIN_TYPE_PROPERTY_TAB, in_plugin_id, v_pos, in_tab_label);

		-- default access
		INSERT INTO csr.property_tab_group (plugin_id, group_sid)
			 VALUES (in_plugin_id, security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'groups/RegisteredUsers'));

		-- Enable the Issues filter if we have just added the Issues Tab.
		SELECT plugin_id
		  INTO v_issue_plugin_id
		  FROM plugin
		 WHERE js_class = 'Controls.IssuesPanel';

		IF v_issue_plugin_id = in_plugin_id THEN
			SELECT card_id
			  INTO v_issue_filter_card_id
			  FROM chain.card
			 WHERE js_class_type = 'Credit360.Property.Filters.PropertyIssuesFilter';

			BEGIN
				INSERT INTO chain.card_group_card (card_group_id, card_id, position)
				SELECT chain.filter_pkg.FILTER_TYPE_PROPERTY, v_issue_filter_card_id, MAX(position) + 1
				  FROM chain.card_group_card
				 WHERE app_sid = security_pkg.GetApp
				   AND card_group_id = chain.filter_pkg.FILTER_TYPE_PROPERTY;
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					-- Do nothing - card might've been added already.
					NULL;
			END;
		END IF;

		SELECT tab_sid
		  INTO v_tab_sid
		  FROM plugin
		 WHERE plugin_id = in_plugin_id;

		IF v_tab_sid IS NOT NULL THEN
			UPDATE cms.tab
			   SET show_in_property_filter = 1
			 WHERE tab_sid = v_tab_sid;
		END IF;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE property_tab
			   SET tab_label = in_tab_label,
				   pos = v_pos
			 WHERE plugin_id = in_plugin_id;
	END;

	-- Trash existing restrictions to catch those that have
	-- since been removed for this tab.
	DELETE FROM prop_type_prop_tab
	 WHERE app_sid = security.security_pkg.GetApp
	   AND plugin_id = in_plugin_id;

	INSERT INTO prop_type_prop_tab(property_type_id, plugin_id)
	SELECT p.column_value, in_plugin_id
	  FROM TABLE(v_prop_type_ids_table) p;

	OPEN out_cur FOR
		SELECT p.plugin_id, p.plugin_type_id, p.cs_class, p.js_include, p.js_class, p.description,
			   p.details, p.preview_image_path, pt.pos, pt.tab_label
		  FROM plugin p
		  JOIN property_tab pt ON p.plugin_id = pt.plugin_id
		 WHERE pt.plugin_id = in_plugin_id;

	OPEN out_restrict_to_types FOR
		SELECT ptpt.property_type_id, ptpt.plugin_id
		  FROM prop_type_prop_tab ptpt
		 WHERE ptpt.plugin_id = in_plugin_id;

END;

PROCEDURE RemovePropertyTab(
	in_plugin_id					IN  property_tab.plugin_id%TYPE
)
AS
	v_tab_sid						security_pkg.T_SID_ID;
	v_issue_plugin_id				plugin.plugin_id%TYPE;
	v_issue_filter_card_id			chain.card.card_id%TYPE;
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can modify property plugins');
	END IF;

	SELECT tab_sid
	  INTO v_tab_sid
	  FROM plugin
	 WHERE plugin_id = in_plugin_id;

	IF v_tab_sid IS NOT NULL THEN
		UPDATE cms.tab
		   SET show_in_property_filter = 0
		 WHERE tab_sid = v_tab_sid;
	END IF;

	DELETE FROM property_tab_group
	 WHERE plugin_id = in_plugin_id
	   AND app_sid = security_pkg.GetApp;

	DELETE FROM prop_type_prop_tab
	 WHERE plugin_id = in_plugin_id
	   AND app_sid = security_pkg.GetApp;

	DELETE FROM property_tab
	 WHERE plugin_id = in_plugin_id
	   AND app_sid = security_pkg.GetApp;

	-- Disable the Issues filter if we have just removed the Issues Tab.
	SELECT plugin_id
	  INTO v_issue_plugin_id
	  FROM plugin
	 WHERE js_class = 'Controls.IssuesPanel';

	IF v_issue_plugin_id = in_plugin_id THEN
		SELECT card_id
		  INTO v_issue_filter_card_id
		  FROM chain.card
		 WHERE js_class_type = 'Credit360.Property.Filters.PropertyIssuesFilter';

		DELETE FROM chain.card_group_card
		 WHERE app_sid = security_pkg.GetApp
		   AND card_id = v_issue_filter_card_id;
	END IF;
END;

PROCEDURE SaveTenant(
	in_tenant_id	IN	tenant.tenant_id%TYPE,
	in_tenant_name	IN	tenant.name%TYPE,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_tenant_id		tenant.tenant_id%TYPE;
BEGIN
	-- TODO - Security check?

	-- If we've not been given a tennant ID,
	-- we must be adding. Otherwise, update.
	IF NVL(in_tenant_id, -1) =-1 THEN
		INSERT INTO tenant(tenant_id, name)
		VALUES(tenant_id_seq.NEXTVAL, in_tenant_name)
		RETURNING tenant_id INTO v_tenant_id;
	ELSE
		UPDATE tenant
		   SET name = in_tenant_name
		 WHERE tenant_id = in_tenant_id;

		 v_tenant_id := in_tenant_id;
	END IF;

	OPEN out_cur FOR
		SELECT tenant_id, name
		  FROM tenant
		 WHERE tenant_id = v_tenant_id;
END;

PROCEDURE DeleteLease(
	in_lease_id				IN lease.lease_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can delete tenants');
	END IF;

	FOR r IN (
		SELECT region_sid
		  FROM space
		 WHERE current_lease_id = in_lease_id
		   AND app_sid = security_pkg.GetApp
	) LOOP
		UPDATE all_space
		   SET current_lease_id = null
		 WHERE region_sid = r.region_sid
		   AND app_sid = security_pkg.GetApp;

		INTERNAL_CallHelperPkg('SpaceLeaseUpdated', r.region_sid);
	END LOOP;

	DELETE FROM lease_space
	 WHERE lease_id = in_lease_id
	   AND app_sid = security_pkg.GetApp;

	UPDATE all_property
	   SET current_lease_id = null
	 WHERE current_lease_id = in_lease_id
	   AND app_sid = security_pkg.GetApp;

	DELETE FROM lease_property
	 WHERE lease_id = in_lease_id
	   AND app_sid = security_pkg.GetApp;

	DELETE FROM lease
	  WHERE lease_id = in_lease_id
		AND app_sid = security_pkg.GetApp;
END;

PROCEDURE DeleteTenant(
	in_tenant_id	IN	tenant.tenant_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can delete tenants');
	END IF;

	-- Delete any leases associated with the given tenant.
	FOR r IN (
		SELECT lease_id
		  FROM lease
		 WHERE tenant_id = in_tenant_id
		   AND app_sid = security_pkg.GetApp
	) LOOP
		DeleteLease(r.lease_id);
	END LOOP;

	DELETE FROM tenant
	 WHERE tenant_id = in_tenant_id
	   AND app_sid = security_pkg.GetApp;
END;

PROCEDURE GetTenants(
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetTenantByName(null, out_cur);
END;

PROCEDURE GetTenantByName(
	in_tenant_name			IN  tenant.name%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- TODO - Security check?

	OPEN out_cur FOR
		SELECT tenant_id, name
		  FROM tenant
		 WHERE name = NVL(in_tenant_name, name)
		 ORDER BY tenant_id ASC;
END;

PROCEDURE SaveFundType(
	in_fund_type_id		IN	fund_type.fund_type_id%TYPE,
	in_fund_type_label	IN	fund_type.label%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_fund_type_id		fund_type.fund_type_id%TYPE;
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can delete fund types');
	END IF;

	-- If we've not been given a fund type ID,
	-- we must be adding. Otherwise, update.
	IF NVL(in_fund_type_id, -1) =-1 THEN
		INSERT INTO fund_type(fund_type_id, label)
		VALUES(fund_type_id_seq.NEXTVAL, in_fund_type_label)
		RETURNING fund_type_id INTO v_fund_type_id;
	ELSE
		UPDATE fund_type
		   SET label = in_fund_type_label
		 WHERE fund_type_id = in_fund_type_id;

		 v_fund_type_id := in_fund_type_id;
	END IF;

	OPEN out_cur FOR
		SELECT fund_type_id, label
		  FROM fund_type
		 WHERE fund_type_id = v_fund_type_id;
END;

PROCEDURE DeleteFundType(
	in_fund_type_id	IN	fund_type.fund_type_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can delete fund types');
	END IF;

	DELETE FROM fund_type
	 WHERE fund_type_id = in_fund_type_id
	   AND app_sid = security_pkg.GetApp;
END;

PROCEDURE GetFundTypes(
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- TODO - Security check?

	OPEN out_cur FOR
		SELECT fund_type_id, label
		  FROM fund_type
		 ORDER BY fund_type_id ASC;
END;

PROCEDURE SaveManagementCompany(
	in_mgmt_company_id		IN	mgmt_company.mgmt_company_id%TYPE,
	in_mgmt_company_name	IN	mgmt_company.name%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_mgmt_company_id		mgmt_company.mgmt_company_id%TYPE;
	v_company_sid			mgmt_company.company_sid%TYPE;
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can delete management companies');
	END IF;

	v_company_sid := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');

	-- If we've not been given a management company ID,
	-- we must be adding. Otherwise, update.
	IF NVL(in_mgmt_company_id, -1) =-1 THEN
		INSERT INTO mgmt_company(mgmt_company_id, name, company_sid)
		VALUES(mgmt_company_id_seq.NEXTVAL, in_mgmt_company_name, v_company_sid)
		RETURNING mgmt_company_id INTO v_mgmt_company_id;
	ELSE
		UPDATE mgmt_company
		   SET name = in_mgmt_company_name
		 WHERE mgmt_company_id = in_mgmt_company_id;

		 v_mgmt_company_id := in_mgmt_company_id;
	END IF;

	OPEN out_cur FOR
		SELECT mgmt_company_id, name, company_sid
		  FROM mgmt_company
		 WHERE mgmt_company_id = v_mgmt_company_id;
END;

PROCEDURE DeleteManagementCompany(
	in_mgmt_company_id	IN	mgmt_company.mgmt_company_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can delete management companies');
	END IF;

	DELETE FROM mgmt_company_contact
	 WHERE mgmt_company_id = in_mgmt_company_id
	   AND app_sid = security_pkg.GetApp;

	DELETE FROM mgmt_company
	 WHERE mgmt_company_id = in_mgmt_company_id
	   AND app_sid = security_pkg.GetApp;
END;

PROCEDURE GetManagementCompany(
	in_mgmt_company_id				IN	mgmt_company.mgmt_company_id%TYPE,
	out_mgmt_company_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_mgmt_company_contacts_cur	OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- TODO - Security check?

	OPEN out_mgmt_company_cur FOR
		SELECT mgmt_company_id, name, company_sid
		  FROM mgmt_company
		 WHERE mgmt_company_id = in_mgmt_company_id;

	OPEN out_mgmt_company_contacts_cur FOR
		SELECT mgmt_company_contact_id, name, email, phone, mgmt_company_id
		  FROM mgmt_company_contact
		 WHERE mgmt_company_id = in_mgmt_company_id;
END;

PROCEDURE GetManagementCompanies(
	out_mgmt_companies_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_mgmt_company_contacts_cur	OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- TODO - Security check?

	OPEN out_mgmt_companies_cur FOR
		SELECT mgmt_company_id, name, company_sid
		  FROM mgmt_company
		 ORDER BY mgmt_company_id ASC;

	OPEN out_mgmt_company_contacts_cur FOR
		SELECT mgmt_company_contact_id, name, email, phone, mgmt_company_id
		  FROM mgmt_company_contact
		  ORDER BY mgmt_company_id ASC, mgmt_company_contact_id ASC;
END;

PROCEDURE SaveManagementCompanyContact(
	in_mgmt_company_id				IN	mgmt_company_contact.mgmt_company_id%TYPE,
	in_mgmt_company_contact_id		IN	mgmt_company_contact.mgmt_company_contact_id%TYPE,
	in_mgmt_company_contact_name	IN  mgmt_company_contact.name%TYPE,
	in_mgmt_company_contact_email	IN  mgmt_company_contact.email%TYPE,
	in_mgmt_company_contact_phone	IN  mgmt_company_contact.phone%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	SaveManagementCompanyContact(
		in_mgmt_company_id,
		in_mgmt_company_contact_id,
		in_mgmt_company_contact_name,
		in_mgmt_company_contact_email,
		in_mgmt_company_contact_phone,
		0,
		out_cur);
END;

PROCEDURE SaveManagementCompanyContact(
	in_mgmt_company_id				IN	mgmt_company_contact.mgmt_company_id%TYPE,
	in_mgmt_company_contact_id		IN	mgmt_company_contact.mgmt_company_contact_id%TYPE,
	in_mgmt_company_contact_name	IN  mgmt_company_contact.name%TYPE,
	in_mgmt_company_contact_email	IN  mgmt_company_contact.email%TYPE,
	in_mgmt_company_contact_phone	IN  mgmt_company_contact.phone%TYPE,
	in_skip_security_check			IN	number,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_mgmt_company_contact_id		mgmt_company_contact.mgmt_company_id%TYPE;
BEGIN
	IF in_skip_security_check = 0 THEN
		IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can save management company contacts');
		END IF;
	END IF;

	IF NVL(in_mgmt_company_contact_id, -1) =-1 THEN
		INSERT INTO mgmt_company_contact(mgmt_company_id, mgmt_company_contact_id, name, email, phone)
		VALUES(in_mgmt_company_id, mgmt_company_contact_id_seq.NEXTVAL, in_mgmt_company_contact_name, in_mgmt_company_contact_email, in_mgmt_company_contact_phone)
		RETURNING mgmt_company_contact_id INTO v_mgmt_company_contact_id;
	ELSE
		UPDATE mgmt_company_contact
		   SET name = in_mgmt_company_contact_name,
			   email = in_mgmt_company_contact_email,
			   phone = in_mgmt_company_contact_phone
		 WHERE mgmt_company_id = in_mgmt_company_id
		   AND mgmt_company_contact_id = in_mgmt_company_contact_id;

		 v_mgmt_company_contact_id := in_mgmt_company_contact_id;
	END IF;

	OPEN out_cur FOR
		SELECT mgmt_company_id, mgmt_company_contact_id, name, email, phone
		  FROM mgmt_company_contact
		 WHERE mgmt_company_id = in_mgmt_company_id
		   AND mgmt_company_contact_id = v_mgmt_company_contact_id;
END;

PROCEDURE DeleteManagementCompanyContact(
	in_mgmt_company_id				IN	mgmt_company_contact.mgmt_company_id%TYPE,
	in_mgmt_company_contact_id		IN	mgmt_company_contact.mgmt_company_contact_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can delete management company contacts');
	END IF;

	UPDATE all_property
	   SET mgmt_company_contact_id = NULL
	 WHERE mgmt_company_contact_id = in_mgmt_company_contact_id;

	DELETE FROM mgmt_company_contact
		  WHERE mgmt_company_id = in_mgmt_company_id
			AND mgmt_company_contact_id = in_mgmt_company_contact_id;
END;

PROCEDURE SaveSpaceType(
	in_space_type_id	IN	space_type.space_type_id%TYPE,
	in_space_type_name	IN	space_type.label%TYPE,
	in_is_tenantable	IN	space_type.is_tenantable%TYPE,
	out_space_type_id	OUT	space_type.space_type_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can edit space types');
	END IF;

	-- If we've not been given a tennant ID,
	-- we must be adding. Otherwise, update.
	IF NVL(in_space_type_id, -1) =-1 THEN
		INSERT INTO space_type(space_type_id, label, is_tenantable)
		VALUES(space_type_id_seq.NEXTVAL, in_space_type_name, in_is_tenantable)
		RETURNING space_type_id INTO out_space_type_id;
	ELSE
		UPDATE space_type
		   SET label = in_space_type_name,
		   is_tenantable = in_is_tenantable
		 WHERE space_type_id = in_space_type_id;

		 out_space_type_id := in_space_type_id;
	END IF;
END;

PROCEDURE SaveSpaceType(
	in_space_type_id	IN	space_type.space_type_id%TYPE,
	in_space_type_name	IN	space_type.label%TYPE,
	in_is_tenantable	IN	space_type.is_tenantable%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_space_type_id		space_type.space_type_id%TYPE;
BEGIN
	SaveSpaceType(
		in_space_type_id,
		in_space_type_name,
		in_is_tenantable,
		v_space_type_id
	);

	OPEN out_cur FOR
		SELECT space_type_id, label, is_tenantable
		  FROM space_type
		 WHERE space_type_id = v_space_type_id;
END;

PROCEDURE SaveSpaceType(
	in_space_type_id	IN	space_type.space_type_id%TYPE,
	in_space_type_name	IN	space_type.label%TYPE,
	in_is_tenantable	IN	space_type.is_tenantable%TYPE,
	in_ind_sids			IN	VARCHAR2,
	in_property_type_ids	IN	VARCHAR2,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_properties_cur	OUT security_pkg.T_OUTPUT_CUR,
	out_metrics_cur		OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_space_type_id		space_type.space_type_id%TYPE;
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can edit space types');
	END IF;

	-- If we've not been given a space type ID,
	-- we must be adding. Otherwise, update.
	IF NVL(in_space_type_id, -1) =-1 THEN
		INSERT INTO space_type(space_type_id, label, is_tenantable)
		VALUES(space_type_id_seq.NEXTVAL, in_space_type_name, in_is_tenantable)
		RETURNING space_type_id INTO v_space_type_id;
	ELSE
		UPDATE space_type
		   SET label = in_space_type_name,
		   is_tenantable = in_is_tenantable
		 WHERE space_type_id = in_space_type_id;

		 v_space_type_id := in_space_type_id;
	END IF;

	UpdateSpaceTypePropertyAssoc(v_space_type_id, in_property_type_ids);
	region_metric_pkg.UpdateSpaceTypeMetrics(v_space_type_id, in_ind_sids);

	-- get updated record info
	OPEN out_cur FOR
		SELECT space_type_id, label, is_tenantable
		  FROM space_type
		 WHERE space_type_id = v_space_type_id;

	OPEN out_properties_cur FOR
		SELECT pt.property_type_id, pt.label, ptst.space_type_id
		  FROM property_type pt
		  JOIN property_type_space_type ptst
			ON ptst.space_type_id = v_space_type_id
		   AND pt.app_sid = ptst.app_sid
		   AND pt.property_type_id = ptst.property_type_id
		ORDER BY LOWER(pt.label);

	OPEN out_metrics_cur FOR
		SELECT rm.ind_sid, m.measure_sid,
			NVL(i.format_mask, m.format_mask) format_mask, i.lookup_Key, i.description,
			rm.is_mandatory, strm.SPACE_TYPE_ID
		  FROM csr.space_type_region_metric strm
			JOIN csr.region_metric rm ON strm.ind_sid = rm.ind_sid AND strm.app_sid = rm.app_sid
			JOIN csr.v$ind i ON rm.ind_sid = i.ind_sid AND rm.app_sid = i.app_sid
			JOIN csr.measure m ON i.measure_sid = m.measure_sid AND i.app_sid = m.app_sid
		WHERE strm.space_type_id = v_space_type_id
		ORDER BY lower(i.description);
END;

PROCEDURE DeleteSpaceType(
	in_space_type_id	IN	space_type.space_type_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can remove space types');
	END IF;

	-- Will this throw constraint exceptions with csr.property_type????
	DELETE FROM property_type_space_type
	 WHERE space_type_id = in_space_type_id
	   AND app_sid = security_pkg.GetApp;

	DELETE FROM space_type_region_metric
	 WHERE space_type_id = in_space_type_id
	   AND app_sid = security_pkg.GetApp;

	DELETE FROM space
	 WHERE space_type_id = in_space_type_id
	   AND app_sid = security_pkg.GetApp;

	DELETE FROM space_type
	 WHERE space_type_id = in_space_type_id
	   AND app_sid = security_pkg.GetApp;
END;

PROCEDURE AddSpaceTypePropertyAssoc(
	in_property_type_id		IN	property_type.property_type_id%TYPE,
	in_space_type_id		IN	space_type.space_type_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can edit space type associations');
	END IF;

	-- Add Property Type + Space Type association.
	INSERT INTO property_type_space_type(property_type_id, space_type_id)
	VALUES(in_property_type_id, in_space_type_id);
END;

PROCEDURE RemoveSpaceTypePropertyAssoc(
	in_property_type_id		IN	property_type.property_type_id%TYPE,
	in_space_type_id		IN	space_type.space_type_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can edit space type associations');
	END IF;

	-- Remove Property Type + Space Tyoe association.
	DELETE FROM property_type_space_type
	 WHERE property_type_id = in_property_type_id
	   AND space_type_id = in_space_type_id
	   AND app_sid = security_pkg.GetApp;
END;

PROCEDURE UpdateSpaceTypePropertyAssoc(
	in_space_type_id		IN	space_type.space_type_id%TYPE,
	in_property_type_ids	IN	VARCHAR2
)
AS
	v_split_char	VARCHAR(1) := ',';
	v_table			ASPEN2.T_SPLIT_NUMERIC_TABLE := ASPEN2.T_SPLIT_NUMERIC_TABLE();
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can edit space type associations');
	END IF;

	v_table := aspen2.utils_pkg.SplitNumericString(in_property_type_ids, v_split_char);

	DELETE FROM property_type_space_type
	 WHERE space_type_id = in_space_type_id
	   AND app_sid = security_pkg.GetApp
	   AND property_type_id NOT IN (SELECT t.ITEM FROM TABLE(v_table) t);

	INSERT INTO property_type_space_type(property_type_id, space_type_id)
		SELECT 	t.ITEM PROPERTY_TYPE_ID,
				in_space_type_id SPACE_TYPE_ID
			FROM TABLE(v_table) t
			WHERE t.ITEM NOT IN (SELECT PROPERTY_TYPE_ID FROM property_type_space_type WHERE SPACE_TYPE_ID = in_space_type_id);
END;

PROCEDURE UpdatePropertyTypeSpaceAssoc(
	in_property_type_id	IN	property_type.property_type_id%TYPE,
	in_space_type_ids	IN	VARCHAR2
)
AS
	v_split_char	VARCHAR(1) := ',';
	v_table			ASPEN2.T_SPLIT_NUMERIC_TABLE := ASPEN2.T_SPLIT_NUMERIC_TABLE();
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can edit space type associations');
	END IF;

	v_table := aspen2.utils_pkg.SplitNumericString(in_space_type_ids, v_split_char);

	DELETE FROM property_type_space_type
	 WHERE property_type_id = in_property_type_id
	   AND app_sid = security_pkg.GetApp
	   AND space_type_id NOT IN (SELECT t.ITEM FROM TABLE(v_table) t);

	INSERT INTO property_type_space_type(property_type_id, space_type_id)
		SELECT	in_property_type_id PROPERTY_TYPE_ID,
				t.ITEM SPACE_TYPE_ID
			FROM TABLE(v_table) t
			WHERE t.ITEM NOT IN (SELECT SPACE_TYPE_ID FROM property_type_space_type WHERE PROPERTY_TYPE_ID = in_property_type_id);
END;

PROCEDURE GetSpaceTypes(
	out_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_properties_cur		OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT DISTINCT st.space_type_id, st.label, st.is_tenantable, DECODE(stm.est_space_type, NULL, 0, 1) is_est_compatible
		  FROM space_type st
		  -- This is used to check for Energy Star comaptibility
		  LEFT JOIN est_space_type_map stm ON st.app_sid = stm.app_sid AND st.space_type_id = stm.space_type_id
		 ORDER BY LOWER(label) ASC;

	OPEN out_properties_cur FOR
		SELECT pt.property_type_id, pt.label, ptst.space_type_id
		  FROM property_type pt
		  JOIN property_type_space_type ptst
			ON pt.app_sid = ptst.app_sid
		   AND pt.property_type_id = ptst.property_type_id
		ORDER BY LOWER(pt.label);
END;

PROCEDURE GetSpaceTypes(
	out_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_properties_cur		OUT security_pkg.T_OUTPUT_CUR,
	out_metrics_cur			OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetSpaceTypes(out_cur, out_properties_cur);

	OPEN out_metrics_cur FOR
		SELECT rm.ind_sid, m.measure_sid,
			NVL(i.format_mask, m.format_mask) format_mask, i.lookup_Key, i.description,
			rm.is_mandatory, strm.SPACE_TYPE_ID
		  FROM csr.space_type_region_metric strm
			JOIN csr.region_metric rm ON strm.ind_sid = rm.ind_sid AND strm.app_sid = rm.app_sid
			JOIN csr.v$ind i ON rm.ind_sid = i.ind_sid AND rm.app_sid = i.app_sid
			JOIN csr.measure m ON i.measure_sid = m.measure_sid AND i.app_sid = m.app_sid
		ORDER BY i.description;
END;

PROCEDURE GetLease (
	in_lease_id				IN  lease.lease_id%TYPE,
	out_lease_cur			OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_lease_ids				security.T_SID_TABLE;
BEGIN
	-- TODO security

	OPEN out_lease_cur FOR
		SELECT lease_id, start_dtm, end_dtm, next_break_dtm,
			   current_rent, normalised_rent, next_rent_review, currency_code,
			   tenant_id, tenant_name
		  FROM v$lease
		 WHERE lease_id = in_lease_id;
END;

PROCEDURE GetSpaceLeases (
	in_property_region_sid	IN  security_pkg.T_SID_ID,
	in_tenant_id			IN  tenant.tenant_id%TYPE,
	out_lease_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_spaces_cur			OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_lease_ids				security.T_SID_TABLE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_property_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the property with sid '||in_property_region_sid);
	END IF;

	SELECT DISTINCT l.lease_id
	  BULK COLLECT INTO v_lease_ids
	  FROM property p
	  JOIN space s
		ON s.property_region_sid = p.region_sid
	  JOIN lease_space ls
		ON s.region_sid = ls.space_region_sid
	  JOIN lease l
		ON ls.lease_id = l.lease_id
	 WHERE p.region_sid = NVL(in_property_region_sid, p.region_sid)
	   AND l.tenant_id = NVL(in_tenant_id, l.tenant_id);


	OPEN out_lease_cur FOR
		SELECT lease_id, start_dtm, end_dtm, next_break_dtm,
			   current_rent, normalised_rent, next_rent_review, currency_code,
			   tenant_id, tenant_name
		  FROM v$lease l
		  JOIN TABLE(v_lease_ids) li
			ON l.lease_id = li.column_value;

	OPEN out_spaces_cur FOR
		SELECT ls.lease_id, s.description
		  FROM lease_space ls
		  JOIN TABLE(v_lease_ids) li
			ON ls.lease_id = li.column_value
		  JOIN v$space s
			ON ls.space_region_sid = s.region_sid;
END;

PROCEDURE SaveLease (
	in_lease_id				IN  lease.lease_id%TYPE,
	in_start_dtm			IN  lease.start_dtm%TYPE,
	in_end_dtm				IN  lease.end_dtm%TYPE,
	in_next_break_dtm		IN  lease.next_break_dtm%TYPE,
	in_current_rent			IN  lease.current_rent%TYPE,
	in_normalised_rent		IN  lease.normalised_rent%TYPE,
	in_next_rent_review		IN  lease.next_rent_review%TYPE,
	in_tenant_id			IN  lease.tenant_id%TYPE,
	in_currency_code		IN  lease.currency_code%TYPE,
	in_space_region_sid		IN  security_pkg.T_SID_ID,
	in_property_region_sid	IN  security_pkg.T_SID_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_lease_id				lease.lease_id%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_space_region_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the space with sid '||in_space_region_sid);
	END IF;

	IF NVL(in_lease_id, -1) =-1 THEN
		INSERT INTO lease(lease_id, start_dtm, end_dtm, next_break_dtm, current_rent, normalised_rent,
						  next_rent_review, tenant_id, currency_code)
		VALUES(lease_id_seq.NEXTVAL, in_start_dtm, in_end_dtm, in_next_break_dtm, in_current_rent,
			   in_normalised_rent, in_next_rent_review, in_tenant_id, in_currency_code)
		RETURNING lease_id INTO v_lease_id;
	ELSE
		UPDATE lease
		   SET start_dtm = in_start_dtm,
			   end_dtm = in_end_dtm,
			   next_break_dtm = in_next_break_dtm,
			   current_rent = in_current_rent,
			   normalised_rent = in_normalised_rent,
			   next_rent_review = in_next_rent_review,
			   tenant_id = in_tenant_id,
			   currency_code = in_currency_code
		 WHERE lease_id = in_lease_id;

		 v_lease_id := in_lease_id;
	END IF;

	IF NVL(in_space_region_sid, -1) != -1 THEN
		BEGIN
			INSERT INTO lease_space(lease_id, space_region_sid)
				 VALUES (v_lease_id, in_space_region_sid);
		EXCEPTION
			WHEN dup_val_on_index THEN
				NULL;
		END;

		UPDATE all_space
		   SET current_lease_id = v_lease_id
		 WHERE region_sid = in_space_region_sid;

		INTERNAL_CallHelperPkg('SpaceLeaseUpdated', in_space_region_sid);
	END IF;

	IF NVL(in_property_region_sid, -1) != -1 THEN
		BEGIN
			INSERT INTO lease_property(lease_id, property_region_sid)
				 VALUES (v_lease_id, in_property_region_sid);
		EXCEPTION
			WHEN dup_val_on_index THEN
				NULL;
		END;
	END IF;

	OPEN out_cur FOR
		SELECT lease_id, start_dtm, end_dtm, next_break_dtm,
			   current_rent, normalised_rent, next_rent_review, currency_code,
			   tenant_id, tenant_name,
			   in_space_region_sid space_region_sid, in_property_region_sid property_region_sid
		  FROM v$lease
		 WHERE lease_id = v_lease_id;
END;

PROCEDURE ClearSpaceLease (
	in_space_region_sid		IN  security_pkg.T_SID_ID
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_space_region_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the space with sid '||in_space_region_sid);
	END IF;

	UPDATE all_space
	   SET current_lease_id = null
	 WHERE region_sid = in_space_region_sid;

	INTERNAL_CallHelperPkg('SpaceLeaseUpdated', in_space_region_sid);
END;

PROCEDURE SetLeasePostIt(
	in_lease_id				IN	security_pkg.T_SID_ID,
	in_postit_id			IN	postit.postit_id%TYPE,
	out_postit_id			OUT postit.postit_id%TYPE
)
AS
	v_property_region_sid		space.property_region_sid%TYPE;
BEGIN

	-- we need a sid to secure the postit. The region will do.
	SELECT MIN(property_region_sid)
	  INTO v_property_region_sid
	  FROM lease_space ls
	  JOIN space s ON s.region_sid = ls.space_region_sid
	 WHERE lease_id = in_lease_id;

	postit_pkg.Save(in_postit_id, null, 'message', v_property_region_sid, out_postit_id);

	BEGIN
		INSERT INTO lease_postit (lease_id, postit_id)
			VALUES (in_lease_id, out_postit_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL; -- ignore
	END;
END;

PROCEDURE GetLeasePostIts(
	in_lease_id	IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_cur_files			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- TODO Security

	OPEN out_cur FOR
		SELECT iap.lease_id, p.postit_id, p.message, p.label, p.created_dtm, p.created_by_sid,
			p.created_by_user_name, p.created_by_full_name, p.created_by_email, p.can_edit
		  FROM lease_postit iap
			JOIN v$postit p ON iap.postit_id = p.postit_id AND iap.app_sid = p.app_sid
		 WHERE lease_id = in_lease_id
		 ORDER BY created_dtm;

	OPEN out_cur_files FOR
		SELECT pf.postit_file_Id, pf.postit_id, pf.filename, pf.mime_type, cast(pf.sha1 as varchar2(40)) sha1, pf.uploaded_dtm
		  FROM lease_postit iap
			JOIN postit p ON iap.postit_id = p.postit_id AND iap.app_sid = p.app_sid
			JOIN postit_file pf ON p.postit_id = pf.postit_id AND p.app_sid = pf.app_sid
		 WHERE lease_id = in_lease_id;
END;

PROCEDURE SetRegionPostIt(
	in_region_sid	IN	security_pkg.T_SID_ID,
	in_postit_id	IN	postit.postit_id%TYPE,
	out_postit_id	OUT postit.postit_id%TYPE
)
AS
BEGIN
	IF NOT CanViewProperty(in_region_sid) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the property with sid '||in_region_sid);
	END IF;

	postit_pkg.Save(in_postit_id, null, 'message', in_region_sid, out_postit_id);

	BEGIN
		INSERT INTO region_postit (region_sid, postit_id)
			VALUES (in_region_sid, out_postit_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL; -- ignore
	END;
END;

PROCEDURE GetRegionPostIts(
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_cur_files			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT CanViewProperty(in_region_sid) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the property with sid '||in_region_sid);
	END IF;

	OPEN out_cur FOR
		SELECT rpi.region_sid, p.postit_id, p.message, p.label, p.created_dtm, p.created_by_sid,
			p.created_by_user_name, p.created_by_full_name, p.created_by_email, p.can_edit
		  FROM region_postit rpi
			JOIN v$postit p ON rpi.postit_id = p.postit_id AND rpi.app_sid = p.app_sid
		 WHERE region_sid = in_region_sid
		 ORDER BY created_dtm;

	OPEN out_cur_files FOR
		SELECT pf.postit_file_Id, pf.postit_id, pf.filename, pf.mime_type, cast(pf.sha1 as varchar2(40)) sha1, pf.uploaded_dtm
		  FROM region_postit rpi
			JOIN postit p ON rpi.postit_id = p.postit_id AND rpi.app_sid = p.app_sid
			JOIN postit_file pf ON p.postit_id = pf.postit_id AND p.app_sid = pf.app_sid
		 WHERE region_sid = in_region_sid;
END;


PROCEDURE AddPropertyPhoto (
	in_property_region_sid	IN	security_pkg.T_SID_ID,
	in_space_region_sid		IN	security_pkg.T_SID_ID,
	in_cache_key			IN	aspen2.filecache.cache_key%TYPE,
	out_property_photo_id	OUT	property_photo.property_photo_id%TYPE
)
AS
	v_act					security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY','ACT');
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(v_act, in_property_region_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to the property with sid '||in_property_region_sid);
	END IF;

	INSERT INTO property_photo (property_photo_id, property_region_sid, space_region_sid, filename, mime_type, data)
	SELECT property_photo_id_seq.nextval, in_property_region_sid, in_space_region_sid,
		   f.filename, f.mime_type, f.object
	  FROM aspen2.filecache f
	 WHERE f.cache_key = in_cache_key;

	SELECT property_photo_id_seq.currval
	  INTO out_property_photo_id
	  FROM dual;
END;

PROCEDURE DeletePropertyPhoto (
	in_property_photo_id	IN	property_photo.property_photo_id%TYPE
)
AS
	v_property_region_sid	security_pkg.T_SID_ID;
	v_act					security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY','ACT');
BEGIN
	SELECT property_region_sid
	  INTO v_property_region_sid
	  FROM property_photo
	 WHERE property_photo_id = in_property_photo_id;

	IF NOT security_pkg.IsAccessAllowedSID(v_act, v_property_region_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to the property with sid '||v_property_region_sid);
	END IF;

	DELETE FROM property_photo
	 WHERE property_photo_id = in_property_photo_id;
END;

PROCEDURE GetPropertyPhoto (
	in_property_photo_id	IN	property_photo.property_photo_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_property_region_sid	security_pkg.T_SID_ID;
	v_act					security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY','ACT');
BEGIN
	SELECT property_region_sid
	  INTO v_property_region_sid
	  FROM property_photo
	 WHERE property_photo_id = in_property_photo_id;

	IF NOT security_pkg.IsAccessAllowedSID(v_act, v_property_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to the property with sid '||v_property_region_sid);
	END IF;

	OPEN out_cur FOR
		SELECT property_photo_id, property_region_sid, space_region_sid, filename, mime_type, data
		  FROM property_photo
		 WHERE property_photo_id = in_property_photo_id;
END;

PROCEDURE GetFundFormPlugins(
	out_cur		OUT		security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT ffp.plugin_id, ffp.xml_path, ffp.key_name, p.cs_class, p.js_include, p.js_class
		  FROM fund_form_plugin ffp
		  JOIN plugin p ON ffp.plugin_id = p.plugin_id
		 WHERE ffp.app_sid = security_pkg.getApp
	  ORDER BY ffp.pos;
END;

PROCEDURE GetStates(
	in_country	IN	postcode.country.country%TYPE,
	in_filter	IN	VARCHAR2,
	out_cur		OUT Security_Pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT p.state
		  FROM v$my_property p
		  JOIN region r ON p.region_sid = r.region_sid AND p.app_sid = r.app_sid
		 WHERE p.app_sid = security_pkg.getApp
		   AND (in_country IS NULL AND r.geo_country IS NULL) OR r.geo_country = in_country
		   AND (in_filter IS NULL OR LOWER(p.state) LIKE LOWER(in_filter)||'%')
		 GROUP BY p.state
		 ORDER BY p.state;
END;

PROCEDURE GetCities(
	in_country	IN	postcode.country.country%TYPE,
	in_state	IN	property.state%TYPE,
	in_filter	IN	VARCHAR2,
	out_cur		OUT Security_Pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT p.city
		  FROM v$my_property p
		  JOIN region r ON p.region_sid = r.region_sid AND p.app_sid = r.app_sid
		 WHERE p.app_sid = security_pkg.getApp
		   AND (in_country IS NULL AND r.geo_country IS NULL) OR r.geo_country = in_country
		   AND (in_state IS NULL AND p.state IS NULL) OR p.state = in_state
		   AND (in_filter IS NULL OR LOWER(p.city) LIKE LOWER(in_filter)||'%')
		 GROUP BY p.city
		 ORDER BY p.city;
END;

PROCEDURE GetAllProperties(
	out_cur 	OUT  SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT p.region_sid, p.description, p.region_ref, p.street_addr_1, p.street_addr_2, p.city, p.state,
			p.postcode, p.country_code, p.country_name, p.country_currency,
			p.property_type_id, p.property_type_label, p.property_sub_type_id, p.property_sub_type_label,
			p.flow_item_id, p.current_state_id, p.current_state_label, p.current_state_colour, p.current_state_lookup_key, p.active,
			p.acquisition_dtm, p.disposal_dtm, p.lng, p.lat,
			mc.mgmt_company_id, NVL(mc.name, mgmt_company_other) mgmt_company_name, f.name fund_name, p.fund_id,
			cc.name member_name,
			p.energy_star_sync, p.energy_star_push, -- raw energy star option flags
			p.energy_star_sync is_energy_star, DECODE(p.energy_star_sync, 0, 0, p.energy_star_push) is_energy_star_push, -- takes into account the sync flag being set to zero
			pg.asset_id gresb_asset_id
		  FROM v$property p
		  LEFT JOIN property_gresb pg ON pg.region_sid = p.region_sid
		  LEFT JOIN mgmt_company mc ON p.mgmt_company_id = mc.mgmt_company_id AND p.app_sid = mc.app_sid
		  LEFT JOIN fund f ON p.fund_id = f.fund_id AND p.app_sid = f.app_sid
		  LEFT JOIN chain.company cc ON p.company_sid = cc.company_sid AND p.app_sid = cc.app_sid
		  ORDER BY p.description;
END;

PROCEDURE GetAllPropertiesWTagsMetrics(
	out_cur 				OUT  SYS_REFCURSOR,
	out_tags_cur 			OUT  SYS_REFCURSOR,
	out_region_metrics_cur 	OUT  SYS_REFCURSOR
)
AS
BEGIN
	GetAllProperties(out_cur);

	OPEN out_tags_cur FOR
		SELECT rt.region_sid, rt.tag_id
		  FROM v$property p
		  JOIN region_tag rt ON p.region_sid = rt.region_sid;

	OPEN out_region_metrics_cur FOR
		SELECT x.region_sid, x.ind_sid, x.val AS value
		  FROM (
			SELECT rmv.region_sid, rmv.ind_sid, i.lookup_key,
				row_number() OVER (PARTITION BY rmv.region_sid, rmv.ind_sid ORDER BY rmv.effective_dtm DESC) rn,
				rmv.val
			  FROM region_metric_val rmv
				JOIN region_metric rm ON rmv.ind_sid = rm.ind_sid AND rmv.app_sid = rm.app_sid
				JOIN ind i ON rm.ind_sid = i.ind_sid AND rm.app_sid = i.app_sid
			  WHERE rmv.effective_dtm < SYSDATE -- we only want to show the current applicable value
				AND rmv.region_sid IN (
					 SELECT region_sid
					   FROM region
					CONNECT BY PRIOR region_sid = parent_sid
				 )
			)x
			WHERE rn = 1;
END;

-- Yuck! An exact copy of 'GetAllProperties' SP but with a WHERE...
PROCEDURE GetAllPropertiesForPropType(
	in_property_type_id	IN	property.property_type_id%TYPE,
	out_cur 			OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT p.region_sid, p.description, p.region_ref, p.street_addr_1, p.street_addr_2, p.city, p.state,
			p.postcode, p.country_code, p.country_name, p.country_currency,
			p.property_type_id, p.property_type_label, p.property_sub_type_id, p.property_sub_type_label,
			p.flow_item_id, p.current_state_id, p.current_state_label, p.current_state_colour, p.current_state_lookup_key, p.active,
			p.acquisition_dtm, p.disposal_dtm, p.lng, p.lat,
			mc.mgmt_company_id, NVL(mc.name, mgmt_company_other) mgmt_company_name, f.name fund_name, p.fund_id,
			cc.name member_name,
			p.energy_star_sync, p.energy_star_push, -- raw energy star option flags
			p.energy_star_sync is_energy_star, DECODE(p.energy_star_sync, 0, 0, p.energy_star_push) is_energy_star_push, -- takes into account the sync flag being set to zero
			pg.asset_id gresb_asset_id
		  FROM v$property p
		  LEFT JOIN mgmt_company mc ON p.mgmt_company_id = mc.mgmt_company_id AND p.app_sid = mc.app_sid
		  LEFT JOIN fund f ON p.fund_id = f.fund_id AND p.app_sid = f.app_sid
		  LEFT JOIN property_gresb pg ON pg.region_sid = p.region_sid
		  LEFT JOIN (
			-- I would have thought you could only map something once but there's
			-- no unique constraint on est_building.region_sid. If we knew it was unique we could
			-- join straight to est_building. One to check and talk to Dickie about
			SELECT DISTINCT b.region_sid
			  FROM est_building b
			 WHERE b.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND b.region_sid IS NOT NULL
		  )es ON p.region_sid = es.region_sid
		  LEFT JOIN chain.company cc ON p.company_sid = cc.company_sid AND p.app_sid = cc.app_sid
		  WHERE p.property_type_id = in_property_type_id
		  ORDER BY p.description;
END;

PROCEDURE AddIssue(
	in_region_sid 					IN 	security_pkg.T_SID_ID,
	in_label						IN	issue.label%TYPE,
	in_description					IN	issue_log.message%TYPE,
	in_due_dtm						IN	issue.due_dtm%TYPE,
	in_source_url					IN	issue.source_url%TYPE,
	in_assigned_to_user_sid			IN	issue.assigned_to_user_sid%TYPE,
	in_is_urgent					IN	NUMBER,
	in_is_critical					IN	issue.is_critical%TYPE DEFAULT 0,
	out_issue_id					OUT issue.issue_id%TYPE
)
AS
	v_can_edit						NUMBER;
	v_can_view						BOOLEAN := CanViewProperty(in_region_sid, v_can_edit);
BEGIN
	IF v_can_edit = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the property with sid '||in_region_sid);
	END IF;

	issue_pkg.CreateIssue(
		in_label					=> in_label,
		in_description				=> in_description,
		in_issue_type_id			=> csr_data_pkg.ISSUE_PROPERTY,
		in_raised_by_user_sid		=> SYS_CONTEXT('SECURITY', 'SID'),
		in_assigned_to_user_sid		=> in_assigned_to_user_sid,
		in_due_dtm					=> in_due_dtm,
		in_source_url				=> in_source_url,
		in_region_sid				=> in_region_sid,
		in_is_urgent				=> in_is_urgent,
		in_is_critical				=> in_is_critical,
		out_issue_id				=> out_issue_id
	);
END;

PROCEDURE GetBenchmarkSpaces(
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT s.space_type_id, st.label, s.property_region_sid, s.region_sid, p.country_code, p.property_type_Id
		  FROM space s
		  JOIN v$property p ON s.property_region_sid = p.region_sid
		  JOIN space_type st ON s.space_type_id = st.space_type_id;
END;

PROCEDURE GetPropertyMapSid(
	out_map_sid			OUT security_pkg.T_SID_ID
)
AS
	v_map_sid			security_pkg.T_SID_ID;
BEGIN
	BEGIN
		SELECT properties_geo_map_sid INTO v_map_sid FROM csr.property_options;

		IF security_pkg.IsAccessAllowedSID(security_pkg.GetACT, v_map_sid, security_pkg.PERMISSION_READ) THEN
			out_map_sid := v_map_sid;
		ELSE
			out_map_sid := NULL;
		END IF;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			out_map_sid := NULL;
	END;
END;

FUNCTION IsMultiFundEnabled
RETURN NUMBER
AS
	v_enabled						NUMBER(1, 0);
BEGIN
	SELECT enable_multi_fund_ownership
	  INTO v_enabled
	  FROM csr.property_options;

	RETURN v_enabled;
END;

PROCEDURE GetPropertyFund(
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT f.fund_id, f.name
			FROM fund f
			JOIN v$property p ON p.fund_id = f.fund_id AND p.region_sid = in_region_sid
			WHERE f.app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetPropertyFunds(
	in_region_sid					IN	security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	GetPropertyFunds(
		in_region_sid		=> in_region_sid,
		in_fund_id			=> NULL,
		out_cur				=> out_cur
	);
END;


PROCEDURE GetPropertyFunds(
	in_region_sid					IN	security_pkg.T_SID_ID,
	in_fund_id						IN	NUMBER,
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT pf.region_sid, f.fund_id, f.name, pf.container_sid
		  FROM property_fund pf
		  JOIN fund f ON pf.app_sid = f.app_sid AND pf.fund_id = f.fund_id
		 WHERE (in_region_sid IS NULL OR pf.region_sid = in_region_sid)
		   AND (in_fund_id IS NULL OR f.fund_id = in_fund_id);
END;

PROCEDURE GetPropertyFundOwnership(
	in_region_sid					IN	security_pkg.T_SID_ID DEFAULT NULL,
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	GetPropertyFundOwnership(in_region_sid, NULL, out_cur);
END;

PROCEDURE GetPropertyFundOwnership(
	in_region_sid					IN	security_pkg.T_SID_ID,
	in_fund_id						IN	NUMBER,
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT app_sid, region_sid, fund_id, name, container_sid, start_dtm, end_dtm, ownership
		  FROM v$property_fund_ownership
		 WHERE (in_region_sid IS NULL OR region_sid = in_region_sid)
		   AND (in_fund_id IS NULL OR fund_id = in_fund_id);
END;

PROCEDURE UpdateFundTree(
	in_property_sid					IN security_pkg.T_SID_ID,
	in_fund_id						IN NUMBER
)
AS
	v_act							security_pkg.T_ACT_ID := security.security_pkg.GetAct();
	v_fund_root						security_pkg.T_SID_ID := GetFundTreeRoot();
	v_fund_region					security_pkg.T_SID_ID;
	v_fund_name						fund.name%TYPE;
	v_container_region				security_pkg.T_SID_ID;
	v_property_name					v$region.description%TYPE;
	v_link_region					security_pkg.T_SID_ID;
	v_no_entries					BOOLEAN := TRUE;
	v_calc_start_dtm				customer.calc_start_dtm%TYPE;
	v_fund_start_dtm				DATE;
BEGIN
	-- If there are no ownership entries, remove the holding nodes from the tree
	FOR r IN (SELECT 1
				FROM property_fund_ownership
			   WHERE fund_id = in_fund_id
				 AND region_sid = in_property_sid)
	LOOP
		v_no_entries := FALSE;
		EXIT;
	END LOOP;

	IF v_no_entries THEN
		FOR r IN (SELECT pf.container_sid
					FROM property_fund pf
				   WHERE pf.fund_id = in_fund_id
					 AND pf.region_sid = in_property_sid
					 AND pf.container_sid IS NOT NULL)
		LOOP
			UPDATE property_fund
			   SET container_sid = NULL
			 WHERE fund_id = in_fund_id
			   AND region_sid = in_property_sid;

			security.securableobject_pkg.DeleteSO(
				in_act_id			=> v_act,
				in_sid_id			=> r.container_sid
			);
		END LOOP;
		RETURN;
	END IF;

	SELECT r.description
	  INTO v_property_name
	  FROM v$region r
	 WHERE r.region_sid = in_property_sid;

	-- Get/create node for fund
	SELECT r.region_sid, f.name
	  INTO v_fund_region, v_fund_name
	  FROM fund f
	  LEFT JOIN region r
		ON f.app_sid = r.app_sid
	   AND f.region_sid = r.region_sid
	 WHERE f.fund_id = in_fund_id
	   FOR UPDATE of f.region_sid;

	IF v_fund_region IS NULL THEN
		region_pkg.CreateRegion(
			in_parent_sid => v_fund_root,
			in_name => v_fund_name,
			in_description => v_fund_name,
			out_region_sid => v_fund_region
		);

		UPDATE fund
		   SET region_sid = v_fund_region
		 WHERE fund_id = in_fund_id;
	END IF;

	-- Create/update ownership holding node
	BEGIN
		SELECT pf.container_sid
		  INTO v_container_region
		  FROM property_fund pf
		  JOIN region r ON r.region_sid = pf.container_sid
		 WHERE pf.fund_id = in_fund_id
		   AND pf.region_sid = in_property_sid
		   FOR UPDATE OF container_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_container_region := NULL;
	END;

	IF v_container_region IS NULL THEN
		-- Create the holding region (ensuring it has a unique SO name)
		DECLARE
			v_name					region.name%TYPE := v_property_name;
			v_index					NUMBER(9) := 1;
		BEGIN
			LOOP
				SAVEPOINT before_create;
				BEGIN
					region_pkg.CreateRegion(
						in_parent_sid  => v_fund_region,
						in_name        => v_name,
						in_description => v_property_name,
						out_region_sid => v_container_region
					);
					EXIT;
				EXCEPTION
					WHEN security_pkg.duplicate_object_name THEN
						-- Make sure CreateRegion is fully reversed
						ROLLBACK TO before_create;

						v_name := v_property_name || ' (' || v_index || ')';
						v_index := v_index + 1;
				END;
			END LOOP;
		END;

		UPDATE property_fund
		   SET container_sid = v_container_region
		 WHERE fund_id = in_fund_id
		   AND region_sid = in_property_sid;
	END IF;

	-- Delete existing ownership records
	FOR r IN (
		SELECT start_dtm
		  FROM pct_ownership
		 WHERE region_sid = v_container_region
	)
	LOOP
		-- skip the permission check as we know we can write to the region.
		region_pkg.UNSEC_SetPctOwnership(
			in_act_id			=> v_act,
			in_region_sid		=> v_container_region,
			in_start_dtm		=> r.start_dtm,
			in_pct          	=> NULL
		);
	END LOOP;

	SELECT calc_start_dtm
	  INTO v_calc_start_dtm
	  FROM customer;

	-- Create new ownership records
	FOR r IN (
		SELECT start_dtm, ownership
		  FROM property_fund_ownership
		 WHERE region_sid = in_property_sid
		   AND fund_id = in_fund_id
	)
	LOOP
		region_pkg.UNSEC_SetPctOwnership(
			in_act_id			=> v_act,
			in_region_sid		=> v_container_region,
			in_start_dtm		=> r.start_dtm,
			in_pct          	=> r.ownership
		);
	END LOOP;

	SELECT MIN(start_dtm)
	  INTO v_fund_start_dtm
	  FROM property_fund_ownership
	 WHERE region_sid = in_property_sid
	   AND fund_id = in_fund_id;
	
	IF v_fund_start_dtm > v_calc_start_dtm THEN
		-- region_pkg.GetPctOwnership assumes 100% unless we explicitly set ownership to 0% at the
		-- beginning of time
		region_pkg.UNSEC_SetPctOwnership(
			in_act_id			=> v_act,
			in_region_sid		=> v_container_region,
			in_start_dtm		=> v_calc_start_dtm,
			in_pct          	=> 0
		);
	END IF;

	-- Get create region link. There should never be more than a single node under the container.
	-- TODO: is this a safe assumption? What if the fund was updated concurrently, or manually?
	SELECT MAX(r.region_sid)
	  INTO v_link_region
	  FROM v$region r
	 WHERE r.parent_sid = v_container_region;

	IF v_link_region IS NULL THEN
		region_pkg.CreateLinkToRegion(
			in_act_id			=> v_act,
			in_parent_sid		=> v_container_region,
			in_link_to_sid		=> in_property_sid,
			out_region_sid		=> v_link_region
		);
	END IF;
END;

PROCEDURE AuditFundChange(
	in_region_sid					IN security_pkg.T_SID_ID,
	in_fund_id						IN NUMBER,
	in_date							IN DATE,
	in_ownership					IN NUMBER
)
AS
	v_fund_name						fund.name%TYPE;
BEGIN
	SELECT f.name
	  INTO v_fund_name
	  FROM csr.fund f
	 WHERE f.fund_id = in_fund_id;

	csr_data_pkg.WriteAuditLogEntry(
		in_act_id					=> security_pkg.GetAct,
		in_audit_type_id			=> csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA,
		in_app_sid					=> security_pkg.GetApp,
		in_object_sid				=> in_region_sid,
		in_description				=> 'Set fund "{0}" ownership to {1}, effective at {2}',
		in_param_1          		=> v_fund_name,
		in_param_2					=> in_ownership,
		in_param_3					=> in_date
	);
END;

PROCEDURE ClearFundOwnership(
	in_region_sid					IN	security_pkg.T_SID_ID
)
AS
	v_act							security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY','ACT');
	v_funds							security_pkg.T_SID_IDS;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(v_act, in_region_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(
			security_pkg.ERR_ACCESS_DENIED,
			'Access denied to the property with sid '||in_region_sid);
	END IF;

	csr_data_pkg.WriteAuditLogEntry(
		in_act_id					=> security_pkg.GetAct,
		in_audit_type_id			=> csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA,
		in_app_sid					=> security_pkg.GetApp,
		in_object_sid				=> in_region_sid,
		in_description				=> 'Clear fund ownership'
	);

	DELETE FROM csr.property_fund_ownership
	 WHERE region_sid = in_region_sid;

	FOR r IN (SELECT fund_id FROM property_fund WHERE region_sid = in_region_sid) LOOP
		UpdateFundTree(
			in_property_sid		=> in_region_sid,
			in_fund_id			=> r.fund_id
		);
	END LOOP;

	DELETE FROM csr.property_fund
	 WHERE region_sid = in_region_sid;
END;

PROCEDURE SetFundOwnerships(
	in_region_sid					IN security_pkg.T_SID_ID,
	in_fund_ids						IN security_pkg.T_SID_IDS,
	in_ownerships					IN security_pkg.T_DECIMAL_ARRAY,
	in_start_dates					IN security_pkg.T_VARCHAR2_ARRAY
)
AS
	v_fund_ids						security.T_SID_TABLE;
BEGIN
	FOR i IN in_fund_ids.FIRST .. in_fund_ids.LAST
	LOOP
		INTERNAL_SetFundOwnership(
			in_region_sid			=> in_region_sid,
			in_fund_id				=> in_fund_ids(i),
			in_ownership			=> in_ownerships(i),
			in_start_date			=> TO_DATE(in_start_dates(i), 'YYYY-MM-DD'),
			in_update_fund_tree		=> 0
		);
	END LOOP;

	IF IsMultiFundEnabled() != 0 THEN
		v_fund_ids := security_pkg.SidArrayToTable(in_fund_ids);
		v_fund_ids := v_fund_ids MULTISET INTERSECT DISTINCT v_fund_ids;

		FOR i IN v_fund_ids.FIRST .. v_fund_ids.LAST
		LOOP
			UpdateFundTree(
				in_property_sid		=> in_region_sid,
				in_fund_id			=> v_fund_ids(i)
			);
		END LOOP;
	END IF;
END;

PROCEDURE SetFundOwnership(
	in_region_sid					IN security_pkg.T_SID_ID,
	in_fund_id						IN NUMBER,
	in_ownership					IN NUMBER,
	in_start_date					IN DATE
)
AS
BEGIN
	INTERNAL_SetFundOwnership(in_region_sid, in_fund_id, in_ownership, in_start_date, 1);
END;

PROCEDURE INTERNAL_SetFundOwnership(
	in_region_sid					IN security_pkg.T_SID_ID,
	in_fund_id						IN NUMBER,
	in_ownership					IN NUMBER,
	in_start_date					IN DATE,
	in_update_fund_tree				IN NUMBER
)
AS
	v_act							security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY','ACT');
	v_start_date					DATE := NVL(in_start_date, DATE'1900-01-01');
	v_total_ownership				NUMBER;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(v_act, in_region_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(
			security_pkg.ERR_ACCESS_DENIED,
			'Access denied to the property with sid '||in_region_sid);
	END IF;

	AuditFundChange(in_region_sid, in_fund_id, in_start_date, in_ownership);

	SAVEPOINT before_update;

	-- Create header record
	BEGIN
		INSERT INTO csr.property_fund (region_sid, fund_id)
		VALUES (in_region_sid, in_fund_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	-- Create ownership record
	BEGIN
		INSERT INTO csr.property_fund_ownership (region_sid, fund_id, start_dtm, ownership)
		VALUES (in_region_sid, in_fund_id, v_start_date, in_ownership);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE csr.property_fund_ownership
			   SET ownership = in_ownership
			 WHERE region_sid = in_region_sid
			   AND fund_id = in_fund_id
			   AND start_dtm = v_start_date;
	END;

	-- Maintain invariant: total ownership always < 100%
	FOR r IN (
		SELECT start_dtm
		  FROM property_fund_ownership
		 WHERE region_sid = in_region_sid
	  GROUP BY start_dtm
		HAVING SUM(ownership) > 1)
	LOOP
		-- Client will probably rollback anyway, but might as well be certain
		ROLLBACK TO before_update;

		RAISE_APPLICATION_ERROR(
			csr_data_pkg.ERR_MAX_OWNERSHIP_EXCEEDED,
			'Sum of fund ownership exceeds 100% on ' || r.start_dtm);
	END LOOP;

	IF in_update_fund_tree != 0 AND IsMultiFundEnabled() != 0 THEN
		UpdateFundTree(
			in_property_sid		=> in_region_sid,
			in_fund_id			=> in_fund_id
		);
	END IF;
END;

PROCEDURE EnableMultiFund
AS
BEGIN
	UPDATE csr.property_options SET enable_multi_fund_ownership = 1;

	FOR r IN (SELECT DISTINCT pf.region_sid, pf.fund_id
				FROM csr.property_fund pf)
	LOOP
		UpdateFundTree(
			in_property_sid			=> r.region_sid,
			in_fund_id				=> r.fund_id
		);
	END LOOP;
END;

PROCEDURE SavePropertySubType(
	in_property_sub_type_id			IN	property_sub_type.property_sub_type_id%TYPE,
	in_property_sub_type_name		IN	property_sub_type.label%TYPE,
	in_property_type_id				IN	property_sub_type.property_type_id%TYPE,
	in_gresb_property_type_id		IN	property_sub_type.gresb_property_type_id%TYPE,
	in_gresb_property_sub_type_id	IN	property_sub_type.gresb_property_sub_type_id%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_property_sub_type_id		property_sub_type.property_sub_type_id%TYPE;
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can edit property sub types');
	END IF;

	-- If we've not been given a property sub type ID,
	-- we must be adding. Otherwise, update.
	IF in_property_sub_type_id IS NULL THEN
		INSERT INTO property_sub_type(property_sub_type_id, label, property_type_id, gresb_property_type_id, gresb_property_sub_type_id)
		VALUES(property_sub_type_id_seq.NEXTVAL, in_property_sub_type_name, in_property_type_id, in_gresb_property_type_id, in_gresb_property_sub_type_id)
		RETURNING property_sub_type_id INTO v_property_sub_type_id;
	ELSE
		UPDATE property_sub_type
		   SET label = in_property_sub_type_name,
			   property_type_id = in_property_type_id,
			   gresb_property_type_id = in_gresb_property_type_id,
			   gresb_property_sub_type_id = in_gresb_property_sub_type_id
		 WHERE property_sub_type_id = in_property_sub_type_id;

		 v_property_sub_type_id := in_property_sub_type_id;
	END IF;

	OPEN out_cur FOR
		SELECT property_sub_type_id, label, property_type_id, gresb_property_type_id, gresb_property_sub_type_id
		  FROM property_sub_type
		 WHERE property_sub_type_id = v_property_sub_type_id;
END;

PROCEDURE SavePropertyType(
	in_property_type_id		IN	property_type.property_type_id%TYPE,
	in_property_type_name	IN	property_type.label%TYPE,
	in_space_type_ids		IN	VARCHAR2,
	in_gresb_prop_type		IN	property_type.gresb_property_type_id%TYPE,
	out_property_type_id	OUT	property_type.property_type_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can edit property types');
	END IF;

	-- If we've not been given a property ID,
	-- we must be adding. Otherwise, update.
	IF NVL(in_property_type_id, -1) =-1 THEN
		INSERT INTO property_type(property_type_id, label, gresb_property_type_id)
		VALUES(property_type_id_seq.NEXTVAL, in_property_type_name, in_gresb_prop_type)
		RETURNING property_type_id INTO out_property_type_id;
	ELSE
		UPDATE property_type
		   SET label = in_property_type_name,
				gresb_property_type_id = in_gresb_prop_type
		 WHERE property_type_id = in_property_type_id;
		
		UPDATE property_sub_type
		   SET gresb_property_type_id = in_gresb_prop_type,
				gresb_property_sub_type_id = null
		 WHERE property_type_id = in_property_type_id
		   AND gresb_property_type_id != in_gresb_prop_type;
		
		 out_property_type_id := in_property_type_id;
	END IF;

	UpdatePropertyTypeSpaceAssoc(out_property_type_id, in_space_type_ids);
END;

PROCEDURE SavePropertyType(
	in_property_type_id		IN	property_type.property_type_id%TYPE,
	in_property_type_name	IN	property_type.label%TYPE,
	in_space_type_ids		IN	VARCHAR2,
	in_gresb_prop_type		IN	property_type.gresb_property_type_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_property_type_id		property_type.property_type_id%TYPE;
BEGIN
	SavePropertyType(
		in_property_type_id,
		in_property_type_name,
		in_space_type_ids,
		in_gresb_prop_type,
		v_property_type_id
	);

	OPEN out_cur FOR
		SELECT property_type_id, label, in_gresb_prop_type
		  FROM property_type
		 WHERE property_type_id = v_property_type_id;
END;

FUNCTION SetCmsPlugin(
	in_tab_sid				IN	security_pkg.T_SID_ID,
	in_form_path			IN	plugin.form_path%TYPE,
	in_description			IN	plugin.description%TYPE
) RETURN plugin.plugin_id%TYPE
AS
BEGIN
	RETURN csr.plugin_pkg.SetCustomerPlugin(
		in_plugin_type_id		=> csr.csr_data_pkg.PLUGIN_TYPE_PROPERTY_TAB,
		in_js_class				=> 'Controls.CmsTab',
		in_description			=> in_description,
		in_js_include			=> '/csr/site/property/properties/controls/CmsTab.js',
		in_cs_class				=> 'Credit360.Plugins.PluginDto',
		in_details				=> 'This tab infomation coming from a custom form.',
		in_tab_sid				=> in_tab_sid,
		in_form_path			=> in_form_path
	);
END;

FUNCTION SetMeterPlugin(
	in_group_key			IN	plugin.group_key%TYPE,
	in_control_lookup_keys	IN  plugin.control_lookup_keys%TYPE,
	in_description			IN	plugin.description%TYPE
) RETURN plugin.plugin_id%TYPE
AS

BEGIN
	RETURN csr.plugin_pkg.SetCustomerPlugin(
		in_plugin_type_id		=> csr.csr_data_pkg.PLUGIN_TYPE_PROPERTY_TAB,
		in_js_class				=> 'Controls.MeterTab',
		in_description			=> in_description,
		in_js_include			=> '/csr/site/property/properties/controls/MeterTab.js',
		in_cs_class				=> 'Credit360.Plugins.PluginDto',
		in_details				=> 'This tab shows meters for the property matching the given group key and enables managing of meter readings.',
		in_group_key			=> in_group_key,
		in_control_lookup_keys	=> in_control_lookup_keys
	);
END;

PROCEDURE SetEnergyStar(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_pm_building_id		IN	property.pm_building_id%TYPE,
	in_sync					IN	property.energy_star_sync%TYPE,
	in_push					IN	property.energy_star_push%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the property with sid '||in_region_sid);
	END IF;

	UPDATE all_property
	   SET energy_star_sync = in_sync,
		   energy_star_push = in_push
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND region_sid = in_region_sid;

	SetPmBuildingId(in_region_sid, in_pm_building_id);

	-- Flush any change log entries created during this transaction
	-- as they will have been created before changing the enrgy star
	-- settings, the settings affect which jobs should be created.
	energy_star_job_pkg.DeleteChangeLogs(in_region_sid);

	-- Force an update for 'pull' properties
	IF in_sync != 0 AND in_push = 0 THEN
		UPDATE est_building
		   SET last_job_dtm = NULL
		 WHERE pm_building_id = in_pm_building_id;
	END IF;

	-- Create new change log enetries for the region using the new settings
	energy_star_job_pkg.OnRegionChange(in_region_sid);
END;

PROCEDURE SetGresbAssetId(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_asset_id				IN	property_gresb.asset_id%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the property with sid '||in_region_sid);
	END IF;

	BEGIN
		INSERT INTO property_gresb (app_sid, region_sid, asset_id)
		VALUES (SYS_CONTEXT('SECURITY', 'APP'), in_region_sid, in_asset_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE property_gresb
				SET asset_id = in_asset_id
				WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				AND region_sid = in_region_sid;
	END;
END;

PROCEDURE ClearGresbAssetId(
	in_region_sid			IN	security_pkg.T_SID_ID
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the property with sid '||in_region_sid);
	END IF;

	DELETE property_gresb
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND region_sid = in_region_sid;
END;

PROCEDURE DeletePropertyType(
	in_property_type_id	IN	property_type.property_type_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can remove property types');
	END IF;

	-- Will this throw constraint exceptions with csr.property_type????
	DELETE FROM property_type_space_type
	 WHERE property_type_id = in_property_type_id
	   AND app_sid = security_pkg.GetApp;

	--Clear of sub types. Might throw exceptions as well.
	DELETE FROM property_sub_type
	 WHERE property_type_id = in_property_type_id
	   AND app_sid = security_pkg.GetApp;

	DELETE FROM property_type
	 WHERE property_type_id = in_property_type_id
	   AND app_sid = security_pkg.GetApp;
END;

PROCEDURE DeletePropertySubType(
	in_property_sub_type_id	IN	property_sub_type.property_sub_type_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can remove property sub-types');
	END IF;

	DELETE FROM property_sub_type
	 WHERE property_sub_type_id = in_property_sub_type_id
	   AND app_sid = security_pkg.GetApp;
END;

PROCEDURE SetPropertyType(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_prop_type_id			IN	property_type.property_type_id%TYPE,
	in_prop_sub_type_id		IN	property_sub_type.property_sub_type_id%TYPE	DEFAULT NULL
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the property with sid '||in_region_sid);
	END IF;

	UPDATE all_property
	   SET property_type_id = in_prop_type_id,
		   property_sub_type_id = in_prop_sub_type_id
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND region_sid = in_region_sid
	   AND property_type_id != in_prop_type_id; -- Prevent updating the sub-type id (which might be passes in as null) unless the property type id has actually changed

	FOR r IN (
		SELECT DISTINCT space_type_id
		  FROM space
		 WHERE property_region_sid = in_region_sid
	) LOOP
		BEGIN
			INSERT INTO property_type_space_type (property_type_id, space_type_id)
			VALUES (in_prop_type_id, r.space_type_id);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL; -- Ignore dupes
		END;
	END LOOP;

	UPDATE all_space
	   SET property_type_id = in_prop_type_id
	 WHERE property_region_sid = in_region_sid
	   AND property_type_id != in_prop_type_id;
END;

PROCEDURE SetPropertyTypeWithCheck(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_prop_type_id			IN	property_type.property_type_id%TYPE,
	in_prop_sub_type_id		IN	property_sub_type.property_sub_type_id%TYPE	DEFAULT NULL
)
AS
	v_existing_prop_type_id	property_type.property_type_id%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the property with sid '||in_region_sid);
	END IF;

	-- Get the existing property type
	SELECT property_type_id
	  INTO v_existing_prop_type_id
	  FROM property
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND region_sid = in_region_sid;

	-- If the old property type is not set then it's safe to change
	IF v_existing_prop_type_id IS NOT NULL THEN

		-- If the space types for the new property type encompass the
		-- space types for the old property type then it's safe to change
		FOR st IN (
			SELECT space_type_id
			  FROM property_type_space_type
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND property_type_id = v_existing_prop_type_id
			MINUS
			SELECT space_type_id
			  FROM property_type_space_type
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND property_type_id = in_prop_type_id
		)
		LOOP
			-- If the space type sets don't overlap as required then it's only safe
			-- to change if there are no region metric values
			-- (which are associated with the space types)
			FOR rm IN (
				SELECT 1
				  FROM property_type_space_type p
				  JOIN space_type_region_metric s ON p.app_sid = s.app_sid AND p.space_type_id = s.space_type_id
				  JOIN region_metric_val v ON s.app_sid = v.app_sid AND s.ind_sid = v.ind_sid
				 WHERE p.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND p.property_type_id = v_existing_prop_type_id
				   AND v.region_sid = in_region_sid
			) LOOP
				RAISE_APPLICATION_ERROR(-20001, 'Not safe to change property type id from '||v_existing_prop_type_id||' to id '||in_prop_type_id||' for region with sid '||in_region_sid);
			END LOOP;

			EXIT;
		END LOOP;
	END IF;

	-- If we get here then it should be ok to change the property type
	SetPropertyType(
		in_region_sid,
		in_prop_type_id,
		in_prop_sub_type_id
	);
END;

PROCEDURE UNSEC_MakeRegionMetric (
	in_ind_sid						IN  security_pkg.T_SID_ID,
	in_region_type					IN  region_type_metric.region_type%TYPE
)
AS
	v_count							NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM region_metric
	 WHERE ind_sid = in_ind_sid;

	IF v_count = 0 THEN
		region_metric_pkg.SetMetric(in_ind_sid);
	END IF;

	BEGIN
		INSERT INTO region_type_metric (region_type, ind_sid)
			 VALUES (in_region_type, in_ind_sid);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
END;

PROCEDURE UNSEC_CleanPropMetricsNotInUse
AS
BEGIN
	-- clean up any region type metrics that are no longer in use
	DELETE FROM region_type_metric
		  WHERE region_type = csr_data_pkg.REGION_TYPE_PROPERTY
			AND ind_sid NOT IN (
				SELECT i.ind_sid
				  FROM property_character_layout pcl
				  JOIN ind i ON pcl.app_sid = i.app_sid
				   AND ((pcl.ind_sid IS NOT NULL AND pcl.ind_sid = i.ind_sid)
					OR (pcl.ind_sid IS NULL AND pcl.element_name = i.lookup_key))
				 UNION
				SELECT i.ind_sid
				  FROM property_element_layout pel
				  JOIN ind i ON pel.app_sid = i.app_sid
				   AND ((pel.ind_sid IS NOT NULL AND pel.ind_sid = i.ind_sid)
					OR (pel.ind_sid IS NULL AND pel.element_name = i.lookup_key))
			);
END;

PROCEDURE GetEditPageBuildingElements (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT pel.element_name, pel.pos, pel.ind_sid, pel.tag_group_id,
			   i.description ind_description, tg.name tag_group_name,
			   rm.is_mandatory, rm.show_measure
		  FROM property_element_layout pel
		  LEFT JOIN v$ind i ON pel.app_sid = i.app_sid AND pel.ind_sid = i.ind_sid
		  LEFT JOIN v$tag_group tg ON pel.app_sid = tg.app_sid AND pel.tag_group_id = tg.tag_group_id
		  LEFT JOIN region_metric rm ON pel.app_sid = rm.app_sid AND pel.ind_sid = rm.ind_sid
		 WHERE pel.app_sid = security.security_pkg.GetApp
		 ORDER BY pel.pos;
END;

PROCEDURE AddEditPageBuildingElement (
	in_element_name			IN	property_element_layout.element_name%TYPE,
	in_pos					IN	property_element_layout.pos%TYPE,
	in_ind_sid				IN  property_element_layout.ind_sid%TYPE,
	in_tag_group_id			IN  property_element_layout.tag_group_id%TYPE,
	in_is_mandatory			IN  region_metric.is_mandatory%TYPE,
	in_show_measure			IN  region_metric.show_measure%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can edit property elements.');
	END IF;

	IF in_ind_sid IS NOT NULL THEN
		UNSEC_MakeRegionMetric(in_ind_sid, csr_data_pkg.REGION_TYPE_PROPERTY);

		UPDATE region_metric
		   SET is_mandatory = in_is_mandatory,
			   show_measure = in_show_measure
		 WHERE ind_sid = in_ind_sid;
	END IF;

	--Changed to upsert means if someone tries to add a new item with same name will update the other but ListControl doesn't tell you if it is a edit save or a new save.
	BEGIN
		INSERT INTO property_element_layout (element_name, pos, ind_sid, tag_group_id)
		VALUES (in_element_name, in_pos, in_ind_sid, in_tag_group_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE property_element_layout
			   SET pos = in_pos
			 WHERE ind_sid = in_ind_sid
				OR tag_group_id = in_tag_group_id
				OR (ind_sid IS NULL AND tag_group_id IS NULL AND element_name = in_element_name);
	END;
END;

PROCEDURE RemoveEditPageBuildingElement (
	in_element_name					IN	VARCHAR2
)
AS
	v_ind_sid						security_pkg.T_SID_ID;
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can edit property elements.');
	END IF;

	SELECT ind_sid
	  INTO v_ind_sid
	  FROM property_element_layout
	 WHERE element_name = in_element_name;

	DELETE FROM property_element_layout
	 WHERE element_name = in_element_name
	   AND app_sid = security.security_pkg.GetApp;

	IF v_ind_sid IS NOT NULL THEN
		UNSEC_CleanPropMetricsNotInUse;
	END IF;
END;

PROCEDURE GetViewPageBuildingElements (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT pcl.element_name, pcl.pos, pcl.col, pcl.ind_sid, pcl.tag_group_id,
			   i.description ind_description, tg.name tag_group_name, rm.show_measure
		  FROM property_character_layout pcl
		  LEFT JOIN v$ind i ON pcl.app_sid = i.app_sid AND pcl.ind_sid = i.ind_sid
		  LEFT JOIN v$tag_group tg ON pcl.app_sid = tg.app_sid AND pcl.tag_group_id = tg.tag_group_id
		  LEFT JOIN region_metric rm ON pcl.app_sid = rm.app_sid AND pcl.ind_sid = rm.ind_sid
		 WHERE pcl.app_sid = security.security_pkg.GetApp
		 ORDER BY pcl.pos;
END;

PROCEDURE AddViewPageBuildingElement (
	in_element_name			IN	property_character_layout.element_name%TYPE,
	in_pos					IN	property_character_layout.pos%TYPE,
	in_col					IN	property_character_layout.col%TYPE,
	in_ind_sid				IN  property_character_layout.ind_sid%TYPE,
	in_tag_group_id			IN  property_character_layout.tag_group_id%TYPE,
	in_show_measure			IN  region_metric.show_measure%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can edit property elements.');
	END IF;

	IF in_ind_sid IS NOT NULL THEN
		UNSEC_MakeRegionMetric(in_ind_sid, csr_data_pkg.REGION_TYPE_PROPERTY);

		UPDATE region_metric
		   SET show_measure = in_show_measure
		 WHERE ind_sid = in_ind_sid;
	END IF;

	--Changed to upsert means if someone tries to add a new item with same name will update the other but ListControl doesn't tell you if it is a edit save or a new save.
	BEGIN
		INSERT INTO property_character_layout (element_name, pos, col, ind_sid, tag_group_id)
		VALUES (in_element_name, in_pos, NVL(in_col, 0), in_ind_sid, in_tag_group_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE property_character_layout
			   SET pos = in_pos,
				   col = NVL(in_col, 0)
			 WHERE ind_sid = in_ind_sid
				OR tag_group_id = in_tag_group_id
				OR (ind_sid IS NULL AND tag_group_id IS NULL AND element_name = in_element_name);
	END;
END;

PROCEDURE RemoveViewPageBuildingElement (
	in_element_name					IN	VARCHAR2
)
AS
	v_ind_sid						security_pkg.T_SID_ID;
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can edit property elements.');
	END IF;

	SELECT ind_sid
	  INTO v_ind_sid
	  FROM property_character_layout
	 WHERE element_name = in_element_name;

	DELETE FROM property_character_layout
	 WHERE element_name = in_element_name
	   AND app_sid = security.security_pkg.GetApp;

	IF v_ind_sid IS NOT NULL THEN
		UNSEC_CleanPropMetricsNotInUse;
	END IF;
END;

PROCEDURE GetActiveCountries (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT country, name FROM postcode.country
		 WHERE country IN (SELECT DISTINCT country_code FROM v$property)
		 ORDER BY LOWER(name);
END;

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

PROCEDURE GetPageMeterElements (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT mel.meter_element_layout_id, mel.pos, mel.ind_sid, i.description,
				mel.tag_group_id, tg.name tag_group_name, rm.is_mandatory, rm.show_measure
		  FROM meter_element_layout mel
		  LEFT JOIN v$ind i ON i.ind_sid = mel.ind_sid
		  LEFT JOIN v$tag_group tg ON tg.tag_group_id = mel.tag_group_id
		  LEFT JOIN region_metric rm ON mel.app_sid = rm.app_sid AND mel.ind_sid = rm.ind_sid
		 WHERE mel.app_sid = security.security_pkg.GetApp
		 ORDER BY mel.pos;
END;

PROCEDURE AddPageMeterElement (
	in_meter_element_layout_id		IN	meter_element_layout.meter_element_layout_id%TYPE,
	in_pos							IN	meter_element_layout.pos%TYPE,
	in_ind_sid						IN  meter_element_layout.ind_sid%TYPE,
	in_tag_group_id					IN  meter_element_layout.tag_group_id%TYPE,
	in_is_mandatory					IN  region_metric.is_mandatory%TYPE,
	in_show_measure					IN  region_metric.show_measure%TYPE,
	out_meter_element_layout_id		OUT	meter_element_layout.meter_element_layout_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can edit property elements.');
	END IF;

	IF in_ind_sid IS NOT NULL THEN
		UNSEC_MakeRegionMetric(in_ind_sid, csr_data_pkg.REGION_TYPE_METER);

		UPDATE region_metric
		   SET is_mandatory = in_is_mandatory,
			   show_measure = in_show_measure
		 WHERE ind_sid = in_ind_sid;
	END IF;

	IF in_tag_group_id IS NOT NULL THEN
		-- XXX: force a lookup key on the tag group if there isn't one, since properties relies on this.
		-- we need to refactor this properly and get rid of the dependency on lookup keys
		UPDATE tag_group
		   SET lookup_key = tag_group_id
		 WHERE tag_group_id = in_tag_group_id
		   AND app_sid = security.security_pkg.GetApp
		   AND lookup_key IS NULL;
	END IF;

	--Changed to upsert means if someone tries to add a new item with same name will update the other but ListControl doesn't tell you if it is a edit save or a new save.
	IF in_meter_element_layout_id IS NULL THEN
		INSERT INTO meter_element_layout (meter_element_layout_id, ind_sid, pos, tag_group_id)
		VALUES (meter_element_layout_id_seq.nextval, in_ind_sid, in_pos, in_tag_group_id)
		RETURNING meter_element_layout_id INTO out_meter_element_layout_id;
	ELSE
		UPDATE meter_element_layout
		   SET pos = in_pos
		 WHERE meter_element_layout_id = in_meter_element_layout_id;

		out_meter_element_layout_id := in_meter_element_layout_id;
	END IF;
END;

PROCEDURE RemovePageMeterElement (
	in_meter_element_layout_id		IN	meter_element_layout.meter_element_layout_id%TYPE
)
AS
	v_ind_sid						security_pkg.T_SID_ID;
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can edit property elements.');
	END IF;

	SELECT ind_sid
	  INTO v_ind_sid
	  FROM meter_element_layout
	 WHERE meter_element_layout_id = in_meter_element_layout_id;

	DELETE FROM meter_element_layout
	 WHERE meter_element_layout_id = in_meter_element_layout_id
	   AND app_sid = security.security_pkg.GetApp;

	IF v_ind_sid IS NOT NULL THEN
		-- clean up any region type metrics that are no longer in use
		DELETE FROM region_type_metric
			  WHERE region_type = csr_data_pkg.REGION_TYPE_METER
				AND ind_sid NOT IN (
					SELECT ind_sid
					  FROM meter_element_layout
					 WHERE ind_sid IS NOT NULL
					 UNION
					SELECT ind_sid
					  FROM meter_header_element
					 WHERE ind_sid IS NOT NULL
				);
	END IF;
END;

-- GeocodeProperties Batchjob Plugin SP (All unsecure, only called from batchjob)
PROCEDURE GetPropertiesToGeocode (
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_cur FOR
		SELECT r.region_sid, p.street_addr_1 street, p.city, p.state, c.name country, p.postcode
		  FROM csr.region r
		  JOIN csr.property p ON r.region_sid = p.region_sid
		  JOIN postcode.country c ON c.country = r.geo_country
		 WHERE r.geo_type != 0
		   AND p.postcode IS NOT NULL
		   AND r.geo_country IS NOT NULL;

END;

PROCEDURE SetPropertyGeoData (
	in_region_sid		 			IN	security_pkg.T_SID_ID,
	in_latitude						IN	region.geo_latitude%TYPE,
	in_longitude					IN	region.geo_longitude%TYPE,
	in_state						IN	property.state%TYPE,
	in_city							IN	property.city%TYPE
)
AS
BEGIN

	UPDATE csr.property
	   SET state = in_state,
			city = in_city
	 WHERE region_sid = in_region_sid;

	region_pkg.SetLatLong(
		in_region_sid	=>	in_region_sid,
		in_latitude		=>	in_latitude,
		in_longitude	=>	in_longitude
	);

END;

FUNCTION CountProperiesNotGeocoded RETURN NUMBER
IS
	v_count		NUMBER;
BEGIN

	SELECT count(*)
	  INTO v_count
	  FROM csr.region r
	  JOIN csr.property p ON r.region_sid = p.region_sid
	  JOIN postcode.country c ON c.country = r.geo_country
	 WHERE r.geo_type != 0
	   AND p.postcode IS NOT NULL
	   AND r.geo_country IS NOT NULL;

	RETURN v_count;
END;

FUNCTION PropertyGeocodeBatchJob RETURN NUMBER
IS
	v_batch_job_id		csr.batch_job.batch_job_id%TYPE;
BEGIN
	csr.batch_job_pkg.Enqueue(
		in_batch_job_type_id => csr.batch_job_pkg.jt_batch_prop_geocode,
		in_description => 'Batch Property Geocode',
		in_total_work => 1,
		out_batch_job_id => v_batch_job_id
	);

	RETURN v_batch_job_id;
END;

PROCEDURE GetGresbPropertyTypes (
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- no security - base data
	OPEN out_cur FOR
		SELECT gresb_property_type_id, name, pos
		  FROM gresb_property_type
		  ORDER BY pos ASC;
END;

PROCEDURE GetGresbPropertySubTypes (
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- no security - base data
	OPEN out_cur FOR
		SELECT st.gresb_property_type_id, st.gresb_property_sub_type_id, st.name, st.gresb_code, st.pos
		  FROM gresb_property_sub_type st
		  JOIN gresb_property_type t ON st.gresb_property_type_id = t.gresb_property_type_id
		  ORDER BY t.pos, st.pos ASC;
END;

PROCEDURE GetGresbServiceConfig (
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- no security for base config
	OPEN out_cur FOR
		SELECT gsc.name, gsc.url, gsc.oauth_url, gsc.client_id, gsc.client_secret
		  FROM gresb_service_config gsc
		  JOIN property_options po ON gsc.name = po.gresb_service_config
		 WHERE po.app_sid = security.security_pkg.GetApp;
END;

PROCEDURE GetPropertyOptions(
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- no security check needed
	OPEN out_cur FOR
		SELECT fund_company_type_id, auto_assign_manager, gresb_service_config, show_inherited_roles
		  FROM property_options
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE SavePropertyOptions(
	in_fund_company_type_id			IN NUMBER,
	in_auto_assign_manager			IN NUMBER,
	in_gresb_service_config			IN VARCHAR2,
	in_show_inherited_roles			IN NUMBER)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can edit property options');
	END IF;

	BEGIN
		INSERT INTO property_options(fund_company_type_id, auto_assign_manager, gresb_service_config, show_inherited_roles)
			 VALUES (in_fund_company_type_id, in_auto_assign_manager, in_gresb_service_config, in_show_inherited_roles);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE property_options
			   SET fund_company_type_id = in_fund_company_type_id,
				   auto_assign_manager = in_auto_assign_manager,
				   gresb_service_config = in_gresb_service_config,
				   show_inherited_roles = in_show_inherited_roles
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	END;
END;

PROCEDURE GetMandatoryRoles(
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT role_sid FROM property_mandatory_roles;
END;

PROCEDURE SetMandatoryRoles(
	in_role_sids					IN security_pkg.T_SID_IDS
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can edit property options');
	END IF;

	DELETE FROM property_mandatory_roles;

	FOR i IN in_role_sids.FIRST .. in_role_sids.LAST
	LOOP
		IF in_role_sids(i) IS NOT NULL THEN
			INSERT INTO property_mandatory_roles (role_sid) VALUES (in_role_sids(i));
		END IF;
	END LOOP;
END;

PROCEDURE CreatePropertyDocLibFolder(
	in_property_sid					IN	security_pkg.T_SID_ID,
	out_folder_sid					OUT security_pkg.T_SID_ID
)
AS
	v_doc_lib						security_pkg.T_SID_ID := GetPropertyDocLib;
	v_property_description			v$property.description%TYPE;
BEGIN
	out_folder_sid := NULL;

	-- Property doc lib is not enabled for the site, do nothing
	IF v_doc_lib IS NULL THEN
		RETURN;
	END IF;

	BEGIN
		SELECT doc_folder_sid
		  INTO out_folder_sid
		  FROM doc_folder
		 WHERE property_sid = in_property_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			out_folder_sid := NULL;
	END;

	-- The folder already exists
	IF out_folder_sid IS NOT NULL THEN
		RETURN;
	END IF;

	SELECT description
	  INTO v_property_description
	  FROM v$property
	 WHERE region_sid = in_property_sid;

	doc_folder_pkg.CreateFolder(
		in_parent_sid 			=> doc_folder_pkg.GetDocumentsFolder(v_doc_lib),
		in_name 				=> FormatDocFolderName(v_property_description, in_property_sid),
		in_property_sid 		=> in_property_sid,
		in_is_system_managed	=> 1,
		out_sid_id 				=> out_folder_sid
	);
END;

PROCEDURE CreateMissingDocLibFolders
AS
	v_folder_sid					security_pkg.T_SID_ID;
BEGIN
	FOR r IN (SELECT region_sid
				FROM property
			   WHERE region_sid NOT IN (SELECT property_sid
										  FROM doc_folder
										 WHERE property_sid IS NOT NULL))
	LOOP
		CreatePropertyDocLibFolder(r.region_sid, v_folder_sid);
	END LOOP;
END;

FUNCTION GetDocLibFolder (
	in_property_sid					IN security_pkg.T_SID_ID
) RETURN security_pkg.T_SID_ID
AS
	v_doc_lib						security_pkg.T_SID_ID := GetPropertyDocLib;
	v_doc_folder					security_pkg.T_SID_ID := NULL;
BEGIN
	IF v_doc_lib IS NOT NULL THEN
		BEGIN
			SELECT df.doc_folder_sid
			  INTO v_doc_folder
			  FROM doc_folder df
			  JOIN security.securable_object so ON so.sid_id = df.doc_folder_sid
			 WHERE df.property_sid = in_property_sid
			   AND df.is_system_managed = 1
			   AND so.parent_sid_id = doc_folder_pkg.GetDocumentsFolder(v_doc_lib);
		EXCEPTION
			WHEN NO_DATA_FOUND THEN NULL;
		END;
	END IF;

	RETURN v_doc_folder;
END;

FUNCTION GetPropertyDocLib
  RETURN security_pkg.T_SID_ID
AS
	v_app_sid						security_pkg.T_SID_ID := security_pkg.GetApp;
	v_act_id						security_pkg.T_ACT_ID := security_pkg.GetAct;
BEGIN
	BEGIN
		RETURN securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'PropertyDocuments');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN RETURN NULL;
	END;
END;

FUNCTION GetPermissibleDocumentFolders (
	in_doc_library_sid				IN  security_pkg.T_SID_ID
) RETURN security.T_SID_TABLE
AS
	v_sids							security.T_SID_TABLE;
BEGIN
	-- Only checking for read access
	SELECT DISTINCT df.doc_folder_sid
	  BULK COLLECT INTO v_sids
	  FROM doc_folder df
	  JOIN v$my_property p ON df.property_sid = p.region_sid;

	RETURN v_sids;
END;

FUNCTION CheckDocumentPermissions (
	in_property_sid					IN  security_pkg.T_SID_ID,
	in_permission_set				IN  security_pkg.T_PERMISSION
) RETURN BOOLEAN
AS
	v_can_view						BOOLEAN;
	v_can_edit						NUMBER;
	v_mapped						security_pkg.T_PERMISSION := 0;
BEGIN
	v_can_view := CanViewProperty(in_property_sid, v_can_edit);

	IF v_can_view THEN
		v_mapped := v_mapped +
			security_pkg.PERMISSION_READ +
			security_pkg.PERMISSION_READ_ATTRIBUTES +
			security_pkg.PERMISSION_LIST_CONTENTS;
	END IF;

	IF v_can_edit != 0 THEN
		v_mapped := v_mapped +
			security_pkg.PERMISSION_WRITE +
			security_pkg.PERMISSION_ADD_CONTENTS +
			security_pkg.PERMISSION_DELETE;
	END IF;

	RETURN BITAND(v_mapped, in_permission_set) = in_permission_set;
END;

PROCEDURE GetAuditLogForPropertyPaged(
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_start_row		IN	NUMBER,
	in_page_size		IN	NUMBER,
	in_start_date		IN	DATE,
	in_end_date			IN	DATE,
	in_search			IN	VARCHAR2,
	out_total			OUT	NUMBER,
	out_cur				OUT	SYS_REFCURSOR
)
AS
	v_app_sid security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
	v_sid_table			security.T_SID_TABLE;
BEGIN
	-- some security check
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the property with sid '||in_region_sid);
	END IF;

	-- get associated spaces
	WITH r AS (
		SELECT region_sid
		  --BULK COLLECT INTO v_sid_table
		  FROM region
		 WHERE region_type IN (
					csr_data_pkg.REGION_TYPE_PROPERTY,
					csr_data_pkg.REGION_TYPE_REALTIME_METER,
					csr_data_pkg.REGION_TYPE_SPACE,
					csr_data_pkg.REGION_TYPE_METER
			)
		 START WITH region_sid = in_region_sid
	   CONNECT BY PRIOR region_sid = parent_sid
		 UNION
		SELECT region_sid
		  FROM space
		 WHERE property_region_sid = in_region_sid
	)
	SELECT region_sid
	  BULK COLLECT INTO v_sid_table
	  FROM (
		SELECT region_sid FROM r
		 UNION
		SELECT trash_sid
		  FROM trash t
		  JOIN r ON t.previous_parent_sid = r.region_sid
		);

	INSERT INTO temp_audit_log_ids(row_id, audit_dtm)
	(SELECT /*+ INDEX (audit_log IDX_AUDIT_LOG_OBJECT_SID) */ al.rowid, al.audit_date
	   FROM audit_log al
	   JOIN TABLE(v_sid_table) sids ON al.object_sid = sids.column_value
	   JOIN v$region r ON r.region_sid = sids.column_value
	   JOIN csr_user cu ON al.user_sid = cu.csr_user_sid
	   JOIN region_type rt ON r.region_type = rt.region_type
	  WHERE al.app_sid = v_app_sid
		AND al.audit_date >= in_start_date AND al.audit_date <= in_end_date+1
		AND (in_search IS NULL OR (
			LOWER(r.description) LIKE '%'||LOWER(in_search)||'%'
			OR LOWER(cu.full_name) LIKE '%'||LOWER(in_search)||'%'
			OR LOWER(al.param_1) LIKE '%'||LOWER(in_search)||'%'
			OR LOWER(rt.label) LIKE '%'||LOWER(in_search)||'%')
			)
		);

	SELECT COUNT(row_id)
	  INTO out_total
	  FROM temp_audit_log_ids;

	OPEN out_cur FOR
		SELECT al.audit_date, aut.label, cu.user_name, cu.full_name, al.param_1, al.param_2,
			   al.param_3, al.description, al.remote_addr, r.description region_desc, rt.label region_type
		  FROM (SELECT row_id, rn
				  FROM (SELECT row_id, rownum rn
						  FROM (SELECT row_id
								  FROM temp_audit_log_ids
							  ORDER BY audit_dtm DESC, row_id DESC)
						 WHERE rownum < in_start_row + in_page_size)
				 WHERE rn >= in_start_row) alr
		  JOIN audit_log al ON al.rowid = alr.row_id
		  JOIN csr_user cu ON cu.csr_user_sid = al.user_sid
		  JOIN v$region r ON al.object_sid = r.region_sid
		  JOIN audit_type aut ON aut.audit_type_id = al.audit_type_id
		  JOIN region_type rt ON rt.region_type = r.region_type
	  ORDER BY al.audit_date DESC;
END;

END;
/
