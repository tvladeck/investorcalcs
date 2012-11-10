module Projection
  def simulate_deals(n, upfront_cost, payback_months, attrition_rate,
                     renewal_rate, contract_length, months)
    total_upfront = n * upfront_cost
    fee = upfront_cost / payback_months
    revenue_stream = []
    months.times do revenue_stream << 0 end

    n.times do |deal|
      fee_vector = contract_stream(fee, attrition_rate, renewal_rate,
                                   contract_length, months)
      fee_vector.each_with_index do |fee, index|
        revenue_stream[index] += fee
      end
    end

    result = { :capex => total_upfront, :revenues => revenue_stream }
    result
  end
end
