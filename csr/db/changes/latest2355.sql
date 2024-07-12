-- Please update version.sql too -- this keeps clean builds in sync
define version=2355
@update_header

UPDATE csr.portlet SET name = 'Target dashboard map' WHERE portlet_id = 3;

DECLARE
	v_cnt	NUMBER;
BEGIN
	SELECT count(*) INTO v_cnt
	  FROM dba_tab_columns
	 WHERE owner = 'CSR'
	   AND table_name = 'GEO_TILESET'
	   AND column_name = 'BASE_CSS_CLASS';

	IF v_cnt = 1 THEN

		EXECUTE IMMEDIATE 'ALTER TABLE CSR.GEO_TILESET DROP ( BASE_CSS_CLASS )';

	END IF;
END;
/

DECLARE
	v_cnt	NUMBER;
BEGIN
	SELECT count(*) INTO v_cnt
	  FROM dba_tab_columns
	 WHERE owner = 'CSR'
	   AND table_name = 'GEO_TILESET'
	   AND column_name = 'SUBDOMAINS';

	IF v_cnt = 0 THEN

		EXECUTE IMMEDIATE 'ALTER TABLE CSR.GEO_TILESET ADD ( SUBDOMAINS VARCHAR2(255) )';
		EXECUTE IMMEDIATE 'UPDATE CSR.GEO_TILESET SET SUBDOMAINS = ''a''';
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.GEO_TILESET MODIFY ( SUBDOMAINS VARCHAR2(255) NOT NULL )';

		COMMIT;

	END IF;
END;
/

DECLARE
	v_cnt	NUMBER;
BEGIN
	SELECT count(*) INTO v_cnt
	  FROM dba_tab_columns
	 WHERE owner = 'CSR'
	   AND table_name = 'GEO_TILESET'
	   AND column_name = 'DEFAULT_ZOOM';

	IF v_cnt = 0 THEN

		EXECUTE IMMEDIATE 'ALTER TABLE CSR.GEO_TILESET ADD ( DEFAULT_ZOOM NUMBER(10) )';
		EXECUTE IMMEDIATE 'UPDATE CSR.GEO_TILESET SET DEFAULT_ZOOM = 13';
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.GEO_TILESET MODIFY ( DEFAULT_ZOOM NUMBER(10) NOT NULL )';

		COMMIT;

	END IF;
END;
/

CREATE OR REPLACE PACKAGE csr.latest_xxx_pkg AS

PROCEDURE UpsertGeoTileset(
	in_geo_tileset_id	IN	csr.geo_tileset.geo_tileset_id%TYPE,
	in_label			IN	csr.geo_tileset.label%TYPE,
	in_lookup_key		IN	csr.geo_tileset.lookup_key%TYPE,
	in_url_template		IN	csr.geo_tileset.url_template%TYPE,
	in_subdomains		IN	csr.geo_tileset.subdomains%TYPE,
	in_attribution		IN	csr.geo_tileset.attribution%TYPE,
	in_min_zoom			IN	csr.geo_tileset.min_zoom%TYPE,
	in_max_zoom			IN	csr.geo_tileset.max_zoom%TYPE,
	in_default_zoom		IN	csr.geo_tileset.default_zoom%TYPE,
	in_tile_size		IN	csr.geo_tileset.tile_size%TYPE
);

END;
/

CREATE OR REPLACE PACKAGE BODY csr.latest_xxx_pkg AS

