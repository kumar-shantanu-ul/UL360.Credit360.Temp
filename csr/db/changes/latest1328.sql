-- Please update version.sql too -- this keeps clean builds in sync
define version=1328
@update_header

-- Update all InternalAudit aggregate indicators to have extra descriptions (this cannot be done via the UI as they are system managed indicators)
DECLARE
	v_definition_xml_start			VARCHAR2(256);
	v_definition_xml_end			VARCHAR2(256);
BEGIN

	v_definition_xml_start := '<?xml version="1.0" encoding="UTF-8"?><fields><field name="definition"><![CDATA[';
	v_definition_xml_end := ']]></field></fields>';

	UPDATE csr.ind
	   SET info_xml = v_definition_xml_start || 'Count of audits that have a survey submitted (in order to submit a survey you have to choose an option for the "Question set" field when raising an audit)' || v_definition_xml_end
	 WHERE info_xml IS NULL
	   AND ind_sid IN (
		SELECT i.ind_sid
		  FROM csr.aggregate_ind_group aig
		  JOIN csr.aggregate_ind_group_member aigm
			ON aig.aggregate_ind_group_id = aigm.aggregate_ind_group_id
		   AND aig.app_sid = aigm.app_sid
		  JOIN csr.ind i
			ON i.ind_sid = aigm.ind_sid
		   AND i.app_sid = aigm.app_sid
		 WHERE aig.name = 'InternalAudit'
		   AND i.name = 'audits_completed'
		);
		
	UPDATE csr.ind
	   SET info_xml = v_definition_xml_start || 'The number of audits created for that month. If you pull this indicator annually for the current year, it will give you the number of audits held for that year so far.  You create an audit (normally with a survey) ahead of time when the audit is booked/organised - this is why the indicator is called "planned audits". When the audit occurs the survey would normally be submitted and is therefore "audit completed".  If an audit doesn’t have a survey then "audits planned" is the closest equivalent to the number of audits carried out.' || v_definition_xml_end
	 WHERE info_xml IS NULL
	   AND ind_sid IN (
		SELECT i.ind_sid
		  FROM csr.aggregate_ind_group aig
		  JOIN csr.aggregate_ind_group_member aigm
			ON aig.aggregate_ind_group_id = aigm.aggregate_ind_group_id
		   AND aig.app_sid = aigm.app_sid
		  JOIN csr.ind i
			ON i.ind_sid = aigm.ind_sid
		   AND i.app_sid = aigm.app_sid
		 WHERE aig.name = 'InternalAudit'
		   AND i.name = 'audits_planned'
		);
		
	UPDATE csr.ind
	   SET info_xml = v_definition_xml_start || 'All the closed audit action indicators are updated as actions are RESOLVED and are updated each month.  The number returned in the reports will be the number of actions resolved within the period selected.  It would be sensible to set a YTD calculation to count the number resolved so far this year.  These indicators are broken down according to their resolution date compared to due date.' || v_definition_xml_end
	 WHERE info_xml IS NULL
	   AND ind_sid IN (
		SELECT i.ind_sid
		  FROM csr.aggregate_ind_group aig
		  JOIN csr.aggregate_ind_group_member aigm
			ON aig.aggregate_ind_group_id = aigm.aggregate_ind_group_id
		   AND aig.app_sid = aigm.app_sid
		  JOIN csr.ind i
			ON i.ind_sid = aigm.ind_sid
		   AND i.app_sid = aigm.app_sid
		 WHERE aig.name = 'InternalAudit'
		   AND i.name = 'closed_on_time_issues'
		);
		
	UPDATE csr.ind
	   SET info_xml = v_definition_xml_start || 'All the closed audit action indicators are updated as actions are RESOLVED and are updated each month.  The number returned in the reports will be the number of actions resolved within the period selected.  It would be sensible to set a YTD calculation to count the number resolved so far this year.  These indicators are broken down according to their resolution date compared to due date.' || v_definition_xml_end
	 WHERE info_xml IS NULL
	   AND ind_sid IN (
		SELECT i.ind_sid
		  FROM csr.aggregate_ind_group aig
		  JOIN csr.aggregate_ind_group_member aigm
			ON aig.aggregate_ind_group_id = aigm.aggregate_ind_group_id
		   AND aig.app_sid = aigm.app_sid
		  JOIN csr.ind i
			ON i.ind_sid = aigm.ind_sid
		   AND i.app_sid = aigm.app_sid
		 WHERE aig.name = 'InternalAudit'
		   AND i.name = 'closed_late_issues'
		);
		
	UPDATE csr.ind
	   SET info_xml = v_definition_xml_start || 'All the closed audit action indicators are updated as actions are RESOLVED and are updated each month.  The number returned in the reports will be the number of actions resolved within the period selected.  It would be sensible to set a YTD calculation to count the number resolved so far this year.  These indicators are broken down according to their resolution date compared to due date.' || v_definition_xml_end
	 WHERE info_xml IS NULL
	   AND ind_sid IN (
		SELECT i.ind_sid
		  FROM csr.aggregate_ind_group aig
		  JOIN csr.aggregate_ind_group_member aigm
			ON aig.aggregate_ind_group_id = aigm.aggregate_ind_group_id
		   AND aig.app_sid = aigm.app_sid
		  JOIN csr.ind i
			ON i.ind_sid = aigm.ind_sid
		   AND i.app_sid = aigm.app_sid
		 WHERE aig.name = 'InternalAudit'
		   AND i.name = 'closed_late_issues_u30'
		);
		
	UPDATE csr.ind
	   SET info_xml = v_definition_xml_start || 'All the closed audit action indicators are updated as actions are RESOLVED and are updated each month.  The number returned in the reports will be the number of actions resolved within the period selected.  It would be sensible to set a YTD calculation to count the number resolved so far this year.  These indicators are broken down according to their resolution date compared to due date.' || v_definition_xml_end
	 WHERE info_xml IS NULL
	   AND ind_sid IN (
		SELECT i.ind_sid
		  FROM csr.aggregate_ind_group aig
		  JOIN csr.aggregate_ind_group_member aigm
			ON aig.aggregate_ind_group_id = aigm.aggregate_ind_group_id
		   AND aig.app_sid = aigm.app_sid
		  JOIN csr.ind i
			ON i.ind_sid = aigm.ind_sid
		   AND i.app_sid = aigm.app_sid
		 WHERE aig.name = 'InternalAudit'
		   AND i.name = 'closed_late_issues_u60'
		);
		
	UPDATE csr.ind
	   SET info_xml = v_definition_xml_start || 'All the closed audit action indicators are updated as actions are RESOLVED and are updated each month.  The number returned in the reports will be the number of actions resolved within the period selected.  It would be sensible to set a YTD calculation to count the number resolved so far this year.  These indicators are broken down according to their resolution date compared to due date.' || v_definition_xml_end
	 WHERE info_xml IS NULL
	   AND ind_sid IN (
		SELECT i.ind_sid
		  FROM csr.aggregate_ind_group aig
		  JOIN csr.aggregate_ind_group_member aigm
			ON aig.aggregate_ind_group_id = aigm.aggregate_ind_group_id
		   AND aig.app_sid = aigm.app_sid
		  JOIN csr.ind i
			ON i.ind_sid = aigm.ind_sid
		   AND i.app_sid = aigm.app_sid
		 WHERE aig.name = 'InternalAudit'
		   AND i.name = 'closed_late_issues_u90'
		);
		
	UPDATE csr.ind
	   SET info_xml = v_definition_xml_start || 'All the closed audit action indicators are updated as actions are RESOLVED and are updated each month.  The number returned in the reports will be the number of actions resolved within the period selected.  It would be sensible to set a YTD calculation to count the number resolved so far this year.  These indicators are broken down according to their resolution date compared to due date.' || v_definition_xml_end
	 WHERE info_xml IS NULL
	   AND ind_sid IN (
		SELECT i.ind_sid
		  FROM csr.aggregate_ind_group aig
		  JOIN csr.aggregate_ind_group_member aigm
			ON aig.aggregate_ind_group_id = aigm.aggregate_ind_group_id
		   AND aig.app_sid = aigm.app_sid
		  JOIN csr.ind i
			ON i.ind_sid = aigm.ind_sid
		   AND i.app_sid = aigm.app_sid
		 WHERE aig.name = 'InternalAudit'
		   AND i.name = 'closed_late_issues_o90'
		);
		
	UPDATE csr.ind
	   SET info_xml = v_definition_xml_start || 'This is a cumulative count of all open audit actions, whether overdue or not.  E.g. if an audit action has not been resolved from 2012 it will roll forward to 2013 so this number always shows how many audit actions are un-resolved (open).  Since these indicators are cumulative, you cannot add the monthly values to get an annual total. You should not set a YTD calculation using this indicator.' || v_definition_xml_end
	 WHERE info_xml IS NULL
	   AND ind_sid IN (
		SELECT i.ind_sid
		  FROM csr.aggregate_ind_group aig
		  JOIN csr.aggregate_ind_group_member aigm
			ON aig.aggregate_ind_group_id = aigm.aggregate_ind_group_id
		   AND aig.app_sid = aigm.app_sid
		  JOIN csr.ind i
			ON i.ind_sid = aigm.ind_sid
		   AND i.app_sid = aigm.app_sid
		 WHERE aig.name = 'InternalAudit'
		   AND i.name = 'open_issues'
		);
		
	UPDATE csr.ind
	   SET info_xml = v_definition_xml_start || 'This is a cumulative count of all audit actions that are open and overdue.  The same rules apply as with Open audit actions, it will show a cumulative total so you cannot add the monthly values to get the annual total. You also should not do a YTD action on this indicator.' || v_definition_xml_end
	 WHERE info_xml IS NULL
	   AND ind_sid IN (
		SELECT i.ind_sid
		  FROM csr.aggregate_ind_group aig
		  JOIN csr.aggregate_ind_group_member aigm
			ON aig.aggregate_ind_group_id = aigm.aggregate_ind_group_id
		   AND aig.app_sid = aigm.app_sid
		  JOIN csr.ind i
			ON i.ind_sid = aigm.ind_sid
		   AND i.app_sid = aigm.app_sid
		 WHERE aig.name = 'InternalAudit'
		   AND i.name = 'overdue_issues'
		);
		
	UPDATE csr.ind
	   SET info_xml = v_definition_xml_start || 'Counts the number of audit actions raised in the selected reporting period. It takes into consideration when the record was created.  This is not a running total of audits raised to date - to get this you should create a YTD calculation.' || v_definition_xml_end
	 WHERE info_xml IS NULL
	   AND ind_sid IN (
		SELECT i.ind_sid
		  FROM csr.aggregate_ind_group aig
		  JOIN csr.aggregate_ind_group_member aigm
			ON aig.aggregate_ind_group_id = aigm.aggregate_ind_group_id
		   AND aig.app_sid = aigm.app_sid
		  JOIN csr.ind i
			ON i.ind_sid = aigm.ind_sid
		   AND i.app_sid = aigm.app_sid
		 WHERE aig.name = 'InternalAudit'
		   AND i.name = 'raised_issues'
		);	
	
END;
/

@..\audit_body

@update_tail

