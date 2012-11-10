module Projection

  def contract_stream(fee, attrition_rate, renewal_rate,
                      contract_length, months)
    fee_vector = []
    cancel_rate = 1 - renewal_rate
    months.times do |month|
      if month % contract_length == 0 && month != 0 && Random.rand < cancel_rate
        break
      elsif Random.rand < attrition_rate
        break
      else
        fee_vector << fee
      end
    end

    fee_vector
  end
end
