class ArrayExistTransformer < NSValueTransformer

  def transformedValueClass
    NSNumber.class
  end
  
  def allowsReverseTransformation
    false
  end
  
  def transformedValue(value)
    if value.nil? || value.length == 0
      return 0
    else
      return 1
    end
  end
  
end


class ValueZeroSelectedTransformer < NSValueTransformer

  def transformedValueClass
    NSNumber.class
  end
  
  def allowsReverseTransformation
    false
  end
  
  def transformedValue(value)
    value.to_i == 0 ? true : false
  end
  
end

class ValueOneSelectedTransformer < NSValueTransformer

  def transformedValueClass
    NSNumber.class
  end
  
  def allowsReverseTransformation
    false
  end
  
  def transformedValue(value)
    value.to_i == 1 ? true : false
  end
  
end


class ArrayLengthTransformer < NSValueTransformer

  def transformedValueClass
    NSNumber.class
  end

  def allowsReverseTransformation
    false
  end

  def transformedValue(value)
    if value.nil? || value.length == 0
      return 0
    else
      return value.length
    end
  end

end


class ArrayLengthMoreThanOneTransformer < NSValueTransformer

  def transformedValueClass
    NSNumber.class
  end
  
  def allowsReverseTransformation
    false
  end
  
  def transformedValue(value)
    if value.length > 1
      1
    else
      0
    end
  end
  
end



class ValueTwoNotSelectedTransformer < NSValueTransformer

  def transformedValueClass
    NSNumber.class
  end
  
  def allowsReverseTransformation
    false
  end
  
  def transformedValue(value)
    value.to_i == 2 ? 0 : 1
  end
  
end


class ValueTwoSelectedTransformer < NSValueTransformer

  def transformedValueClass
    NSNumber.class
  end
  
  def allowsReverseTransformation
    false
  end
  
  def transformedValue(value)
    value.to_i == 2 ? 1 : 0
  end
  
end



class GetGroupValueTransformer < NSValueTransformer

  def transformedValueClass
    NSArray.class
  end
  
  def allowsReverseTransformation
    false
  end
  
  def transformedValue(value)
    if !value.nil?
      value.map{|x| x['group']}
    else
      value
    end
  end
  
end


class GetLocalizedFontNameTransformer < NSValueTransformer

  def transformedValueClass
    NSArray.class
  end
  
  def allowsReverseTransformation
    false
  end
  
  def transformedValue(value)
    value.map{|x| x['localizedFontName']}
  end
  
end


class TwoObjectsSelectedTransformer < NSValueTransformer

  def transformedValueClass
    NSNumber.class
  end
  
  def allowsReverseTransformation
    false
  end
  
  def transformedValue(value)
    if value.length > 1
      1
    else
      0
    end
  end
  
end




class ArrayLengthZeroTransformer < NSValueTransformer
  
  def transformedValueClass
    NSNumber.class
  end
  
  def allowsReverseTransformation
    false
  end
  
  def transformedValue(value)
    if value.nil? || value.length == 0
      1
    else
      0
    end
  end

end


class TableRowHeightAdjustTransformer < NSValueTransformer

  def transformedValueClass
    NSNumber.class
  end
  
  def allowsReverseTransformation
    false
  end
  
  def transformedValue(value)
    value + 3
  end
  
end






class ValueOneNotSelectedTransformer < NSValueTransformer

  def transformedValueClass
    NSNumber.class
  end
  
  def allowsReverseTransformation
    false
  end
  
  def transformedValue(value)
    value.to_i == 1 ? 0 : 1
  end
  
end

class ValueThreeNotSelectedTransformer < NSValueTransformer

  def transformedValueClass
    NSNumber.class
  end
  
  def allowsReverseTransformation
    false
  end
  
  def transformedValue(value)
    value.to_i == 3 ? 0 : 1
  end
  
end


class ValueThreeSelectedTransformer < NSValueTransformer

  def transformedValueClass
    NSNumber.class
  end
  
  def allowsReverseTransformation
    false
  end
  
  def transformedValue(value)
    value.to_i == 3 ? 1 : 0
  end
  
end



class ValueZeroNotSelectedTransformer < NSValueTransformer
  
  def transformedValueClass
    NSNumber.class
  end
  
  def allowsReverseTransformation
    false
  end
  
  def transformedValue(value)
    value.to_i == 0 ? 0 : 1
  end

end


class ValueNineNotSelectedTransformer < NSValueTransformer

  def transformedValueClass
    NSNumber.class
  end
  
  def allowsReverseTransformation
    false
  end
  
  def transformedValue(value)
    value.to_i != 9 ? 1 : 0
  end
  
end

class ValueOneTwoNotSelectedTransformer < NSValueTransformer

  def transformedValueClass
    NSNumber.class
  end
  
  def allowsReverseTransformation
    false
  end
  
  def transformedValue(value)
    (value.to_i == 1 || value.to_i == 2) ? 0 : 1
  end
  
end




class ValueZeroToTrueTransformer < NSValueTransformer

  def transformedValueClass
    NSNumber.class
  end
  
  def allowsReverseTransformation
    false
  end
  
  def transformedValue(value)
    value.to_i == 0
  end
  
end

class ValueOneToTrueTransformer < NSValueTransformer

  def transformedValueClass
    NSNumber.class
  end
  
  def allowsReverseTransformation
    false
  end
  
  def transformedValue(value)
    value.to_i == 1
  end
  
end

