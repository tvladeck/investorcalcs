class Projection

  def initialize(options = {})
## Args:
##  upfrontCost: the upfront cost of a single deal
##  paybackMonths: the number of months it takes for BH to get paid back under
##  our price
##  attritionRate: the annual probability of a customer defaulting and going
##  away
##  renewalRate: the probability of a customer renewing their deal with BH
##  contractLength: the length of our contracts
##  stopMonths: the number of months that salespeople are adding deals
##  padMonths: the number after stopmonths to keep considering the existing
##  deals
##  initialSalespeople: the number of salespeople we start with
##  salesAddTiming: the N in "every N months we add salespeople"
##  salesAddNumber: the number of salespeople we add when we add salespeople
##  dealsPerSalesperson: the number of deals per month per salesperson
##  salesSalary: salary of a salesperson
##  salesToOps: ratio of sales to operations people
##  opsSalary: salary of ops people;
##  opex_ratio: opex expenses as ratio of salary
    @upfront_cost         = options[:upfront_cost] || 2000
    @payback_months       = options[:payback_months] || 14
    @attrition_rate       = options[:attrition_rate] || 0.03
    @renewal_rate         = options[:renewal_rate] || 0.9
    @contract_length      = options[:contract_length] || 24
    @stop_months          = options[:stop_months] || 72
    @pad_months           = options[:pad_months] || 24
    @initial_sales        = options[:initial_sales] || 1
    @sales_add_timing     = options[:sales_add_timing] || 6
    @sales_add_num        = options[:sales_add_num] || 2
    @deals_per_sales      = options[:deals_per_sales] || 5
    @sales_sal            = options[:sales_sal] || 5000
    @sales_to_ops         = options[:sales_to_ops] || 10
    @ops_sal              = options[:ops_sal] || 5000
    @opex_ratio           = options[:opex_ratio] || 0.25
  end


  def simulate_business
##
## Returns: (object containing)
##  profit: array of revenues - salaries
##  cashflow: array of revenues - salaries - capex
##  revenues: just revenues
##  capex: just capex
##  salaries: just salaries

    attrition_rate  = 1 - ((1 - @attrition_rate) ** (1 / 12.0))
    revenues        = []
    capex           = []
    salaries        = []
    profit          = []
    cashflow        = []
    opex            = []
    sales           = @initial_sales
    ops             = [1, (sales / @sales_to_ops).floor].max
    total_months    = @stop_months + @pad_months
    total_months.times do 
      revenues << 0 
      profit   << 0
      cashflow << 0
    end

    @stop_months.times do |month|
      if month % @sales_add_timing == 0 && month != 0
        sales += @sales_add_num
        ops   = [1, (sales / @sales_to_ops).floor].max
      end
      salary = @sales_sal * sales + @ops_sal * ops
      opex_month = @opex_ratio * salary
      num_deals = @deals_per_sales * sales
      months_ahead = total_months - month
      simulation = simulate_deals(num_deals, @upfront_cost, @payback_months,
                                  @attrition_rate, @renewal_rate, @contract_length,
                                  months_ahead)
      capex << simulation[:capex]
      salaries << salary
      opex << opex_month

      revs = simulation[:revenues]
      month.times do
        revs.unshift(0)
      end
      total_months.times do |m|
        revenues[m] += revs[m]
      end
    end

    @pad_months.times do
      salaries  << 0
      capex     << 0
      opex      << 0
    end

    total_months.times do |m|
      profit[m] = revenues[m] - salaries[m] - opex[m]
      cashflow[m] = revenues[m] - capex[m] - salaries[m] - opex[m]
    end

    result = { :profit => profit, :cashflow => cashflow, :revenues => revenues,
               :salaries => salaries, :opex => opex, :capex => capex }
  end

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
