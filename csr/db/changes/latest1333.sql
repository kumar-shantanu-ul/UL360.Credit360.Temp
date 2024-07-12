-- Please update version.sql too -- this keeps clean builds in sync
define version=1333
@update_header

alter table csr.customer_portlet modify app_sid DEFAULT SYS_CONTEXT('SECURITY','APP');

CREATE TABLE CSR.TEMP_PORTLET(
    PORTLET_ID       NUMBER(10, 0)    NOT NULL,
    NAME             VARCHAR2(255)    NOT NULL,
    TYPE             VARCHAR2(255)    NOT NULL,
    DEFAULT_STATE    CLOB,
    SCRIPT_PATH      VARCHAR2(255),
    CONSTRAINT PK_TEMP_PORTLET PRIMARY KEY (PORTLET_ID)
);	
begin
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (0,'Access Denied','Credit360.Portlets.AccessDeniedPortlet', EMPTY_CLOB(),'/csr/site/portal/Portlets/AccessDeniedPortlet.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (1,'Chart','Credit360.Portlets.Chart', EMPTY_CLOB(),'/csr/site/portal/Portlets/Chart.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (2,'Table','Credit360.Portlets.Table', EMPTY_CLOB(),'/csr/site/portal/Portlets/Table.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (3,'Map','Credit360.Portlets.Map', EMPTY_CLOB(),'/csr/site/portal/Portlets/Map.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (4,'Notes','Credit360.Portlets.StickyNote', EMPTY_CLOB(),'/csr/site/portal/Portlets/StickyNote.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (21,'My delegations','Credit360.Portlets.MyDelegations','{"portletHeight":400}','/csr/site/portal/Portlets/MyDelegations.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (42,'Normal Forms','Credit360.Portlets.NormalForms', EMPTY_CLOB(),'/csr/site/portal/Portlets/NormalForms.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (43,'Report Content','Credit360.Portlets.ReportContent', EMPTY_CLOB(),'/csr/site/portal/Portlets/ReportContent.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (61,'RSS feed','Credit360.Portlets.FeedViewer', EMPTY_CLOB(),'/csr/site/portal/Portlets/FeedViewer.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (81,'Community','Credit360.Portlets.Donated', EMPTY_CLOB(),'/csr/site/portal/Portlets/Donated.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (101,'Target Dashboard','Credit360.Portlets.TargetDashboard', EMPTY_CLOB(),'/csr/site/portal/Portlets/TargetDashboard.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (142,'Action Tasks','Credit360.Portlets.ActionsMyTasks', EMPTY_CLOB(),'/csr/site/portal/Portlets/ActionsMyTasks.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (161,'Gantt Chart','Credit360.Portlets.GanttChart', EMPTY_CLOB(),'/csr/site/portal/Portlets/GanttChart.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (181,'Add Donation','Credit360.Portlets.AddDonation', EMPTY_CLOB(),'/csr/site/portal/Portlets/AddDonation.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (202,'Issues','Credit360.Portlets.Issue', EMPTY_CLOB(),'/csr/site/portal/Portlets/Issue.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (204,'My questionnaires','Credit360.Portlets.MyApprovalSteps', EMPTY_CLOB(),'/csr/site/portal/Portlets/MyApprovalSteps.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (223,'Supply Chain Messages','Credit360.Portlets.Chain.Messages', EMPTY_CLOB(),'/csr/site/portal/Portlets/Chain.Messages.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (224,'Supply Chain Mailbox','Credit360.Portlets.Chain.Mailbox', EMPTY_CLOB(),'/csr/site/portal/Portlets/Chain.Mailbox.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (243,'Your travel','Credit360.Portlets.Travel', EMPTY_CLOB(),'/csr/site/portal/Portlets/Travel.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (263,'Supply Chain Charts','Credit360.Portlets.Chain.Charts', EMPTY_CLOB(),'/csr/site/portal/Portlets/Chain.Charts.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (283,'Region picker','Credit360.Portlets.RegionPicker', EMPTY_CLOB(),'/csr/site/portal/Portlets/RegionPicker.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (303,'Trucost Peer Comparison','Credit360.Portlets.Trucost.PeerComparison', EMPTY_CLOB(),'/trucost/site/portlets/peerComparison.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (323,'Help','Credit360.Portlets.Help', EMPTY_CLOB(),'/csr/site/portal/Portlets/Help.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (343,'My initiatives','Credit360.Portlets.ActionsMyInitiatives','{"portletHeight":450}','/csr/site/portal/Portlets/ActionsMyInitiatives.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (363,'My messages','Credit360.Portlets.MyMessages', EMPTY_CLOB(),'/csr/site/portal/Portlets/MyMessages.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (383,'Document library','Credit360.Portlets.Document', EMPTY_CLOB(),'/csr/site/portal/Portlets/Document.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (403,'Supply Chain News Flash','Credit360.Portlets.Chain.NewsFlash', EMPTY_CLOB(),'/csr/site/portal/Portlets/Chain/NewsFlash.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (404,'Supply Chain Summary','Credit360.Portlets.Chain.InvitationSummary', EMPTY_CLOB(),'/csr/site/portal/Portlets/Chain/InvitationSummary.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (405,'Supply Chain Required Actions','Credit360.Portlets.Chain.Actions', EMPTY_CLOB(),'/csr/site/portal/Portlets/Chain/Actions.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (406,'Supply Chain Events','Credit360.Portlets.Chain.Events', EMPTY_CLOB(),'/csr/site/portal/Portlets/Chain/Events.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (423,'Region list','Credit360.Portlets.RegionList', EMPTY_CLOB(),'/csr/site/portal/Portlets/RegionList.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (443,'Member company logo','Credit360.Portlets.CompanyLogo', EMPTY_CLOB(),'/csr/site/portal/Portlets/CompanyLogo.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (463,'Logging Form','Credit360.Portlets.LoggingForm', EMPTY_CLOB(),'/csr/site/portal/Portlets/LoggingForm.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (483,'Supply Chain Required Actions','Credit360.Portlets.Chain.RequiredActions', EMPTY_CLOB(),'/csr/site/portal/Portlets/Chain/RequiredActions.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (484,'Supply Chain Recent Activity','Credit360.Portlets.Chain.RecentActivity', EMPTY_CLOB(),'/csr/site/portal/Portlets/Chain/RecentActivity.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (503,'Region roles','Credit360.Portlets.RegionRoles', EMPTY_CLOB(),'/csr/site/portal/Portlets/RegionRoles.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (504,'Philips - Site ORUs','Philips.Portlets.SiteORUs', EMPTY_CLOB(),'/philips/site/portlets/SiteORUs.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (523,'Task Summary','Credit360.Portlets.Chain.TaskSummary', EMPTY_CLOB(),'/csr/site/portal/Portlets/Chain/TaskSummary.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (543,'Maersk Invitation Summary','Clients.Maersk.Portlets.Summary', EMPTY_CLOB(),'/maersk/site/portlets/Summary.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (563,'McDonalds-Boss Submission Summary','Clients.Mcdonalds.Portlets.SubmissionSummary', EMPTY_CLOB(),'/mcdonalds-boss/site/portlets/submissionSummary.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (583,'Issue Dashboard','Clients.Jlp.Portlets.IssueDashboard', EMPTY_CLOB(),'/jlp/site/portlets/IssueDashboard.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (603,'Quick survey','Credit360.Portlets.QuickSurvey', EMPTY_CLOB(),'/csr/site/portal/Portlets/QuickSurvey.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (623,'My forms','Credit360.Portlets.MySheets','{"portletHeight":400}','/csr/site/portal/Portlets/MySheets.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (643,'Philips - My forms','Philips.Portlets.HsMySheets', EMPTY_CLOB(),'/philips/site/portlets/HsMySheets.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (663,'Trucost Report Summary','Credit360.Portlets.Trucost.ReportSummary','{ portletHeight: 575 }','/trucost/site/portlets/reportSummary.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (683,'ChainDemo Invitation Summary','Clients.ChainDemo.Portlets.Summary', EMPTY_CLOB(),'/chaindemo/site/portlets/Summary.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (703,'John Lewis Partnership Legislation dashboard','Clients.Jlp.Portlets.LegislationDashboard', EMPTY_CLOB(),'/jlp/site/portlets/LegislationDashboard.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (724,'My donations','Credit360.Portlets.MyDonations','{"portletHeight":400}','/csr/site/portal/Portlets/MyDonations.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (763,'My dashboards','Credit360.Portlets.MyApprovalDashboards', EMPTY_CLOB(),'/csr/site/portal/Portlets/MyApprovalDashboards.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (783,'Supply Chain To Do List','Credit360.Portlets.Chain.ToDoList', EMPTY_CLOB(),'/csr/site/portal/Portlets/Chain/ToDoList.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (784,'Supply Chain Product Work Summary','Credit360.Portlets.Chain.ProductWorkSummary', EMPTY_CLOB(),'/csr/site/portal/Portlets/Chain/ProductWorkSummary.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (803,'Rainforest Alliance FSC Checker','Clients.RainforestAlliance.Portlets.FscChecker', EMPTY_CLOB(),'/rainforestalliance/site/portlets/FscChecker.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (823,'Meter list','Credit360.Portlets.MeterList', EMPTY_CLOB(),'/csr/site/portal/Portlets/MeterList.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (843,'New Issues','Credit360.Portlets.Issue2', EMPTY_CLOB(),'/csr/site/portal/portlets/issue2.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (863,'Region dropdown','Credit360.Portlets.RegionDropdown','{"portletHeight":100}','/csr/site/portal/portlets/regionDropdown.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (883,'Period dropdown','Credit360.Portlets.PeriodPicker','{"portletHeight":100}','/csr/site/portal/portlets/PeriodPicker.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (903,'Location map','Credit360.Portlets.LocationMap', EMPTY_CLOB(),'/csr/site/portal/portlets/locationMap.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (904,'Image chart','Credit360.Portlets.ImageChart', EMPTY_CLOB(),'/csr/site/portal/portlets/imageChart.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (923,'Indicator Map','Credit360.Portlets.IndicatorMap', EMPTY_CLOB(),'/csr/site/portal/Portlets/IndicatorMap.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (943,'Indicator picker','Credit360.Portlets.IndicatorPicker','{"portletHeight":100}','/csr/site/portal/portlets/IndicatorPicker.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (963,'Greenprint - My forms','Greenprint.Portlets.MySheetsWithVariance', EMPTY_CLOB(),'/greenprint/site/portlets/MySheetsWithVariance.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (983,'CT Breakdown picker','Credit360.Portlets.CarbonTrust.BreakdownPicker', EMPTY_CLOB(),'/csr/site/portal/portlets/ct/hotspot.jsi');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (984,'Fusion chart','Credit360.Portlets.FusionChart', EMPTY_CLOB(),'/csr/site/portal/portlets/FusionChart.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (985,'CT Advice','Credit360.Portlets.CarbonTrust.Advice', EMPTY_CLOB(),'/csr/site/portal/portlets/ct/hotspot.jsi');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (986,'Hotspot chart','Credit360.Portlets.CarbonTrust.HotspotChart', EMPTY_CLOB(),'/csr/site/portal/portlets/ct/hotspot.jsi');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (1004,'CT Welcome','Credit360.Portlets.CarbonTrust.Welcome', EMPTY_CLOB(),'/csr/site/portal/portlets/ct/hotspot.jsi');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (1005,'CT Chart Picker','Credit360.Portlets.CarbonTrust.ChartPicker', EMPTY_CLOB(),'/csr/site/portal/portlets/ct/hotspot.jsi');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (1025,'My surveys','Credit360.Portlets.MySurveys', EMPTY_CLOB(),'/csr/site/portal/Portlets/MySurveys.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (1026,'CT Flash Map','Credit360.Portlets.CarbonTrust.FlashMap', EMPTY_CLOB(),'/csr/site/portal/portlets/ct/FlashMap.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (1027,'CT Whats Next','Credit360.Portlets.CarbonTrust.WhatsNext', EMPTY_CLOB(),'/csr/site/portal/portlets/ct/WhatsNext.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (1028,'CT VC Before Hotspot','Credit360.Portlets.CarbonTrust.VCBeforeHotspot', EMPTY_CLOB(),'/csr/site/portal/portlets/ct/VCBeforeHotspot.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (1029,'CT VC Before Snapshot','Credit360.Portlets.CarbonTrust.VCBeforeSnapshot', EMPTY_CLOB(),'/csr/site/portal/portlets/ct/VCBeforeSnapshot.js');
Insert into csr.temp_portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (1030,'CT VC Before Module Configuration','Credit360.Portlets.CarbonTrust.VCBeforeModuleConfiguration', EMPTY_CLOB(),'/csr/site/portal/portlets/ct/VCBeforeModuleConfiguration.js');
end;
/

begin
	for r in (select table_name, constraint_name
	  			from all_constraints 
	 		   where ((table_name = 'CUSTOMER_PORTLET' and constraint_type = 'R')
	 		      or (table_name = 'PORTLET' and constraint_type = 'P'))
	 		     and owner = 'CSR'
			   order by decode(constraint_type,'P',1,'R',0)) loop
		execute immediate 'alter table csr.'||r.table_name||' disable constraint '||r.constraint_name;
	end loop;
end;
/

begin
	for r in (
		select op.portlet_id old_portlet_id, np.portlet_id new_portlet_id
		  from csr.temp_portlet np, csr.portlet op 
		 where lower(np.type) = lower(op.type)) loop

		update csr.customer_portlet
		   set portlet_id = -portlet_id
		 where portlet_id = r.old_portlet_id;
	end loop;

	for r in (
		select op.portlet_id old_portlet_id, np.portlet_id new_portlet_id
		  from csr.temp_portlet np, csr.portlet op 
		 where lower(np.type) = lower(op.type)) loop

		update csr.customer_portlet
		   set portlet_id = r.new_portlet_id
		 where portlet_id = -r.old_portlet_id;
	end loop;
	
	delete from csr.portlet
	 where lower(type) in (select lower(type) from csr.temp_portlet);
	 
	-- oh well
	delete from csr.portlet
	 where portlet_id in (select portlet_id from csr.temp_portlet);
	 
	insert into csr.portlet (portlet_id, name, type, default_state, script_path)
		select portlet_id, name, type, default_state, script_path
		  from csr.temp_portlet;
end;
/

begin
	for r in (select table_name, constraint_name
	  			from all_constraints 
	 		   where ((table_name = 'CUSTOMER_PORTLET' and constraint_type = 'R')
	 		      or (table_name = 'PORTLET' and constraint_type = 'P'))
	 		     and owner = 'CSR'
			   order by decode(constraint_type,'P',1,'R',0) desc) loop
		execute immediate 'alter table csr.'||r.table_name||' enable constraint '||r.constraint_name;
	end loop;
end;
/

drop sequence csr.portlet_id_seq;

-- not the best idea, but this is csrimp so only affects manually run processes
BEGIN
	FOR r IN (
		SELECT object_name, policy_name 
		  FROM all_policies 
		 WHERE function IN ('SESSIONIDCHECK')
		   AND object_owner = 'CSRIMP'
	) LOOP
		dbms_rls.drop_policy(
            object_schema   => 'CSRIMP',
            object_name     => r.object_name,
            policy_name     => r.policy_name
        );
    END LOOP;
END;
/

BEGIN	
 	FOR r IN (
		SELECT c.owner, c.table_name, c.nullable, (SUBSTR(c.table_name, 1, 26) || '_POL') policy_name
		  FROM all_tables t
		  JOIN all_tab_columns c ON t.owner = c.owner AND t.table_name = c.table_name
		 WHERE t.owner = 'CSRIMP' AND (t.dropped = 'NO' OR t.dropped IS NULL) AND c.column_name = 'CSRIMP_SESSION_ID'
 	)
 	LOOP
		dbms_output.put_line('Writing policy '||r.policy_name);
		dbms_rls.add_policy(
			object_schema   => r.owner,
			object_name     => r.table_name,
			policy_name     => r.policy_name, 
			function_schema => r.owner,
			policy_function => 'SessionIDCheck',
			statement_types => 'select, insert, update, delete',
			update_check	=> true,
			policy_type     => dbms_rls.static);
	END LOOP;
	
END;
/

@update_tail
