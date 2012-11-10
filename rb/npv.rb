module Projection

  def npv(discount, payments)
    sum = 0
    payments.each_with_index do |x, i|
      sum += x / ( (1 + discount) ** i )
    end
    sum
  end

end
