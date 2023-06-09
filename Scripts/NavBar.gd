extends ScrollContainer

signal ExportFinished
signal ShowToast

onready var Settings_btn=$HBoxContainer/RightNav/Settings
onready var Minus_btn=$HBoxContainer/Zoom/PanelContainer/HBoxContainer/minus
onready var Plus_btn=$HBoxContainer/Zoom/PanelContainer/HBoxContainer/plus

onready var Animation_player=$AnimationPlayer

func _ready():
	self.connect("ExportFinished",self,"_on_Navbar_ExportFinished")
	

func validate_goto(txt):
	var cards=0
	if (str(txt).is_valid_integer()):
		var ch=$"../PanelContainer/ScrollContainer/Panel/MarginContainer/MainGrid".get_children()
		for c in ch:
			if not c.is_in_group('ConnectorLines'):
				cards+=1

		if int(txt)<=cards and not int(txt)<=0:
			return true
		else:
			return false

func Export():
	var FINAL_JSON={'story_line':[]}
	for card in $"../PanelContainer/ScrollContainer/Panel/MarginContainer/MainGrid".get_children():
		if not card.is_in_group('ConnectorLines'):
			var Single_Card={}
			
			if card.is_in_group('StoryCard'):
				Single_Card['card_type']='StoryCard'
				Single_Card['required_vars']=[]
				Single_Card['on_end']={'set_vars':[]}
				
				var req_vars=card.get_node('VBoxContainer/OnStart/VBox/Reqs').get_children()
				var set_vars=card.get_node('VBoxContainer/OnEnd/VBoxContainer/SetVars').get_children()
				
				for vars in req_vars:
					if not vars.get_node('VarName').text.is_valid_identifier() and vars.get_node('VarVal').text.empty():
						print('Error : invalid variable name or invalid value assigned to card of id '+card.get_node('VBoxContainer/MainDetails/Index').text)
						emit_signal("ExportFinished",false,'Error : invalid variable name or invalid value assigned to card of id '+card.get_node('VBoxContainer/MainDetails/Index').text)
					Single_Card['required_vars'].append([vars.get_node('VarName').text,vars.get_node('VarVal').text])

				if card.get_node('VBoxContainer/OnEnd/VBoxContainer/Goto').text.empty():
					print('Error : invalid goto step assigned to card of id '+card.get_node('VBoxContainer/MainDetails/Index').text)
					return [false,'Error : invalid goto step assigned to card of id '+card.get_node('VBoxContainer/MainDetails/Index').text]
				Single_Card['on_end']['goto']=int(card.get_node('VBoxContainer/OnEnd/VBoxContainer/Goto').text)
				
				for vars in set_vars:
					if not vars.get_node('VarName').text.is_valid_identifier() and vars.get_node('VarVal').text.empty():
						print('Error : invalid variable name or invalid value assigned to card of id '+card.get_node('VBoxContainer/MainDetails/Index').text)
						
						emit_signal("ExportFinished",false,'Error : invalid variable name or invalid value assigned to card of id '+card.get_node('VBoxContainer/MainDetails/Index').text)
						
					Single_Card['on_end']['set_vars'].append([vars.get_node('VarName').text,vars.get_node('VarVal').text])
				Single_Card['content']=card.get_node('VBoxContainer/Content/ContentLabel').text


			
			elif card.is_in_group('RouterCard'):
				Single_Card['card_type']='RouterCard'
				Single_Card['else_goto_step']=0
				Single_Card['routers']=[]
				
				var goto_panels=card.get_node('VBoxContainer/Panel/VBoxContainer').get_children()
				goto_panels.remove(0)
				goto_panels.remove(0)
				
				for panel in goto_panels:
					if not validate_goto(panel.get_node('VBoxContainer/HBoxContainer/Goto').text):
						print('Error : invalid goto step assigned to card of id '+card.get_node('VBoxContainer/HBox/Index').text)
						emit_signal("ExportFinished",false,'Error : invalid goto step assigned to card of id '+card.get_node('VBoxContainer/HBox/Index').text)
					
					var gotoset={'goto':panel.get_node('VBoxContainer/HBoxContainer/Goto').text,'required_vars':[]}
					
					var var_set=panel.get_node('VBoxContainer').get_children()
					var_set.remove(0)

					for vars in var_set:
						if not vars.get_node('VarName').text.is_valid_identifier() and vars.get_node('VarVal').text.empty():
							print('Error : invalid variable name or invalid value assigned to card of id '+card.get_node('VBoxContainer/HBox/Index').text)
							emit_signal("ExportFinished",false,'Error : invalid variable name or invalid value assigned to card of id '+card.get_node('VBoxContainer/HBox/Index').text)
						gotoset['required_vars'].append([vars.get_node('VarName').text,vars.get_node('VarVal').text])

					Single_Card['routers'].append(gotoset)
		


			elif card.is_in_group('ChoiceCard'):
				Single_Card['card_type']='ChoiceCard'
				Single_Card['pretext']=card.get_node('VBoxContainer/VBoxContainer/Content/ContentLabel').text
				Single_Card['choices']=[]
				
				var choice_panels=card.get_node('VBoxContainer/VBoxContainer/Choices/VBoxContainer').get_children()
				for panel in choice_panels:
					var choice={}
					var goto_text=panel.get_node('VBoxContainer/HBoxContainer/Goto').text
					var choice_title=panel.get_node('VBoxContainer/ChoiceTitle').text
					var change_vars=panel.get_node('VBoxContainer').get_children()
					change_vars.remove(0)
					change_vars.remove(0)
					
					choice['title']=choice_title
					choice['goto']=goto_text
					choice['set_vars']=[]
					
					if not validate_goto(goto_text):
						print('Error : invalid goto step assigned to card of id '+card.get_node('VBoxContainer/MainDetails/Index').text)
						emit_signal("ExportFinished",false,'Error : invalid goto step assigned to card of id '+card.get_node('VBoxContainer/MainDetails/Index').text)
					
					for vars in change_vars:
						if not vars.get_node('VarName').text.is_valid_identifier() and vars.get_node('VarVal').text.empty():
							print('Error : invalid variable name or invalid value assigned to card of id '+card.get_node('VBoxContainer/MainDetails/Index').text)
							emit_signal("ExportFinished",false,'Error : invalid variable name or invalid value assigned to card of id '+card.get_node('VBoxContainer/MainDetails/Index').text)
						choice['set_vars'].append([vars.get_node('VarName').text,vars.get_node('VarVal').text])
					
					Single_Card['choices'].append(choice)
			
			FINAL_JSON['story_line'].append(Single_Card)
	FINAL_JSON=JSON.print(FINAL_JSON)
	

	emit_signal("ExportFinished",true,FINAL_JSON)




