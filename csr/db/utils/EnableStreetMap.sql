PROMPT ***************************************************
PROMPT Available providers:
PROMPT ***************************************************
PROMPT OpenStreetMap        0
PROMPT ShadedRelief         1
PROMPT BlueMarble           2
PROMPT MicrosoftAerial      3
PROMPT MicrosoftHybrid      4
PROMPT MicrosoftRoad        5
PROMPT YahooAerial          6
PROMPT YahooHybrid          7
PROMPT YahooRoad            8
PROMPT 
PROMPT ***************************************************
PROMPT Available contexts:
PROMPT ***************************************************
PROMPT DATA EXPLORER        1
PROMPT SNAPSHOT VIEWER      2
PROMPT TARGET DASHBOARD     3
PROMPT INITIATIVES          4
PROMPT 
DEFINE host = '&&host'
DEFINE provider = '&&provider'
DEFINE context = '&&context'

DECLARE	
	v_map_id		security_pkg.T_SID_ID;
	v_config_path	varchar2(1024);
BEGIN
	security.user_pkg.logonadmin('&&host');
	
	SELECT 
		CASE &provider
			WHEN 0 THEN '/fp/shared/map/OpenStreetMap.js'
			WHEN 1 THEN '/fp/shared/map/ShadedRelief.js'
			WHEN 2 THEN '/fp/shared/map/BlueMarble.js'
			WHEN 3 THEN '/fp/shared/map/MicrosoftAerial.js'
			WHEN 4 THEN '/fp/shared/map/MicrosoftHybrid.js'
			WHEN 5 THEN '/fp/shared/map/MicrosoftRoad.js'
			WHEN 6 THEN '/fp/shared/map/YahooAerial.js'
			WHEN 7 THEN '/fp/shared/map/YahooHybrid.js'
			WHEN 8 THEN '/fp/shared/map/YahooRoad.js'
		END provider INTO v_config_path 
	FROM DUAL;
		
	
	-- create record in db, that will enable code to display map
	INSERT INTO csr.customer_map (app_sid, map_id, map_context, config_path) 
	     VALUES (sys_context('SECURITY', 'APP'), csr.map_id_seq.nextval, &context, v_config_path)
	   RETURNING map_id INTO v_map_id;
	
	-- associate map with world-countries shpfile
	-- for custom shpfiles contact emil@credit360.com
	-- we don't want any shpfile with INITIATIVES (it shows points only atm)
	IF &context != 4 THEN
		INSERT INTO csr.map_shpfile(app_sid, map_id, shpfile, geo_field, geo_country, z_order) 
			VALUES	(sys_context('SECURITY', 'APP'), v_map_id, '/fp/shared/map/shp/world/world.shp', 'ISO_2_CODE', null, 0);
	END IF;
	COMMIT;
END;
/