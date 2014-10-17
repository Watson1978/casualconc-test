#
#  CCStats.rb
#  CasualConc
#
#  Created by Yasu on 10/12/17.
#  Copyright (c) 2010 Yasu Imao. All rights reserved.
#

include Math

class CCStats
  

  def chiSquareCalc(a,b,aa,bb)
    begin
      a = a.to_i
      b = b.to_i
      c = aa - a
      d = bb - b
      n = a + b + c + d
      return (n.to_f * (((a * d - b * c).abs - (n / 2)) ** 2)) / ((a + b) * (c + d) * (a + c) * (b + d))
    rescue
      return 0
    end
  end


  def chiSquareNoCalc(a,b,aa,bb)
    begin
      a = a.to_i
      b = b.to_i
      c = aa - a
      d = bb - b
      n = a + b + c + d
      return (n.to_f * (((a * d - b * c).abs) ** 2)) / ((a + b) * (c + d) * (a + c) * (b + d)).to_f
    rescue
      return 0
    end
  end



  def miScoreCalc(coFreq,nodeFreq,contextFreq,totalFreq,spanN)
    return 0 if spanN == 0
    begin
      return log((coFreq.to_f * totalFreq) / (nodeFreq * contextFreq * spanN)) / log(2)
    rescue
      return 0
    end
  end


  def miScoreNoSpanCalc(coFreq,nodeFreq,contextFreq,totalFreq)
    begin
      return log((coFreq.to_f * totalFreq) / (nodeFreq * contextFreq)) / log(2)
    rescue
      return 0
    end
  end
  
  
  def diceScoreCalc(keyFreq,refKeyFreq,totalFreq,refTotalFreq)
    begin
      refKeyFreq = refKeyFreq.to_i
      return (2 * keyFreq.to_f) / ((keyFreq + refKeyFreq) + totalFreq)
    rescue
      return 0
    end
  end


  def cmsScoreCalc(keyFreq,refKeyFreq,totalFreq,refTotalFreq)
    begin
      refKeyFreq = refKeyFreq.to_i
      return ((keyFreq.to_f * (refTotalFreq - refKeyFreq)) - (refKeyFreq * (totalFreq - keyFreq))) / sqrt(totalFreq * refTotalFreq)
    rescue
      return 0
    end
  end
  

  def pmiScoreCalc(keyFreq,refKeyFreq,totalFreq,refTotalFreq)
    begin
      refKeyFreq = refKeyFreq.to_i
      return log((keyFreq.to_f * (totalFreq + refTotalFreq)) / ((keyFreq + refKeyFreq) * totalFreq)) / log(2)
    rescue
      return 0
    end
  end

  def cosineScoreCalc(keyFreq,refKeyFreq,totalFreq,refTotalFreq)
    begin
      refKeyFreq = refKeyFreq.to_i
      return (keyFreq.to_f / sqrt(((keyFreq + refKeyFreq) * totalFreq)))
    rescue
      return 0
    end
  end


  def mi3ScoreCalc(coFreq,nodeFreq,contextFreq,totalFreq,spanN)
    return 0 if spanN == 0
    begin
      nodeFreq = nodeFreq.to_i
      return log(((coFreq.to_f ** 3)* totalFreq) / (nodeFreq * contextFreq * spanN)) / log(2)
    rescue
      return 0
    end
  end

  def mi3ScoreNoSpanCalc(coFreq,nodeFreq,contextFreq,totalFreq)
    begin
      nodeFreq = nodeFreq.to_i
      return log(((coFreq.to_f ** 3)* totalFreq) / (nodeFreq * contextFreq)) / log(2)
    rescue
      return 0
    end
  end



  def llCalc(aFreq,bFreq,totalAFreq,totalBFreq)
    begin
      bFreq = bFreq.to_i
      e1 = (totalAFreq.to_f * (aFreq + bFreq) / (totalAFreq + totalBFreq))
      e2 = (totalBFreq.to_f * (aFreq + bFreq) / (totalAFreq + totalBFreq))
      if bFreq != 0 && !bFreq.nil?
        return 2*((aFreq * log(aFreq / e1)) + (bFreq * log(bFreq / e2)))
      else
        return 2*((aFreq * log(aFreq / e1)))
      end
    rescue
      return 0
    end
  end



  def llTblCalc(a,b,c,d)
    begin
      if b > 0 && c > 0
        return 2 * (a.to_f * log(a) + b * log(b) + c * log(c) + d * log(d) - (a + b) * log(a + b) - (a + c) * log(a + c) - (b + d) * log(b + d) - (c + d) * log(c + d) + (a + b + c + d) * log(a + b + c + d))
      elsif b <= 0 && c > 0
        return 2 * (a.to_f * log(a) + c * log(c) + d * log(d) - (a + b) * log(a + b) - (a + c) * log(a + c) - (b + d) * log(b + d) - (c + d) * log(c + d) + (a + b + c + d) * log(a + b + c + d))
      elsif b > 0 && c <= 0
        return 2 * (a.to_f * log(a) + b * log(b) + d * log(d) - (a + b) * log(a + b) - (a + c) * log(a + c) - (b + d) * log(b + d) - (c + d) * log(c + d) + (a + b + c + d) * log(a + b + c + d))
      else b <= 0 && c <= 0
        return 2 * (a.to_f * log(a) + d * log(d) - (a + b) * log(a + b) - (a + c) * log(a + c) - (b + d) * log(b + d) - (c + d) * log(c + d) + (a + b + c + d) * log(a + b + c + d))    
      end
    rescue
      return 0
    end
  end


  def collocLLCalc(coFreq,nodeFreq,contextFreq,totalFreq)
    p coFreq,nodeFreq,contextFreq,totalFreq if coFreq.nil? || nodeFreq.nil? || contextFreq.nil? || totalFreq.nil?
    a = coFreq
    b = (nodeFreq - a) <= 0 ? 0 : nodeFreq - a
    c = (contextFreq - a) <= 0 ? 0 : contextFreq - a
    d = totalFreq - nodeFreq - contextFreq

    return llTblCalc(a,b,c,d)
  end




  def tscoreCalc(coFreq,nodeFreq,contextFreq,totalFreq)
    begin
      return (coFreq - (nodeFreq.to_f * contextFreq) / totalFreq) / sqrt(coFreq)
    rescue
      return 0
    end
  end



  def loglogCalc(coFreq,nodeFreq,contextFreq,totalFreq,spanN)
    return 0 if spanN == 0
    begin
      if coFreq == 0
        return 0
      else
        return (log((coFreq.to_f * totalFreq) / (nodeFreq * contextFreq * spanN)) * log(coFreq)) / (log(2) ** 2)      
      end
    rescue
      return 0
    end
  end


  def loglogNoSpanCalc(coFreq,nodeFreq,contextFreq,totalFreq)
    begin
      if coFreq == 0
        return 0
      else
        return (log((coFreq.to_f * totalFreq) / (nodeFreq * contextFreq)) * log(coFreq)) / (log(2) ** 2)      
      end
    rescue
      return 0
    end
  end


  def zscoreCalc(coFreq,nodeFreq,contextFreq,totalFreq,spanN)
    return 0 if spanN == 0
    begin
      pro = contextFreq.to_f / (totalFreq - nodeFreq)
      ex = pro.to_f * nodeFreq * spanN
      return (coFreq - ex) / sqrt(ex * (1 - pro))
    rescue
      return 0
    end
  end


  def zscoreNoSpanCalc(coFreq,nodeFreq,contextFreq,totalFreq)
    begin
      pro = contextFreq.to_f / (totalFreq - nodeFreq)
      ex = pro.to_f * nodeFreq
      return (coFreq - ex) / sqrt(ex * (1 - pro))
    rescue
      return 0
    end
  end



  def fisherCollocCalc(coFreq,nodeFreq,contextFreq,totalFreq)
    a = coFreq
    b = (nodeFreq - a) <= 0 ? 0 : nodeFreq - a
    c = (contextFreq - a) <= 0 ? 0 : contextFreq - a
    d = totalFreq - nodeFreq - contextFreq

    begin
      return fisherCalc(a,b,c,d)
    rescue
      return 0
    end
  end


  def fisherCalc(a,b,c,d)
    fisher1 = 0.0
    fisher2 = 0.0
    out = 0.0  

    fisher = 0.0
    fisher2 = 0.0
    base = fisherProb(a,b,c,d)
    if b == 0 || c == 0
      base1 = 0
    else
      base1 = fisherProb(a+1,b-1,c-1,d+1)
    end
    if a == 0 || d == 0
      base2 = 0
    else
      base2 = fisherProb(a-1,b+1,c+1,d-1)
    end

    case [a,b,c,d].min
    when a,d

      if (base >= base1 && base < base2) || (base > base1 && base <= base2)
        fisher1 += base
      else
        fisher2 += base
      end

      a1,b1,c1,d1 = a,b,c,d


      while a1 >= 0 && d1 >= 0
        add = fisherProb(a1,b1,c1,d1)
        break if add == 0.0
        fisher2 += add if add < base
        break if a1 == 0 || d1 == 0
        a1 -= 1
        b1 += 1
        c1 += 1
        d1 -= 1
      end

      a2,b2,c2,d2 = a,b,c,d

      while b2 >= 0 && c2 >= 0
        add = fisherProb(a2,b2,c2,d2)
        break if add == 0.0
        fisher1 += add if add < base
        break if b2 == 0 || c2 ==0
        a2 += 1
        b2 -= 1
        c2 -= 1
        d2 += 1
      end
    when b,c

      if (base >= base1 && base < base2) || (base > base1 && base <= base2)
        fisher2 += base
      else
        fisher1 += base
      end

      a1,b1,c1,d1 = a,b,c,d

      while b1 >= 0 && c1 >= 0
        add = fisherProb(a1,b1,c1,d1)
        break if add == 0.0
        fisher1 += add
        break if b1 == 0 || c1 == 0
        a1 += 1
        b1 -= 1
        c1 -= 1
        d1 += 1
      end

      a2,b2,c2,d2 = a,b,c,d

      while a2 >= 0 && d2 >= 0
        add = fisherProb(a2,b2,c2,d2)
        break if add == 0.0
        fisher2 += add if add < base
        break if a2 == 0 || d2 == 0
        a2 -= 1
        b2 += 1
        c2 += 1
        d2 -= 1
      end
    end

    fisher3 = fisher1 + fisher2 >= 1 ? 1.0 : fisher1 + fisher2

    return fisher1,fisher2,fisher3

  end


  def fisherProb(a,b,c,d)
    aa = a + b
    bb = c + d
    cc = a + c
    dd = b + d
    max = [aa,bb,cc,dd].max
    nn = a + b + c + d
    fix = 10000000000

    case max
    when aa
      case [a,b,c,d].min
      when a
        return fact2(bb,d)*fact2(cc,c)*fact2(dd,b)*fix/(fact2(nn,aa)*fact(a))/fix.to_f
      when b
        return fact2(bb,c)*fact2(cc,a)*fact2(dd,d)*fix/(fact2(nn,aa)*fact(b))/fix.to_f
      when c
        return fact2(bb,d)*fact2(cc,a)*fact2(dd,b)*fix/(fact2(nn,aa)*fact(c))/fix.to_f
      when d
        return fact2(bb,c)*fact2(cc,a)*fact2(dd,b)*fix/(fact2(nn,aa)*fact(d))/fix.to_f
      end
    when bb
      case [a,b,c,d].min
      when a
        return fact2(aa,b)*fact2(cc,c)*fact2(dd,d)*fix/(fact2(nn,bb)*fact(a))/fix.to_f
      when b
        return fact2(aa,a)*fact2(cc,c)*fact2(dd,d)*fix/(fact2(nn,bb)*fact(b))/fix.to_f
      when c
        return fact2(aa,b)*fact2(cc,a)*fact2(dd,d)*fix/(fact2(nn,bb)*fact(c))/fix.to_f
      when d
        return fact2(aa,a)*fact2(cc,c)*fact2(dd,b)*fix/(fact2(nn,bb)*fact(d))/fix.to_f
      end
    when cc
      case [a,b,c,d].min
      when a
        return fact2(aa,b)*fact2(bb,c)*fact2(dd,d)*fix/(fact2(nn,cc)*fact(a))/fix.to_f
      when b
        return fact2(aa,a)*fact2(bb,c)*fact2(dd,d)*fix/(fact2(nn,cc)*fact(b))/fix.to_f
      when c
        return fact2(aa,a)*fact2(bb,d)*fact2(dd,b)*fix/(fact2(nn,cc)*fact(c))/fix.to_f
      when d
        return fact2(aa,a)*fact2(bb,c)*fact2(dd,b)*fix/(fact2(nn,cc)*fact(d))/fix.to_f
      end
    when dd
      case [a,b,c,d].min
      when a
        return fact2(aa,b)*fact2(bb,d)*fact2(cc,c)*fix/(fact2(nn,dd)*fact(a))/fix.to_f
      when b
        return fact2(aa,a)*fact2(bb,d)*fact2(cc,c)*fix/(fact2(nn,dd)*fact(b))/fix.to_f
      when c
        return fact2(aa,b)*fact2(bb,d)*fact2(cc,a)*fix/(fact2(nn,dd)*fact(c))/fix.to_f
      when d
        return fact2(aa,b)*fact2(bb,c)*fact2(cc,a)*fix/(fact2(nn,dd)*fact(d))/fix.to_f
      end    
    end
  end

  def fact(n)
    return 1 if n == 0
    (1..n).inject{|a,b| a*b}
  end

  def fact2(n,nn)
    return 1 if n == 0 || n == nn
    (nn+1..n).inject{|a,b| a*b}
  end

  
  
  
end
