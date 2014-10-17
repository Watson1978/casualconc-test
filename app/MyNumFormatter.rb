#
#  MyNumFormatter.rb
#  CasualConc
#
#  Created by Yasu on 10/12/14.
#  Copyright (c) 2010 Yasu Imao. All rights reserved.
#

class MyNumFormatter < NSNumberFormatter
  
  def textAttributesForNegativeValues
    {"NSColor" => NSColor.redColor}
  end
end
