/*
 Creates a quick survey from an xml file, set up audience to chain
*/
PROMPT please enter: host
PROMPT please enter: quick survey name
PROMPT please enter: quick survey label
PROMPT please enter: quick survey directory
PROMPT please enter: quick survey filename
PROMPT please enter: quick survey audience

define host='&&1'
define name='&&2'
define label='&&3'
define directory='&&4';
define filename = '&&5';
define audience = '&&6';

/* whenever oserror exit failure rollback
whenever sqlerror exit failure rollback */
PROMPT '&directory';
PROMPT '&filename';
create or replace directory tmp as '&directory';
-- import survey and set audience to chain
@@importSurvey_Internal

drop directory tmp;

PROMPT > Survey has been successfully imported

 