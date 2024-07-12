-- Please update version.sql too -- this keeps clean builds in sync
define version=16
@update_header

/* RUN ON LIVE ON 10 MAR 2006 */
/* BY RICHARD */

-- create SOs for jobs
DECLARE
	v_act VARCHAR(38);
	v_sid NUMBER(36);
	v_new_sid	number(10);
BEGIN
	user_pkg.logonauthenticatedpath(0,'//builtin/administrator',500,v_act);
	for r in (select csr_root_sid from customer)
	loop
		securableobject_pkg.CreateSO(v_act, r.csr_root_Sid, security_pkg.SO_CONTAINER, 'Jobs', v_sid);
		aspen2.Job_Pkg.CreateJob(v_act, v_sid, 'csrexport.datadump', 'Data overview report', null, v_new_sid);
		aspen2.Job_Pkg.CreateJob(v_act, v_sid, 'csrexport.fulldatadump', 'All region data dump', null, v_new_sid);
		acl_pkg.PropogateACEs(v_act, r.csr_root_Sid);
	end loop;
END;
/
COMMIT;




INSERT INTO SOURCE_TYPE ( SOURCE_TYPE_ID, DESCRIPTION) VALUES (6, 'Stored calculation');
COMMIT;



@update_tail
