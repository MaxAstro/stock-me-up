# Stock Me Up
Have you ever been building your base and annoyed by the constant swarm of flies as your logistics bots bring you one item at a time? Do you wish you had more control over when your logistic bots restock you? Are you slightly short of one item and wish you could quickly request more of it? Do you use modded bots that have higher carrying capacity and want them to take better advantage of that? If so, this mod is for you.

# Features

### Logistics Changes
Stock Me Up changes how logistic bots function for any personal logistic request that has both a minimum and maximum amount set. When your inventory falls below the minimum, instead of only bringing enough items to refill you to it, your logistics bots will stock you all the way up to the maximum. That way, another stock request won't be created until you fall below the minimum again.

This is accomplished by a special logistics section, named "Stock Me Up" by default, that is automatically created and removed as needed. This section is robust, and will automatically adjust its request if you make changes to your logistics sections while a request is ongoing. You can also define a keyword or character in the settings to designate logistic sections the mod should ignore.

These automatic stock requests can optionally be disabled entirely if you only want the hotkey functionality below.

### Stock Up Hotkey
For even more control over your logistics requests, Stock Me Up also adds a versatile hotkey, Alt+S by default. With this hotkey, a variety of functions can be triggered:
* If there is an item in your cursor, a stock up request will be generated for it.
* If there is already a stock request for the item, an extra stack of the item will be requested - this extra request will not be automatically removed, to avoid the items being taken away by your bots as soon as they are delivered.
* If there is no item in your cursor, your bots will stock you up with _every_ item that has both a minimum and maximum set.
* If you press the hotkey twice in a row with no item in your cursor, all stock requests (including overstock requests) added by the mod will be removed.

# Known Issues
* If you have 100 personal logistic sections, the mod will be unable to create another. This will cause unexpected behavior and possibly crashes. Why do you have 100 logistic sections?
* If you have more than 1000 unique item requests simultaneously, the special logistic section will be unable to fit them all. This will cause unexpected behavior and possibly crashes. Why are you requesting 1000 different items? How will you even fit them in your inventory?

# Special Thanks
* Huge thanks to Atria1234 for letting me use the code that creates and cleans up the special logistics section
* PennyJim, justarandomgeek, Xorimuth, and others on the Factorio Discord for their patience with a newbie modder