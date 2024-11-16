# Stock Me Up
Have you ever been building your base and annoyed by the constant swarm of flies as your logistics bots bring you one item at a time? Do you wish you had more control over when your logistic bots restock you? Do you use modded bots that have higher carrying capacity and want them to take better advantage of that? If so, this mod is for you.

# Features

### Logistics Changes
Stock Me Up changes how logistic bots function for any personal logistic request that has both a minimum and maximum amount set. When your inventory falls below the minimum, instead of only bringing enough items to refill you to it, your logistics bots will stock you all the way up to the maximum. That way, another stock request won't be created until you fall below the minimum again.

This is accomplished by a special logistics section, named "Stock Me Up", that is automatically created and removed as needed. This section is robust, and will automatically adjust its request if you make changes to your logistics sections while a request is ongoing.

### Stock Up Hotkey
For even more control over your logistics requests, Stock Me Up also adds a versatile hotkey, Ctrl+S by default. With this hotkey, a variety of functions can be triggered:
* If there is an item in your cursor, a stock up request will be generated for it.
* If there is already a stock request for the item, an extra stack of the item will be requested - this extra request will not be automatically removed, to avoid the items being taken away by your bots as soon as they are delivered.
* If there is no item in your cursor, your bots will stock you up with _every_ item that has both a minimum and maximum set.
* If you press the hotkey twice in a row with no item in your cursor, all stock requests (including overstock requests) added by the mod will be removed.

# Usage Notes
* For performance reasons, logistic requests are only checked when the player's inventory changes or when the hotkey is pressed. This means, for example, that if you lower or raise the amount of a request, the special logistics section won't respond until something causes your inventory to change. Because bots bringing you things or items going into trash slots both count as "changes", this will rarely delay an update by more than a second or two.
* Related to the above, if you turn personal logistics off or leave your logistic range, once you turn it back on or re-enter Stock Me Up will not create any requests until your inventory changes again.
* Also for performance reasons, the mod only checks to remove requests from the special logistics section once per second. If you are constantly placing items while a request is inbound, you may get the "swarm of flies" effect until you pause for a moment.

# Known Issues
* If you have 100 personal logistic sections, the mod will be unable to create another. This will cause unexpected behavior and possibly crashes. Why do you have 100 logistic sections?
* If you have more than 1000 unique item requests simultaneously, the special logistic section will be unable to fit them all. This will cause unexpected behavior and possibly crashes. Why are you requesting 1000 different items? How will you even fit them in your inventory?
* While quality is supported, due to an engine limitation the mod can't tell what quality of item you are short on. If you have multiple requests for the same item at different qualities, they will all get stocked up simultaneously. This doesn't apply to the hotkey, which will respect the quality of the item you are holding.
* Weird edge case: If you are outside of a logistic zone and re-enter, and your inventory doesn't change before your bots reach you, AND the first bot that gets to you fills you up to your minimum request, Stock Me Up will not notice you need restocking. This is unfortunately difficult to account for in any performant way.

# Upcoming Features
-The ability to create logistic sections that are ignored by Stock Me Up
-The ability to choose the name of the special logistics section
-More settings in general

# Special Thanks
* Huge thanks to Atria1234 for letting me use the code that creates and cleans up the special logistics section
* PennyJim, justarandomgeek, Xorimuth, and others on the Factorio Discord for their patience with a newbie modder