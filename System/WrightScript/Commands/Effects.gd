extends Reference

var main

func _init(commands):
	main = commands.main

func ws_grey(script, arguments):
	var name = Commands.keywords(arguments).get("name", null)
	var value = Commands.keywords(arguments).get("value", 1)
	var obs
	if name:
		obs = Commands.get_objects(name, null)
	else:
		obs = Commands.get_objects(null, null)
	for o in obs:
		if o.has_method("set_grey"):
			o.set_grey(value)
			
# TODO IMPLEMENT
#    @category([KEYWORD("degrees","How many degrees to rotate"),KEYWORD("speed","How many degrees to rotate per frame"),
#    KEYWORD("axis","which axis to rotate on, z is the only valid value","z"),
#    KEYWORD("name","Name a specific object to rotate","Will try to rotate all objects (not what you might expect)"),
#    TOKEN("nowait","Continue script while rotation happens","The script will pause until rotation is finished")],type="effect")
#    def _rotate(self,command,*args):
#        """Begins an object rotation animation. Will wait for rotation to finish unless
#        'nowait' is included."""
#        kwargs,args = parseargs(args,intvals=["degrees","speed","wait"],
#                                                defaults={"axis":"z",'wait':1},
#                                                setzero={"nowait":"wait"})
#        self.add_object(rotateanim(obs=self.obs,**kwargs))
#        if kwargs['wait']:
#            return True
func ws_rotate(script, arguments):
	pass
	
# TODO IMPLEMENT
#    @category([KEYWORD("start","Color tint to start at","'ffffff' or no tint (full color)"),
#    KEYWORD("end","Color tint to end at","'000000' or full black tint"),
#    KEYWORD("speed","How many color steps per frame",1),
#    KEYWORD("name","Name a specific object to tint","Will try to tint all objects"),
#    TOKEN("nowait","Continue script while fade happens","The script will pause until fade is finished")],type="effect")
#    def _tint(self,command,*args):
#        """Animate an object's tint from one color to another. You can make an object darker but not brighter. Tinting an object
#        to red subtly can make a blush effect, tinting objects darker if there is a cloud overhead, or mixing tint with greyscale
#        to make a sepia toned flashback scene are different ways this can be used."""
#        kwargs,args = parseargs(args,intvals=["speed","wait"],
#                                                defaults={"start":"ffffff","end":"000000","speed":1,"wait":1},
#                                                setzero={"nowait":"wait"})
#        self.add_object(tintanim(obs=self.obs,**kwargs))
#        if kwargs['wait']:
#            return True
func ws_tint(script, arguments):
	pass
	
# TODO IMPLEMENT
#    @category([KEYWORD("value","Whether an object should be inverted or not: 1=inverted 0=not","1"),
#    KEYWORD("name","Name a specific object to tint","Will try to tint all objects")],type="effect")
#    def _invert(self,command,*args):
#        """Invert the colors of an object."""
#        kwargs,args = parseargs(args,intvals=["value"],
#                                                defaults={"value":1,"name":None})
#        kwargs["start"] = 1-kwargs["value"]
#        kwargs["end"] = kwargs["value"]
#        self.add_object(invertanim(obs=self.obs,**kwargs))
func ws_invert(script, arguments):
	pass
	
# TODO IMPLEMENT
#    @category([VALUE("ttl","Time for shake to last in frames","30"),
#    VALUE("offset","How many pixels away to move the screen (how violent)","15"),
#    TOKEN("nowait","Continue executing script during shake"),
#    TOKEN("both","Shake affects both screens as a whole")],type="effect")
#    def _shake(self,command,*args):
#        """Shake the screen for effect."""
#        sh = shake()
#        args = list(args)
#        if "nowait" in args:
#            args.remove("nowait")
#            sh.wait = False
#        if "both" in args:
#            sh.screen_setting = "both"
#            args.remove("both")
#        try:
#            if len(args)>0:
#                sh.ttl = int(args[0])
#            if len(args)>1:
#                sh.offset = int(args[1])
#        except ValueError:
#            raise script_error("Shake text macro needs an integer")
#            return
#        self.add_object(sh)
#        if sh.wait:
#            return True
func ws_shake(script, arguments):
	pass
	
# TODO IMPLEMENT
#@category([KEYWORD("mag","How many times to magnify","1 (will magnify 1 time, which is 2x magnification)"),
#    KEYWORD("frames","how many frames for the zoom to take","1"),
#    KEYWORD("name","Which object to magnify","tries to magnify everything"),
#    TOKEN("nowait","continue script during magnification"),
#    TOKEN("last","Choose last added object as target")],type="effect")
#    def _zoom(self,command,*args):
#        """Causes a single object or all objects to be magnified. The value for 'mag' will be added to the current magnification
#        value of an object, and it will take 'frames' frames to get to the new value. By default, all objects are at a magnification
#        of 1. To shrink an object to half it's size for instance, you would use this command:
#{{{
#zoom mag=-0.5 frames=10
#}}}
#        This will subtract half magnification from an object over 10 frames: 1x - 0.5x = 0.5x."""
#        mag = 1
#        frames = 1
#        wait = 1
#        last = 0
#        name = None
#        filter = "top"
#        for a in args:
#            if a.startswith("mag="):
#                mag=float(a[4:])
#            if a.startswith("frames="):
#                frames=int(a[7:])
#            if a.startswith("last"):
#                last = 1
#            if a.startswith("nowait"):
#                wait = 0
#            if a.startswith("name="):
#                name = a[5:]
#        zzzooom = zoomanim(mag,frames,wait,name)
#        if last:
#            zzzooom.control_last()
#        if name:
#            zzzooom.control(name)
#        self.add_object(zzzooom)
#        if wait: 
#            return True
func ws_zoom(script, arguments):
	pass

