define version=135
@update_header

	INSERT INTO chain.message_priority (message_priority_id, description)
			VALUES (3, 'This message is a To Do to allowed it to be displayed differently');
	
	INSERT INTO csr.portlet (portlet_id, name, type, script_path) VALUES (csr.portlet_id_seq.nextval, 'Supply Chain To Do List', 'Credit360.Portlets.Chain.ToDoList', '/csr/site/portal/Portlets/Chain/ToDoList.js');
			
@update_tail