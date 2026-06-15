--Script based on "Big, Animated Button" addon from MrStump and modified by Lan.
function buttonPress()
    if lockout == false then

        self.AssetBundle.playTriggerEffect(0)
        lockout = true
        startLockoutTimer()
    end
end


function onload()
    self.interactable = false
    self.createButton({
        click_function = "buttonPress",
        tooltip='Bruh', function_owner = self,  position={0,0.45,0}, height=730, width=730, color = {0,0,0,0}
    })
    self.createButton({
        click_function = "buttonPress",
        tooltip='Bruh', function_owner = self,  position={0,0.45,0}, rotation={0,11.25,0}, height=730, width=730, color = {0,0,0,0}
    })
    self.createButton({
        click_function = "buttonPress",
        tooltip='Bruh', function_owner = self,  position={0,0.45,0}, rotation={0,22.5,0}, height=730, width=730, color = {0,0,0,0}
    })
    self.createButton({
        click_function = "buttonPress",
        tooltip='Bruh', function_owner = self,  position={0,0.45,0}, rotation={0,33.75,0}, height=730, width=730, color = {0,0,0,0}
    })
    self.createButton({
        click_function = "buttonPress",
        tooltip='Bruh', function_owner = self,  position={0,0.45,0}, rotation={0,45,0}, height=730, width=730, color = {0,0,0,0}
    })
    self.createButton({
        click_function = "buttonPress",
        tooltip='Bruh', function_owner = self,  position={0,0.45,0}, rotation={0,55.25,0}, height=730, width=730, color = {0,0,0,0}
    })
    self.createButton({
        click_function = "buttonPress",
        tooltip='Bruh', function_owner = self,  position={0,0.45,0}, rotation={0,77.5,0}, height=730, width=730, color = {0,0,0,0}
    })
    self.createButton({
        click_function = "buttonPress",
        tooltip='Bruh', function_owner = self,  position={0,0.45,0}, rotation={0,88.75,0}, height=730, width=730, color = {0,0,0,0}
    })
    lockout = false
end


function startLockoutTimer()
    Timer.create({identifier=self.getGUID(), function_name='unlockLockout', delay=0})
end


function unlockLockout()
    lockout = false
end


function onDestroy()
    Timer.destroy(self.getGUID())
end