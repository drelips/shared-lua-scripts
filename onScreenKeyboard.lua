module(..., package.seeall)

--[[

    Simple helper class that creates a virtual keyboard on the screen. This is useful for getting user input without the need of using the native
    input methods of the devices.
    The onScreenKeyboard class provides keyboards for upper letters, for small letters, for numbers and for a wide range of special characters such as the
    question mark, different kinds of brackets or the @ sign.

    You need a keyboard with red keys an yellow text on it? No problem. The onScreenKeyboard is fully customizable and gives you the freedom of selecting 
    its color,  position, alpha value and behaviour. This makes it easy to create an input keyboard in the visual style of your App.


    Sample usage:

    << main.lua

        require("onScreenKeyboard") -- include the onScreenKeyboard.lua file

        --create a textfield for the content created with the keyoard
        local textField = display.newText("",  0, 0, display.contentWidth, 100, native.systemFont, 50)
        textField:setTextColor(255,255,255)

        --create an instance of the onScreenKeyboard class without any parameters. This creates a keyboard
        --with the default values. You can manipulate the visual representation of the keyboard by passing a table to the new() function.
        --Read more about this in the section "customizing the keyboard style"
        local keyboard = onScreenKeyboard:new() 

        --create a listener function that receives the events of the keyboard
        local listener = function(event)
            if(event.phase == "ended")  then
                textField.text=keyboard:getText() --update the textfield with the current text of the keyboard
                textField:setReferencePoint(display.TopLeftReferencePoint)
                textField.x = 0
                textField.y = 0

                --check whether the user finished writing with the keyboard. The inputCompleted
                --flag of  the keyboard is set to true when the user touched its "OK" button
                if(event.target.inputCompleted == true) then
                    print("Input of data complete...")
                    keyboard:destroy()                                            
                end
            end
        end

        --let the onScreenKeyboard know about the listener
        keyboard:setListener(  listener  )
        
        --show a keyboard with small printed letters as default. Read more about the possible values for keyboard types in the section "possible keyboard types"
        keyboard:drawKeyBoard(keyboard.keyBoardMode.letters_small)
    
    >>>>>>>>>>>>>>>


    customizing the keyboard style

    If you create an instance of the onScreenKeyboard class without any parameters by calling onScreenKeyboard:new(  )  
    the keyboard is created with default values (as in the example above).
    To customize the style and behaviour you simply can apply a table with one or more of the following keys.    

    1.  MAX_TEXT_SIZE
    A numerical value to specify the maximum allowed length of the input text. If not specified, the size of the allowed thext is not limited
    Default value is: 0 which means the text length is unlimited

    2. BGCOLOR
    An array  with 3 numerical values in the range from 0 to 255 that adjust the RGB-colors for the background of the keyboard buttons        
    Default value is: { 125, 125, 125 } 

    3. FGCOLOR 
    An array  with 3 numerical values in the range from 0 to 255 that adjust the RGB-colors for the text at the keyboard buttons
    Default value is: { 255, 255, 255 } 

    4. ALPHA
    An numerical value in the range of 0 to 1 that specifies the alpha value of the keyboard buttons
    Default value is: 0.6

    5. START_X
    An numerical value that specifies the x position of the top left corner of the keyboard
    Default value is: 0

    6. START_Y
    An numerical value that specifies the y position of the top left corner of the keyboard
    Default value is: display.contentHeight/3        

    7. KEY_SPACE
    An numerical value that specifies the space between the keys of the keyboard in pixels
    Default value is: 5        

    8. PARENT
    A reference to a display group where the created objects of the keyboard will be integrated too.
    Default value is: nil        

    9. IGNORE_ORIENTATION_CHANGES
    A boolean value that specifies whether the keyboard redraws itself automatically when it detects an orientation change of the device.
    Default value is: false which means the keyboard is automatically redrawn when the device turns its orientation.

    ATTENTION: To make this work you need to specify the supported orientations in your build.settings file. 
    Read more about his here http://developer.coronalabs.com/content/configuring-projects#Orientation_Support_iOS

    
    Example of creating a customized keyboard
    
    onScreenKeyboard:new(  { BGCOLOR={255,0,0},  MAX_TEXT_SIZE = 5})  creates a keyboard with red keys and a maximum text length of 5 signs

    
    possible keyboard types

    After the creation of an instance of the onScreenKeyboard class you must specify the type of the keyboard that is shown first. You need to do this by calling the "drawKeyBoard" method.
    This method takes one of the 4 following values.

    1. keyBoardMode.letters_small - Draws a keyboard with small printed letters
    2. keyBoardMode.letters_large - Draws a keyboard with large printed letters
    3. keyBoardMode.letters_numbers - Draws a keyboard with a numerical input pad
    4. keyBoardMode.letters_signs - Draws a keyboard with a table of special characters (such as ? ! % ...)         
    
    
    Methods you need to know
    
    The onScreenKeyboard class provides some methods you may want to use in your code
    
    1. setListener(  listener  )
    Sets up a listener method that will be notified about keyboard events (user touches)
    
    2. getText()
    Returns the current text the user wrote with the keyboard
    
    3. drawKeyBoard(  type  )
    Draws a keyboard of the specified type. For more information about this task please read the section "possible keyboard types"
    
    4.destroy()
    Destorys the keyboard and clears all references to it
    
    5. hide()
    Hides the keyboard. This method sets the keyboard invisible, but it is still there
    
    6. show()
    Makes a previously hidden keyboard visible again
    
    7. All other methods are for internal use only. Don't care about them
        
]]--




