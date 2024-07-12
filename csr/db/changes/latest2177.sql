-- Please update version.sql too -- this keeps clean builds in sync
define version=2177
@update_header

CREATE OR REPLACE VIEW csr.v$issue_involved_user AS
	SELECT ii.app_sid, ii.issue_id, MAX(ii.is_an_owner) is_an_owner, cu.csr_user_sid user_sid, cu.user_name, 
		   cu.full_name, cu.email, MIN(ii.from_role) from_role
	  FROM (
		SELECT ii.app_sid, ii.issue_id, is_an_owner, NVL(ii.user_sid, rrm.user_sid) user_sid,
			   CASE WHEN ii.role_sid IS NOT NULL THEN 1 ELSE 0 END from_role
		  FROM issue_involvement ii
		  JOIN issue i
			ON i.app_sid = ii.app_sid
		   AND i.issue_id = ii.issue_id
		  LEFT JOIN region_role_member rrm
			ON rrm.app_sid = i.app_sid
		   AND rrm.region_sid = i.region_sid
		   AND rrm.role_sid = ii.role_sid
		 UNION
		SELECT ii.app_sid, ii.issue_id, ii.is_an_owner, rrm.user_sid, 1 from_role
		  FROM issue_involvement ii
		  JOIN issue i
			ON i.app_sid = ii.app_sid
		   AND i.issue_id = ii.issue_id
		  JOIN region_role_member rrm
			ON rrm.app_sid = i.app_sid
		   AND rrm.region_sid = i.region_2_sid
		   AND rrm.role_sid = ii.role_sid
		) ii
	  JOIN csr_user cu
		ON ii.app_sid = cu.app_sid AND ii.user_sid = cu.csr_user_sid
	 GROUP BY ii.app_sid, ii.issue_id, cu.csr_user_sid, cu.user_name, cu.full_name, cu.email;

@update_tail
