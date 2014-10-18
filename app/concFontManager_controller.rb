#
#  ConcFontManagerPanelController.rb
#  CasualConc
#
#  Created by Yasu on 10/12/04.
#  Copyright (c) 2010 Yasu Imao. All rights reserved.
#

class ConcFontManagerController < NSWindowController
  extend IB
  
  outlet :allFontAryCtl
  outlet :fontAryCtl
  outlet :fontTable
  outlet :fontChoice
  
  def windowNibName
    "ConcFontManagerPanel"
  end
  
  def awakeFromNib
    fontManager = NSFontManager.sharedFontManager
    fontNames = []
    fontManager.availableFontFamilies.each do |font|
      fontNames << {"fontName" => font, "localizedFontName" => font}
    end
    @allFontAryCtl.addObjects(fontNames)
  end
	
	def addFont(sender)
	  @fontAryCtl.addObject(@allFontAryCtl.arrangedObjects[@fontChoice.indexOfSelectedItem])
  end
  
  def removeFont(sender)
    case @fontAryCtl.selectionIndex
    when 0,1
      alert = NSAlert.alertWithMessageText("You cannot delete '#{@fontAryCtl.arrangedObjects[@fontAryCtl.selectionIndex]['localizedFontName']}'.",
                                          defaultButton:"OK",
                                          alternateButton:nil,
                                          otherButton:nil,
                                          informativeTextWithFormat:"")
      alert.beginSheetModalForWindow(self.window,completionHandler:Proc.new { |returnCode| })
    else
      @fontAryCtl.removeObjects(@fontAryCtl.selectedObjects)
    end
  end

end
