-- Please update version.sql too -- this keeps clean builds in sync
define version=60
@update_header

update customer_options set region_picker_config='[{level: 3,width: 200,search: false}, {level: 4,width: 200,search: false,button: {id: "pickerAddCountryButton",text: "Add country",iconCls: "tbNew",handler: null}}, {level: -1,width: 400,search: true,emptyText:"Please type the name of the property here",button: {id: "pickerAddRegionButton",text: "Add property",iconCls: "tbNew",handler: null}}]'
where app_sid=7919047;
 
@update_tail
