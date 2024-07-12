-- Please update version.sql too -- this keeps clean builds in sync
define version=3119
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

CREATE OR REPLACE FUNCTION csr.ConcatTags(
	in_ind_sid			IN	csr.ind.ind_sid%TYPE
) RETURN VARCHAR2
AS
	v_s	VARCHAR2(32767);
	v_sep VARCHAR2(10);
BEGIN
	v_s := '';
	v_sep := '';
	FOR r IN (
		SELECT tag FROM IND_TAG it, csr.v$TAG t 
		 WHERE IND_SID = in_ind_sid
		   AND it.tag_id = t.tag_id
	)
	LOOP
		v_s := v_s || v_sep || r.tag;		
		v_sep := ', ';
	END LOOP;
	RETURN v_s;
END;
/

CREATE OR REPLACE FUNCTION CSR.GetKPIClass(
	in_app_sid		IN 	security_pkg.T_SID_ID,
	in_region_sid	IN 	csr.region.region_sid%TYPE

)	RETURN csr.tag_description.tag%TYPE
IS
	v_classification	csr.tag_description.tag%TYPE;
BEGIN
	SELECT t.tag
	  INTO v_classification
	  FROM csr.region r
	 INNER JOIN csr.region_tag rt
		ON r.region_sid = rt.region_sid
	 INNER JOIN csr.v$tag t
		ON t.tag_id = rt.tag_id
	 INNER JOIN csr.tag_group_member tgm
		ON rt.tag_id = tgm.tag_id
	 INNER JOIN csr.v$tag_group tg
		ON tg.tag_group_id = tgm.tag_group_id
	 WHERE r.region_sid = in_region_sid AND
		  tg.name = 'Product Type';
	RETURN v_classification;
END;
/

@update_tail
