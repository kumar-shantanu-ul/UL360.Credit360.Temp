-- Please update version.sql too -- this keeps clean builds in sync
define version=2291
@update_header

-- put app_sids on existing client plugins  
ALTER TABLE CSR.INITIATIVE_PROJECT_TAB_GROUP DROP CONSTRAINT FK_INIT_PRJ_TB_INIT_PRJ_TB_GRP;
ALTER TABLE CSR.PROPERTY_TAB_MOBILE DROP CONSTRAINT FK_PROPERTY_TAB_MOBILE_TAB;
ALTER TABLE CSR.PROPERTY_TAB_GROUP DROP CONSTRAINT FK_PRPTY_TAB_GROUP_PRPTY_TAB;
ALTER TABLE CSR.TEAMROOM_TYPE_TAB_GROUP DROP CONSTRAINT FK_TR_TYP_TB_TR_TYP_TB_GRP;
  
DECLARE
	v_plugin_id		NUMBER(10);
	v_first			BOOLEAN;
BEGIN
	FOR j IN (
		SELECT *
		  FROM csr.plugin
		 WHERE app_sid IS NULL
		   AND js_class IN (
			'Otto.Plugins.AuditFactories',
			'Otto.Plugins.FactoryList',
			'Otto.Plugins.OgcSupplierList',
			'Otto.Plugins.RiskFactories',
			'Otto.Plugins.VvcrSupplierList'
		)
	) LOOP
		v_first := TRUE;
		FOR r IN (
			SELECT app_sid
			  FROM chain.company_tab
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
				  
				UPDATE chain.company_tab
				   SET plugin_id = v_plugin_id
				 WHERE app_sid = r.app_sid
				   AND plugin_id = j.plugin_id;
			END IF;
		END LOOP;
	END LOOP;
	
	FOR j IN (
		SELECT *
		  FROM csr.plugin
		 WHERE app_sid IS NULL
		   AND js_class IN (
			'MarksAndSpencer.Initiatives.MainTab.SettingsPanel',
			'Lidl.Initiatives.DetailsArtikelPanel',
			'Lidl.Initiatives.DetailsPanel',
			'MarksAndSpencer.Initiatives.DetailsPanel',
			'MarksAndSpencer.Initiatives.FinancePanel',
			'MarksAndSpencer.Initiatives.NextStepsPanel',
			'MarksAndSpencer.Initiatives.PostImpReviewPanel',
			'MarksAndSpencer.Initiatives.SizingPanel',
			'MarksAndSpencer.Teamroom.Initiatives.PostImpReviewPanel'
		)
	) LOOP
		v_first := TRUE;
		FOR r IN (
			SELECT app_sid
			  FROM csr.initiative_project_tab
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
				  
				UPDATE csr.initiative_project_tab
				   SET plugin_id = v_plugin_id
				 WHERE app_sid = r.app_sid
				   AND plugin_id = j.plugin_id;
				  
				UPDATE csr.initiative_project_tab_group
				   SET plugin_id = v_plugin_id
				 WHERE app_sid = r.app_sid
				   AND plugin_id = j.plugin_id;
			END IF;
		END LOOP;
	END LOOP;
	
	FOR j IN (
		SELECT *
		  FROM csr.plugin
		 WHERE app_sid IS NULL
		   AND js_class IN (
			'MetricDashboard.Plugins.GreenprintPlugin'
		)
	) LOOP
		v_first := TRUE;
		FOR r IN (
			SELECT app_sid
			  FROM csr.metric_dashboard_plugin
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
				  
				UPDATE csr.metric_dashboard_plugin
				   SET plugin_id = v_plugin_id
				 WHERE app_sid = r.app_sid
				   AND plugin_id = j.plugin_id;
			END IF;
		END LOOP;
	END LOOP;
	
	FOR j IN (
		SELECT *
		  FROM csr.plugin
		 WHERE app_sid IS NULL
		   AND js_class IN (
			'Apax.Controls.EnergyMeterPanel',
			'Apax.Controls.WaterMeterPanel',
			'Berkeley.Controls.EnergyMeterPanel',
			'Berkeley.Controls.HeatingMeterPanel',
			'Berkeley.Controls.WaterMeterPanel',
			'BritishLand.Controls.ConceptsPanel',
			'CBRE.Controls.ActionTracker',
			'CBRE.Controls.EpcPanel',
			'CBRE.Controls.FundValuationPanel',
			'CBRE.Controls.SiteDetailsPanel',
			'CBRE.Controls.SpaceListEpcPanel',
			'CBRE.Controls.UnitEpcRAPanel',
			'Customer.Controls.CertificationPanel',
			'Customer.Controls.EnergyContractPanel',
			'Customer.Controls.EnergyMeterPanel',
			'Customer.Controls.WasteRefrigPanel',
			'Customer.Controls.WaterMeterPanel',
			'Greenprint.Controls.EnergyMeterPanel',
			'Greenprint.Controls.RatingPanel',
			'Greenprint.Controls.RefrigerantPanel',
			'Greenprint.Controls.ReportsPanel',
			'Greenprint.Controls.SpaceListMetricPanel',
			'Greenprint.Controls.WastePanel',
			'Greenprint.Controls.WaterMeterPanel',
			'HS.Controls.EnvIncidentPanel',
			'HS.Controls.EquipmentPanel',
			'HS.Controls.PumpsPanel',
			'Hyatt.Controls.CertificationPanel',
			'Hyatt.Controls.EnergyContractPanel',
			'Hyatt.Controls.EnergyMeterPanel',
			'Hyatt.Controls.HeatingMeterPanel',
			'Hyatt.Controls.WaterMeterPanel',
			'IMI.Controls.BuildingLeasePanel',
			'IMI.Controls.BuildingListPanel',
			'IMI.Controls.PropertyContactsPanel',
			'IMI.Controls.SiteDetailsPanel',
			'Imi.Controls.EnergyMeterPanel',
			'Imi.Controls.SiteDetailsPanel',
			'Imi.Controls.WaterMeterPanel',
			'McdDe.Controls.AltfettPanel',
			'McdDe.Controls.AvbPanel',
			'McdDe.Controls.AzvPanel',
			'McdDe.Controls.LvpPanel',
			'McdDe.Controls.PpkPanel',
			'McdDe.Controls.SonstigesPanel',
			'McdDe.Controls.SpeiserestePanel',
			'SBB.Controls.EnergyMeterPanel',
			'SBB.Controls.HeatingMeterPanel',
			'SBB.Controls.WaterMeterPanel',
			'Tishman.Controls.EnergyMeterPanel',
			'Tishman.Controls.WaterMeterPanel',
			'UBS.Controls.EnergyMeterPanel',
			'UBS.Controls.WaterMeterPanel',
			'lenovo.Controls.EnergyMeterPanel',
			'lenovo.Controls.WaterMeterPanel'
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
	
	FOR j IN (
		SELECT *
		  FROM csr.plugin
		 WHERE app_sid IS NULL
		   AND js_class IN (
			'MarksAndSpencer.Teamroom.Edit.SettingsPanel',
			'Mattel.Teamroom.Edit.SettingsPanel',
			'MarksAndSpencer.Teamroom.MainTab.SettingsPanel',
			'Mattel.Teamroom.MainTab.SettingsPanel',
			'MarksAndSpencer.Teamroom.BGIPanel',
			'MarksAndSpencer.Teamroom.InitiativesPanel',
			'MarksAndSpencer.Teamroom.PrioritisationPanel',
			'MarksAndSpencer.Teamroom.SpendSavePanel',
			'MarksAndSpencer.Teamroom.VOTrackerPanel'
		)
	) LOOP
		v_first := TRUE;
		FOR r IN (
			SELECT app_sid
			  FROM csr.teamroom_type_tab
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
				  
				UPDATE csr.teamroom_type_tab
				   SET plugin_id = v_plugin_id
				 WHERE app_sid = r.app_sid
				   AND plugin_id = j.plugin_id;
				   
				UPDATE csr.teamroom_type_tab_group
				   SET plugin_id = v_plugin_id
				 WHERE app_sid = r.app_sid
				   AND plugin_id = j.plugin_id;
			END IF;
		END LOOP;
	END LOOP;
END;
/

ALTER TABLE CSR.INITIATIVE_PROJECT_TAB_GROUP ADD CONSTRAINT FK_INIT_PRJ_TB_INIT_PRJ_TB_GRP 
    FOREIGN KEY (APP_SID, PROJECT_SID, PLUGIN_ID)
    REFERENCES CSR.INITIATIVE_PROJECT_TAB(APP_SID, PROJECT_SID, PLUGIN_ID)
;

ALTER TABLE CSR.PROPERTY_TAB_MOBILE ADD CONSTRAINT fk_property_tab_mobile_tab 
	FOREIGN KEY (app_sid, plugin_id) 
	REFERENCES csr.property_tab (app_sid, plugin_id)
;

ALTER TABLE CSR.PROPERTY_TAB_GROUP ADD CONSTRAINT FK_PRPTY_TAB_GROUP_PRPTY_TAB 
	FOREIGN KEY (APP_SID, PLUGIN_ID) 
	REFERENCES CSR.PROPERTY_TAB(APP_SID, PLUGIN_ID)
;

ALTER TABLE CSR.TEAMROOM_TYPE_TAB_GROUP ADD CONSTRAINT FK_TR_TYP_TB_TR_TYP_TB_GRP 
    FOREIGN KEY (APP_SID, TEAMROOM_TYPE_ID, PLUGIN_ID)
    REFERENCES CSR.TEAMROOM_TYPE_TAB(APP_SID, TEAMROOM_TYPE_ID, PLUGIN_ID)
;

@update_tail