-- Please update version.sql too -- this keeps clean builds in sync
define version=437
@update_header

-- force things that don't have an HTML tempalte to text/plain
update alert_template
   set mime_type='text/plain'
 where (mail_template like '#BODY#%' or length(mail_template)=0) 
   and mime_type !='text/plain';

-- force things that _do_ have an HTML tempalte to text/html (previously Credit360.Alert.Template worked like this 
-- we've changed the code to respect the mime_type setting of the alert, but this will preserve behaviour for existing 
-- customers
update alert_template
   set mime_type='text/html'
 where length(mail_template)>0 
   and mime_type ='text/plain'
   and mail_template not like '#BODY#%';


@update_tail