PROCEDURE UpsertGeoTileset(
	in_geo_tileset_id	IN	csr.geo_tileset.geo_tileset_id%TYPE,
	in_label			IN	csr.geo_tileset.label%TYPE,
	in_lookup_key		IN	csr.geo_tileset.lookup_key%TYPE,
	in_url_template		IN	csr.geo_tileset.url_template%TYPE,
	in_subdomains		IN	csr.geo_tileset.subdomains%TYPE,
	in_attribution		IN	csr.geo_tileset.attribution%TYPE,
	in_min_zoom			IN	csr.geo_tileset.min_zoom%TYPE,
	in_max_zoom			IN	csr.geo_tileset.max_zoom%TYPE,
	in_default_zoom		IN	csr.geo_tileset.default_zoom%TYPE,
	in_tile_size		IN	csr.geo_tileset.tile_size%TYPE
)
AS
BEGIN
	BEGIN
		INSERT INTO csr.geo_tileset 
			(geo_tileset_id,
			 label, lookup_key, 
			 url_template, subdomains,
			 attribution,
			 min_zoom, max_zoom, default_zoom,
			 tile_size)
		VALUES 
			(in_geo_tileset_id,
			 in_label, in_lookup_key,
			 in_url_template, in_subdomains,
			 in_attribution,
			 in_min_zoom, in_max_zoom, in_default_zoom,
			 in_tile_size);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE csr.geo_tileset
			SET label = in_label,
				lookup_key = in_lookup_key,
				url_template = in_url_template,
				subdomains = in_subdomains,
				attribution = in_attribution,
				min_zoom = in_min_zoom,
				max_zoom = in_max_zoom,
				default_zoom = in_default_zoom,
				tile_size = in_tile_size
			WHERE geo_tileset_id = in_geo_tileset_id;
	END;
END;

END;
/

DECLARE
	v_osm_attr			VARCHAR(2000) := 'Map data '||chr(38)||'copy;<a href="http://openstreetmap.org" target="_blank">OpenStreetMap</a> contributors, <a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>';
	v_mq_tiles_attr		VARCHAR(2000) := 'Tiles '||chr(38)||'copy;<a href="http://www.mapquest.com/" target="_blank">MapQuest</a>';
	v_mq_sat_attr		VARCHAR(2000) := 'Imagery '||chr(38)||'copy;<a href="http://www.jpl.nasa.gov/" target="_blank">NASA/JPL-Caltech</a> and <a href="http://www.fsa.usda.gov/" target="_blank">USDA FSA</a>';
BEGIN
	csr.latest_xxx_pkg.UpsertGeoTileset(
		in_geo_tileset_id => 1,
		in_label => 'OpenStreetMap',
		in_lookup_key => 'OPEN_STREET_MAP',
		in_url_template => 'http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
		in_subdomains => 'abc',
		in_attribution => v_osm_attr,
		in_min_zoom => 0,
		in_max_zoom => 18,
		in_default_zoom => 13,
		in_tile_size => 256
	);
	
	csr.latest_xxx_pkg.UpsertGeoTileset(
		in_geo_tileset_id => 2,
		in_label => 'MapQuest OSM',
		in_lookup_key => 'MAP_QUEST_OSM',
		in_url_template => 'http://otile{s}.mqcdn.com/tiles/1.0.0/map/{z}/{x}/{y}.png',
		in_subdomains => '1234',
		in_attribution => v_osm_attr || '; ' || v_mq_tiles_attr, 
		in_min_zoom => 0,
		in_max_zoom => 18,
		in_default_zoom => 13,
		in_tile_size => 256
	);
	
	csr.latest_xxx_pkg.UpsertGeoTileset(
		in_geo_tileset_id => 3,
		in_label => 'MapQuest OSM Aerial',
		in_lookup_key => 'MAP_QUEST_OSM_AERIAL',
		in_url_template => 'http://otile{s}.mqcdn.com/tiles/1.0.0/sat/{z}/{x}/{y}.png',
		in_subdomains => '1234',
		in_attribution => v_mq_sat_attr || '; ' || v_mq_tiles_attr, 
		in_min_zoom => 0,
		in_max_zoom => 18,
		in_default_zoom => 9,
		in_tile_size => 256
	);

	COMMIT;
END;
/

DROP PACKAGE csr.latest_xxx_pkg;

@update_tail
