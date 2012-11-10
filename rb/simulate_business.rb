module Projection
  def simulate_business(upfront_cost, payback_months, attrition_rate,
                        renewal_rate, contract_length, stop_months,
                        pad_months, initial_sales, sales_add_timing,
                        sales_add_num, deals_per_sales, sales_sal,
                        sales_to_ops, ops_sal, opex_ratio)
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
##
## Returns: (object containing)
##  profit: array of revenues - salaries
##  cashflow: array of revenues - salaries - capex
##  revenues: just revenues
##  capex: just capex
##  salaries: just salaries

    attrition_rate  = 1 - ((1 - attrition_rate) ** (1 / 12.0))
    revenues        = []
    capex           = []
    salaries        = []
    profit          = []
    cashflow        = []
    opex            = []
    sales           = initial_sales
    ops             = [1, (sales / sales_to_ops).floor].max
    total_months    = stop_months + pad_months
    total_months.times do 
      revenues << 0 
      profit   << 0
      cashflow << 0
    end

    stop_months.times do |month|
      if month % sales_add_timing == 0 && month != 0
        sales += sales_add_num
        ops   = [1, (sales / sales_to_ops).floor].max
      end
      salary = sales_sal * sales + ops_sal * ops
      opex_month = opex_ratio * salary
      num_deals = deals_per_sales * sales
      months_ahead = total_months - month
      simulation = simulate_deals(num_deals, upfront_cost, payback_months,
                                  attrition_rate, renewal_rate, contract_length,
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

    pad_months.times do
      salaries  << 0
      capex     << 0
      opex      << 0
    end

    total_months.times do |m|
      profit[m] = revenues[m] - salaries[m] - opex[m]
      cashflow[m] = revenues[m] - capex[m] - salaries[m] - opex[m]
    end

    result = { :profit => profit, :cashflow => cashflow, :revenues => revenues,
               :salaries => salaries, :opex => opex }

  end
end