func _on_Settings_mouse_entered():
	Settings_btn.rect_pivot_offset=Settings_btn.rect_size/2
	Animation_player.play("clockwise_rotate")
	


func _on_Settings_mouse_exited():
	Settings_btn.rect_pivot_offset=Settings_btn.rect_size/2
	Animation_player.play("anti_clockwise_rotate")




func _on_plus_mouse_entered():
	Plus_btn.rect_pivot_offset=Plus_btn.rect_size/2
	Animation_player.play("magnify_plus")

func _on_plus_mouse_exited():
	Plus_btn.rect_pivot_offset=Plus_btn.rect_size/2
	Animation_player.play("shrink_plus")
	

func _on_minus_mouse_entered():
	Minus_btn.rect_pivot_offset=Minus_btn.rect_size/2
	Animation_player.play("magnify_minus")

	

func _on_minus_mouse_exited():
	Minus_btn.rect_pivot_offset=Minus_btn.rect_size/2
	Animation_player.play("shrink_minus")
	




func _on_LineEdit_focus_entered():
	Animation_player.play("search_bar_focus")


func _on_LineEdit_focus_exited():
	Animation_player.play("search_bar_unfocus")



func _on_ExportButton_pressed():
	$"../ExportPopupPanel/AnimationPlayer".play("loading")
	yield(get_tree().create_timer(1.5), "timeout") # Just to showoff the animation ;)
	Export()

func _on_Button_pressed():#Copy to clipboard
	var json_text=$"../ExportPopupPanel/PanelContainer/VBoxContainer/TextEdit"
	OS.set_clipboard(json_text.text)


func _on_Navbar_ExportFinished(state,result):
	$"../ExportPopupPanel".popup()
	$"../ExportPopupPanel/AnimationPlayer".play("popup_appear")
	if state:
		$"../ExportPopupPanel/PanelContainer/VBoxContainer/ErrorMsg".visible=false
		$"../ExportPopupPanel/PanelContainer/VBoxContainer/TextEdit".set_text(str(result))
	else:
		$"../ExportPopupPanel/PanelContainer/VBoxContainer/ErrorMsg".visible=true
		$"../ExportPopupPanel/PanelContainer/VBoxContainer/ErrorMsg".text=result
		$"../ExportPopupPanel/PanelContainer/VBoxContainer/TextEdit".set_text("Couldn't generate the json. check the error message for assistance.")



func _on_ExportPopupPanel_popup_hide():
	$"../ExportPopupPanel".visible=false
	$"../BgDrop".visible=false
	


