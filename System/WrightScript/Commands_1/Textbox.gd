extends Reference

var main

func _init(commands):
	main = commands.main
	
func ws_textbox(script, arguments):
	var text = Commands.join(arguments)
	text = text.substr(1,text.length()-2)
	return Commands.create_textbox(text)
	
func ws_text(script, arguments):
	return ws_textbox(script, arguments)

func ws_nt(script, arguments):
	var nametag = Commands.join(arguments)
	main.stack.variables.set_val("_speaking", "")    		  # Set no character as speaking
	main.stack.variables.set_val("_speaking_name", nametag)   # Next character will have this name

# TODO IMPLEMENT
#    @category([VALUE('x','x value to place text'),VALUE('y','y value to place text'),VALUE('width','width of text block'),
#    VALUE('height','height of text block (determines rows but the value is in pixels)'),
#    KEYWORD('color','color of the text'),
#    KEYWORD('name','id of textblock object for later reference'),
#    COMBINED('text','text to display')],type='text')
#    def _textblock(self,command,x,y,width,height,*text):
#        """Displays a block of text all at once on the screen somewhere. Used to create custom interfaces. The text doesn't
#        support markup in the same way that textboxes do."""
#        id_name = None
#        color = None
#        if text and text[0].startswith("color="):
#            color = color_str(text[0][6:])
#            text = text[1:]
#        if text and text[0].startswith("name="): 
#            id_name = text[0].replace("name=","",1)
#            text = text[1:]
#        y = int(y)
#        if y>=192 and assets.num_screens == 1 and assets.screen_compress:
#            y -= 192
#        tb = textblock(" ".join(text),[int(x),int(y)],[int(width),int(height)],surf=pygame.screen)
#        self.add_object(tb)
#        if id_name: tb.id_name = id_name
#        else: tb.id_name = "$$"+str(id(tb))+"$$"
#        if color:
#            tb.color = color
func ws_textblock(script, arguments):
	pass
