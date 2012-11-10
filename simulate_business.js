function simulateBusiness (upfrontCost, paybackMonths, attritionRate,
                           renewalRate, contractLength, stopMonths,
                           padMonths, initialSalespeople, salesAddTiming,
                           salesAddNumber, dealsPerSalesperson,
                           salesSalary, salesToOps, opsSalary)
// Args:
//  upfrontCost: the upfront cost of a single deal
//  paybackMonths: the number of months it takes for BH to get paid back under
//  our price
//  attritionRate: the annual probability of a customer defaulting and going
//  away
//  renewalRate: the probability of a customer renewing their deal with BH
//  contractLength: the length of our contracts
//  stopMonths: the number of months that salespeople are adding deals
//  padMonths: the number after stopmonths to keep considering the existing
//  deals
//  initialSalespeople: the number of salespeople we start with
//  salesAddTiming: the N in "every N months we add salespeople"
//  salesAddNumber: the number of salespeople we add when we add salespeople
//  dealsPerSalesperson: the number of deals per month per salesperson
//  salesSalary: salary of a salesperson
//  salesToOps: ratio of sales to operations people
//  opsSalary: salary of ops people
{
        var revenues = [];
        var capex    = [];
        var salaries = [];
        var profit   = [];
        var salespeople = initialSalespeople;
        var opspeople   = Math.floor(initialSalespeople / salesToOps);
        var totalMonths = stopMonths + padMonths;
        for(var i = 0; i < totalMonths; i++) { revenues.push(0); }

        for(var i = 0; i < stopMonths; i++)
        {
                if(i % salesAddTiming == 0 && i != 0) 
                // i % salesAddTiming means that it is a month where we add
                // salespeople
                // i != 0 means that we don't add in the zeroth month
                {
                        salespeople += salesAddNumber;
                        opspeople    = Math.floor(salespeople / salesToOps);
                }

                var salary = salespeople * salesSalary + opspeople * opsSalary;
                salaries.push(salary);

                var numDeals = dealsPerSalesperson * salespeople;

                var monthsAhead = totalMonths - i; // this is the number of months that each set of deals will last for
                var simulation = simulateDeals(numDeals, upfrontCost, paybackMonths, attritionRate,
                                               renewalRate, contractLength, monthsAhead);

                capex.push(simulation.capex);

                var revs = simulation.stream;
                for(var j = 0; j < i; j++)
                // this just adds zeroes to the front of the revenue stream so
                // that they are all the same length
                {
                        revs.unshift(0);
                }
                for(var j = 0; j < totalMonths; j++)
                {
                        revenues[j] += revs[j];
                }
        }


        for(var i = 0; i < padMonths; i++)
        {
          salaries.push(0);
        }

        for(var i = 0; i < totalMonths; i++)
        {
          profit[i] = revenues[i] - salaries[i];
        }

        var result =
        {
                capex: capex,
                profit: profit,
                revenues: revenues,
                salaries: salaries
        };

        return result;
}

