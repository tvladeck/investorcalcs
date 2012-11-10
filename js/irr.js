function irr (payments) 
{
        if (npv(1, payments) > 0) return 1; // ensure that irr calc returns a val
        var interval = [0, 1];
        var result = 1;
        // uses the bisection method to find the root
        while (Math.abs(result) > 0.1)
        {
                var middle = (interval[0] + interval[1]) / 2;
                result = npv(middle, payments);
                if(result < 0) interval = [interval[0], middle];
                if(result > 0) interval = [middle, interval[1]];
        }
        return middle;
}

