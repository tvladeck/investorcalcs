function simulateBusiness (upfrontCost, paybackMonths, attritionRate,
                           renewalRate, contractLength, stopMonths,
                           padMonths, initialSalespeople, salesAddTiming,
                           salesAddNumber, dealsPerSalesperson,
                           salesSalary, salesToOps, opsSalary) {
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
//  opsSalary: salary of ops people;
//
// Returns: (object containing)
//  profit: array of revenues - salaries
//  cashflow: array of revenues - salaries - capex
//  revenues: just revenues
//  capex: just capex
//  salaries: just salaries

        var attritionRate = 1 - Math.pow(1-attritionRate, 1/12); //convert annual to monthly #
        var revenues = [];
        var capex    = [];
        var salaries = [];
        var profit   = [];
        var cashflow = [];
        var salespeople = initialSalespeople;
        var opspeople   = Math.max(Math.floor(initialSalespeople / salesToOps), 1);
        var totalMonths = stopMonths + padMonths;
        console.log("check 1");
        for(var i = 0; i < totalMonths; i++) { revenues.push(0); cashflow.push(0); }

        console.log("check 2");
        for(var i = 0; i < stopMonths; i++)
        {
                console.log("loop 1 check 1");
                if(i % salesAddTiming == 0 && i != 0) 
                // i % salesAddTiming means that it is a month where we add
                // salespeople
                // i != 0 means that we don't add in the zeroth month
                {
                        salespeople  += salesAddNumber;
                        opspeople    = Math.max(Math.floor(salespeople / salesToOps), 1);
                }

                console.log("loop 1 check 2");
                var salary = salespeople * salesSalary + opspeople * opsSalary;
                salaries.push(salary);

                console.log("loop 1 check 3");
                var numDeals = dealsPerSalesperson * salespeople;

                var monthsAhead = totalMonths - i; // this is the number of months that each set of deals will last for
                console.log("loop 1 check 3.1" + i);
                var simulation = simulateDeals(numDeals, upfrontCost, paybackMonths, attritionRate, renewalRate, contractLength, monthsAhead);

                console.log("loop 1 check 3.2");
                capex.push(simulation.capex);

                console.log("loop 1 check 4");
                var revs = simulation.revenue;
                for(var j = 0; j < i; j++)
                // this just adds zeroes to the front of the revenue stream so
                // that they are all the same length
                {
                        revs.unshift(0);
                }
                console.log("loop 1 check 5");
                for(var j = 0; j < totalMonths; j++)
                {
                        revenues[j] += revs[j];
                }
        }


        console.log("check 3");
        for(var i = 0; i < padMonths; i++)
        {
          salaries.push(0);
          capex.push(0);
        }

        console.log("check 4");
        for(var i = 0; i < totalMonths; i++)
        {
          profit[i]   = revenues[i] - salaries[i];
          cashflow[i] = revenues[i] - capex[i] - salaries[i];
        }


        console.log("check 5");
        var result =
        {
                cap: capex,
                pro: profit,
                cas: cashflow,
                rev: revenues,
                sal: salaries
        };

        return result;
}

