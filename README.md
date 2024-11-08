# Stock Me Up
Have you ever been building your base and annoyed by the constant swarm of flies as your logistics bots bring you one item at a time? Do you wish you had more control over when your logistic bots restock you? Do you use modded bots that have higher carrying capacity and want them to take better advantage of that? If so, this mod is for you.

## Features
Stock Me Up changes how logistic bots function for any logistic request that has both a minimum and maximum amount set. When your inventory falls below the minimum, instead of only bringing enough items to refill you to it, your logistics bots will stock you all the way up to the maximum. That way, another stock request won't be created until you fall below the minimum again.

This is accomplished by a special logistics section, named "Stock Me Up", that is automatically created and removed as needed. This section is robust, and will automatically adjust its request if you make changes to your logistics sections while a request is ongoing.

## Usage Notes
* For performance reasons, logistic requests are only checked when the player's inventory changes. This means, for example, that if you lower or raise the amount of a request, the special logistics section won't respond until something causes your inventory to change. Because bots bringing you things or items going into trash slots both count as "changes", this will rarely delay an update by more than a second or two.
* Related to the above, if you turn personal logistics off, once you turn it back on Stock Me Up will not create any requests until your inventory changes again.
* Also for performance reasons, the mod only checks to remove requests from the special logistics section once per second. If you are constantly placing items while a request is inbound, you may get the "swarm of flies" effect until you pause for a moment.
* Manually adjusting the values of Stock Me Up requests _may_ cause weird behavior. I tried to account for all possibilities, but I may have missed some. Maybe don't do that? Why do you need to?

## Known Issues
* If you have 100 personal logistic sections, the mod will be unable to create another. This will cause unexpected behavior and possibly crashes. Why do you have 100 logistic sections?
* If you have more than 1000 unique item requests simultaneously, the special logistic section will be unable to fit them all. This will cause unexpected behavior and possibly crashes. Why are you requesting 1000 different items? How will you even fit them in your inventory?
* Quality is not currently supported; all requests will be for normal-quality items. This will be addressed in the next version.

## Upcoming Features
* Support for quality
* The ability to create logistic sections that are ignored by Stock Me Up
* The ability to choose the name of the special logistics section
* A hotkey to stock everything up to max at once
* (Maybe) A GUI to request specific items be stocked up

## Special Thanks
* Huge thanks to Atria1234 for letting me use the code that creates and cleans up the special logistics section
* PennyJim, justarandomgeek, Xorimuth, and others on the Factorio Discord for their patience with a newbie modder
