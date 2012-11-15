class Simulation

  attr_accessor :capex, :revenues, :profit, :cashflow,
                :salaries, :opex, :salesforce

  def initialize(revenues, cashflow, profit, capex, opex, salaries, 
                 salesforce, options = {})
    self.capex = capex
    self.revenues = revenues
    self.profit = profit
    self.cashflow = cashflow
    self.salaries = salaries
    self.opex = opex
    self.salesforce = salesforce

    @min_valuation        = options[:min_valuation] || 1_000_000
    @multiple             = options[:multiple] || 10
    @init_investment      = options[:init_investment] || 250_000
    @invest_months_ahead  = options[:invest_months_ahead] || 6
    @initial_cash         = options[:initial_cash] || 50_000
  end

  def investment_percentages(annual = true)
    invs = self.investments
    vals = self.valuations
    inv_vals = {}
    invs.map do |month, amount|
      inv_vals[month] = amount.to_f / vals[month]
    end
    annual ? convert_to_annual(inv_vals) : inv_vals
  end

  def valuations(annual = true)
    val = self.revenues.map do |r|
      [r * 12 * @multiple, @min_valuation].max
    end
    annual ? convert_to_annual(annual) : val
  end

  def investments(annual = true)
    # simply returns a vector of when investments are taken
    cash_tracker = @initial_cash + @init_investment
    investments = {}
    num_months = self.cashflow.length
    self.cashflow.each_with_index do |cash, index|
      cash_tracker += cash
      if cash_tracker < 0
        inv_amnt = calculate_investment(index, @invest_months_ahead, self.cashflow)
        investments[index] = inv_amnt
        cash_tracker += inv_amnt
      end
    end
    annual ? convert_to_annual(investments) : investments
  end

  def calculate_investment(index, months, vector)
    # this method returns exactly the investment needed to keep the business
    # afloat for the next M months (where m is given).
    # because there is a chance that the cash flow as a whole is positive over
    # that time, but that the initial months are negative, it calculates
    # "lookahead values" for each of the 1, 2, ..., M months ahead, and takes
    # the outermost of those that is still negative
    max_val = [index + months, vector.length].min
    indices = (max_val - index).times.map { |m| index..(index + m) }
    lookahead_amounts = indices.map do |i|
      vector[i].reduce { |a, b| a + b }
    end
    inv = lookahead_amounts.reverse.each do |amount|
      if amount < 0
        return -amount
      end
    end

    # necessary to check, because if there are no negative values, the each
    # operation above will just return the whole array of values
    if inv.class == Array
      inv = 0
    end
    inv
  end

  def convert_to_annual(ary)
    len = ary.length
    rem = len % 12
    idx = len / 12
    ret = idx.times.map { |i| ary[i..(i+11)].reduce(:+) }
    ret << ary[(len-rem)..len].reduce(:+)
    ret
  end

end
