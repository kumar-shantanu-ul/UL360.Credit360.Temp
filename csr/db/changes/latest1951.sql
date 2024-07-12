-- Please update version.sql too -- this keeps clean builds in sync
define version=1951
@update_header

CREATE OR REPLACE VIEW csr.v$current_user_cover AS
	SELECT user_being_covered_sid
	  FROM csr.user_cover
	 WHERE user_giving_cover_sid = SYS_CONTEXT('SECURITY', 'SID')
	   AND start_dtm < SYSDATE
	   AND (end_dtm IS NULL OR end_dtm > SYSDATE)
	   AND cover_terminated = 0;

grant select on csr.v$current_user_cover to cms;

ALTER TABLE csr.issue ADD REGION_2_SID	NUMBER(10);
ALTER TABLE csrimp.issue ADD REGION_2_SID	NUMBER(10);

CREATE OR REPLACE VIEW csr.v$issue_involved_user AS
	SELECT ii.app_sid, ii.issue_id, MAX(ii.is_an_owner) is_an_owner, cu.csr_user_sid user_sid, cu.user_name, 
		   cu.full_name, cu.email, MAX(ii.from_role) from_role
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

@..\csr_data_pkg
@..\postit_pkg
@..\..\..\aspen2\cms\db\tab_body
@..\postit_body
@..\schema_body
@..\csrimp\imp_body



@update_tail