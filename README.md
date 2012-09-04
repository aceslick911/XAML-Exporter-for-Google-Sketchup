This is a branch from the original "Xaml Exporter from Google SketchUp" by Itai Bar-Haim
 Copyright (C) 2009 itaibh@gmail.com

http://itaibh.blogspot.com.au/2009/09/google-sketchup-xaml-exporter.html
http://itaibh.blogspot.com.au/2009/12/xaml-exporter-for-sketchup-round-2.html

2012 Updates by Angelo Perera
License: Not reserved. Free to distribute, please contribute.

Reason for this GIT is because the original implementation:

> Did not have support for units other than inches
> Always output textures surrounded by square brackets [ ] causing XAML parsing errors in Visual Studio.


How to use:
Copy the Ruby .rb file into your "Google SketchUp x\Plugins" directory and start google sketchup. 
You will find this plugin inside the "Plugins" menu item.

Current Problems:
> Only generates XAML for meshes that are not part of a component.
> You must explode all components for the exporter to include it in the output XAML
> Does not support components