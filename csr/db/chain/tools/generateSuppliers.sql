PROMPT >> 
PROMPT >> Host name (e.g. m.credit360.com):
PROMPT >> 
define _1="a&&1"
PROMPT >> 
PROMPT >> Inviting company name or sid (e.g. Maersk):
PROMPT >> 
define _2="a&&2"
PROMPT >> 
PROMPT >> Questionnaire class (e.g. Clients.Maersk.RegistrationHandler):
PROMPT >> 
define _3="a&&3"
PROMPT >> 
PROMPT >> Inviting user (e.g. //casey):
PROMPT >> 
define _4="a&&4"
PROMPT >> 
PROMPT >> Supplier country code (default gb):
PROMPT >> 
define _5="a&&5"
PROMPT >> 
PROMPT >> Supplier base name (default Supplier):
PROMPT >> 
define _6="a&&6"
PROMPT >> 
PROMPT >> Supplier start index (default auto-increment):
PROMPT >> 
define _7="a&&7"
PROMPT >> 
PROMPT >> Number of suppliers to create (default 1):
PROMPT >> 
define _8="a&&8"

BEGIN
	security.user_pkg.logonadmin('&&1');
	chain.dev_pkg.GenerateSuppliers(
		in_company => '&&2', 
		in_questionnaire_class => '&&3', 
		in_from_user => '&&4', 
		in_country => '&&5', 
		in_base_supplier_name => '&&6', 
		in_start_index => to_number('&&7'), 
		in_count => to_number('&&8')
	);
END;
/

commit;
exit
