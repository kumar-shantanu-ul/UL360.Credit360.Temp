-- Please update version.sql too -- this keeps clean builds in sync
define version=1817
@update_header

CREATE OR REPLACE VIEW csr.v$resolved_region AS
	SELECT /*+ALL_ROWS*/ r.app_sid, r.region_sid, r.link_to_region_sid, r.parent_sid,
	  	   -- this pattern is a bit messier than NVL, but it avoids taking properties off the link
	  	   -- in the case that the property is unset on the region -- that's only possible if it's
	  	   -- nullable, but quite a few of the properties are.  They should not be set on the link,
	  	   -- but we don't want to return duff data because we do end up with links with properties.
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.name ELSE r.name END name,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.active ELSE r.active END active,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.pos ELSE r.pos END pos,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.info_xml ELSE r.info_xml END info_xml,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.flag ELSE r.flag END flag,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.acquisition_dtm ELSE r.acquisition_dtm END acquisition_dtm,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.disposal_dtm ELSE r.disposal_dtm END disposal_dtm,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.region_type ELSE r.region_type END region_type,
		   r.lookup_key,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.geo_country ELSE r.geo_country END geo_country,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.geo_region ELSE r.geo_region END geo_region,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.geo_city_id ELSE r.geo_city_id END geo_city_id,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.geo_longitude ELSE r.geo_longitude END geo_longitude,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.geo_latitude ELSE r.geo_latitude END geo_latitude,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.geo_type ELSE r.geo_type END geo_type,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.map_entity ELSE r.map_entity END map_entity,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.egrid_ref ELSE r.egrid_ref END egrid_ref,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.egrid_ref_overridden ELSE r.egrid_ref_overridden END egrid_ref_overridden,
		   -- If either the region or the region link is modified, then the resolved region
		   -- should appear to be modified.  GREATEST returns null if any of its arguments are
		   -- null, so the below ensures that we get the greatest non-null modified date.
		   GREATEST(NVL(r.last_modified_dtm, rl.last_modified_dtm),
				    NVL(rl.last_modified_dtm, r.last_modified_dtm)) last_modified_dtm
	  FROM region r
	  LEFT JOIN region rl ON r.link_to_region_sid = rl.region_sid AND r.app_sid = rl.app_sid;


@update_tail