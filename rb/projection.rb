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
##  lamp replace years: the number of years after which we will replace the
    #lamps. given as an average value
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
    @lamp_replace_years   = options[:lamp_replace_years] || 5
    @sales_step_rate      = options[:sales_step_rate] || 1
    @sales_midpoint       = options[:sales_midpoint] || 50
  end


  def simulate_business(options={})
##
## Returns: (object containing)
##  profit: array of revenues - salaries
##  cashflow: array of revenues - salaries - capex
##  revenues: just revenues
##  capex: just capex
##  salaries: just salaries

    revenues        = []
    capex           = []
    salaries        = []
    profit          = []
    cashflow        = []
    opex            = []
    sales           = @initial_sales
    sales_add_num   = @sales_add_num
    ops             = [1, (sales / @sales_to_ops).floor].max
    total_months    = @stop_months + @pad_months
    total_months.times do
      revenues  << 0
      profit    << 0
      cashflow  << 0
      capex     << 0
    end

    @stop_months.times do |month|
      if month % @sales_add_timing == 0 && month != 0
        sales += sales_add_num
        ops   = [1, (sales / @sales_to_ops).floor].max
        if sales < @sales_midpoint
          sales_add_num += @sales_step_rate
        elsif sales > @sales_midpoint
          sales_add_num -= @sales_step_rate
          sales_add_num = [sales_add_num, 0].max
        end
      end
      salary = @sales_sal * sales + @ops_sal * ops
      opex_month = @opex_ratio * salary
      num_deals = @deals_per_sales * sales
      months_ahead = total_months - month

      salaries << salary
      opex << opex_month

      simulation = simulate_deals(num_deals, months_ahead)
      cap   = simulation[:capex]
      revs  = simulation[:revenues]
      month.times do
        revs.unshift(0)
        cap.unshift(0)
      end
      total_months.times do |m|
        revenues[m] += revs[m]
        capex[m]    += cap[m]
      end
    end

    @pad_months.times do
      salaries  << 0
      opex      << 0
    end

    total_months.times do |m|
      profit[m] = revenues[m] - salaries[m] - opex[m]
      cashflow[m] = revenues[m] - capex[m] - salaries[m] - opex[m]
    end

    result = Simulation.new(revenues, cashflow, profit,
                            capex, opex, salaries, options)

    result
  end

  def simulate_deals(n, months)
    total_upfront = n * @upfront_cost
    fee = @upfront_cost / @payback_months
    revenue_stream = []
    capex = []
    months.times do
      revenue_stream  << 0
      capex           << 0
    end

    n.times do
      deal        = contract_stream(months)
      fee_vector  = deal[:fee_vector]
      cap         = deal[:capex]
      fee_vector.each_with_index do |fee, index|
        revenue_stream[index] += fee
      end
      cap.each_with_index do |cap, index|
        capex[index] += cap
      end
    end

    result = { :capex => capex, :revenues => revenue_stream }
    result
  end

  def contract_stream(months)
    fee                 = @upfront_cost / @payback_months

    # this formula converts an annual probability into a monthly one
    # it's needed as it's easier to reason about yearly probabilities, but
    # the formula needs a monthly number.
    attrition_rate      = 1 - ((1 - @attrition_rate) ** (1 / 12.0))
    lamp_replace_months = @lamp_replace_years * 12
    fee_vector          = []
    capex               = []
    cancel_rate         = 1 - @renewal_rate
    months.times do |month|
      if month % @contract_length == 0 && month != 0 && Random.rand < cancel_rate
        break
      elsif Random.rand < attrition_rate
        break
      else
        fee_vector << fee
      end
      if month % lamp_replace_months == 0
        capex << @upfront_cost
      else
        capex << 0
      end
    end

    {:fee_vector => fee_vector, :capex => capex}
  end

end
