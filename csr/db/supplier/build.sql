set define off

REM tag_pkg has to go first as other packages (e.g. company_pkg) depend on it
PROMPT Compiling tag_pkg
@@tag_pkg
PROMPT Compiling company_pkg
@@company_pkg
PROMPT Compiling product_pkg
@@product_pkg
PROMPT Compiling product_part_pkg
@@product_part_pkg
PROMPT Compiling company_part_pkg
@@company_part_pkg
PROMPT Compiling document_pkg
@@document_pkg
PROMPT Compiling questionnaire_pkg
@@questionnaire_pkg
PROMPT Compiling sales_pkg
@@sales_pkg
PROMPT Compiling report_pkg
@@report_pkg
PROMPT Compiling supplier_user_pkg
@@supplier_user_pkg
PROMPT Compiling audit_pkg
@@audit_pkg
PROMPT Compiling alert_pkg
@@alert_pkg
PROMPT Compiling options_pkg
@@options_pkg
PROMPT Compiling country_pkg
@@country_pkg

PROMPT Compiling company_body
@@company_body
PROMPT Compiling product_body
@@product_body
PROMPT Compiling tag_body
@@tag_body
PROMPT Compiling product_part_body
@@product_part_body
PROMPT Compiling company_part_body
@@company_part_body
PROMPT Compiling document_body
@@document_body
PROMPT Compiling questionnaire_body
@@questionnaire_body
PROMPT Compiling sales_body
@@sales_body
PROMPT Compiling report_body
@@report_body
PROMPT Compiling supplier_user_body
@@supplier_user_body
PROMPT Compiling audit_body
@@audit_body
PROMPT Compiling alert_body
@@alert_body
PROMPT Compiling options_body
@@options_body
PROMPT Compiling country_body
@@country_body

set define on