func _on_SaveButton_pressed():
	$"../SavePopup".popup()

	var x_ax=($HBoxContainer/Save.get_global_position()+Vector2($HBoxContainer/Save.get_size().x/2,0))-Vector2($"../SavePopup".get_size().x/2,0)
	$"../SavePopup".set_position(x_ax+Vector2(0,$HBoxContainer/Save.get_size().y))



func Save(cwd):
	var FINAL_JSON={'story_line':[]}
	for card in $"../PanelContainer/ScrollContainer/Panel/MarginContainer/MainGrid".get_children():
		var Single_Card={}
		
		if card.is_in_group('StoryCard'):
			Single_Card['card_type']='StoryCard'
			Single_Card['required_vars']=[]
			Single_Card['on_end']={'set_vars':[]}
			
			var req_vars=card.get_node('VBoxContainer/OnStart/VBox/Reqs').get_children()
			var set_vars=card.get_node('VBoxContainer/OnEnd/VBoxContainer/SetVars').get_children()
			
			for vars in req_vars:
				Single_Card['required_vars'].append([vars.get_node('VarName').text,vars.get_node('VarVal').text])

			Single_Card['on_end']['goto']=int(card.get_node('VBoxContainer/OnEnd/VBoxContainer/Goto').text)
			
			for vars in set_vars:
				Single_Card['on_end']['set_vars'].append([vars.get_node('VarName').text,vars.get_node('VarVal').text])
			Single_Card['content']=card.get_node('VBoxContainer/Content/ContentLabel').text


		
		elif card.is_in_group('RouterCard'):
			Single_Card['card_type']='RouterCard'
			Single_Card['else_goto_step']=0
			Single_Card['routers']=[]
			
			var goto_panels=card.get_node('VBoxContainer/Panel/VBoxContainer').get_children()
			goto_panels.remove(0)
			goto_panels.remove(0)
			
			for panel in goto_panels:
				var gotoset={'goto':panel.get_node('VBoxContainer/HBoxContainer/Goto').text,'required_vars':[]}
				
				var var_set=panel.get_node('VBoxContainer').get_children()
				var_set.remove(0)

				for vars in var_set:
					gotoset['required_vars'].append([vars.get_node('VarName').text,vars.get_node('VarVal').text])

				Single_Card['routers'].append(gotoset)
	


		elif card.is_in_group('ChoiceCard'):
			Single_Card['card_type']='ChoiceCard'
			Single_Card['pretext']=card.get_node('VBoxContainer/VBoxContainer/Content/ContentLabel').text
			Single_Card['choices']=[]
			
			var choice_panels=card.get_node('VBoxContainer/VBoxContainer/Choices/VBoxContainer').get_children()
			for panel in choice_panels:
				var choice={}
				var goto_text=panel.get_node('VBoxContainer/HBoxContainer/Goto').text
				var choice_title=panel.get_node('VBoxContainer/ChoiceTitle').text
				var change_vars=panel.get_node('VBoxContainer').get_children()
				change_vars.remove(0)
				change_vars.remove(0)
				
				choice['title']=choice_title
				choice['goto']=goto_text
				choice['set_vars']=[]
				
				
				for vars in change_vars:
					choice['set_vars'].append([vars.get_node('VarName').text,vars.get_node('VarVal').text])
				
				Single_Card['choices'].append(choice)
		
		FINAL_JSON['story_line'].append(Single_Card)
	FINAL_JSON=JSON.print(FINAL_JSON)
	
	var file = File.new()
	file.open(cwd, File.WRITE)
	file.store_string(FINAL_JSON)
	file.close()
	emit_signal("ShowToast","Saved Succesfully")


func _on_Popup_Save_pressed():
	Save($"..".path_to_json)
	
func _on_Popup_SaveAs_pressed():
	$"../FileDialog".popup()


func _on_SaveAs_FileDialog_file_selected(path):
	Save(path)
	
	ReloadScene(path)
	



func ReloadScene(new_json_file_path):
	var s = load("res://MainBoard.tscn").instance()
	s.path_to_json=new_json_file_path
	get_tree().get_root().add_child(s)
	get_tree().set_current_scene(s)


func _on_NewFile_AcceptDialog_pressed():
	#print($"..".path_to_json)
	_on_SaveAs_FileDialog_file_selected($"..".path_to_json)
	$"../AcceptDialog".visible=false
	$"../BgDrop".visible=false
	
	emit_signal("ShowToast",'Created new project of name'+$"..".path_to_json.get_file())



func _on_Settings_pressed():
	if not $"../SettingsPanel".visible:
		$"../SettingsPanel".popup()



