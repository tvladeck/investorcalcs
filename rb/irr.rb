module Projection

  def irr(payments)
    if npv(1, payments) > 0; return 1; end
    upper = 1
    lower = 0
    result = 1
    while result.abs > 0.1
      middle = (upper + lower) / 2.0
      result = npv(middle, payments)
      if result < 0
        upper = middle
      elsif result > 0
        lower = middle
      end
    end
    middle
  end

end
