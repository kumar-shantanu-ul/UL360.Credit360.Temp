define usr=abinbev
@../../../clients/abinbev/db/general_form_pkg 
@../../../clients/abinbev/db/general_form_body 
@../../../clients/abinbev/db/incident_pkg 
@../../../clients/abinbev/db/incident_body 

grant execute on &&usr..incident_pkg to csr;
grant execute on &&usr..general_form_pkg to csr;

define usr=berkeley
@../../../clients/berkeley/db/alert_pkg 
@../../../clients/berkeley/db/alert_body 

grant execute on &&usr..alert_pkg to csr;

define usr=gsk
@../../../clients/gsk/db/audit_pkg 
@../../../clients/gsk/db/audit_body 
@../../../clients/gsk/db/incident_pkg 
@../../../clients/gsk/db/incident_body 
@../../../clients/gsk/db/nearmiss_pkg 
@../../../clients/gsk/db/nearmiss_body 

grant execute on &&usr..nearmiss_pkg to csr;
grant execute on &&usr..audit_pkg to csr;
grant execute on &&usr..incident_pkg to csr;

define usr=odebrecht
@../../../clients/odebrecht/db/incident_pkg 
@../../../clients/odebrecht/db/incident_body 

grant execute on &&usr..incident_pkg to csr;

define usr=praxair
@../../../clients/praxair/db/incident_pkg 
@../../../clients/praxair/db/incident_body 

grant execute on &&usr..incident_pkg to csr;

define usr=vestas
@../../../clients/vestas/db/incident_pkg 
@../../../clients/vestas/db/incident_body 

grant execute on &&usr..incident_pkg to csr;

grant execute on mcdsc.helper_pkg to csr;