# TODO IMPLEMENT
#    @category([VALUE("speed","The speed to set the selected animation to - this is the number of display frames to wait before showing the next animation frame."),
#    KEYWORD("name","Only change the animation speed of objects with the given name","Change animation speed of all objects (if you want to mimic fastforward or slowdown you want to leave name= off)"),
#    TOKEN("b","Select blinking animation for char objects"),
#    TOKEN("t","Select talking animation for char objects")],type="animation")
#    def _globaldelay(self,command,spd,*args):
#        """Changes the default delay value for either all running animations or specific ones. First create the animation 
#with a char, bg, fg, etc command, then call globaldelay to adjust the rate the animation will play. Use b or t to choose
#blinking or talking animations if used with char. Normally, you will use the delay values stored with the animations themselves,
#in the .txt files that go alongside the graphics. However, sometimes you may wish something to happen faster or slower."""
#        name = None
#        for a in args:
#            if a.startswith("name="):
#                name = a.split("=",1)[1]
#        any = False
#        for o in self.world.all:
#            if name and getattr(o,"id_name",None)!=name:
#                continue
#            if isinstance(o,portrait):
#                if "b" in args:
#                    o = o.blink_sprite
#                if "t" in args:
#                    o = o.talk_sprite
#            if hasattr(o,"spd"):
#                o.spd = float(spd)
#                any = True
#        if name and not any and vtrue(assets.variables.get("_debug","false")):
#            raise missing_object("globaldelay: No valid objects found by key name "+name)
func ws_globaldelay(script, arguments):
	pass

# TODO IMPLEMENT
#@category([KEYWORD("name","Named object to control","Will alter animation of all current objects - not recommended to use the default value."),
#    KEYWORD("start","Alter the starting frame of the animation","Leave starting frame what it was."),
#    KEYWORD("end","Alter ending frame of the animation","Leave ending frame what it was."),
#    KEYWORD("jumpto","Instantly set an animations frame to this value","Don't change frames"),
#    KEYWORD("pause","Pause animation"),
#    TOKEN("loop","Force animation to loop"),
#    TOKEN("noloop","Force animation not to loop"),
#    TOKEN("b","Alter blink animation of chars"),
#    TOKEN("t","Alter talk animation of chars")],type="animation")
#    def _controlanim(self,command,*args):
#        """Alter the animation settings for a currently playing animated object. Normally you will use the settings that come with
#the animation in the form of a .txt file next to the graphic file. Occasionally you may wish to play an animation differently, such
#as having a non looping animation play several times, or only playing a portion of a longer animation."""
#        start = None
#        end = None
#        name = None
#        loop = None
#        jumpto = None
#        b = None
#        t = None
#        pause = None
#        resume = None
#        for a in args:
#            if a.startswith("name="):
#                name = a.split("=",1)[1]
#            if a == "loop":
#                loop = True
#            if a == "noloop":
#                loop = False
#            if a == "pause":
#                pause = 1
#            if a == "resume":
#                pause = -1
#            if a.startswith("start="):
#                start = int(a.split("=",1)[1])
#            if a.startswith("end="):
#                end = int(a.split("=",1)[1])
#            if a.startswith("jumpto="):
#                jumpto = int(a.split("=",1)[1])
#            if a == "b":
#                b = True
#            elif a == "t":
#                t = True
#        any = False
#        for o in self.world.all:
#            if not name or getattr(o,"id_name",None)==name:
#                any = True
#                if isinstance(o,portrait):
#                    if b:
#                        o = o.blink_sprite
#                    elif t:
#                        o = o.talk_sprite
#                    else:
#                        o = o.cur_sprite
#                if start is not None:
#                    o.start = start
#                    if o.x<start:
#                        o.x = start
#                if end is not None:
#                    o.end = end
#                if loop is not None:
#                    if loop:
#                        o.loops = 1
#                        o.loopmode = getattr(o,"old_loopmode","loop")
#                    else:
#                        o.loops = 0
#                        o.old_loopmode = o.loopmode
#                        o.loopmode = "stop"
#                if jumpto is not None:
#                    o.x = jumpto
#                if pause==1:
#                    o.last_end = o.end
#                    o.end = o.x
#                elif pause==-1:
#                    if hasattr(o,"last_end"):
#                        o.end = o.last_end
#                        del o.last_end
#        if name and not any and vtrue(assets.variables.get("_debug","false")):
#            raise missing_object("controlanim: No valid objects found by key name "+name)
func controlanim(script, arguments):
	pass