--[[
    author - andreas ermrich
    author mail - aeh@incowia.com
    company - incowia GmbH / Garamox
    websites - http://www.incowia.com, http://www.garamox.de
 
    version - 1.0
    date - 2012.08.08
    author comments - use it for free and enjoy. Please give me your feedback with a short mail!!!
]]--
function onScreenKeyboard:new(params)
 local object = {
                   text                = ""                                                             ,
                   listener            = nil                                                            ,
                   displayGroup        = nil                                                            ,
                   parent              = nil                                                            ,
                   btnBgColor          = {125,125,125}                                                  ,                   
                   btnBgAlpha          = 0.6                                                            ,
                   btnFgColor          = {255,255,255}                                                  ,
                   btnFontName         = "Arial"                                                        ,
                   keyBoardMode        = {letters_small = 1, letters_large = 2, numbers = 3, signs = 4} ,
                   maxTextLength       = 0                                                              ,
                   startX              = 0                                                              ,
                   startY              = (display.contentHeight/3)                                      ,
                   breakerItem         = "BREAK"                                                        ,
                   keySpace            = 5                                                              ,
                   animationDuration   = 100                                                            ,
                   textUpdater         = nil                                                            ,
                   userListenerCaller  = nil                                                            ,
                   currentKeyboardMode = nil
                }
 
 --[[
    Constructor of this class
  ]]--
 function object:init(params)
    -- function to check numerical values to be in the range from 0 to 255
    local rangCheck = function(val)
                        local checkValue=false
                        if(type(val) == "number" and val >= 0 and val <=255) then
                            checkValue = true
                        end
                        return checkValue
                      end
 
    --set up the listener that updates the self.text variable
    self.textUpdater = function(event)
                            if(event.phase == "began") then                                    
                                if(self.maxTextLength > 0 and string.len(self.text) == self.maxTextLength) then return end
                                self.text = self.text .. event.target.character
                            end
                            return false
                       end    
                        
    --set up the listener that calls the user listener function for key touch events                        
    self.userListenerCaller = function(event)                                
                                if(self.listener ~= nil) then
                                    event.key = event.target.character                                    
                                    return self.listener(event)
                                end
                                return false
                              end      
    
    --check the given params
    if(params.BGCOLOR ~= nil) then        
        if(type(params.BGCOLOR) == "table" and table.getn(params.BGCOLOR) == 3 and rangCheck(params.BGCOLOR[1]) == true and rangCheck(params.BGCOLOR[2]) == true and rangCheck(params.BGCOLOR[3]) == true) then
            self.btnBgColor = params.BGCOLOR
        else
         print("param BGCOLOR is wrong")
        end
    end

    if(params.FGCOLOR ~= nil) then
        if(type(params.FGCOLOR) == "table" and table.getn(params.FGCOLOR) == 3 and rangCheck(params.FGCOLOR[1]) == true and rangCheck(params.FGCOLOR[2]) == true and rangCheck(params.FGCOLOR[3]) == true) then    
            self.btnFgColor = params.FGCOLOR
        else
         print("param FGCOLOR is wrong")
        end
    end

    if(params.ALPHA ~= nil) then
        if(type(params.ALPHA) == "number" and params.ALPHA >=0 and params.ALPHA <= 1) then
            self.btnBgAlpha = params.ALPHA
        else
            print("param ALPHA is wrong")
        end
    end

    if(params.START_X ~= nil) then
        if(type(params.START_X) == "number") then
            self.startX = params.START_X
        else
            print("param START_X is wrong")
        end    
    end
    
    if(params.START_Y ~= nil) then
        if(type(params.START_Y) == "number") then
            self.startY = params.START_Y
        else
            print("param START_Y is wrong")
        end 
    end

    if(params.KEY_SPACE ~= nil) then
        if(type(params.KEY_SPACE) == "number" and params.KEY_SPACE >= 0) then
            self.keySpace = params.KEY_SPACE
        else
            print("param KEY_SPACE is wrong")
        end
    end

    if(params.MAX_TEXT_SIZE ~= nil) then
        if(type(params.MAX_TEXT_SIZE) == "number" and params.MAX_TEXT_SIZE > 0) then
            self.maxTextLength = params.MAX_TEXT_SIZE
        else
            print("param MAX_TEXT_SIZE is wrong")
        end        
    end
    
    if(params.PARENT ~= nil) then
        if(type(params.PARENT) == "table") then
            self.parent = params.PARENT
        else
            print("param PARENT is wrong")
        end
    end
    
    local activateOrientationListener = true
    if(params.IGNORE_ORIENTATION_CHANGES ~= nil) then
        if(type(params.IGNORE_ORIENTATION_CHANGES) == "boolean")then            
            activateOrientationListener = not params.IGNORE_ORIENTATION_CHANGES
        else
            print("param IGNORE_ORIENTATION_CHANGES is wrong")
        end
        
    end        
    
    if(activateOrientationListener == true) then
        local cl = function(event)
                    return self:orientationChange(event)                    
                   end
        Runtime:addEventListener("orientation", cl)
    end

    self.displayGroup = display.newGroup()    
 end

 
 --[[
    Setter for the user listener that is notified when the user touches a key
  ]]--
 function object:setListener(newListener)
    if(newListener ~= nil and type(newListener) == "function") then
        self.listener = newListener
    end    
 end
 
 --[[
    Getter for self.text
  ]]--
 function object:getText()
  return self.text
 end
 
 --[[
    Event listener for the global system event "orientation change"
  ]]--
 function object:orientationChange(event)    
    self.startY = display.contentHeight/3 -- we need to reset the vertical start position for the virtual keyboard    
    
    local mode= self.keyBoardMode.letters_small
    if(self.currentKeyboardMode ~= nil) then
        mode = self.currentKeyboardMode
    end
    self:drawKeyBoard(mode)
    return false
 end
 
 
 --[[
    Factory method to create a display group for a keyboard button
  ]]--
 function object:createButton(sign, width, height)
   local buttonGroup = display.newGroup()
   
   local backGround = display.newRect(0,0,width,height)
   backGround:setReferencePoint(display.TopLeftReferencePoint)
   backGround:setFillColor(self.btnBgColor[1], self.btnBgColor[2], self.btnBgColor[3])
   buttonGroup:insert(backGround)
        
   local btnText = display.newText(sign, 0, 0, native.systemFont, height/3)
   btnText:setTextColor(self.btnFgColor[1], self.btnFgColor[2], self.btnFgColor[3])
   btnText:setReferencePoint(display.CenterReferencePoint)
   btnText.x = backGround.x + backGround.width/2
   btnText.y = backGround.y + backGround.height/2          
   buttonGroup:insert(btnText)
   
   --Make sure that the text is not larger than the surrounding background
   while(btnText.width > backGround.width or btnText.width > backGround.height) do
    btnText.size= btnText.size-1    
   end   
   
   --animation that will be shown, when the user touches a key button
   local touchAnimation = function(event)
                            local btnGroup = event.target
                            
                            if(event.phase == "began")then
                                if(self.btnBgAlpha <= 0.5) then
                                    btnGroup.alpha = 1                                    
                                else
                                    btnGroup.alpha = 0                                    
                                end 
                                transition.to(btnGroup, {alpha=self.btnBgAlpha, time=250})                                
                            end
                            return false
                          end
                          
   buttonGroup.alpha = self.btnBgAlpha
   buttonGroup:addEventListener("touch", touchAnimation)   
   buttonGroup:setReferencePoint(display.topLeftReferencePoint)
      
   return buttonGroup   
 end
 
 
 --[[
    Clears all currently created keys of the keyboard
  ]]--
 function object:clearCurrentKeyBoard()
    for i=self.displayGroup.numChildren,1,-1 do
        self.displayGroup:remove(i)
    end
    self.displayGroup = display.newGroup()    
 end
 
 
 --[[
    Wrapper that calls the concrete drawing methods that generate a virtual keyboard
  ]]--
 function object:drawKeyBoard(mode)
    local width  = display.contentWidth
    local height = display.contentHeight
       
    local workingClosure= function()
        self:clearCurrentKeyBoard() --remove the currently displayed keyboard buttons
        if(mode == self.keyBoardMode.letters_small) then
            self.currentKeyboardMode = mode
            self:drawLetterKeyboard(width, height, true)
        end
        
        if(mode == self.keyBoardMode.letters_large) then
            self.currentKeyboardMode = mode
            self:drawLetterKeyboard(width, height, false)
        end
        
        if(mode == self.keyBoardMode.numbers) then
            self.currentKeyboardMode = mode
            self:drawNumberKeyboard(width, height)
        end
        
        if(mode == self.keyBoardMode.signs) then
            self.currentKeyboardMode = mode
            self:drawSignsKeyboard(width, height)
        end    
                
        transition.from(self.displayGroup, {alpha=0, time=self.animationDuration})
        
        if(self.parent ~= nil) then
            self.parent:insert(self.displayGroup)
        end
    end
    
    if(self.displayGroup ~= nil) then
        transition.to(self.displayGroup, {alpha=0, time=self.animationDuration, onComplete=workingClosure})
    else
        workingClosure()        
    end
 end

 
 --[[
        Create the keys for a virtual keyboard that contains small printed letters
    ]]--
 function object:drawLetterKeyboard(width, height, smallLetters)
    local numberOfKeyRowsToDraw = 4
    local startX                = self.startX
    local startY                = self.startY
    local startXOrg             = self.startX
    local lettersToDraw         = {"q", "w", "e", "r", "t", "y", "u", "i", "o", "p", self.breakerItem, "a", "s", "d", "f", "g", "h", "j", "k", "l", self.breakerItem, "z", "x", "c", "v", "b", "n", "m"}
    
    --check how many objects the longest button row will consist of
    local firstRowLength=0
    for i=1,#lettersToDraw do
        if(lettersToDraw[i] == self.breakerItem) then
            firstRowLength = i-1
            break
        end
    end
    
    --create necessary counter vars for the following creation process loop
    local totalRows    = 0
    local buttonsOfRow = 0
    
    --check how width and height the buttons can be in maximum
    local maxButtonWidth  = ( (display.contentWidth -self.startX) - ((firstRowLength-1) * self.keySpace) ) / firstRowLength
    local maxButtonHeight = (display.contentHeight - self.startY - (numberOfKeyRowsToDraw*self.keySpace)) / ( numberOfKeyRowsToDraw )
    
    --create the keys for each necessary element
    for i=1,#lettersToDraw do
       local currentItem = lettersToDraw[i]
       
       --check whether to use small or large letters
       if(smallLetters == false)then    currentItem = string.upper(currentItem)    end       
              
       if(currentItem ~= self.breakerItem) then
           local btnGroup = self:createButton(currentItem, maxButtonWidth, maxButtonHeight)
           btnGroup.x = startX + (maxButtonWidth*buttonsOfRow) + (buttonsOfRow * self.keySpace)
           btnGroup.y = startY + (maxButtonHeight*totalRows) + (totalRows * self.keySpace)
           btnGroup.character = currentItem
           btnGroup.inputCompleted=false
           btnGroup:addEventListener("touch", self.textUpdater)
           self.displayGroup:insert(btnGroup)
           
           --call the user defined listener for the key touch events           
           btnGroup:addEventListener("touch", self.userListenerCaller)
           
           buttonsOfRow = buttonsOfRow+1
       else
           buttonsOfRow = 0
           totalRows    = totalRows +1 

           if(totalRows == 1) then
            startX = (maxButtonWidth/2 + self.keySpace) + startXOrg
           else
            startX = ((maxButtonWidth * 1.5) + (2 * self.keySpace)) + startXOrg
           end              
       end
    end

    --draw SHIFT-Button
    local btnGroup = self:createButton("SHIFT", maxButtonWidth*1.5+self.keySpace, maxButtonHeight)
    btnGroup.x = startXOrg
    btnGroup.y = self.startY + (maxButtonHeight*totalRows) + (totalRows * self.keySpace)
    btnGroup.inputCompleted=false
    
    if(smallLetters == true)then
        btnGroup.nextKeyboardStyle = self.keyBoardMode.letters_large
    else
        btnGroup.nextKeyboardStyle = self.keyBoardMode.letters_small
    end
            
    --listener function for the SHIFT button
    local changeKeyBoard = function(event)                                                        
                            if(event.phase == "ended") then
                                self:drawKeyBoard(event.target.nextKeyboardStyle)
                            end    
                            return false                            
                           end
    btnGroup:addEventListener("touch", changeKeyBoard)
    self.displayGroup:insert(btnGroup)    

    
    
    --draw the delete button
    local btnGroup = self:createButton("DEL", maxButtonWidth*1.5, maxButtonHeight)
    btnGroup.x = (8.5 * maxButtonWidth + ((firstRowLength-1) * self.keySpace)) + startXOrg
    btnGroup.y = self.startY + (maxButtonHeight*totalRows) + (totalRows * self.keySpace)
    btnGroup.character = ""
    btnGroup.inputCompleted=false
    
    --listener function for the delete button
    local deleteSign= function(event)
                        if(event.phase == "ended") then
                            self.text = string.sub(self.text, 1, string.len(self.text)-1)                            
                        end
                        return false
                      end
    btnGroup:addEventListener("touch", deleteSign)
    self.displayGroup:insert(btnGroup)    
    
    totalRows    = totalRows +1 
    buttonsOfRow = 0
    
    --call the user defined listener for the key touch events    
    btnGroup:addEventListener("touch", self.userListenerCaller)
    
    
    
    --draw the keyboard switch button
    local btnGroup = self:createButton("123...", maxButtonWidth*1.5+self.keySpace, maxButtonHeight)
    btnGroup.x = startXOrg
    btnGroup.y = self.startY + (maxButtonHeight*totalRows) + (totalRows * self.keySpace)
    btnGroup.inputCompleted=false
    
    --listener function for the keyboard switch button
    local changeKeyBoard = function(event)
                            if(event.phase == "ended") then
                                self:drawKeyBoard(self.keyBoardMode.numbers)
                            end
                           end
    btnGroup:addEventListener("touch", changeKeyBoard)
    self.displayGroup:insert(btnGroup)            
    
    
    
    --draw the space button
    local btnGroup = self:createButton("[                 ]", maxButtonWidth*5 + 4*self.keySpace, maxButtonHeight)
    btnGroup.x = (startXOrg + maxButtonWidth*1.5) + 2*self.keySpace
    btnGroup.y = self.startY + (maxButtonHeight*totalRows) + (totalRows * self.keySpace)
    btnGroup:addEventListener("touch", self.textUpdater)
    btnGroup.character = " "
    btnGroup.inputCompleted=false
    self.displayGroup:insert(btnGroup)    
   
    --call the user defined listener for the key touch events    
    btnGroup:addEventListener("touch", self.userListenerCaller)    
    
    
    
    --draw the enter button that puts in a line break into the text the keyboard
    local btnGroup = self:createButton("ENTER", maxButtonWidth*2+self.keySpace, maxButtonHeight)
    btnGroup.x = (6.5 * maxButtonWidth + (7 * self.keySpace)) + startXOrg
    btnGroup.y = self.startY + (maxButtonHeight*totalRows) + (totalRows * self.keySpace)
    btnGroup:addEventListener("touch", self.textUpdater)
    btnGroup.character = "\n"
    btnGroup.inputCompleted=false
    self.displayGroup:insert(btnGroup)        
    
    
    
    --draw the done button that closes the keyboard    
    local btnGroup = self:createButton("OK", maxButtonWidth*1.5, maxButtonHeight)
    btnGroup.x = (8.5 * maxButtonWidth + ((firstRowLength-1) * self.keySpace)) + startXOrg
    btnGroup.y = self.startY + (maxButtonHeight*totalRows) + (totalRows * self.keySpace)    
    btnGroup.character = ""
    btnGroup.inputCompleted=true
    self.displayGroup:insert(btnGroup)        
    
    --call the user defined listener for the key touch events    
    btnGroup:addEventListener("touch", self.userListenerCaller)    
 end
 
 
 
 
 
 
 
 
 --[[
        Create the keys for a virtual keyboard that contains small printed letters
    ]]--
 function object:drawNumberKeyboard(width, height)
    local numberOfKeyRowsToDraw = 5
    local startX                = self.startX
    local startY                = self.startY
    local startXOrg             = self.startX
    local lettersToDraw         = {"7", "8", "9", self.breakerItem, "4", "5", "6", self.breakerItem, "1", "2", "3", self.breakerItem, "0"}
    
    --check how many objects the longest button row will consist of
    local firstRowLength=0
    for i=1,#lettersToDraw do
        if(lettersToDraw[i] == self.breakerItem) then
            firstRowLength = i-1
            break
        end
    end
    
    --create necessary counter vars for the following creation process loop
    local totalRows    = 0
    local buttonsOfRow = 0
    
    --check how width and height the buttons can be in maximum
    local maxButtonWidth  = ( (display.contentWidth -self.startX) - ((firstRowLength-1) * self.keySpace) ) / firstRowLength
    local maxButtonHeight = (display.contentHeight - self.startY - (numberOfKeyRowsToDraw*self.keySpace)) / ( numberOfKeyRowsToDraw )
    
    --create the keys for each necessary element
    for i=1,#lettersToDraw do
       local currentItem = lettersToDraw[i]
       
       --check whether to use small or large letters
       if(smallLetters == false)then    currentItem = string.upper(currentItem)    end       
              
       if(currentItem ~= self.breakerItem) then
           local btnGroup = self:createButton(currentItem, maxButtonWidth, maxButtonHeight)
           btnGroup.x = startX + (maxButtonWidth*buttonsOfRow) + (buttonsOfRow * self.keySpace)
           btnGroup.y = startY + (maxButtonHeight*totalRows) + (totalRows * self.keySpace)
           btnGroup.character = currentItem
           btnGroup.inputCompleted=false
           btnGroup:addEventListener("touch", self.textUpdater)
           self.displayGroup:insert(btnGroup)
           
           --call the user defined listener for the key touch events           
           btnGroup:addEventListener("touch", self.userListenerCaller)           
           
           buttonsOfRow = buttonsOfRow+1
       else
           buttonsOfRow = 0
           totalRows    = totalRows +1 

           if(totalRows == 3) then
            startX = (maxButtonWidth + self.keySpace) + startXOrg
           end              
       end
    end
    
    totalRows    = totalRows +1 
    buttonsOfRow = 0      
    
    --draw the keyboard switch button
    local btnGroup = self:createButton("?!(...", maxButtonWidth/2, maxButtonHeight)
    btnGroup.x = startXOrg
    btnGroup.y = self.startY + (maxButtonHeight*totalRows) + (totalRows * self.keySpace)
    btnGroup.inputCompleted=false
    
    --listener function for the keyboard switch button
    local changeKeyBoard = function(event)
                            if(event.phase == "ended") then
                                self:drawKeyBoard(self.keyBoardMode.signs)
                            end
                           end
    btnGroup:addEventListener("touch", changeKeyBoard)
    self.displayGroup:insert(btnGroup)                

    
    
    --draw the space button
    local btnGroup = self:createButton("[         ]", maxButtonWidth/2 - self.keySpace, maxButtonHeight)
    btnGroup.x = (startXOrg + maxButtonWidth/2) + self.keySpace
    btnGroup.y = self.startY + (maxButtonHeight*totalRows) + (totalRows * self.keySpace)
    btnGroup:addEventListener("touch", self.textUpdater)
    btnGroup.character = " "
    btnGroup.inputCompleted=false
    self.displayGroup:insert(btnGroup)    
   
    --call the user defined listener for the key touch events    
    btnGroup:addEventListener("touch", self.userListenerCaller)    
    
    
    
    --draw the delete button
    local btnGroup = self:createButton("DEL", maxButtonWidth, maxButtonHeight)
    btnGroup.x = maxButtonWidth + self.keySpace + startXOrg
    btnGroup.y = self.startY + (maxButtonHeight*totalRows) + (totalRows * self.keySpace)
    btnGroup.character = ""
    btnGroup.inputCompleted=false
    
    --listener function for the delete button
    local deleteSign= function(event)
                        if(event.phase == "ended") then
                            self.text = string.sub(self.text, 1, string.len(self.text)-1)                            
                        end
                        return false
                      end
    btnGroup:addEventListener("touch", deleteSign)
    self.displayGroup:insert(btnGroup)    
    
    --call the user defined listener for the key touch events
    btnGroup:addEventListener("touch", self.userListenerCaller)    
    
    
    
    --draw the enter button that puts in a line break into the text the keyboard
    local btnGroup = self:createButton("ENTER", maxButtonWidth/2, maxButtonHeight)
    btnGroup.x = (2 * maxButtonWidth + (2*self.keySpace)) + startXOrg
    btnGroup.y = self.startY + (maxButtonHeight*totalRows) + (totalRows * self.keySpace)
    btnGroup:addEventListener("touch", self.textUpdater)
    btnGroup.character = "\n"
    btnGroup.inputCompleted=false
    self.displayGroup:insert(btnGroup)            
    
    
    --draw the done button that closes the keyboard    
    local btnGroup = self:createButton("OK", maxButtonWidth/2, maxButtonHeight)
    btnGroup.x = 2.5 * maxButtonWidth + 3*self.keySpace + startXOrg
    btnGroup.y = self.startY + (maxButtonHeight*totalRows) + (totalRows * self.keySpace)    
    btnGroup.character = ""
    btnGroup.inputCompleted=true
    self.displayGroup:insert(btnGroup)        
    
    --call the user defined listener for the key touch events
    btnGroup:addEventListener("touch", self.userListenerCaller)    
 end 
 
 
 




