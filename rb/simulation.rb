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

  def cash_position
    cashflow = self.cashflow
    investments = self.investments
    months = cashflow.length
    cash = Array.new(months)
    totalcash = @init_investment + @initial_cash
    months.times do |m|
      totalcash += cashflow[m]
      if !investments[m].nil?
        totalcash += investments[m]
      end
      cash[m] = totalcash
    end
    cash
  end

  def investor_returns
    # returns a hash of the form:
    # month: { irr: irr, percentages: array }
    months      = self.cashflow.length
    investments = self.investments
    percentages = self.investment_percentages
    valuations  = self.valuations
    inv_months  = investments.keys.sort
    returns = {}

    # this loop runs for each investor
    # and first calculates the percentage of the company that she owns in each
    # month that she's involved.
    # then it takes the valuation of the company at that point, and calculates
    # the value of her investment.
    # finally, it 
    percentages.each do |m, p|
      inv_valuations = []
      current_percentage = p
      (m..(months-1)).each do |i|
        if !percentages[i].nil?
          current_percentage = current_percentage * (1 - percentages[i])
        end
        inv_valuations << current_percentage # * valuations[i]
      end

      # need to make a copy as we are updating the array and using values that
      # have already been updated (because we are subtracting the value of 
      inv_vals = inv_valuations
     # inv_vals.each_with_index do |val, idx|
     #   idx != 0 ? inv_valuations[idx] = val - inv_valuations[idx-1] : inv_valuations[idx] = 0
     # end
      returns[m] = inv_valuations
    end
    returns
  end

  def final_investment_percentages
    # calculates the percentage of the company each investor
    # group (keyed by month) owns at the end of the analysis
    # period
    months = self.investment_percentages.keys.sort.reverse
    snapshot_percentages = self.investment_percentages
    company_available = 1
    final_shares = {}
    months.each do |m|
      period_share = snapshot_percentages[m]
      final_share = company_available * period_share
      final_shares[m] = final_share
      company_available -= final_share
    end
    final_shares
  end

  def investment_percentages
    invs = self.investments
    vals = self.valuations
    inv_vals = {}
    invs.map do |month, amount|
      inv_vals[month] = amount.to_f / vals[month]
    end
    inv_vals
  end

  def valuations
    val = self.revenues.map do |r|
      [r * 12 * @multiple, @min_valuation].max
    end
    val
  end

  def investments
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
    investments
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
    if rem != 0
      ret << ary[(len-rem)..len].reduce(:+)
    end
    ret
  end

end
