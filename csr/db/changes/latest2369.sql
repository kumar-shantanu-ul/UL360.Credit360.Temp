-- Please update version.sql too -- this keeps clean builds in sync
define version=2369
@update_header

-- put app_sids on existing client plugins  
ALTER TABLE CSR.PROPERTY_TAB_MOBILE DROP CONSTRAINT FK_PROPERTY_TAB_MOBILE_TAB;
ALTER TABLE CSR.PROPERTY_TAB_GROUP DROP CONSTRAINT FK_PRPTY_TAB_GROUP_PRPTY_TAB;
  
DECLARE
	v_plugin_id		NUMBER(10);
	v_first			BOOLEAN;
BEGIN
	
	FOR j IN (
		SELECT *
		  FROM csr.plugin
		 WHERE app_sid IS NULL
		   AND js_class IN (
			'Kaiser.Controls.HazardousWastePanel',
			'MattelEhs.Controls.CertificationPanel',
			'MattelEhs.Controls.EnergyContractPanel',
			'MattelEhs.Controls.EnergyMeterPanel',
			'MattelEhs.Controls.HeatingMeterPanel',
			'MattelEhs.Controls.WaterMeterPanel',
			'SBB.Controls.CoolingMeterPanel',
			'SBB.Controls.EnergyMeterPanel',
			'SBB.Controls.HeatingMeterPanel',
			'SBB.Controls.WaterMeterPanel'
		)
	) LOOP
		v_first := TRUE;
		FOR r IN (
			SELECT app_sid
			  FROM csr.property_tab
			 WHERE plugin_id = j.plugin_id
			 GROUP BY app_sid
			 ORDER BY app_sid
		) LOOP
			IF v_first THEN
				v_first := FALSE;
				
				UPDATE csr.plugin
				   SET app_sid = r.app_sid
				 WHERE plugin_id = j.plugin_id;
			ELSE
				INSERT INTO csr.plugin (app_sid, plugin_id, plugin_type_id, description, js_include, js_class, cs_class)
				     VALUES (r.app_sid, csr.plugin_id_seq.nextval, j.plugin_type_id, j.description, j.js_include, j.js_class, j.cs_class)
				  RETURNING plugin_id INTO v_plugin_id;
				  
				UPDATE csr.property_tab
				   SET plugin_id = v_plugin_id
				 WHERE app_sid = r.app_sid
				   AND plugin_id = j.plugin_id;
				   
				UPDATE csr.property_tab_group
				   SET plugin_id = v_plugin_id
				 WHERE app_sid = r.app_sid
				   AND plugin_id = j.plugin_id;
				   
				UPDATE csr.property_tab_mobile
				   SET plugin_id = v_plugin_id
				 WHERE app_sid = r.app_sid
				   AND plugin_id = j.plugin_id;
			END IF;
		END LOOP;
	END LOOP;
END;
/

ALTER TABLE CSR.PROPERTY_TAB_MOBILE ADD CONSTRAINT fk_property_tab_mobile_tab 
	FOREIGN KEY (app_sid, plugin_id) 
	REFERENCES csr.property_tab (app_sid, plugin_id)
;

ALTER TABLE CSR.PROPERTY_TAB_GROUP ADD CONSTRAINT FK_PRPTY_TAB_GROUP_PRPTY_TAB 
	FOREIGN KEY (APP_SID, PLUGIN_ID) 
	REFERENCES CSR.PROPERTY_TAB(APP_SID, PLUGIN_ID)
;

@update_tail