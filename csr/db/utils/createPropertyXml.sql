
SELECT EXTRACT(XMLElement(
		"properties", (
			SELECT DBMS_XMLGEN.getxmltype(
				DBMS_XMLGEN.newcontextfromhierarchy('
					SELECT level, 
                        CASE r.region_type
                            WHEN 1 THEN 
                                XMLElement(
                                    "meter", XMLAttributes(
                                        r.region_sid AS "sid",
                                        mi.description AS "type",
                                        r.description AS "description"
                                    )
                                )
                            WHEN 3 THEN 
                                XMLElement(
                                    "property", XMLAttributes(
                                        p.region_sid AS "sid", 
                                        p.description AS "description", 
                                        p.region_ref AS "ref", 
                                        p.street_addr_1 AS "street-addr-1",
                                        p.street_addr_2 AS "street-addr-2",
                                        p.city AS "city",
                                        p.state AS "state",
                                        p.postcode AS "postcode",
                                        p.country_code AS "country-code",
                                        p.property_type_label AS "type",
                                        p.property_sub_type_label AS "sub-type",
                                        TO_CHAR(p.acquisition_dtm,''YYYY-MM-DD'') AS "acquisition-dtm",
                                        TO_CHAR(p.disposal_dtm,''YYYY-MM-DD'') AS "disposal-dtm",
                                        p.lat AS "lat",
                                        p.lat AS "lng",
                                        p.pm_building_id AS "energy-star-building-id"
                                    )
                                )
                            WHEN 8 THEN 
                                XMLElement(
                                    "real-time-meter", XMLAttributes(
                                        r.region_sid AS "sid",
                                        mi.description AS "type",
                                        r.description AS "description"
                                    )
                                ) 
                            WHEN 9 THEN 
                                XMLElement(
                                    "space", XMLAttributes(
                                        r.region_sid AS "sid",
                                        spt.label AS "type",
                                        r.description AS "description"
                                    )
                                ) 
                            ELSE XMLElement(
                                    "region", XMLAttributes(
                                        r.region_sid AS "sid",
                                        r.description AS "description"
                                    )
                                )
                        END "node"
					FROM v$region r
					LEFT JOIN v$property p ON r.region_sid = p.region_sid
					LEFT JOIN space sp ON r.region_sid = sp.region_sid
					LEFT JOIN space_type spt ON sp.space_type_id = spt.space_type_id
					LEFT JOIN all_meter m ON r.region_sid = m.region_sid
					LEFT JOIN v$ind mi ON m.primary_ind_sid = mi.ind_sid
					START WITH r.region_type = 3 AND p.region_sid IS NOT NULL
					CONNECT BY PRIOR r.region_sid = r.parent_sid
				')
			) FROM DUAL
		)
	),'/').getClobVal() FROM dual;