--[[
        Create the keys for a virtual keyboard that contains small printed letters
    ]]--
 function object:drawSignsKeyboard(width, height)
    local numberOfKeyRowsToDraw = 5
    local startX                = self.startX
    local startY                = self.startY
    local startXOrg             = self.startX
    local lettersToDraw         = {"!" , "?" , "&" , "$" , "@" , "%"  , "["  , "]" , self.breakerItem ,
                                   "(" , ")" , "{" , "}" , "/" , "\\" , "\"" , "," , self.breakerItem ,
                                   ";" , ":" , "." , "~" , "#" , "'"  , "`"  , "*" , self.breakerItem ,
                                   "+" , "-" , "=" , "<" , ">" , "|"  , "_"
                                  }
                                  
    --check how many objects the longest button row will consist of
    local firstRowLength=0
    for i=1,#lettersToDraw do
        if(lettersToDraw[i] == self.breakerItem) then
            firstRowLength = i-1
            break
        end
    end
    
    --create necessary counter vars for the following creation process loop
    local totalRows    = 0
    local buttonsOfRow = 0
    
    --check how width and height the buttons can be in maximum
    local maxButtonWidth  = ( (display.contentWidth -self.startX) - ((firstRowLength-1) * self.keySpace) ) / firstRowLength
    local maxButtonHeight = (display.contentHeight - self.startY - (numberOfKeyRowsToDraw*self.keySpace)) / ( numberOfKeyRowsToDraw )
    
    --create the keys for each necessary element
    for i=1,#lettersToDraw do
       local currentItem = lettersToDraw[i]
       
       --check whether to use small or large letters
       if(smallLetters == false)then    currentItem = string.upper(currentItem)    end       
              
       if(currentItem ~= self.breakerItem) then
           local btnGroup = self:createButton(currentItem, maxButtonWidth, maxButtonHeight)
           btnGroup.x = startX + (maxButtonWidth*buttonsOfRow) + (buttonsOfRow * self.keySpace)
           btnGroup.y = startY + (maxButtonHeight*totalRows) + (totalRows * self.keySpace)
           btnGroup.character = currentItem
           btnGroup.inputCompleted=false
           btnGroup:addEventListener("touch", self.textUpdater)
           self.displayGroup:insert(btnGroup)
           
           --call the user defined listener for the key touch events
           btnGroup:addEventListener("touch", self.userListenerCaller)           
           
           buttonsOfRow = buttonsOfRow+1
       else
           buttonsOfRow = 0
           totalRows    = totalRows +1 
       end
    end
    
    totalRows    = totalRows +1 
    buttonsOfRow = 0      
    
    --draw the keyboard switch button
    local btnGroup = self:createButton("abc...", 2.5*maxButtonWidth, maxButtonHeight)
    btnGroup.x = startXOrg
    btnGroup.y = self.startY + (maxButtonHeight*totalRows) + (totalRows * self.keySpace)
    btnGroup.inputCompleted=false
    
    --listener function for the keyboard switch button
    local changeKeyBoard = function(event)
                            if(event.phase == "ended") then
                                self:drawKeyBoard(self.keyBoardMode.letters_small)
                            end
                           end
    btnGroup:addEventListener("touch", changeKeyBoard)
    self.displayGroup:insert(btnGroup)                

    
    
    --draw the space button
    local btnGroup = self:createButton("[         ]", maxButtonWidth, maxButtonHeight)
    btnGroup.x = (startXOrg + 2.5*maxButtonWidth) + self.keySpace
    btnGroup.y = self.startY + (maxButtonHeight*totalRows) + (totalRows * self.keySpace)
    btnGroup:addEventListener("touch", self.textUpdater)
    btnGroup.character = " "
    btnGroup.inputCompleted=false
    self.displayGroup:insert(btnGroup)    
   
    --call the user defined listener for the key touch events
    btnGroup:addEventListener("touch", self.userListenerCaller)    
    
    
    
    --draw the delete button
    local btnGroup = self:createButton("DEL", maxButtonWidth, maxButtonHeight)
    btnGroup.x = (startXOrg + 3.5*maxButtonWidth) + 2*self.keySpace
    btnGroup.y = self.startY + (maxButtonHeight*totalRows) + (totalRows * self.keySpace)
    btnGroup.character = ""
    btnGroup.inputCompleted=false
    
    --listener function for the delete button
    local deleteSign= function(event)
                        if(event.phase == "ended") then
                            self.text = string.sub(self.text, 1, string.len(self.text)-1)                            
                        end
                        return false
                      end
    btnGroup:addEventListener("touch", deleteSign)
    self.displayGroup:insert(btnGroup)    
    
    --call the user defined listener for the key touch events
    btnGroup:addEventListener("touch", self.userListenerCaller)    
    
    
    
    --draw the enter button that puts in a line break into the text the keyboard
    local btnGroup = self:createButton("ENTER", maxButtonWidth, maxButtonHeight)
    btnGroup.x = (startXOrg + 4.5*maxButtonWidth) + 3*self.keySpace
    btnGroup.y = self.startY + (maxButtonHeight*totalRows) + (totalRows * self.keySpace)
    btnGroup:addEventListener("touch", self.textUpdater)
    btnGroup.character = "\n"
    btnGroup.inputCompleted=false
    self.displayGroup:insert(btnGroup)        
    
    
    
    --draw the done button that closes the keyboard    
    local btnGroup = self:createButton("OK", 2.5*maxButtonWidth+2*self.keySpace, maxButtonHeight)
    btnGroup.x = (startXOrg + 5.5*maxButtonWidth) + 4*self.keySpace
    btnGroup.y = self.startY + (maxButtonHeight*totalRows) + (totalRows * self.keySpace)    
    btnGroup.character = ""
    btnGroup.inputCompleted=true
    self.displayGroup:insert(btnGroup)        
    
    --call the user defined listener for the key touch events
    btnGroup:addEventListener("touch", self.userListenerCaller)    
 end 
 

 --[[
    Destroy the entire keyboard
   ]]-- 
 function object:destroy()
    local cl = function()
                self:clearCurrentKeyBoard()
                self = nil
               end
               
    if(self.displayGroup ~= nil) then
        transition.to(self.displayGroup, {alpha = 0, time=self.animationDuration, onComplete=cl})
    end    
 end
 
 
 --[[
    Hide the entire keyboard
   ]]-- 
 function object:hide()               
    if(self.displayGroup ~= nil) then
        transition.to(self.displayGroup, {alpha = 0, time=self.animationDuration})        
    end    
 end
 
 
 --[[
    Show the entire keyboard
   ]]-- 
 function object:show()               
    if(self.displayGroup ~= nil) then          
        transition.to(self.displayGroup, {alpha=1, time=self.animationDuration})        
    end
 end
 
 --check parameters
 if(params~=nil) then
    object:init(params)
 else
    object:init({})
 end
 
 return object
end