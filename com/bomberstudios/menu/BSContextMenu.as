//
//  BSContextMenu
//
//  Created by Ale Muñoz on 2009-10-14.
//  Copyright (c) 2009 The Cocktail. All rights reserved.
//

class com.bomberstudios.menu.BSContextMenu {
  function BSContextMenu(root:MovieClip){
    var myMenu:ContextMenu = new ContextMenu();
    myMenu.hideBuiltInItems();
    var version_data:ContextMenuItem = new ContextMenuItem("FLVPlayer 1.7.1", function(){});
    myMenu.customItems.push(version_data);

    root.menu = myMenu;
  }
}